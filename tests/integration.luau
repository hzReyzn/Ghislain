-- Run the actual bundled hub and standalone FLY in the same simulated client.
local newWorld = require('./mock_roblox')
return function(hubSource, flySource)
    local count = 0
    local function test(name, fn) fn(); count += 1; print('PASS integration: '..name) end
    local function find(parent, name) return assert(parent:FindFirstChild(name, true), 'missing '..name) end
    local function click(parent, name) find(parent, name).Activated:Fire() end
    local function launch(width, height)
        local w = newWorld()
        w.viewport = {X=width or 1280, Y=height or 720}
        w.httpFailure = true -- Artwork availability must not gate the executable.
        local hub = w.run(hubSource)
        local character, humanoid, root = w.character()
        humanoid.RigType = w.env.Enum.HumanoidRigType.R15
        w.step(30)
        return w, hub, character, humanoid, root
    end
    local function openFly(w, hub)
        click(hub, 'FlySS3FE')
        assert(find(hub,'FlySS3FE'):GetAttribute('ExecutableState')=='ready')
        return find(w.pg, 'FlyDBZ')
    end
    local function assertOwner(w, gui)
        local ledger = find(w.pg, 'ReyznNoFallDamage_v1')
        local token = find(ledger, 'Owner').Value
        assert((token and token.Value) == gui, 'wrong No Fall Damage owner')
    end
    local function pulse(w, root, velocity)
        root.AssemblyLinearVelocity = velocity
        local before = w.velocityWrites
        w.services.RunService.Heartbeat:Fire(1/60)
        assert(w.velocityWrites == before+1, 'two velocity writers ran in one pulse')
        assert(root.AssemblyLinearVelocity == w.env.Vector3.zero)
        w.services.RunService.RenderStepped:Fire(1/60)
        assert(root.AssemblyLinearVelocity == velocity, 'original velocity was lost')
    end
    local function dispose(w, hub, fly)
        if hub and hub.Parent then hub:Destroy() end
        if fly and fly.Parent then fly:Destroy() end
        assert(not w.pg:FindFirstChild('ReyznNoFallDamage_v1'), 'ownership ledger leaked')
        for _, event in pairs(w.services.RunService) do assert(event:Count()==0, 'frame handler leaked') end
        assert(w.player.CharacterAdded:Count()==0 and w.player.CharacterRemoving:Count()==0)
    end

    test('two columns retain exact labels, a clear gap and a faint noninteractive divider', function()
        for _, size in ipairs({{1920,1080},{1280,720},{844,390},{600,900},{390,780},{320,640}}) do
            local w,h = launch(size[1],size[2]);click(h,'Tab_Main');w.step(30)
            local page, left, right = find(h,'Page_Main'), find(h,'NoFallDamage'), find(h,'FlySS3FE')
            local divider = find(h,'MainSeparator')
            assert(left.Parent.Name=='ToggleOptions' and right.Parent.Name=='ExecutableOptions')
            assert(left.AbsolutePosition.X+left.AbsoluteSize.X+12 < divider.AbsolutePosition.X)
            assert(divider.AbsolutePosition.X+12 < right.AbsolutePosition.X)
            assert(math.abs(left.AbsolutePosition.Y-right.AbsolutePosition.Y)<.1)
            assert(divider.BackgroundTransparency>=.88 and divider.BackgroundTransparency<1 and not divider.Active)
            assert(right.AbsoluteSize.Y>=44 and right.AbsoluteSize.X>=100)
            local labels=0
            for _, object in ipairs(right:GetDescendants()) do
                if object:IsA('TextLabel') then labels+=1;assert(object.Text=='FLY SS3 FE') end
                if object:IsA('GuiObject') then assert(not object.Active, 'decoration consumes input') end
            end
            assert(labels==1 and not right:FindFirstChild('ToggleStatus',true))
            assert(find(right,'ExecutableCaption').FontFace.Family=='rbxassetid://12187375422')
            local content=find(h,'MainColumns')
            assert(right.AbsolutePosition.X+right.AbsoluteSize.X<=content.AbsolutePosition.X+content.AbsoluteSize.X)
            if size[1]<600 then
                assert(page.ScrollingDirection==w.env.Enum.ScrollingDirection.XY)
                assert(page.CanvasSize.X.Offset>=content.Size.X.Offset)
            else assert(page.CanvasSize.X.Offset==0) end
            assert(not w.pg:FindFirstChild('FlyDBZ'), 'flight auto-launched')
            assert(h:GetAttribute('Version')=='1.0')
            dispose(w,h)
        end
    end)
    test('one click opens OFF; repeated clicks preserve the same live window and speed', function()
        local w,h,_,_,r=launch();local f=openFly(w,h)
        assert(not f:GetAttribute('FlightEnabled') and f:GetAttribute('FlightSpeed')==5)
        assert(not f:GetAttribute('NoFallDamageArmed') and not r:FindFirstChild('FlyDBZVelocity'))
        click(f,'FlightToggle');click(f,'SpeedUp');w.keys.W=true;w.step(90)
        local mover=find(r,'FlyDBZVelocity');local tracks=#w.loadedTracks
        for _=1,15 do assert(openFly(w,h)==f) end
        assert(f:GetAttribute('FlightSpeed')==10 and f:GetAttribute('FlightEnabled'))
        assert(find(r,'FlyDBZVelocity')==mover and #w.loadedTracks==tracks)
        assert(math.abs(mover.VectorVelocity.Z+10)<.03)
        local ledger=find(w.pg,'ReyznNoFallDamage_v1')
        assert(#find(ledger,'Clients'):GetChildren()==2)
        dispose(w,h,f)
    end)
    test('primary enabled first blocks only the FLY protection, not flight or speed edits', function()
        local w,h,_,_,r=launch();click(h,'NoFallDamage');local f=openFly(w,h);click(f,'FlightToggle')
        assertOwner(w,h)
        assert(f:GetAttribute('FlightEnabled') and not f:GetAttribute('NoFallDamageArmed'))
        pulse(w,r,w.env.Vector3.new(8,-120,3))
        click(f,'SpeedUp');assert(f:GetAttribute('FlightSpeed')==10 and find(r,'FlyDBZVelocity'))
        click(h,'NoFallDamage');assertOwner(w,f);assert(f:GetAttribute('NoFallDamageArmed'))
        pulse(w,r,w.env.Vector3.new(9,-94,6))
        dispose(w,h,f)
    end)
    test('handoff restores outgoing velocity and stale restoration cannot touch a new pulse', function()
        local w,h,_,_,r=launch();local f=openFly(w,h);click(f,'FlightToggle')
        local rs=w.services.RunService
        local flyRestore=rs.RenderStepped.links[1].fn
        local v=w.env.Vector3.new(12,-91,4);r.AssemblyLinearVelocity=v
        rs.Heartbeat:Fire(1/60);assert(r.AssemblyLinearVelocity==w.env.Vector3.zero)
        click(h,'NoFallDamage');assert(r.AssemblyLinearVelocity==v);assertOwner(w,h)
        assert(not f:GetAttribute('NoFallDamageArmed'))
        rs.Heartbeat:Fire(1/60);flyRestore()
        assert(r.AssemblyLinearVelocity==w.env.Vector3.zero, 'FLY restored the principal pulse')
        local primaryRestore=rs.RenderStepped.links[#rs.RenderStepped.links].fn
        click(h,'NoFallDamage');assert(r.AssemblyLinearVelocity==v);assertOwner(w,f)
        rs.Heartbeat:Fire(1/60);primaryRestore()
        assert(r.AssemblyLinearVelocity==w.env.Vector3.zero, 'retired principal restored FLY pulse')
        rs.RenderStepped:Fire(1/60);assert(r.AssemblyLinearVelocity==v)
        dispose(w,h,f)
    end)
    test('independent execution order and reversed frame callbacks still allow only one writer', function()
        for _, flyFirst in ipairs({false,true}) do
            local w=newWorld();w.httpFailure=true;local _,_,r=w.character()
            local f,h
            if flyFirst then f=w.run(flySource);h=w.run(hubSource)
            else h=w.run(hubSource);f=w.run(flySource) end
            click(f,'FlightToggle');click(h,'NoFallDamage');assertOwner(w,h)
            for _,reverse in ipairs({false,true}) do
                local v=w.env.Vector3.new(3,-82,9);r.AssemblyLinearVelocity=v
                local before=w.velocityWrites
                for _,name in ipairs({'Heartbeat','RenderStepped'}) do
                    local links=table.clone(w.services.RunService[name].links)
                    for index=1,#links do
                        local link=links[reverse and (#links-index+1) or index]
                        if link.Connected then w.spawn(link.fn,1/60) end
                    end
                    if name=='Heartbeat' then assert(w.velocityWrites==before+1) end
                end
                assert(r.AssemblyLinearVelocity==v)
            end
            dispose(w,h,f)
        end
    end)
    test('rapid priority changes keep velocity, mover and client ownership stable', function()
        local w,h,_,_,r=launch();local f=openFly(w,h);click(f,'FlightToggle')
        local mover=find(r,'FlyDBZVelocity');local objects=#w.objects
        for i=1,40 do
            local v=w.env.Vector3.new(i,-100-i,7);r.AssemblyLinearVelocity=v
            w.services.RunService.Heartbeat:Fire(1/60)
            click(h,'NoFallDamage')
            assert(r.AssemblyLinearVelocity==v)
            assertOwner(w,i%2==1 and h or f)
            pulse(w,r,v)
        end
        assert(#w.objects==objects and find(r,'FlyDBZVelocity')==mover)
        dispose(w,h,f)
    end)
    test('handoff preserves external writes and does not depend on immediate attribute notifications', function()
        local w,h,_,_,r=launch();local f=openFly(w,h);click(f,'FlightToggle')
        local owner=find(find(w.pg,'ReyznNoFallDamage_v1'),'Owner')
        for _,link in ipairs(owner:GetPropertyChangedSignal('Value').links) do
            local callback=link.fn
            link.fn=function() w.env.task.delay(.2,callback) end
        end
        r.AssemblyLinearVelocity=w.env.Vector3.new(2,-90,0)
        w.services.RunService.Heartbeat:Fire(1/60)
        local external=w.env.Vector3.new(19,42,11);r.AssemblyLinearVelocity=external
        click(h,'NoFallDamage');assert(r.AssemblyLinearVelocity==external)
        assertOwner(w,h);pulse(w,r,external)
        click(h,'NoFallDamage');assertOwner(w,f);pulse(w,r,external)
        click(h,'NoFallDamage');w.step(20)
        assertOwner(w,h);assert(not f:GetAttribute('NoFallDamageArmed'))
        dispose(w,h,f);w.step(20)
    end)
    test('death disarms FLY and its animation while primary remains ON across respawn', function()
        local w,h,_,hum,r=launch();local f=openFly(w,h);click(f,'FlightToggle');click(h,'NoFallDamage');w.step(5)
        hum.Health=0;hum.Died:Fire()
        assert(not f:GetAttribute('FlightEnabled') and not f:GetAttribute('NoFallDamageArmed'))
        assert(h:GetAttribute('NoFallDamageEnabled') and not r:FindFirstChild('FlyDBZVelocity'))
        for _,track in ipairs(w.loadedTracks) do assert(not track.IsPlaying and track._destroying) end
        local _,freshHum,freshRoot=w.character();freshHum.RigType=w.env.Enum.HumanoidRigType.R15
        w.step(30);assertOwner(w,h);assert(not f:GetAttribute('FlightEnabled'))
        pulse(w,freshRoot,w.env.Vector3.new(0,-88,2))
        click(h,'NoFallDamage');assertOwner(w,nil);assert(not f:GetAttribute('NoFallDamageArmed'))
        click(f,'FlightToggle');assertOwner(w,f);assert(f:GetAttribute('FlightEnabled'))
        pulse(w,freshRoot,w.env.Vector3.new(0,-93,2))
        dispose(w,h,f)
    end)
    test('closing FLY leaves a pending principal pulse and its ON state intact', function()
        local w,h,_,_,r=launch();local f=openFly(w,h);click(f,'FlightToggle');click(h,'NoFallDamage')
        local v=w.env.Vector3.new(1,-122,5);r.AssemblyLinearVelocity=v
        w.services.RunService.Heartbeat:Fire(1/60);click(f,'Close')
        assert(r.AssemblyLinearVelocity==w.env.Vector3.zero and h:GetAttribute('NoFallDamageEnabled'))
        w.services.RunService.RenderStepped:Fire(1/60);assert(r.AssemblyLinearVelocity==v)
        assertOwner(w,h);dispose(w,h,f)
    end)
    test('closing the hub releases priority to the still-active external FLY window', function()
        local w,h,_,_,r=launch();local f=openFly(w,h);click(f,'FlightToggle');click(h,'NoFallDamage')
        local v=w.env.Vector3.new(7,-101,3);r.AssemblyLinearVelocity=v
        w.services.RunService.Heartbeat:Fire(1/60);h:Destroy()
        assert(r.AssemblyLinearVelocity==v and f:GetAttribute('FlightEnabled'))
        assertOwner(w,f);assert(f:GetAttribute('NoFallDamageArmed'))
        pulse(w,r,v);dispose(w,h,f)
    end)
    test('closing principal never arms a FLY window that is OFF', function()
        local w,h,_,_,r=launch();local f=openFly(w,h);click(h,'NoFallDamage');h:Destroy()
        assertOwner(w,nil);assert(not f:GetAttribute('NoFallDamageArmed'))
        local v=w.env.Vector3.new(0,-85,0);r.AssemblyLinearVelocity=v
        local writes=w.velocityWrites;w.services.RunService.Heartbeat:Fire(1/60)
        assert(w.velocityWrites==writes and r.AssemblyLinearVelocity==v)
        dispose(w,h,f)
    end)
    test('hub reexecution preserves external flight, and standalone reexecution resets only FLY', function()
        local w,h,_,_,r=launch();local f=openFly(w,h);click(f,'FlightToggle');click(h,'NoFallDamage')
        local again=w.run(hubSource);assert(not h.Parent);h=again
        assert(not h:GetAttribute('NoFallDamageEnabled') and f:GetAttribute('FlightEnabled'))
        assertOwner(w,f);assert(openFly(w,h)==f)
        click(h,'NoFallDamage');f=w.run(flySource)
        assert(not f:GetAttribute('FlightEnabled') and h:GetAttribute('NoFallDamageEnabled'))
        assertOwner(w,h);click(f,'FlightToggle');assertOwner(w,h)
        pulse(w,r,w.env.Vector3.new(11,-79,2))
        dispose(w,h,f)
    end)
    test('root replacement cannot transfer velocity or silently reactivate flight', function()
        local w,h,char,_,r=launch();local f=openFly(w,h);click(f,'FlightToggle');click(h,'NoFallDamage')
        r.AssemblyLinearVelocity=w.env.Vector3.new(3,-90,0);w.services.RunService.Heartbeat:Fire(1/60);r:Destroy()
        local fresh=w.env.Instance.new('Part');fresh.Name='HumanoidRootPart';fresh.Parent=char
        assert(not f:GetAttribute('FlightEnabled') and h:GetAttribute('NoFallDamageEnabled'))
        pulse(w,fresh,w.env.Vector3.new(2,-70,1))
        click(h,'NoFallDamage');assertOwner(w,nil);click(f,'FlightToggle');assertOwner(w,f)
        dispose(w,h,f)
    end)
    test('both controllers respect the place guard without blocking flight', function()
        local w,h,_,_,r=launch();w.env.game.PlaceId=12345
        -- Reconstruct the hub so its immutable support guard sees the new place.
        h=w.run(hubSource);local f=openFly(w,h);click(f,'FlightToggle');click(h,'NoFallDamage')
        assert(not h:GetAttribute('NoFallDamageEnabled') and not f:GetAttribute('NoFallDamageArmed'))
        assert(f:GetAttribute('FlightEnabled') and find(r,'FlyDBZVelocity'));assertOwner(w,nil)
        dispose(w,h,f)
    end)
    test('legacy FLY windows are replaced once, and closing allows a fresh OFF launch', function()
        local w,h=launch();local legacy=w.env.Instance.new('ScreenGui');legacy.Name='FlyDBZ';legacy.Parent=w.pg
        local f=openFly(w,h);assert(legacy.Parent==nil and f~=legacy)
        assert(f:GetAttribute('NoFallCoordinatorVersion')==1)
        click(f,'Close');local again=openFly(w,h)
        assert(again~=f and not again:GetAttribute('FlightEnabled') and again:GetAttribute('FlightSpeed')==5)
        dispose(w,h,again)
    end)
    print(tostring(count)..' integration scenarios passed; Roblox physics and rendering remain manual.')
end
