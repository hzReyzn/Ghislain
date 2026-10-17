-- Exercise the distributed source: real feature controllers, simulated Roblox API.
local newWorld=require('./mock_roblox')
return function(source,flySource)
    local count=0
    local function test(name,fn) fn();count+=1;print('PASS character features: '..name) end
    local function find(parent,name) return assert(parent:FindFirstChild(name,true),'missing '..name) end
    local function click(parent,name) find(parent,name).Activated:Fire() end
    local function near(a,b) assert(math.abs(a-b)<.001,tostring(a)..' ~= '..tostring(b)) end
    local function part(w,parent,name,position,size)
        local p=w.env.Instance.new('Part');p.Name=name;p.Size=size or w.env.Vector3.new(2,2,2)
        p.CFrame=w.env.CFrame.new(position);p.Parent=parent;return p
    end
    local function launch()
        local w=newWorld();w.httpFailure=true
        local c,h,r=w.character();h.RigType=w.env.Enum.HumanoidRigType.R15
        h.State=w.env.Enum.HumanoidStateType.Running;h.FloorMaterial=w.env.Enum.Material.Grass
        r.CFrame=w.env.CFrame.new(0,13,0)
        local gui=w.run(source);w.step(35)
        return w,gui,c,h,r
    end
    local function water(w,height)
        local level=w.env.Instance.new('NumberValue');level.Name='WaterLevel';level.Value=height or 10
        level.Parent=w.env.workspace;return level
    end
    local function pad(w) return w.env.workspace:FindFirstChild('HZHubWaterSupport',true) end
    local function pairsFolder(w) return w.env.workspace:FindFirstChild('ReyznAntiflingConstraints') end
    local function enemy(w,position)
        local p=w.env.Instance.new('Player');p.Name='Neighbor'
        local c=w.env.Instance.new('Model');c.Name='NeighborCharacter';c.Parent=w.env.workspace
        local h=w.env.Instance.new('Humanoid');h.Parent=c
        local r=part(w,c,'HumanoidRootPart',position or w.env.Vector3.new(5,13,0))
        p.Character=c;w.players[#w.players+1]=p
        return p,c,h,r
    end
    local function fly(w,g)
        click(g,'FlySS3FE');local f=find(w.pg,'FlyDBZ');click(f,'FlightToggle');return f
    end
    local function enabled(g,name,value)
        assert(g:GetAttribute(name..'Enabled')==value,name..' intent changed')
        assert(find(find(g,name),'ToggleStatus').Text==(value and 'ON' or 'OFF'))
    end
    local function dispose(w,g)
        if g and g.Parent then g:Destroy() end
        local f=w.pg:FindFirstChild('FlyDBZ');if f then f:Destroy() end
        assert(not w.env.workspace:FindFirstChild('ReyznWaterSupports'),'water resources leaked')
        assert(not pairsFolder(w),'collision resources leaked')
        assert(not w.pg:FindFirstChild('ReyznNoFallDamage_v1'),'shared coordinator leaked')
        for _,signal in pairs(w.services.RunService) do assert(signal:Count()==0,'frame listener leaked') end
        assert(w.player.CharacterAdded:Count()==0 and w.player.CharacterRemoving:Count()==0)
        assert(w.env.workspace.DescendantAdded:Count()==0 and w.env.workspace.DescendantRemoving:Count()==0)
    end

    test('three compact independent OFF switches remain in the left column',function()
        local w,g=launch();click(g,'Tab_Main');w.step(30)
        local previous
        for _,name in ipairs({'NoFallDamage','WalkOnWater','Antifling'}) do
            local button=find(g,name);enabled(g,name,false)
            assert(button.Parent.Name=='ToggleOptions' and button.Size.Y.Offset<=74)
            if previous then assert(button.Position.Y.Offset>=previous.Position.Y.Offset+previous.Size.Y.Offset+10) end
            previous=button
        end
        assert(find(g,'FlySS3FE').Parent.Name=='ExecutableOptions')
        assert(find(g,'MainColumns').Size.Y.Offset>=previous.Position.Y.Offset+previous.Size.Y.Offset)
        click(g,'WalkOnWater');enabled(g,'WalkOnWater',true);enabled(g,'NoFallDamage',false);enabled(g,'Antifling',false)
        click(g,'Antifling');enabled(g,'Antifling',true);enabled(g,'NoFallDamage',false)
        click(g,'WalkOnWater');enabled(g,'WalkOnWater',false);enabled(g,'Antifling',true)
        assert(g:GetAttribute('Version')=='1.0');dispose(w,g)
    end)
    test('water support tracks the live level without changing player physics',function()
        local w,g,_,h,r=launch();local level=water(w)
        click(g,'WalkOnWater');w.step(1);local support=assert(pad(w))
        near(support.Position.Y+support.Size.Y*.5,10);assert(support.CanCollide)
        assert(support.Transparency==1 and not support.CanTouch and not support.CanQuery)
        level.Value=12;w.step(1);near(r.Position.Y,15)
        level.Value=11;w.step(1);near(r.Position.Y,14)
        assert(h.WalkSpeed==16 and h.AutoRotate and not h.PlatformStand)
        assert(w.env.workspace.Gravity==196.2 and r.CanCollide)
        click(g,'WalkOnWater');assert(not pad(w));dispose(w,g)
    end)
    test('no water makes no floor; late water and round replacements recover',function()
        local w,g,_,_,r=launch();click(g,'WalkOnWater');w.step(2);assert(not pad(w))
        local level=water(w);w.step(2);assert(pad(w));local before=r.Position
        level:Destroy();local replacement=water(w,40);w.step(2)
        assert(r.Position==before and not pad(w).CanCollide,'new round teleported the character')
        replacement:Destroy();w.step(2);assert(not pad(w));enabled(g,'WalkOnWater',true)
        dispose(w,g)
    end)
    test('late surfaces, mesh offsets and flood markers use the visible water height',function()
        local w,g,_,_,r=launch();click(g,'WalkOnWater');w.step(1)
        local surface=part(w,w.env.workspace,'Water',w.env.Vector3.new(0,6,0),w.env.Vector3.new(100,2,100));surface.Anchored=true
        local mesh=w.env.Instance.new('BlockMesh');mesh.Offset=w.env.Vector3.new(0,2,0);mesh.Scale=w.env.Vector3.new(1,2,1);mesh.Parent=surface
        w.step(1);near(pad(w).Position.Y+.25,10)
        local structure=w.env.Instance.new('Model');structure.Name='Structure';structure.Parent=w.env.workspace
        local flood=part(w,structure,'FloodLevel',w.env.Vector3.new(0,18,0));flood.Anchored=true
        w.step(1);near(pad(w).Position.Y+.25,18);near(r.Position.Y,13)
        surface:Destroy();flood:Destroy();w.step(1);assert(not pad(w));dispose(w,g)
    end)
    test('water never carries jumping, airborne, submerged or grounded-on-land characters',function()
        for _,mode in ipairs({'jump','air','submerged','land'}) do
            local w,g,_,h,r=launch();local level=water(w)
            click(g,'WalkOnWater');w.step(1)
            if mode=='jump' then h.Jump=true
            elseif mode=='air' then h.State=w.env.Enum.HumanoidStateType.Freefall
            elseif mode=='submerged' then r.CFrame=w.env.CFrame.new(0,0,0)
            else
                local ground=part(w,w.env.workspace,'Ground',w.env.Vector3.new(0,0,0));ground.Anchored=true
                w.raycast=function()return {Instance=ground,Normal=w.env.Vector3.new(0,1,0)}end
            end
            local before=r.Position;level.Value=11;w.step(2);assert(r.Position==before,mode)
            if mode=='submerged' then assert(not pad(w).CanCollide) end
            dispose(w,g)
        end
    end)
    test('standing on unchanged water does not suppress Antifling corrections',function()
        local w,g,_,_,r=launch();water(w);click(g,'WalkOnWater');click(g,'Antifling');w.step(2)
        r.AssemblyLinearVelocity=w.env.Vector3.new(900,0,0);w.step(1)
        assert(r.AssemblyLinearVelocity==w.env.Vector3.zero);assert(pad(w));dispose(w,g)
    end)
    test('nearby player constraints are private, reused, and removed when no longer needed',function()
        local w,g,_,_,r=launch();local _,_,otherHum,otherRoot=enemy(w)
        click(g,'Antifling');w.step(1);local folder=assert(pairsFolder(w));local pair=folder:GetChildren()[1]
        assert(pair and pair.Part0==r and pair.Part1==otherRoot)
        local n=#w.objects;w.step(120);assert(#w.objects==n,'stable pairs allocate every frame')
        assert(r.CanCollide and otherRoot.CanCollide,'global collisions changed')
        otherRoot.CFrame=w.env.CFrame.new(100,13,0);w.step(20);assert(#folder:GetChildren()==0)
        otherRoot.CFrame=w.env.CFrame.new(5,13,0);w.step(20);assert(#folder:GetChildren()==1)
        otherHum.Health=0;w.step(20);assert(#folder:GetChildren()==0)
        dispose(w,g)
    end)
    test('collision creation is bounded per frame and nearest players are prioritized',function()
        local w,g,c=launch()
        for i=1,20 do part(w,c,'Local'..i,w.env.Vector3.new(0,13,0)) end
        for j=1,6 do
            local _,remote=enemy(w,w.env.Vector3.new(j*5,13,0))
            for i=1,20 do part(w,remote,'Remote'..i,w.env.Vector3.new(j*5,13,0)) end
        end
        click(g,'Antifling');w.step(1);assert(#pairsFolder(w):GetChildren()<=64)
        w.step(100);assert(#pairsFolder(w):GetChildren()<=2048)
        dispose(w,g)
    end)
    test('Antifling clamps only exceptional impacts and retains downward fall behavior',function()
        local w,g,_,_,r=launch();click(g,'Antifling')
        local ordinary=w.env.Vector3.new(18,-95,0);r.AssemblyLinearVelocity=ordinary;w.step(1)
        assert(r.AssemblyLinearVelocity==ordinary)
        r.AssemblyLinearVelocity=w.env.Vector3.new(450,250,0);r.AssemblyAngularVelocity=w.env.Vector3.new(100,0,0)
        w.step(1);assert(r.AssemblyLinearVelocity==w.env.Vector3.zero and r.AssemblyAngularVelocity==w.env.Vector3.zero)
        dispose(w,g)
    end)
    test('safe recovery needs recent supported ground and never snaps across a teleport',function()
        local w,g,_,h,r=launch();local ground=part(w,w.env.workspace,'Ground',w.env.Vector3.new());ground.Anchored=true
        w.raycast=function()return {Instance=ground,Normal=w.env.Vector3.new(0,1,0)}end
        click(g,'Antifling');w.step(1);local safe=r.CFrame
        r.CFrame=w.env.CFrame.new(10,20,0);r.AssemblyLinearVelocity=w.env.Vector3.new(900,0,0);w.step(1)
        assert(r.Position==safe.Position)
        w.step(30);r.CFrame=w.env.CFrame.new(500,20,0);r.AssemblyLinearVelocity=w.env.Vector3.new(900,0,0);w.step(1)
        near(r.Position.X,500)
        h.FloorMaterial=w.env.Enum.Material.Air;w.step(2);dispose(w,g)
    end)
    test('Antifling sees through pending NFD pulses and cancels stale zero/nonzero restores',function()
        for _,down in ipairs({0,-30}) do
            for _,primaryFirst in ipairs({false,true}) do
                local w,g,_,_,r=launch()
                if primaryFirst then click(g,'NoFallDamage');click(g,'Antifling')
                else click(g,'Antifling');click(g,'NoFallDamage') end
                r.AssemblyLinearVelocity=w.env.Vector3.new(500,down,0)
                w.services.RunService.Heartbeat:Fire(.02);assert(r.AssemblyLinearVelocity==w.env.Vector3.zero)
                w.services.RunService.PostSimulation:Fire(.02)
                local correction=w.env.Vector3.new(0,down,0);assert(r.AssemblyLinearVelocity==correction)
                w.services.RunService.RenderStepped:Fire(.02);assert(r.AssemblyLinearVelocity==correction)
                w.services.RunService.PreSimulation:Fire(.02);assert(r.AssemblyLinearVelocity==correction)
                enabled(g,'NoFallDamage',true);dispose(w,g)
            end
        end
    end)
    test('all features coexist with maximum flight speed; water resumes after manual OFF',function()
        for _,first in ipairs({true,false}) do
            local w,g,_,h,r=launch();water(w);enemy(w);local f
            if first then f=fly(w,g) end
            for _,name in ipairs({'WalkOnWater','Antifling','NoFallDamage'}) do click(g,name) end
            if not first then f=fly(w,g) end
            local box=find(f,'SpeedValue');box.Text='5000';box.FocusLost:Fire(true);w.keys.W=true;w.step(100)
            local v=w.env.Vector3.new(5000,200,0);r.AssemblyLinearVelocity=v;w.step(2)
            assert(r.AssemblyLinearVelocity==v and not pad(w))
            assert(#pairsFolder(w):GetChildren()>0 and h.PlatformStand)
            assert(math.abs(find(r,'FlyDBZVelocity').VectorVelocity.Magnitude-5000)<1)
            assert(not f:GetAttribute('NoFallDamageArmed'))
            for _,name in ipairs({'WalkOnWater','Antifling','NoFallDamage'}) do enabled(g,name,true) end
            click(f,'FlightToggle');r.AssemblyLinearVelocity=w.env.Vector3.zero
            h.State=w.env.Enum.HumanoidStateType.Running;w.step(2);assert(pad(w))
            dispose(w,g)
        end
    end)
    test('individual OFF switches do not destroy another controller or external flight',function()
        local w,g,_,_,r=launch();water(w);enemy(w)
        for _,name in ipairs({'WalkOnWater','Antifling','NoFallDamage'}) do click(g,name) end
        w.step(1);local p=pad(w);click(g,'Antifling');assert(pad(w)==p and not pairsFolder(w))
        click(g,'Antifling');w.step(1);local folder=pairsFolder(w);click(g,'WalkOnWater')
        assert(pairsFolder(w)==folder and not pad(w));enabled(g,'NoFallDamage',true)
        local f=fly(w,g);click(g,'Antifling');click(g,'NoFallDamage')
        assert(find(r,'FlyDBZVelocity') and f:GetAttribute('NoFallDamageArmed'))
        dispose(w,g)
    end)
    test('death preserves three toggle intents but disarms flight until manual ON',function()
        local w,g,_,h,r=launch();water(w);enemy(w)
        for _,name in ipairs({'WalkOnWater','Antifling','NoFallDamage'}) do click(g,name) end
        local f=fly(w,g);w.step(1);h.Health=0;h.Died:Fire();w.step(1)
        assert(not pad(w) and not pairsFolder(w) and not r:FindFirstChild('FlyDBZVelocity'))
        assert(not f:GetAttribute('FlightEnabled') and not f:GetAttribute('NoFallDamageArmed'))
        for _,name in ipairs({'WalkOnWater','Antifling','NoFallDamage'}) do enabled(g,name,true) end
        local _,h2,r2=w.character();r2.CFrame=w.env.CFrame.new(0,13,0);w.step(2)
        assert(pad(w) and pairsFolder(w) and not h2.PlatformStand and not r2:FindFirstChild('FlyDBZVelocity'))
        local before=w.velocityWrites;w.services.RunService.Heartbeat:Fire(.02);assert(w.velocityWrites==before+1)
        dispose(w,g)
    end)
    test('reset without death and missing parts recover without a queued flight activation',function()
        local w,g=launch();water(w);enemy(w)
        for _,name in ipairs({'WalkOnWater','Antifling','NoFallDamage'}) do click(g,name) end
        local f=fly(w,g);local c,h,r=w.character();h.Parent=nil;r.Parent=nil;w.step(2)
        assert(not pad(w) and not pairsFolder(w));h.Parent=c;r.CFrame=w.env.CFrame.new(0,13,0);r.Parent=c;w.step(2)
        assert(pad(w) and pairsFolder(w) and not f:GetAttribute('FlightEnabled'))
        dispose(w,g)
    end)
    test('root replacement clears old resources and ignores callbacks from the retired body',function()
        local w,g,c,h,r=launch();water(w);enemy(w)
        click(g,'WalkOnWater');click(g,'Antifling');w.step(1)
        local callbacks={};for _,entry in ipairs(h.Died.links) do callbacks[#callbacks+1]=entry.fn end
        local oldPad=pad(w);r.Parent=nil
        local replacement=part(w,c,'HumanoidRootPart',w.env.Vector3.new(0,13,0));w.step(1)
        local newPad=pad(w);assert(newPad and newPad~=oldPad and oldPad._destroying)
        for _,callback in ipairs(callbacks) do callback() end
        w.step(1);assert(pad(w)==newPad and pairsFolder(w));assert(replacement~=r)
        dispose(w,g)
    end)
    test('void and model removal release resources before parts disappear; fresh bodies recover',function()
        for _,mode in ipairs({'void','detached','stored'}) do
            local w,g,c,_,r=launch();water(w);enemy(w)
            for _,name in ipairs({'WalkOnWater','Antifling','NoFallDamage'}) do click(g,name) end
            local f=fly(w,g);w.step(1)
            if mode=='void' then r.CFrame=w.env.CFrame.new(0,-501,0)
            elseif mode=='stored' then c.Parent=w.pg else c.Parent=nil end
            w.step(2);assert(not pad(w) and not pairsFolder(w) and not f:GetAttribute('FlightEnabled'))
            local before=w.velocityWrites;w.services.RunService.Heartbeat:Fire(.02)
            assert(w.velocityWrites==before,'protection wrote to an unavailable character')
            local _,_,nextRoot=w.character();nextRoot.CFrame=w.env.CFrame.new(0,13,0);w.step(2)
            assert(pad(w) and pairsFolder(w));enabled(g,'WalkOnWater',true);enabled(g,'Antifling',true)
            dispose(w,g)
        end
    end)
    test('manual OFF while dead remains OFF after respawn',function()
        local w,g,_,h=launch();water(w);enemy(w);click(g,'WalkOnWater');click(g,'Antifling');w.step(1)
        h.Health=0;click(g,'WalkOnWater');click(g,'Antifling');w.character();w.step(2)
        assert(not pad(w) and not pairsFolder(w));enabled(g,'WalkOnWater',false);enabled(g,'Antifling',false)
        dispose(w,g)
    end)
    test('water vehicle damping invalidates a pending NFD value on the same rigid assembly',function()
        local w,g,c,h,r=launch();water(w)
        local vehicle=w.env.Instance.new('Model');vehicle.Parent=w.env.workspace
        local seat=part(w,vehicle,'Seat',w.env.Vector3.new(0,11,0));h.SeatPart=seat
        r.AssemblyRootPart=seat;seat._connected={r};r._connected={seat}
        click(g,'NoFallDamage');click(g,'WalkOnWater')
        seat.AssemblyLinearVelocity=w.env.Vector3.new(20,-4,0)
        w.services.RunService.Heartbeat:Fire(.02);assert(seat.AssemblyLinearVelocity==w.env.Vector3.zero)
        w.services.RunService.PreSimulation:Fire(.02)
        local v=seat.AssemblyLinearVelocity;near(v.X,20);assert(v.Y> -4 and v.Y<0)
        w.services.RunService.RenderStepped:Fire(.02);assert(seat.AssemblyLinearVelocity==v)
        assert(pad(w));dispose(w,g)
    end)
    test('nearby vehicles never move a newly acquired character assembly',function()
        local w,g,_,_,r=launch();local level=water(w)
        local vehicle=part(w,w.env.workspace,'FloatingCrate',w.env.Vector3.new(20,11,0));w.nearby={vehicle}
        click(g,'WalkOnWater');w.step(1)
        local _,_,_,remoteRoot=enemy(w,w.env.Vector3.new(20,13,0))
        vehicle._connected={remoteRoot};remoteRoot.AssemblyRootPart=vehicle
        local before=vehicle.Position;level.Value=11;w.step(1);assert(vehicle.Position==before)
        assert(r.Position.Y==14);dispose(w,g)
    end)
    test('exiting a vehicle retains its support but stops carrying a new occupant',function()
        local w,g,_,h,r=launch();local level=water(w)
        local vehicle=w.env.Instance.new('Model');vehicle.Parent=w.env.workspace
        local seat=part(w,vehicle,'Seat',w.env.Vector3.new(0,11,0));h.SeatPart=seat
        r.AssemblyRootPart=seat;seat._connected={r};r._connected={seat}
        click(g,'WalkOnWater');w.step(1);local vehiclePad=pad(w)
        h.SeatPart=nil;r.AssemblyRootPart=nil;r._connected={};seat._connected={}
        r.CFrame=w.env.CFrame.new(20,13,0);w.step(1)
        assert(vehiclePad.Parent and vehiclePad.CanCollide,'exited vehicle lost its floor')
        local _,_,_,occupant=enemy(w,w.env.Vector3.new(0,13,0))
        occupant.AssemblyRootPart=seat;seat._connected={occupant}
        local before=seat.Position;level.Value=11;w.step(1)
        assert(seat.Position==before,'parked support moved another occupant')
        click(g,'WalkOnWater');assert(vehiclePad._destroying);dispose(w,g)
    end)
    test('deleted owned pads and collision pairs are recreated without duplicates',function()
        local w,g=launch();water(w);enemy(w);click(g,'WalkOnWater');click(g,'Antifling');w.step(1)
        pad(w):Destroy();pairsFolder(w):Destroy();w.step(20)
        assert(pad(w) and #pairsFolder(w):GetChildren()==1)
        find(w.env.workspace,'HZWaterArea400'):Destroy();w.step(2)
        assert(find(w.env.workspace,'HZWaterArea400'));dispose(w,g)
    end)
    test('world scans occur only on enable; idle operation reuses platforms and constraints',function()
        local w,g=launch();water(w);enemy(w);click(g,'WalkOnWater');click(g,'Antifling');w.step(2)
        local scans=w.descendantScans;local n=#w.objects;w.step(120)
        assert(w.descendantScans==scans,'full world rescanned each frame')
        assert(#w.objects==n,'steady operation allocated Instances')
        dispose(w,g)
    end)
    test('rapid cycles and old callbacks cannot affect a fresh activation',function()
        local w,g=launch();water(w);enemy(w)
        click(g,'WalkOnWater');click(g,'Antifling');w.step(1)
        local callbacks={};for _,entry in ipairs(w.services.RunService.PreSimulation.links) do callbacks[#callbacks+1]=entry.fn end
        for _=1,12 do
            click(g,'WalkOnWater');click(g,'Antifling');click(g,'WalkOnWater');click(g,'Antifling');w.step(1)
        end
        local p,folder=pad(w),pairsFolder(w)
        for _,callback in ipairs(callbacks) do callback(.02) end
        assert(pad(w)==p and pairsFolder(w)==folder)
        assert(w.env.workspace.DescendantAdded:Count()==1 and w.env.workspace.DescendantRemoving:Count()==1)
        dispose(w,g)
    end)
    test('closing and reexecuting the hub clear only its features; FLY stays independent',function()
        local w,g,_,_,r=launch();water(w);enemy(w)
        for _,name in ipairs({'WalkOnWater','Antifling','NoFallDamage'}) do click(g,name) end
        local f=fly(w,g);w.step(1);g:Destroy()
        assert(not pad(w) and not pairsFolder(w) and find(r,'FlyDBZVelocity'))
        assert(f:GetAttribute('FlightEnabled') and f:GetAttribute('NoFallDamageArmed'))
        local fresh=w.run(source);w.step(1)
        for _,name in ipairs({'WalkOnWater','Antifling','NoFallDamage'}) do enabled(fresh,name,false) end
        assert(find(w.pg,'FlyDBZ')==f);dispose(w,fresh)
    end)
    print(tostring(count)..' character-feature scenarios passed; live physics still require Roblox.')
end
