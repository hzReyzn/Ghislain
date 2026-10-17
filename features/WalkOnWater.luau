-- Walk on Water from HzReyzn Hub: character/vehicle support and 400-stud area.
-- All platforms belong to this feature; flight suspends support, not the switch.
return function(context)
local char,hum,root,controller,ownedFolder
local function make(class,parent,props)
    if parent==workspace then
        if not ownedFolder or ownedFolder.Parent~=workspace then
            ownedFolder=Instance.new("Folder");ownedFolder.Name="ReyznWaterSupports";ownedFolder.Parent=workspace
        end
        parent=ownedFolder
    end
    local object=Instance.new(class)
    for key,value in pairs(props) do object[key]=value end
    object.Parent=parent
    return object
end
local waterObject, waterPad, waterLastY, waterLastSource
local waterSubject, waterParts, waterPartsAt = nil, {}, 0
local parkedWater={}
local previousWaterSeat
local areaPad,areaLastY,areaScan=nil,nil,0
local areaAssemblies,areaExclusions={},{}
local areaOverlap=OverlapParams.new()
areaOverlap.FilterType=Enum.RaycastFilterType.Exclude
areaOverlap.MaxParts=160
local function clearWaterArea()
    if areaPad then areaPad:Destroy();areaPad=nil end
    areaLastY,areaScan=nil,0
    areaAssemblies,areaExclusions={},{}
end
local waterGroundParams=RaycastParams.new()
waterGroundParams.FilterType=Enum.RaycastFilterType.Exclude
waterGroundParams.IgnoreWater=true
waterGroundParams.RespectCanCollide=true
local function clearWater()
    for _,entry in ipairs(parkedWater) do entry.pad:Destroy() end
    parkedWater={};previousWaterSeat=nil
    clearWaterArea()
    if waterPad then waterPad:Destroy();waterPad=nil end
    waterLastY,waterLastSource=nil,nil
    waterSubject,waterParts,waterPartsAt=nil,{},0
end
local waterCandidates={}
local function indexWater(obj)
    if not obj:IsA("BasePart") or (ownedFolder and obj:IsDescendantOf(ownedFolder)) then return end
    local n=obj.Name:lower()
    local parentName=obj.Parent and obj.Parent.Name:lower() or ""
    local named=n:find("flood",1,true) or n=="water" or n=="waterlevel" or parentName:find("flood",1,true)
    if n~="floodlevel" and (n=="waterlevel" or ((named or obj.Material==Enum.Material.Water) and obj.Size.X>=32 and obj.Size.Z>=32)) then
        waterCandidates[obj]=true
    end
end
local function waterSurfaceAt(position)
    waterObject=workspace:FindFirstChild("WaterLevel")
    local bestY,bestSource
    if waterObject and (waterObject:IsA("NumberValue") or waterObject:IsA("IntValue")) then
        bestY,bestSource=waterObject.Value,waterObject
    end
    if waterObject and waterObject:IsA("BasePart") then waterCandidates[waterObject]=true end
    for water in pairs(waterCandidates) do
        if water:IsDescendantOf(workspace) then
            local mesh=water:FindFirstChildWhichIsA("DataModelMesh")
            local cf=water.CFrame
            local origin=cf.Position
            local localY=water.Size.Y*0.5
            local sx,sz=water.Size.X,water.Size.Z
            if mesh then
                origin=cf:PointToWorldSpace(mesh.Offset)
                sx=sx*math.abs(mesh.Scale.X);sz=sz*math.abs(mesh.Scale.Z)
                if mesh:IsA("BlockMesh") or (mesh:IsA("SpecialMesh") and mesh.MeshType==Enum.MeshType.Brick) then
                    localY=water.Size.Y*math.abs(mesh.Scale.Y)*0.5
                else localY=0 end
            end
            local normal=cf.UpVector
            local relative=cf:VectorToObjectSpace(position-origin)
            local inside=water==waterObject or (math.abs(relative.X)<=sx*0.5 and math.abs(relative.Z)<=sz*0.5)
            if inside and normal.Y>=0.95 then
                local top=origin+normal*localY
                local y=top.Y-(normal.X*(position.X-top.X)+normal.Z*(position.Z-top.Z))/normal.Y
                if not bestY or y>bestY then bestY,bestSource=y,water end
            end
        end
    end
    -- FloodLevel is a height marker, not the full rendered water footprint.
    -- Read the live instance every frame so round replacements are handled.
    local structure=workspace:FindFirstChild("Structure")
    local flood=structure and structure:FindFirstChild("FloodLevel")
    if flood then
        local floodY
        if flood:IsA("BasePart") then
            floodY=flood.Position.Y
        elseif flood:IsA("NumberValue") or flood:IsA("IntValue") then
            floodY=flood.Value
        end
        if floodY and (not bestY or floodY>bestY) then
            bestY,bestSource=floodY,flood
        end
    end
    return bestY,bestSource
