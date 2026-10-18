-- Behavioral checks of actual bundled controllers; no real server join occurs.
local newWorld=require('./mock_roblox')
return function(source)
    local passed=0
    local URL='https://games.roblox.com/v1/games/189707/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100'
    local function find(g,n)return assert(g:FindFirstChild(n,true),n)end
    local function click(g,n)find(g,n).Activated:Fire()end
    local function test(n,f)local ok,e=pcall(f);assert(ok,n..': '..tostring(e));passed+=1;print('PASS session tools: '..n)end
    local function launch(width,height)
        local w=newWorld();w.httpFailure=true;w.viewport={X=width or 1280,Y=height or 720}
        local c,h,r=w.character();local g=w.run(source);w.step(40);w.httpFailure=false
        return w,g,c,h,r
    end
    local function dispose(w,g)
        g:Destroy();local f=w.pg:FindFirstChild('FlyDBZ');if f then f:Destroy()end
        for _,s in pairs(w.services.RunService)do assert(s:Count()==0,'frame connection leaked')end
        assert(w.services.TeleportService.TeleportInitFailed:Count()==0)
    end
    local function page(w,url,data,cursor)
        local body='page:'..url;w.http[url]=body;w.json[body]={data=data,nextPageCursor=cursor}
    end
    local function server(id,n,max)return {id=id,playing=n,maxPlayers=max or 30}end
    local function serverRequests(w)
        local count=0;for _,url in ipairs(w.requests)do if url:find('games.roblox.com',1,true)then count+=1 end end;return count
    end
    test('Main has two click-only destinations and Settings has four readable controls',function()
        for _,v in ipairs({{1280,720},{844,390},{390,780},{320,640}})do
            local w,g=launch(v[1],v[2]);click(g,'Tab_Main');w.step(20)
            local last=find(g,'FlySS3FE')
            for _,row in ipairs({{'TeleportIsland','Teleport island'},{'TeleportTower','Teleport Tower'}})do
                local b=find(g,row[1]);assert(find(b,'ExecutableCaption').Text==row[2])
                assert(b.Parent.Name=='ExecutableOptions' and not b:FindFirstChild('ToggleStatus',true))
                assert(b.Position.Y.Offset>=last.Position.Y.Offset+last.Size.Y.Offset+12)
                assert(b.Size.Y.Offset>=44);last=b
            end
            click(g,'Tab_Settings');w.step(20)
            local toggle=find(g,'FPSCounter');assert(find(toggle,'ToggleCaption').Text=='FPS COUNTER')
            assert(find(toggle,'ToggleStatus').Text=='OFF')
            last=toggle
            for _,row in ipairs({{'RejoinServer','Rejoin Server'},{'ServerHop','Server Hop'},{'ServerHopFewPlayers','Server Hop Few players'}})do
                local b=find(g,row[1]);assert(find(b,'ExecutableCaption').Text==row[2])
                assert(b.Parent.Name=='SettingsOptions' and not b:FindFirstChild('ToggleStatus',true))
                assert(b.Position.Y.Offset>=last.Position.Y.Offset+last.Size.Y.Offset+12)
                assert(b.Size.Y.Offset>=44);last=b
            end
            assert(find(g,'Page_Settings').CanvasSize.Y.Offset>=last.Position.Y.Offset+last.Size.Y.Offset)
            assert(serverRequests(w)==0 and #w.teleportCalls==0);dispose(w,g)
        end
    end)
    test('exact island/tower positions accept every immediate click with no cooldown',function()
        local w,g,_,_,r=launch()
        for _=1,12 do
            click(g,'TeleportIsland');assert(r.Position==w.env.Vector3.new(-127.3518295288086,47.61382293701172,8.868382453918457))
            click(g,'TeleportTower');assert(r.Position==w.env.Vector3.new(-236.30526733398438,194.6138153076172,337.5936584472656))
        end
        assert(find(g,'TeleportIsland'):GetAttribute('Uses')==12 and find(g,'TeleportTower'):GetAttribute('Uses')==12)
        assert(serverRequests(w)==0 and #w.teleportCalls==0);dispose(w,g)
    end)
    test('dead/missing/seated/anchored characters never queue a teleport on respawn',function()
        for _,mode in ipairs({'dead','missing','seated','anchored','unsupported'})do
            local w,g,c,h,r=launch();local before=r.Position
            if mode=='dead'then h.Health=0 elseif mode=='missing'then c.Parent=nil
            elseif mode=='seated'then h.SeatPart=w.env.Instance.new('Seat')
            elseif mode=='anchored'then r.Anchored=true else w.env.game.PlaceId=1 end
            click(g,'TeleportIsland');assert(r.Position==before)
            local _,_,fresh=w.character();w.step(30);assert(fresh.Position==w.env.Vector3.zero)
            dispose(w,g)
        end
    end)
    test('teleport clears pending No Fall Damage and recovery while keeping all switches and FLY enabled',function()
        local w,g,c,h,r=launch();h.RigType=w.env.Enum.HumanoidRigType.R15
        for _,n in ipairs({'NoFallDamage','WalkOnWater','Antifling'})do click(g,n)end
        click(g,'FlySS3FE');local fly=find(w.pg,'FlyDBZ');click(fly,'FlightToggle')
        r.AssemblyLinearVelocity=w.env.Vector3.new(0,-160,0);w.services.RunService.Heartbeat:Fire(1/60)
        click(g,'TeleportTower');w.services.RunService.RenderStepped:Fire(1/60)
        assert(r.AssemblyLinearVelocity==w.env.Vector3.zero,'old velocity restored after teleport')
        assert(r.Position==find(g,'TeleportTower'):GetAttribute('Destination'))
        for _,n in ipairs({'NoFallDamage','WalkOnWater','Antifling'})do assert(find(find(g,n),'ToggleStatus').Text=='ON')end
        assert(fly:GetAttribute('FlightEnabled'));w.step(5)
        assert(r.Position==find(g,'TeleportTower'):GetAttribute('Destination'));dispose(w,g)
    end)
    test('FPS measures real frame cadence above 60/120 and reflects slow frames without a cap',function()
        local w,g=launch();assert(not find(g,'FPSOverlay').Visible and w.services.RunService.PreRender:Count()==0)
        for _,rate in ipairs({30,60,144,360,1440})do
            click(g,'FPSCounter');assert(w.services.RunService.PreRender:Count()==1)
            for _=1,math.ceil(rate*.5)+2 do w.services.RunService.PreRender:Fire(1/rate)end
            assert(math.abs(g:GetAttribute('MeasuredFPS')-rate)<.001)
            assert(find(g,'FPSValue').Text==tostring(rate))
            click(g,'FPSCounter');assert(w.services.RunService.PreRender:Count()==0)
        end
        click(g,'FPSCounter')
        for _,dt in ipairs({.1,.1,.3})do w.services.RunService.PreRender:Fire(dt)end
        assert(g:GetAttribute('MeasuredFPS')==6);dispose(w,g)
    end)
    test('FPS remains visible while minimized, dead and respawned; OFF releases sampling',function()
        local w,g,_,h=launch();click(g,'FPSCounter');w.step(40)
        local overlay=find(g,'FPSOverlay');assert(overlay.Visible and overlay.Position.X.Offset==12 and overlay.Position.Y.Offset==12)
        click(g,'Minimize');h.Health=0;h.Died:Fire();w.character();w.step(40)
        assert(overlay.Visible and find(g,'FPSValue').Text=='60' and g:GetAttribute('FPSCounterEnabled'))
        local old=w.services.RunService.PreRender.links[1].fn
        click(g,'FPSCounter');local value=g:GetAttribute('MeasuredFPS');old(.5);w.step(20)
        assert(not overlay.Visible and w.services.RunService.PreRender:Count()==0 and g:GetAttribute('MeasuredFPS')==value)
        dispose(w,g)
    end)
    test('FPS mouse/touch drag owns only its initiating pointer and survives viewport changes',function()
        for _,touch in ipairs({true,false})do
            local w,g=launch();click(g,'FPSCounter');w.step(20);local e=w.env;local overlay=find(g,'FPSOverlay')
            local input={UserInputType=touch and e.Enum.UserInputType.Touch or e.Enum.UserInputType.MouseButton1,Position=e.Vector3.new(50,70)}
            overlay.InputBegan:Fire(input)
            w.services.UserInputService.InputChanged:Fire({UserInputType=e.Enum.UserInputType.Touch,Position=e.Vector3.new(900,900)})
            assert(overlay.Position.X.Offset==12)
            local move=touch and input or {UserInputType=e.Enum.UserInputType.MouseMovement}
            move.Position=e.Vector3.new(-400,220);w.services.UserInputService.InputChanged:Fire(move)
            assert(overlay.Position.X.Offset==-438 and overlay.Position.Y.Offset==162)
            w.services.UserInputService.InputEnded:Fire(input)
            w.viewport={X=320,Y=640};find(g,'SafeArea'):GetPropertyChangedSignal('AbsoluteSize'):Fire()
            assert(overlay.Position.X.Offset==-438 and overlay.Size.X.Offset==296)
            assert(find(g,'FPSValue').Position.X.Scale==.51 and find(g,'FPSValue').Size.Y.Scale==.30)
            dispose(w,g)
        end
    end)
    test('Rejoin targets the current job, has one in-flight operation and can retry after failure',function()
        local w,g=launch();click(g,'RejoinServer');w.step(1)
        assert(#w.teleportCalls==1 and w.teleportCalls[1].job==w.env.game.JobId and w.teleportCalls[1].player==w.player)
        for _=1,10 do click(g,'RejoinServer');click(g,'ServerHop')end;w.step(1)
        assert(#w.teleportCalls==1 and serverRequests(w)==0)
        w.services.TeleportService.TeleportInitFailed:Fire(w.player,nil,'failure',189707,{ServerInstanceId='test'})
        assert(g:GetAttribute('ServerTravelState')=='error' and find(g,'RejoinServer').Active)
        click(g,'RejoinServer');w.step(1);assert(#w.teleportCalls==2);dispose(w,g)
    end)
    test('random hop reads bounded paginated public servers and rejects current/full/duplicate entries',function()
        local w,g=launch()
        page(w,URL,{server('test',1),server('full',30),server('A',7),server('A',7),server('bad',-1)},'next+/=')
        page(w,URL..'&cursor=next%2B%2F%3D',{server('B',2),server('C',8)})
        click(g,'ServerHop');w.step(30)
        assert(serverRequests(w)==2 and #w.teleportCalls==1)
        assert(w.teleportCalls[1].job=='A','random fixture chooses the middle eligible candidate after sorting')
        dispose(w,g)
    end)
    test('Few players chooses an empty server if listed, otherwise the lowest available count',function()
        for _,empty in ipairs({true,false})do
            local w,g=launch();local rows={server('test',0),server('busy',29),server('few',2),server('more',5)}
            if empty then rows[#rows+1]=server('empty',0)end
            page(w,URL,rows,'more-results');click(g,'ServerHopFewPlayers');w.step(2)
            assert(#w.teleportCalls==1 and w.teleportCalls[1].job==(empty and 'empty' or 'few'))
            assert(serverRequests(w)==1);dispose(w,g)
        end
    end)
    test('Few players follows cursors when the first page only contains current/full servers',function()
        local w,g=launch();page(w,URL,{server('test',0),server('full',30)},'two')
        page(w,URL..'&cursor=two',{server('few',1)});click(g,'ServerHopFewPlayers');w.step(30)
        assert(serverRequests(w)==2 and w.teleportCalls[1].job=='few');dispose(w,g)
    end)
    test('failed hop tries another candidate, ignores unrelated failures and stops after three attempts',function()
        local w,g=launch();page(w,URL,{server('A',1),server('B',2),server('C',3),server('D',4)})
        click(g,'ServerHopFewPlayers');w.step(2)
        local event=w.services.TeleportService.TeleportInitFailed
        event:Fire(w.player,nil,'failure',189707,{ServerInstanceId='unrelated'});w.step(2);assert(#w.teleportCalls==1)
        for i=1,3 do
            event:Fire(w.player,nil,'failure',189707,{ServerInstanceId=w.teleportCalls[i].job});w.step(40)
        end
        assert(#w.teleportCalls==3 and g:GetAttribute('ServerTravelState')=='error')
        assert(w.teleportCalls[1].job~=w.teleportCalls[2].job);dispose(w,g)
    end)
    test('empty results, invalid JSON and network failures restore all controls without teleporting',function()
        for _,mode in ipairs({'empty','malformed','network'})do
            local w,g=launch()
            if mode=='empty'then page(w,URL,{server('test',0)}) elseif mode=='malformed'then w.http[URL]='not-json' else w.httpFailure=true end
            click(g,'ServerHop');w.step(60)
            assert(#w.teleportCalls==0 and g:GetAttribute('ServerTravelState')=='error')
            assert(find(g,'ServerHop').Active and serverRequests(w)<=2);dispose(w,g)
        end
    end)
    test('timeouts and closing during server lookup cannot issue a late teleport',function()
        for _,mode in ipairs({'timeout','close'})do
            local w,g=launch();page(w,URL,{server('A',1)});w.httpDelay=22
            click(g,'ServerHop');w.step(1)
            if mode=='close'then click(g,'Close')end
            w.step(24,1)
            assert(#w.teleportCalls==0)
            if mode=='timeout'then assert(g:GetAttribute('ServerTravelState')=='error' and find(g,'ServerHop').Active)end
            dispose(w,g)
        end
    end)
    test('reexecution retires the old FPS sampler and pending travel while new FPS starts OFF',function()
        local w,g=launch();click(g,'FPSCounter');page(w,URL,{server('A',1)});w.httpDelay=1
        click(g,'ServerHop');w.step(1);local fresh=w.run(source);w.step(70)
        assert(g.Parent==nil and not fresh:GetAttribute('FPSCounterEnabled') and #w.teleportCalls==0)
        assert(w.services.RunService.PreRender:Count()==0 and w.services.TeleportService.TeleportInitFailed:Count()==1)
        dispose(w,fresh)
    end)
    print(passed..' session-tool scenarios passed; real rendering and teleports still require Roblox.')
end
