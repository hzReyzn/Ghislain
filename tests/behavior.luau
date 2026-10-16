local newWorld=require('./mock_roblox')
return function(source)
    local count=0
    local URL='https://raw.githubusercontent.com/hzReyzn/Ghislain/main/assets/reyzn-x/'
    local function png(bytes) return '\137PNG\13\10\26\10'..'\0\0\0\13IHDR'..string.rep('a',bytes-24)..'IEND\174\66\96\130' end
    local artwork={['launcher-r-v1.png']=png(2136070),['emblem-x-v1.png']=png(1699126)}
    local function setup(width,height)
        local w=newWorld();w.viewport={X=width or 1280,Y=height or 720}
        for name,data in pairs(artwork) do w.http[URL..name]=data end
        return w
    end
    local function launch(width,height)
        local w=setup(width,height);local gui=w.run(source)
        assert(gui and gui.Name=='ReyznX');return w,gui
    end
    local function find(gui,name) return assert(gui:FindFirstChild(name,true),'missing '..name) end
    local function click(gui,name) find(gui,name).Activated:Fire() end
    local function close(w,gui) click(gui,'Close');w.step(30);assert(gui.Parent==nil) end
    local function near(a,b,message) assert(math.abs(a-b)<.02,message or (tostring(a)..' ~= '..tostring(b))) end
    local function test(name,fn) fn();count+=1;print('PASS '..name) end
    local function drag(w,gui,target,dx,dy,touch)
        local e=w.env
        local input={UserInputType=touch and e.Enum.UserInputType.Touch or e.Enum.UserInputType.MouseButton1,Position=e.Vector3.new(200,140)}
        find(gui,target).InputBegan:Fire(input)
        local change=touch and input or {UserInputType=e.Enum.UserInputType.MouseMovement}
        change.Position=e.Vector3.new(200+dx,140+dy)
        w.services.UserInputService.InputChanged:Fire(change)
        w.services.UserInputService.InputEnded:Fire(input)
    end
    test('clean interface, original requested identity and four font changes',function()
        local w,gui=launch();w.step(30)
        assert(gui.ResetOnSpawn==false and gui:GetAttribute('Version')=='2.0.0')
        assert(find(gui,'UserID').Text=='ID  123' and find(gui,'SessionTime').Text=='00:00:00')
        assert(w.thumbnailRequest.id==123 and w.thumbnailRequest.kind.Name=='HeadShot')
        assert(find(gui,'Avatar').Image=='rbxthumb://test-avatar')
        assert(find(gui,'Credit').Text=='Made By Reyzn')
        for _,name in ipairs({'Main','Visuals','Scripts','Settings'}) do
            assert(find(gui,'Tab_'..name):FindFirstChild('Caption').Font.Name=='BuilderSansMedium')
            assert(#find(gui,'Page_'..name):GetChildren()==0,'section should be empty')
        end
        assert(find(gui,'Tab_Home'):FindFirstChild('Caption').Font.Name=='GothamMedium')
        local banned={'Your Workspace','YOUR WORKSPACE','WORKSPACE','Make it yours','Choose your accent','A clean slate','A new space','Themes','Key System','Featured Scripts','Links','Ghislain','Built for gamers','Play • Exploit • Dominate'}
        for _,o in ipairs(gui:GetDescendants())do
            for _,text in ipairs(banned) do assert(not (o.Text or ''):find(text,1,true),'unnecessary text: '..text) end
            assert(o.ClassName~='VideoFrame' and o.ClassName~='Sound' and o.ClassName~='CanvasGroup')
        end
        for _,name in ipairs({'Maximize','Size_Large','Size_Default','Size_Compact','Theme_Amethyst','Theme_Ember','Motion','AmbientGlow','Recenter','DrawerShade'}) do
            assert(not gui:FindFirstChild(name,true),'obsolete control: '..name)
        end
        close(w,gui)
    end)
    test('supplied PNGs load once, register locally and preserve transparency',function()
        local w,gui=launch();w.step(30)
        assert(#w.requests==2 and #w.writes==2)
        assert(w.files['ReyznX-launcher-r-v1.png']==artwork['launcher-r-v1.png'])
        assert(w.files['ReyznX-emblem-x-v1.png']==artwork['emblem-x-v1.png'])
        assert(find(gui,'EmblemX').Image=='mock://ReyznX-emblem-x-v1.png')
        assert(find(gui,'LauncherR').Image=='mock://ReyznX-launcher-r-v1.png')
        assert(find(gui,'RecoveryR').Image==find(gui,'LauncherR').Image)
        assert(gui:GetAttribute('AssetX')=='ready' and gui:GetAttribute('AssetR')=='ready')
        assert(not find(gui,'XFallback').Visible and not find(gui,'RFallback').Visible)
        assert(find(gui,'EmblemX').ImageTransparency==0 and find(gui,'EmblemX').BackgroundTransparency==1)
        click(gui,'Minimize');w.step(30)
        assert(find(gui,'LauncherR').ImageTransparency==0 and find(gui,'Launcher').BackgroundTransparency==1)
        local again=w.run(source);w.step(30)
        assert(gui.Parent==nil and #w.requests==2 and #w.writes==2,'valid cache was downloaded again')
        close(w,again)
    end)
    test('only selected section opens to the right; dock works on its own',function()
        local w,gui=launch();w.step(30)
        local dock=find(gui,'Dock');local dockX=dock.AbsolutePosition.X
        local full=find(gui,'Window').Size.X.Offset
        click(gui,'Collapse');w.step(8)
        local middle=find(gui,'PanelReveal').Size.X.Offset
        assert(middle>0 and middle<full-dock.Size.X.Offset,'panel did not animate')
        w.step(30)
        assert(not find(gui,'PanelReveal').Visible and not gui:GetAttribute('PanelOpen'))
        assert(find(gui,'Window').Size.X.Offset==dock.Size.X.Offset)
        near(dock.AbsolutePosition.X,dockX,'dock moved while folding')
        click(gui,'Tab_Scripts');w.step(8)
        assert(find(gui,'PanelReveal').Size.X.Offset>0 and find(gui,'PanelReveal').Size.X.Offset<middle+full)
        w.step(30)
        assert(gui:GetAttribute('Page')=='Scripts' and gui:GetAttribute('PanelOpen'))
        for _,name in ipairs({'Home','Main','Visuals','Scripts','Settings'}) do
            assert(find(gui,'Page_'..name).Visible==(name=='Scripts'))
        end
        near(dock.AbsolutePosition.X,dockX)
        click(gui,'Tab_Scripts');w.step(30);assert(not find(gui,'PanelReveal').Visible)
        click(gui,'Tab_Home');w.step(30);click(gui,'OpenMain');w.step(30)
        assert(gui:GetAttribute('Page')=='Main' and find(gui,'Page_Main').Visible)
        close(w,gui)
    end)
    test('rapid page/fold reversal preserves geometry and restores scroll origin',function()
        local w,gui=launch();w.step(30)
        for _,name in ipairs({'Main','Scripts','Settings','Visuals','Home'}) do
            click(gui,'Tab_'..name);w.step(3);click(gui,'Collapse');w.step(2)
        end
        click(gui,'Tab_Main');w.step(30)
        assert(gui:GetAttribute('Page')=='Main' and gui:GetAttribute('PanelOpen'))
        assert(find(gui,'Page_Main').Position.X.Offset==0 and find(gui,'PageOpacity').Value==1)
        assert(find(gui,'Panel').Position.X.Offset==4)
        find(gui,'Page_Home').CanvasPosition=w.env.Vector2.new(0,200)
        click(gui,'Tab_Home');assert(find(gui,'Page_Home').CanvasPosition.Y==0)
        w.step(6);assert(find(gui,'Page_Home').Position.X.Offset<0)
        w.step(30);assert(find(gui,'Page_Home').Position.X.Offset==0)
        close(w,gui)
    end)
    test('free drag crosses all four screen edges and resize does not clamp',function()
        local w,gui=launch(1280,720);w.step(30)
        local win=find(gui,'Window');local x,y=win.Position.X.Offset,win.Position.Y.Offset
        drag(w,gui,'DragArea',-1900,-1200,false)
        near(win.Position.X.Offset,x-1900);near(win.Position.Y.Offset,y-1200)
        assert(win.AbsolutePosition.X+win.AbsoluteSize.X<0 and win.AbsolutePosition.Y+win.AbsoluteSize.Y<0)
        w.step(3);assert(find(gui,'Recover').Visible,'off-screen recovery missing')
        w.viewport={X=720,Y=1280};find(gui,'SafeArea'):GetPropertyChangedSignal('AbsoluteSize'):Fire()
        near(win.Position.X.Offset,x-1900,'resize clamped position')
        click(gui,'Recover');w.step(30);assert(not find(gui,'Recover').Visible)
        x,y=win.Position.X.Offset,win.Position.Y.Offset
        drag(w,gui,'PanelDragArea',2200,2400,true)
        near(win.Position.X.Offset,x+2200);near(win.Position.Y.Offset,y+2400)
        assert(win.AbsolutePosition.X>w.viewport.X and win.AbsolutePosition.Y>w.viewport.Y)
        w.step(3);assert(find(gui,'Recover').Visible)
        w.services.UserInputService.InputBegan:Fire({KeyCode=w.env.Enum.KeyCode.RightShift},false);w.step(30)
        assert(win.AbsolutePosition.X>=0 and win.AbsolutePosition.Y>=0)
        close(w,gui)
    end)
    test('touch ownership, body scrolling and focus release do not move window',function()
        local w,gui=launch(844,354);w.step(30);local e=w.env
        local win=find(gui,'Window');local x,y=win.Position.X.Offset,win.Position.Y.Offset
        local input={UserInputType=e.Enum.UserInputType.Touch,Position=e.Vector3.new(200,100)}
        find(gui,'Page_Home').InputBegan:Fire(input)
        input.Position=e.Vector3.new(200,170);w.services.UserInputService.InputChanged:Fire(input)
        near(win.Position.X.Offset,x);near(win.Position.Y.Offset,y)
        input.Position=e.Vector3.new(200,100);find(gui,'DragArea').InputBegan:Fire(input)
        local other={UserInputType=e.Enum.UserInputType.Touch,Position=e.Vector3.new(500,500)}
        w.services.UserInputService.InputChanged:Fire(other);w.services.UserInputService.InputEnded:Fire(other)
        near(win.Position.Y.Offset,y)
        input.Position=e.Vector3.new(280,130);w.services.UserInputService.InputChanged:Fire(input)
        near(win.Position.X.Offset,x+80);near(win.Position.Y.Offset,y+30)
        w.services.UserInputService.WindowFocusReleased:Fire()
        input.Position=e.Vector3.new(100,400);w.services.UserInputService.InputChanged:Fire(input)
        near(win.Position.X.Offset,x+80);near(win.Position.Y.Offset,y+30)
        close(w,gui)
    end)
    test('minimized R is freely draggable; releasing a drag never restores it',function()
        local w,gui=launch();w.step(30);click(gui,'Minimize');w.step(30)
        local launcher=find(gui,'Launcher');local x,y=launcher.Position.X.Offset,launcher.Position.Y.Offset
        drag(w,gui,'Launcher',220,100,true);click(gui,'Launcher')
        near(launcher.Position.X.Offset,x+220);near(launcher.Position.Y.Offset,y+100)
        assert(gui:GetAttribute('Minimized'))
        w.step(30);click(gui,'Launcher');w.step(30)
        assert(not gui:GetAttribute('Minimized') and find(gui,'Window').Visible)
        click(gui,'Minimize');w.step(30)
        near(launcher.Position.X.Offset,x+220,'launcher position reset')
        drag(w,gui,'Launcher',-2000,1800,false);w.step(30)
        assert(launcher.Position.X.Offset<0 and launcher.Position.Y.Offset>w.viewport.Y)
        assert(find(gui,'Recover').Visible);click(gui,'Recover');w.step(30)
        assert(not gui:GetAttribute('Minimized'))
        close(w,gui)
    end)
    test('fade has intermediate frames; repeated and reversed transitions stay crisp',function()
        local w,gui=launch();w.step(30)
        local x,y=find(gui,'Window').Position.X.Offset,find(gui,'Window').Position.Y.Offset
        for cycle=1,8 do
            click(gui,'Minimize');w.step(6)
            assert(find(gui,'WindowOpacity').Value>0 and find(gui,'WindowOpacity').Value<1)
            assert(find(gui,'LauncherOpacity').Value>0 and find(gui,'LauncherOpacity').Value<1)
            if cycle%2==0 then w.step(30) end
            click(gui,'Launcher');w.step(30)
            assert(find(gui,'WindowOpacity').Value==1 and find(gui,'WindowZoom').Value==1)
            assert(find(gui,'Dock').BackgroundTransparency==0 and find(gui,'Panel').BackgroundTransparency==0)
            assert(find(gui,'EmblemX').ImageTransparency==0,'artwork became progressively faint')
            assert(find(gui,'HeroTitle').TextTransparency==0,'text became progressively faint')
            assert(find(gui,'Window').Visible and not find(gui,'Launcher').Visible)
            near(find(gui,'Window').Position.X.Offset,x);near(find(gui,'Window').Position.Y.Offset,y)
        end
        click(gui,'Close');w.step(7)
        assert(gui.Parent and find(gui,'WindowOpacity').Value>0 and find(gui,'WindowOpacity').Value<1)
        click(gui,'Minimize');click(gui,'Launcher');w.step(30);assert(gui.Parent==nil,'close resurrected GUI')
    end)
    test('session clock continues through collapse, minimize and respawn',function()
        local w,gui=launch();w.step(61);assert(find(gui,'SessionTime').Text=='00:00:01')
        click(gui,'Collapse');w.step(30);click(gui,'Minimize');w.step(30)
        w.time=65;w.step(1);assert(find(gui,'SessionTime').Text=='00:01:05')
        w.character();assert(gui.Parent==w.pg)
        click(gui,'Launcher');w.step(30);assert(not gui:GetAttribute('PanelOpen'))
        click(gui,'Tab_Settings');w.step(30)
        w.time=3601;w.step(1);assert(find(gui,'SessionTime').Text=='01:00:01')
        close(w,gui)
    end)
    test('responsive desktop/mobile bounds, readable fonts and scrollable Home',function()
        for _,size in ipairs({{1536,691},{1280,720},{844,354},{390,780},{320,568},{568,280}}) do
            local w,gui=launch(size[1],size[2]);w.player.UserId=11575308681;w.step(30)
            local win=find(gui,'Window');local p,s=win.AbsolutePosition,win.AbsoluteSize
            assert(p.X>=0 and p.Y>=0 and p.X+s.X<=size[1]+1 and p.Y+s.Y<=size[2]+1,'initial fit '..size[1])
            assert(s.Y<=size[2]*.83 and (size[1]<600 or s.X<=size[1]*.87),'window too large')
            local panel=find(gui,'Panel');assert(find(gui,'Content').AbsoluteSize.X>=130)
            for _,name in ipairs({'Minimize','Collapse','Close'}) do
                local b=find(gui,name);local bp,bs=b.AbsolutePosition,b.AbsoluteSize
                assert(bp.X>=p.X and bp.X+bs.X<=find(gui,'Dock').AbsolutePosition.X+find(gui,'Dock').AbsoluteSize.X)
            end
            local nav=find(gui,'Navigation');local settings=find(gui,'Tab_Settings')
            assert(settings.Position.Y.Offset+settings.Size.Y.Offset<=nav.CanvasSize.Y.Offset)
            assert(settings:FindFirstChild('Caption').TextSize>=15)
            local header=find(gui,'Header');local id=find(gui,'UserID');local clock=find(gui,'SessionTime')
            assert(id.Position.X.Offset+id.Size.X.Offset<=header.Size.X.Offset+panel.Size.X.Offset+1,'ID cut off')
            if id.Position.Y.Offset==clock.Position.Y.Offset then assert(id.Position.X.Offset+id.Size.X.Offset<clock.Position.X.Offset) end
            local last=find(gui,'Shortcut_Visuals')
            assert(find(gui,'Page_Home').CanvasSize.Y.Offset>=last.Position.Y.Offset+last.Size.Y.Offset)
            if size[1]==844 then
                local main=find(gui,'OpenMain');local content=find(gui,'Content')
                assert(main.AbsolutePosition.Y+main.AbsoluteSize.Y<=content.AbsolutePosition.Y+content.AbsoluteSize.Y,'main action clipped in landscape')
            end
            click(gui,'Tab_Visuals');w.step(30);assert(find(gui,'Content').AbsoluteSize.Y>35)
            w.viewport={X=size[2],Y=size[1]};find(gui,'SafeArea'):GetPropertyChangedSignal('AbsoluteSize'):Fire();w.step(30)
            assert(find(gui,'Content').AbsoluteSize.X>(size[2]<320 and 110 or 130) and find(gui,'Content').AbsoluteSize.Y>35, 'rotated content unusable')
            close(w,gui)
        end
    end)
    test('one clock/controller after reexecution; all handlers clean on close',function()
        local w,gui=launch();w.step(90);assert(w.services.RunService.Heartbeat:Count()==1)
        local again=w.run(source);assert(gui.Parent==nil and again:GetAttribute('ElapsedSeconds')==0)
        assert(w.services.RunService.Heartbeat:Count()==1)
        local n=0;for _,o in ipairs(w.pg:GetChildren())do if o.Name=='ReyznX' then n+=1 end end;assert(n==1)
        w.step(30);click(again,'Minimize');w.step(4);click(again,'Close');w.step(30)
        assert(again.Parent==nil and w.services.RunService.Heartbeat:Count()==0)
        for _,key in ipairs({'InputBegan','InputChanged','InputEnded','WindowFocusReleased'}) do assert(w.services.UserInputService[key]:Count()==0,key..' leaked') end
    end)
    test('bad cache is replaced; invalid HTTP body cannot become a local asset',function()
        local w=setup();w.files['ReyznX-launcher-r-v1.png']='broken PNG'
        local gui=w.run(source);w.step(30);assert(w.files['ReyznX-launcher-r-v1.png']==artwork['launcher-r-v1.png']);close(w,gui)
        local broken=setup();broken.http[URL..'emblem-x-v1.png']='<html>not an image</html>'
        local g=broken.run(source);broken.step(90)
        assert(g:GetAttribute('AssetX')=='failed' and find(g,'XFallback').Visible)
        assert(broken.files['ReyznX-emblem-x-v1.png']==nil and #broken.requests==3)
        click(g,'Tab_Main');broken.step(30);assert(g:GetAttribute('Page')=='Main');close(broken,g)
    end)
    test('missing asset APIs/network/write errors leave controls and clock usable',function()
        for _,failure in ipairs({'unsupported','network','write','registration'}) do
            local w=setup()
            if failure=='unsupported' then w.env.getcustomasset=false
            elseif failure=='network' then w.httpFailure=true
            elseif failure=='write' then w.writeFailure=true
            else w.assetApiFailure=true end
            local gui=w.run(source);w.step(100)
            assert(find(gui,'XFallback').Visible and gui:GetAttribute('ElapsedSeconds')>=1)
            assert(#w.requests<=4,'unbounded retries')
            click(gui,'Minimize');w.step(30);assert(find(gui,'Launcher').Visible)
            click(gui,'Launcher');w.step(30);assert(find(gui,'Dock').BackgroundTransparency==0)
            close(w,gui)
        end
    end)
    test('slow PNGs and thumbnails never block opening; cancelled safely on close',function()
        local w=setup();w.httpDelay=5;w.thumbnailDelay=5
        local gui=w.run(source);w.step(61)
        assert(find(gui,'Dock').BackgroundTransparency==0 and gui:GetAttribute('ElapsedSeconds')==1)
        click(gui,'Tab_Main');w.step(10);click(gui,'Close');w.step(400)
        assert(gui.Parent==nil and #w.writes==0 and w.services.RunService.Heartbeat:Count()==0)
        local failed=setup();failed.thumbnailFailure=true
        local g=failed.run(source);failed.step(60);assert(find(g,'AvatarFallback').Visible);close(failed,g)
    end)
    print(tostring(count)..' scenarios passed. Rendering and real touch input still require Roblox.')
end