end

local function waterCharacterPart(part)
    local ancestor=part.Parent
    while ancestor and ancestor~=workspace do
        if ancestor:IsA("Model") and ancestor:FindFirstChildOfClass("Humanoid") then return true end
        ancestor=ancestor.Parent
    end
    return false
end
local function hasForeignOccupant(assembly,allowLocal)
    local function occupied(part)
        return waterCharacterPart(part) and not (allowLocal and part:IsDescendantOf(char))
    end
    if occupied(assembly) then return true end
    for _,part in ipairs(assembly:GetConnectedParts(true)) do
        if occupied(part) then return true end
    end
    return false
end
-- Collect rigid assemblies and attached wheels/chassis without moving the map.
local function waterConnectedParts(seed)
    local edges={}
    local scope=seed:FindFirstAncestorOfClass("Model") or workspace
    if scope==char then scope=workspace end
    for _,obj in ipairs(scope~=workspace and scope:GetDescendants() or {}) do
        if obj:IsA("Constraint") and obj.Enabled then
            local ok,a,b=pcall(function() return obj.Attachment0,obj.Attachment1 end)
            local pa=a and a.Parent
            local pb=b and b.Parent
            if ok and pa and pb and pa:IsA("BasePart") and pb:IsA("BasePart") then
                edges[pa]=edges[pa] or {};table.insert(edges[pa],pb)
                edges[pb]=edges[pb] or {};table.insert(edges[pb],pa)
            end
        end
    end
    local result,seen,queue={}, {}, {seed}
    local i=1
    while i<=#queue do
        local part=queue[i];i=i+1
        if not seen[part] then
            seen[part]=true
            if part.Anchored or #result>=256 or (waterCharacterPart(part) and not part:IsDescendantOf(char)) then return {} end
            result[#result+1]=part
            for _,other in ipairs(part:GetConnectedParts(true)) do
                if not seen[other] then queue[#queue+1]=other end
            end
            for _,other in ipairs(edges[part] or {}) do
                if not seen[other] then queue[#queue+1]=other end
            end
        end
    end
    return result
end
local function updateWaterObject(y,source,feet,dt)
    local seed=hum.SeatPart
    if not seed and not hum.Jump and hum:GetState()~=Enum.HumanoidStateType.Jumping then
        waterGroundParams.FilterDescendantsInstances={char,ownedFolder}
        local hit=workspace:Raycast(root.Position,Vector3.new(0,-(root.Position.Y-feet+1.2),0),waterGroundParams)
        if hit and hit.Instance:IsA("BasePart") and not waterCharacterPart(hit.Instance) then seed=hit.Instance end
    end
    -- An exited vehicle retains its own support even if we stand on its roof.
    if seed and not hum.SeatPart then
        for _,entry in ipairs(parkedWater) do
            for _,part in ipairs(entry.parts) do
                if part==seed then
                    waterSubject,waterParts=nil,{}
                    return false
                end
            end
        end
    end
    if not seed or seed.Anchored then
        waterSubject,waterParts=nil,{}
        return false
    end
    if seed~=waterSubject or os.clock()>=waterPartsAt then
        waterSubject=seed;waterPartsAt=os.clock()+.75
        waterParts=waterConnectedParts(seed)
    end
    local minX,minY,minZ=math.huge,math.huge,math.huge
    local maxX,maxZ=-math.huge,-math.huge
    local assemblies={}
    local valid=false
    for _,part in ipairs(waterParts) do
        if not part.Parent or part.Anchored then return false end
        local assembly=part.AssemblyRootPart
        if assembly then
            if assembly.Anchored or (not assemblies[assembly] and hasForeignOccupant(assembly,true)) then return false end
            assemblies[assembly]=true
        end
        if part.CanCollide and not waterCharacterPart(part) then
            local cf,size=part.CFrame,part.Size*.5
            local extent=Vector3.new(
                math.abs(cf.RightVector.X)*size.X+math.abs(cf.UpVector.X)*size.Y+math.abs(cf.LookVector.X)*size.Z,
                math.abs(cf.RightVector.Y)*size.X+math.abs(cf.UpVector.Y)*size.Y+math.abs(cf.LookVector.Y)*size.Z,
                math.abs(cf.RightVector.Z)*size.X+math.abs(cf.UpVector.Z)*size.Y+math.abs(cf.LookVector.Z)*size.Z)
            minX=math.min(minX,cf.X-extent.X);maxX=math.max(maxX,cf.X+extent.X)
            minZ=math.min(minZ,cf.Z-extent.Z);maxZ=math.max(maxZ,cf.Z+extent.Z)
            minY=math.min(minY,cf.Y-extent.Y);valid=true
        end
    end
    if not valid or maxX-minX>512 or maxZ-minZ>512 then return false end
    -- Lift a supported object by the water's rise; preserve horizontal motion.
    local shift=0
    if waterLastY and waterPad.CanCollide and math.abs(minY-waterLastY)<1.5 then
        local delta=y-waterLastY
        if delta>0 and delta<=12 then shift=delta end
    end
    if minY+shift<y-.15 and minY>=y-3 then shift=math.max(shift,y-minY) end
    if shift>0 then
        context.motion:markCarry(root)
        local offset=Vector3.new(0,shift,0)
        for assembly in pairs(assemblies) do assembly.CFrame=assembly.CFrame+offset end
        if not assemblies[root.AssemblyRootPart] then root.CFrame=root.CFrame+offset end
        minY=minY+shift
    end
    if math.abs(minY-y)<.6 then
        for assembly in pairs(assemblies) do
            local v=context.motion:readVelocity(assembly)
            local w=assembly.AssemblyAngularVelocity
            -- Leave high-speed impacts and steering alone.
            if math.abs(v.Y)<8 then context.motion:writeVelocity(assembly,Vector3.new(v.X,v.Y*math.exp(-12*math.min(dt,.1)),v.Z)) end
            assembly.AssemblyAngularVelocity=Vector3.new(w.X*math.exp(-6*math.min(dt,.1)),w.Y,w.Z*math.exp(-6*math.min(dt,.1)))
        end
    end
    waterPad.Size=Vector3.new(math.max(16,maxX-minX+4),.5,math.max(16,maxZ-minZ+4))
    waterPad.CFrame=CFrame.new((minX+maxX)*.5,y-.25,(minZ+maxZ)*.5)
    waterPad.CanCollide=minY>=y-.7
    waterLastY,waterLastSource=y,source
    return true
end

local function retainWaterVehicle()
    local seat=hum.SeatPart
    if previousWaterSeat and previousWaterSeat~=seat and waterPad and waterPad.CanCollide then
        local parts={}
        for _,part in ipairs(waterParts) do
            if part.Parent and not part.Anchored and not waterCharacterPart(part) then parts[#parts+1]=part end
        end
        if #parts>0 then
            if #parkedWater>=6 then table.remove(parkedWater,1).pad:Destroy() end
            parkedWater[#parkedWater+1]={pad=waterPad,parts=parts,lastY=waterLastY,source=waterLastSource}
            -- Transfer the actual support floor, without a frame-long gap.
            waterPad=nil;waterLastY=nil;waterLastSource=nil
            waterSubject=nil;waterParts={};waterPartsAt=0;areaScan=0
        end
    end
    previousWaterSeat=seat
end
local function updateParkedWater(dt)
    for i=#parkedWater,1,-1 do
        local entry=parkedWater[i]
        local minX,minY,minZ=math.huge,math.huge,math.huge
        local maxX,maxZ=-math.huge,-math.huge
        local assemblies,excluded={},{}
        local valid,active,inside=false,false,false
        for _,part in ipairs(waterParts) do excluded[part]=true end
        for _,part in ipairs(entry.parts) do
            if part.Parent and not part.Anchored and not waterCharacterPart(part) then
                if excluded[part] then active=true end
                if (part.Position-root.Position).Magnitude<=400 then inside=true end
                local assembly=part.AssemblyRootPart
                if assembly and not assembly.Anchored then assemblies[assembly]=true end
                if part.CanCollide then
                    local cf,h=part.CFrame,part.Size*.5
                    local e=Vector3.new(
                        math.abs(cf.RightVector.X)*h.X+math.abs(cf.UpVector.X)*h.Y+math.abs(cf.LookVector.X)*h.Z,
                        math.abs(cf.RightVector.Y)*h.X+math.abs(cf.UpVector.Y)*h.Y+math.abs(cf.LookVector.Y)*h.Z,
                        math.abs(cf.RightVector.Z)*h.X+math.abs(cf.UpVector.Z)*h.Y+math.abs(cf.LookVector.Z)*h.Z)
                    minX=math.min(minX,cf.X-e.X);maxX=math.max(maxX,cf.X+e.X)
                    minY=math.min(minY,cf.Y-e.Y)
                    minZ=math.min(minZ,cf.Z-e.Z);maxZ=math.max(maxZ,cf.Z+e.Z);valid=true
                end
            end
        end
        if active or not inside or not valid or not entry.pad.Parent then
            entry.pad:Destroy();table.remove(parkedWater,i);areaScan=0
        else
            local y,source=waterSurfaceAt(Vector3.new((minX+maxX)*.5,minY,(minZ+maxZ)*.5))
            if not y then entry.pad:Destroy();table.remove(parkedWater,i) else
                local delta=entry.lastY and source==entry.source and y-entry.lastY or 0
                local shift=0
                if entry.lastY and math.abs(minY-entry.lastY)<1.5 and delta>0 and delta<=12 then shift=delta end
                if minY+shift<y-.15 and minY>=y-3 then shift=math.max(shift,y-minY) end
                for assembly in pairs(assemblies) do
                    -- Do not move an assembly that has acquired another occupant.
                    local occupied=waterCharacterPart(assembly)
                    if not occupied then
                        for _,part in ipairs(assembly:GetConnectedParts(true)) do
                            if waterCharacterPart(part) then occupied=true;break end
                        end
                    end
                    if not occupied then
                        if shift>0 then assembly.CFrame=assembly.CFrame+Vector3.new(0,shift,0) end
                        if math.abs(minY+shift-y)<.7 then
                            local v,w=context.motion:readVelocity(assembly),assembly.AssemblyAngularVelocity
                            local vertical=math.max(v.Y,0)*math.exp(-12*math.min(dt,.1))
                            context.motion:writeVelocity(assembly,Vector3.new(v.X,vertical,v.Z))
                            local damping=math.exp(-6*math.min(dt,.1))
                            assembly.AssemblyAngularVelocity=Vector3.new(w.X*damping,w.Y,w.Z*damping)
                        end
                    end
                end
                entry.pad.Size=Vector3.new(math.max(16,maxX-minX+4),.5,math.max(16,maxZ-minZ+4))
                entry.pad.CFrame=CFrame.new((minX+maxX)*.5,y-.25,(minZ+maxZ)*.5)
                entry.pad.CanCollide=true;entry.lastY=y;entry.source=source
            end
        end
    end
end

local function updateWater(dt)
    if not controller.enabled then return end
    if waterPad and not waterPad.Parent then clearWater() end
    retainWaterVehicle()
    local y,source=waterSurfaceAt(root.Position)
    if not y then clearWater();return end
    if waterLastSource and waterLastSource~=source then clearWater() end
    if not waterPad then
        waterPad=make("Part",workspace,{
            Name="HZHubWaterSupport",Size=Vector3.new(16,0.5,16),
            Anchored=true,Transparency=1,CanCollide=false,CanTouch=false,
            CanQuery=false,CastShadow=false,
        })
    end
    local targetY=y -- Fixed separation: 0 studs.
    local leg=char:FindFirstChild("Left Leg")
    local feet=root.Position.Y-(hum.HipHeight+root.Size.Y*0.5+(leg and leg.Size.Y or 0))
    if updateWaterObject(targetY,source,feet,dt) then return end
    waterPad.Size=Vector3.new(16,.5,16)
    local grounded=waterPad.CanCollide and waterLastY and math.abs(feet-waterLastY)<0.8
        and not hum.Jump and hum:GetState()~=Enum.HumanoidStateType.Jumping
        and hum:GetState()~=Enum.HumanoidStateType.Freefall
    if grounded and source==waterLastSource then
        local delta=targetY-waterLastY
        if math.abs(delta)>.0001 and math.abs(delta)<=12 then
            waterGroundParams.FilterDescendantsInstances={char,ownedFolder}
            local ground=workspace:Raycast(root.Position,
                Vector3.new(0,-(root.Position.Y-feet+0.8),0),waterGroundParams)
            if not ground then
                context.motion:markCarry(root)
                root.CFrame=root.CFrame+Vector3.new(0,delta,0)
                feet=feet+delta
            end
        end
    end
    waterPad.CFrame=CFrame.new(root.Position.X,targetY-waterPad.Size.Y*0.5,root.Position.Z)
    waterPad.CanCollide=feet>=targetY-0.7
    waterLastY,waterLastSource=targetY,source
end

local function updateWaterArea(dt)
    if not controller.enabled or not waterPad or not waterLastY then clearWaterArea();return end
    local y=waterLastY
    if areaPad and not areaPad.Parent then clearWaterArea() end
    if not areaPad then
        areaPad=make("Part",workspace,{
            Name="HZWaterArea400",Shape=Enum.PartType.Cylinder,
            Size=Vector3.new(.5,800,800),Anchored=true,Transparency=1,
            CanCollide=true,CanTouch=false,CanQuery=false,CastShadow=false,
            CustomPhysicalProperties=PhysicalProperties.new(1,.1,0,100,100),
        })
    end
    -- Keep one support per ridden object: the area floor excludes the player
    -- and the connected vehicle/part handled by the original support pad.
    local excluded={}
    for _,part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then excluded[part]=true end
    end
    for _,part in ipairs(waterParts) do if part.Parent then excluded[part]=true end end
    for _,entry in ipairs(parkedWater) do
        for _,part in ipairs(entry.parts) do if part.Parent then excluded[part]=true end end
    end
    for part,c in pairs(areaExclusions) do
        if not excluded[part] or not part.Parent then c:Destroy();areaExclusions[part]=nil end
    end
    for part in pairs(excluded) do
        if not areaExclusions[part] or not areaExclusions[part].Parent then
            areaExclusions[part]=make("NoCollisionConstraint",areaPad,{Part0=areaPad,Part1=part})
        end
    end
    if os.clock()>=areaScan then
        areaScan=os.clock()+.4;areaAssemblies={}
        areaOverlap.FilterDescendantsInstances={char,ownedFolder}
        local seen={}
        for _,part in ipairs(workspace:GetPartBoundsInRadius(root.Position,400,areaOverlap)) do
            local assembly=part.AssemblyRootPart
            if assembly and not assembly.Anchored and not seen[assembly] and not excluded[part] then
                seen[assembly]=true
                local parts=assembly:GetConnectedParts(true)
                table.insert(parts,assembly)
                local safe=true
                for _,p in ipairs(parts) do
                    if p.Anchored or waterCharacterPart(p) then safe=false;break end
                end
                if safe and #parts<=64 then table.insert(areaAssemblies,{root=assembly,parts=parts}) end
                if #areaAssemblies>=24 then break end
            end
        end
    end
    local delta=areaLastY and y-areaLastY or 0
    local damping=math.exp(-12*math.min(dt,.1))
    local angularDamping=math.exp(-6*math.min(dt,.1))
    for _,entry in ipairs(areaAssemblies) do
        local assembly=entry.root
        if assembly.Parent and not assembly.Anchored and not excluded[assembly] then
            local bottom=math.huge
            local inside=false
            local safe=true
            for _,part in ipairs(entry.parts) do
                if not part.Parent or part.Anchored or excluded[part] or waterCharacterPart(part) then safe=false;break end
                if part.AssemblyRootPart~=assembly then safe=false;areaScan=0;break end
                if (part.Position-root.Position).Magnitude<=400 then inside=true end
                if part.CanCollide then
                    local cf,half=part.CFrame,part.Size*.5
                    local extent=math.abs(cf.RightVector.Y)*half.X+math.abs(cf.UpVector.Y)*half.Y+math.abs(cf.LookVector.Y)*half.Z
                    bottom=math.min(bottom,cf.Y-extent)
                end
            end
            if safe and inside and bottom<math.huge and not hasForeignOccupant(assembly,false) then
                if areaLastY and math.abs(bottom-areaLastY)<1.25 and delta>0 and delta<=12 then
                    assembly.CFrame=assembly.CFrame+Vector3.new(0,delta,0)
                    bottom=bottom+delta
                end
                if math.abs(bottom-y)<.6 then
                    local v,w=context.motion:readVelocity(assembly),assembly.AssemblyAngularVelocity
                    if math.abs(v.Y)<8 then context.motion:writeVelocity(assembly,Vector3.new(v.X,v.Y*damping,v.Z)) end
                    assembly.AssemblyAngularVelocity=Vector3.new(w.X*angularDamping,w.Y,w.Z*angularDamping)
                end
            end
        end
    end
    -- Cylinder's axis is X; rotate it upright for a circular 400-stud radius.
    areaPad.CFrame=CFrame.new(root.Position.X,y-.25,root.Position.Z)*CFrame.Angles(0,0,math.pi*.5)
    areaLastY=y
end

local suspended=false
local function reset()
    if root then context.motion:clearCarry(root) end
    clearWater()
    if ownedFolder then ownedFolder:Destroy();ownedFolder=nil end
    char,hum,root=nil,nil,nil;suspended=false
end
controller=context.newFeature(context.player,context.runService,{
    reset=reset,
    start=function(self)
        table.clear(waterCandidates)
        self:listen(self.links,workspace.DescendantAdded,indexWater)
        self:listen(self.links,workspace.DescendantRemoving,function(object) waterCandidates[object]=nil end)
        for _,object in ipairs(workspace:GetDescendants()) do indexWater(object) end
    end,
    stop=function() table.clear(waterCandidates) end,
    step=function(self,dt)
        char,hum,root=self.character,self.humanoid,self.root
        if root.Anchored or (hum.PlatformStand and not hum.SeatPart) or context.motion:isFlying(root) then
            if not suspended then clearWater();context.motion:clearCarry(root) end
            suspended=true;return
        end
        suspended=false
        updateWater(dt)
        if waterPad then updateParkedWater(dt);updateWaterArea(dt) end
    end,
})
return controller
end
