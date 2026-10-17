-- Adapted from HzReyzn Hub's local collision pairs and bounded recovery.
return function(context)
    local config={Radius=65,ScanInterval=.25,MaxConstraints=2048,CreatePerStep=64,
        MaxHorizontal=140,MaxUpward=180,MaxAngular=65,SafeAge=1.5,RecoveryDistance=60}
    local pairsByPart,queue={},{}
    local folder,cursor,count,scanClock=nil,1,0,config.ScanInterval
    local safeCFrame,safeTime,safeRoot,recoveryUntil=nil,nil,nil,0
    local ray=RaycastParams.new()
    ray.FilterType=Enum.RaycastFilterType.Exclude;ray.IgnoreWater=true;ray.RespectCanCollide=true
    local function resetRecovery()
        safeCFrame,safeTime,safeRoot=nil,nil,nil;recoveryUntil=0
    end
    local function reset()
        if folder then folder:Destroy();folder=nil end
        table.clear(pairsByPart);table.clear(queue)
        cursor,count,scanClock=1,0,config.ScanInterval;resetRecovery()
    end
    local function colliders(model)
        local result={}
        for _,part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                result[#result+1]=part
                if #result>=32 then break end
            end
        end
        return result
    end
    local function scan(self)
        local neighbors={}
        for _,other in ipairs(context.players:GetPlayers()) do
            local char=other.Character
            local root=char and char:FindFirstChild("HumanoidRootPart")
            local hum=char and char:FindFirstChildOfClass("Humanoid")
            if other~=context.player and char and char.Parent and root and root:IsA("BasePart")
                and hum and hum.Health>0 then
                local distance=(root.Position-self.root.Position).Magnitude
                if distance<=config.Radius then neighbors[#neighbors+1]={model=char,distance=distance} end
            end
        end
        table.sort(neighbors,function(a,b) return a.distance<b.distance end)
        local localParts=colliders(self.character)
        local desired={};table.clear(queue);cursor=1
        local total=0
        for _,other in ipairs(neighbors) do
            for _,remote in ipairs(colliders(other.model)) do
                for _,localPart in ipairs(localParts) do
                    if total>=config.MaxConstraints then break end
                    desired[localPart]=desired[localPart] or {};desired[localPart][remote]=true
                    local existing=pairsByPart[localPart] and pairsByPart[localPart][remote]
                    if not existing or not existing.Parent then queue[#queue+1]={localPart,remote} end
                    total+=1
                end
                if total>=config.MaxConstraints then break end
            end
            if total>=config.MaxConstraints then break end
        end
        for localPart,mapping in pairs(pairsByPart) do
            for otherPart,constraint in pairs(mapping) do
                if not desired[localPart] or not desired[localPart][otherPart] or not constraint.Parent then
                    constraint:Destroy();mapping[otherPart]=nil;count-=1
                end
            end
            if not next(mapping) then pairsByPart[localPart]=nil end
        end
    end
    local function buildPairs(self)
        local made=0
        while cursor<=#queue and made<config.CreatePerStep do
            local pair=queue[cursor];cursor+=1
            local a,b=pair[1],pair[2]
            if a:IsDescendantOf(self.character) and b:IsDescendantOf(workspace) and a.CanCollide and b.CanCollide then
                if not folder or folder.Parent~=workspace then folder=Instance.new("Folder");folder.Name="ReyznAntiflingConstraints";folder.Parent=workspace end
                local constraint=Instance.new("NoCollisionConstraint")
                constraint.Name="PlayerPair";constraint.Part0=a;constraint.Part1=b;constraint.Parent=folder
                pairsByPart[a]=pairsByPart[a] or {};pairsByPart[a][b]=constraint
                count+=1;made+=1
            end
        end
    end
    local function protect(self)
        local r,h=self.root,self.humanoid
        if r.Anchored or h.SeatPart or h.PlatformStand or context.motion:isFlying(r)
            or context.motion:wasCarried(r) then resetRecovery();return end
        local velocity=context.motion:readVelocity(r)
        local angular=r.AssemblyAngularVelocity
        local horizontal=Vector3.new(velocity.X,0,velocity.Z).Magnitude
        local extreme=horizontal>math.max(config.MaxHorizontal,h.WalkSpeed*1.5+20)
            or velocity.Y>config.MaxUpward or angular.Magnitude>config.MaxAngular
        local now=os.clock()
        if extreme then
            if safeRoot==r and safeCFrame and now-safeTime<=config.SafeAge
                and (r.Position-safeCFrame.Position).Magnitude<=config.RecoveryDistance then
                local excluded={self.character}
                if folder then excluded[#excluded+1]=folder end
                for _,other in ipairs(context.players:GetPlayers()) do
                    if other~=context.player and other.Character then excluded[#excluded+1]=other.Character end
                end
                ray.FilterDescendantsInstances=excluded
                local ground=workspace:Raycast(safeCFrame.Position,Vector3.new(0,-(h.HipHeight+r.Size.Y*.5+6),0),ray)
                if ground and ground.Normal.Y>.55 then r.CFrame=safeCFrame end
            end
            context.motion:writeVelocity(r,Vector3.new(0,math.clamp(velocity.Y,-60,0),0))
            r.AssemblyAngularVelocity=Vector3.zero
            resetRecovery();recoveryUntil=now+.35
        elseif now>=recoveryUntil and h.FloorMaterial~=Enum.Material.Air
            and horizontal<config.MaxHorizontal*.5 and math.abs(velocity.Y)<15 and angular.Magnitude<8 then
            safeCFrame,safeTime,safeRoot=r.CFrame,now,r
        end
    end
    return context.newFeature(context.player,context.runService,{
        reset=reset,post=true,
        step=function(self,dt,phase)
            if phase=="pre" then
                scanClock+=dt
                if scanClock>=config.ScanInterval then scanClock=0;scan(self) end
                buildPairs(self)
            end
            protect(self)
        end,
    })
end
