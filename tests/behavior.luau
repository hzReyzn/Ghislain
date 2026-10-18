local newWorld=require('./mock_roblox')
return function(source)
    local count=0
    local URL='https://raw.githubusercontent.com/hzReyzn/Ghislain/main/assets/reyzn-x/'
    local function png(bytes) return '\137PNG\13\10\26\10'..'\0\0\0\13IHDR'..string.rep('a',bytes-24)..'IEND\174\66\96\130' end
    local artwork={['launcher-r-v1.png']=png(2136070),['emblem-x-v1.png']=png(1699126),['flame-wisp-v1.png']=png(1172326),['minimize-v1.png']=png(1283532),['collapse-v1.png']=png(1337784),['close-v1.png']=png(1570916)}
    for name,bytes in pairs({['icon-home-v1.png']=1933132,['icon-main-v1.png']=2142879,
        ['icon-scripts-v1.png']=2546120,['icon-settings-v1.png']=1892474,['icon-visuals-v1.png']=1628114,['disaster-success-v1.png']=1346483,['disaster-failure-v1.png']=1491592}) do
        artwork[name]=png(bytes)
    end
    artwork['background-cyber-v2.jpg']='\255\216\255\224'..string.rep('a',167325-6)..'\255\217'
    local function setup(width,height)
        local w=newWorld();w.viewport={X=width or 1280,Y=height or 720}
        for name,data in pairs(artwork) do w.http[URL..name]=data end
        return w
    end
    local function launch(width,height)
        local w=setup(width,height);local gui=w.run(source)
        assert(gui and gui.Name=='ReyznX');return w,gui
    end
    local function find(gui,name) return (assert(gui:FindFirstChild(name,true),'missing '..name)) end
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
    test('clean interface, retained identity and native Rajdhani option labels',function()
        local w,gui=launch();w.step(30)
        assert(gui.ResetOnSpawn==false and gui:GetAttribute('Version')=='1.0')
        assert(find(gui,'UserID').Text=='ID  123' and find(gui,'SessionTime').Text=='00:00:00')
        assert(w.thumbnailRequest.id==123 and w.thumbnailRequest.kind.Name=='HeadShot')
        assert(find(gui,'Avatar').Image=='rbxthumb://test-avatar')
        assert(find(gui,'Credit').Text=='Made By Reyzn')
        for _,name in ipairs({'Main','Visuals','Scripts','Settings'}) do
            assert(find(gui,'Tab_'..name):FindFirstChild('Caption',true).FontFace.Family=='rbxassetid://12187375422')
            if name=='Main' then assert(#find(gui,'Page_Main'):GetChildren()==1 and find(gui,'NoFallDamage'))
            elseif name=='Scripts' then assert(#find(gui,'Page_Scripts'):GetChildren()==1 and find(gui,'ScriptExecutables'))
            else assert(#find(gui,'Page_'..name):GetChildren()==0,'section should be empty') end
        end
        assert(find(gui,'Tab_Home'):FindFirstChild('Caption',true).FontFace.Family=='rbxassetid://12187375422')
        assert(find(gui,'PageTitle').FontFace.Weight.Name=='SemiBold')
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
        assert(#w.requests==14 and #w.writes==14)
        assert(w.files['ReyznX-launcher-r-v1.png']==artwork['launcher-r-v1.png'])
        assert(w.files['ReyznX-emblem-x-v1.png']==artwork['emblem-x-v1.png'])
        assert(find(gui,'DisasterSuccessIcon').Image=='mock://ReyznX-disaster-success-v1.png')
        assert(find(gui,'DisasterFailureIcon').Image=='mock://ReyznX-disaster-failure-v1.png')
        assert(find(gui,'DisasterSuccessGlow').Image==find(gui,'DisasterSuccessIcon').Image)
        assert(find(gui,'DisasterFailureGlow').Image==find(gui,'DisasterFailureIcon').Image)
        assert(gui:GetAttribute('AssetDisasterSuccess')=='ready' and gui:GetAttribute('AssetDisasterFailure')=='ready')
        assert(find(gui,'EmblemX').Image=='mock://ReyznX-emblem-x-v1.png')
        assert(find(gui,'LauncherR').Image=='mock://ReyznX-launcher-r-v1.png')
        assert(find(gui,'RecoveryR').Image==find(gui,'LauncherR').Image)
        assert(gui:GetAttribute('AssetX')=='ready' and gui:GetAttribute('AssetR')=='ready')
        assert(not find(gui,'XFallback').Visible and not find(gui,'RFallback').Visible)
        assert(find(gui,'EmblemX').ImageTransparency==0 and find(gui,'EmblemX').BackgroundTransparency==1)
        click(gui,'Minimize');w.step(30)
        assert(find(gui,'LauncherR').ImageTransparency==0 and find(gui,'Launcher').BackgroundTransparency==1)
        local again=w.run(source);w.step(30)
        assert(gui.Parent==nil and #w.requests==14 and #w.writes==14,'valid cache was downloaded again')
        close(w,again)
    end)
    test('disaster icons render when preload only caches hidden textures',function()
        local w=setup();w.preloadCacheOnly=true
        local gui=w.run(source);w.step(30)
        local success,failure=find(gui,'DisasterSuccessIcon'),find(gui,'DisasterFailureIcon')
        assert(success.Image~='' and failure.Image~='')
        assert(not success.IsLoaded and not failure.IsLoaded,'notice is initially hidden')
        click(gui,'DisasterPredictionManual');w.step(30)
        assert(failure.Visible and failure.IsLoaded,'assigned failure icon must reach the renderer')
        assert(not find(gui,'DisasterFailureFallback').Visible)
        local c=w.character();local tag=w.env.Instance.new('StringValue')
        tag.Name='SurvivalTag';tag.Value='Tsunami';tag.Parent=c
        click(gui,'DisasterPrediction');w.step(30)
        assert(success.Visible and success.IsLoaded,'success icon must load on its first notice')
        assert(not failure.Visible and not find(gui,'DisasterSuccessFallback').Visible)
        assert(gui:GetAttribute('DisasterNoticeDuration')==5)
        close(w,gui)
    end)
    test('notice artwork retries bypass cached missing responses and then reuses valid local files',function()
        local w=setup();local get=w.env.game.HttpGet;local attempts={}
        w.env.game.HttpGet=function(self,url)
            if url:find('/disaster-',1,true)then
                assert(url:find('?build=disaster-icons-visible-20261018',1,true),'missing image cache revision')
                local base=url:match('^[^?]+');attempts[base]=(attempts[base] or 0)+1
                if attempts[base]==1 then
                    w.requests[#w.requests+1]=url
                    return '<html>cached missing asset</html>'
                end
                assert(url:find('&attempt=2',1,true),'retry must use a distinct URL')
            end
            return get(self,url)
        end
        local gui=w.run(source);w.step(100)
        for _,name in ipairs({'disaster-success-v1.png','disaster-failure-v1.png'})do
            assert(attempts[URL..name]==2)
            assert(w.files['ReyznX-'..name]==artwork[name])
        end
        local count=#w.requests;local again=w.run(source);w.step(30)
        assert(gui.Parent==nil and #w.requests==count,'valid cached images must not redownload')
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
        click(gui,'Tab_Home');w.step(30);click(gui,'Tab_Main');w.step(30)
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
            assert(settings:FindFirstChild('Caption',true).TextSize>=15)
            local header=find(gui,'Header');local id=find(gui,'UserID');local clock=find(gui,'SessionTime')
            assert(id.Position.X.Offset+id.Size.X.Offset<=header.Size.X.Offset+panel.Size.X.Offset+1,'ID cut off')
            if id.Position.Y.Offset==clock.Position.Y.Offset then assert(id.Position.X.Offset+id.Size.X.Offset<clock.Position.X.Offset) end
            local hero=find(gui,'Hero');local info=find(gui,'ScriptInfo')
            assert(find(gui,'Page_Home').CanvasSize.Y.Offset>=hero.Position.Y.Offset+hero.Size.Y.Offset)
            assert(info.Position.Y.Offset+info.Size.Y.Offset<hero.Size.Y.Offset,'status below card')
            assert(info.Position.X.Offset+info.Size.X.Offset<=hero.Size.X.Offset+find(gui,'Content').AbsoluteSize.X+.01,'info exceeds card width')
            for _,name in ipairs({'StatusValue','VersionValue'}) do
                local value=find(gui,name)
                assert(value.Size.X.Offset+info.AbsoluteSize.X>=28,'status/version too narrow')
            end
            if size[1]==844 or size[1]==390 or size[1]==320 then
                local content=find(gui,'Content')
                assert(info.AbsolutePosition.Y+info.AbsoluteSize.Y<=content.AbsolutePosition.Y+content.AbsoluteSize.Y,'status clipped in landscape')
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
        assert(broken.files['ReyznX-emblem-x-v1.png']==nil and #broken.requests==15)
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
            assert(#w.requests<=28,'unbounded retries')
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

    test('native chrome typography replaces only the wordmark, retaining original artwork',function()
        local w,gui=launch();w.step(30)
        for _,name in ipairs({'BrandText','HeroTitle'}) do
            local title=find(gui,name)
            assert(title.ClassName=='TextLabel' and title.Text=='Reyzn' and not title.RichText)
            assert(title.Font.Name=='GrenzeGotisch' and title.TextTransparency==0)
            assert(title:FindFirstChildOfClass('UIGradient') and title:FindFirstChildOfClass('UIStroke'))
        end
        assert(not gui:FindFirstChild('BrandWordmark',true) and not gui:FindFirstChild('HeroTitleFallback',true))
        for _,url in ipairs(w.requests)do assert(not url:find('wordmark'),'unwanted wordmark download')end
        assert(find(gui,'Credit').Text=='Made By Reyzn')
        assert(find(gui,'EmblemX').Image=='mock://ReyznX-emblem-x-v1.png','X replaced')
        close(w,gui)
    end)
    test('PNG controls map to their actions, retain hitboxes and release press feedback',function()
        local w,gui=launch();w.step(30);local e=w.env
        for _,name in ipairs({'Minimize','Collapse','Close'})do
            local b=find(gui,name);local art=b:FindFirstChild('ControlArtwork')
            assert(b.ClassName=='ImageButton' and b.Active and b.BackgroundTransparency==1)
            assert(art.Image=='mock://ReyznX-'..string.lower(name)..'-v1.png')
            assert(art.ImageRectOffset.X>180 and art.ImageRectSize.X>1200,'transparent margin not trimmed in display')
            assert(not b:FindFirstChild('ControlFallback').Visible)
            local x,y=b.Position.X.Offset,b.Position.Y.Offset
            local scale=art:FindFirstChildOfClass('UIScale')
            local touch={UserInputType=e.Enum.UserInputType.Touch,Position=e.Vector3.new(0,0)}
            b.InputBegan:Fire(touch);w.step(6);near(scale.Scale,.97)
            w.services.UserInputService.InputEnded:Fire({UserInputType=e.Enum.UserInputType.Touch})
            w.step(12);near(scale.Scale,.97,'unrelated finger released control')
            w.services.UserInputService.InputEnded:Fire(touch);w.step(12);near(scale.Scale,1)
            near(b.Position.X.Offset,x);near(b.Position.Y.Offset,y)
        end
        click(gui,'Collapse');w.step(30);assert(not gui:GetAttribute('PanelOpen') and not gui:GetAttribute('Minimized'))
        click(gui,'Collapse');w.step(30);assert(gui:GetAttribute('PanelOpen'))
        click(gui,'Minimize');w.step(30);assert(gui:GetAttribute('Minimized') and gui.Parent~=nil)
        click(gui,'Launcher');w.step(30);close(w,gui)
    end)
    test('fire and particle pools animate outside surfaces without allocations or input capture',function()
        local w,gui=launch();w.step(30);w.step(20)
        local dock,panel,launcher=find(gui,'DockAura'),find(gui,'PanelAura'),find(gui,'LauncherAura')
        assert(dock.Parent==find(gui,'Window') and panel.Parent==find(gui,'Window'))
        assert(not panel:IsDescendantOf(find(gui,'PanelReveal')) and launcher.Parent==find(gui,'Launcher'))
        assert(not gui:FindFirstChild('AuraHalo',true) and not gui:FindFirstChild('AuraWisp',true),'old rings survived')
        local fire,particles=0,0
        for _,aura in ipairs({dock,panel,launcher}) do
            assert(not aura.Active and not aura.ClipsDescendants)
            for _,o in ipairs(aura:GetDescendants())do
                if o:IsA('GuiObject')then assert(not o.Active,'VFX captures input')end
                if o.Name=='UpdraftCore'then fire+=1;assert(o.Image=='mock://ReyznX-flame-wisp-v1.png')end
                if o.Name=='RisingEmber'then particles+=1 end
            end
        end
        assert(fire==63 and particles==24,'unbounded shared fire pools')
        local plume=dock:FindFirstChild('UpdraftRoot');local length=plume:FindFirstChild('UpdraftBody').Size.Y.Offset
        local objects=#w.objects;w.step(120)
        assert(#w.objects==objects and plume:FindFirstChild('UpdraftBody').Size.Y.Offset~=length,'frozen or allocating effect')
        for _,aura in ipairs({dock,panel})do
            for _,particle in ipairs(aura:GetChildren())do
                if particle.Name=='RisingEmber' and particle.Visible then
                    local p=particle.Position;local s=aura.Size
                    assert(p.X.Offset<-4 or p.Y.Offset<-4 or p.X.Offset>s.X.Offset+4 or p.Y.Offset>s.Y.Offset+4,'particle over content')
                end
            end
        end
        click(gui,'Collapse');w.step(30);assert(not panel.Visible)
        click(gui,'Tab_Main');w.step(30);assert(panel.Visible)
        click(gui,'Minimize');w.step(30)
        assert(plume:FindFirstChild('UpdraftBody').ImageTransparency==1,'window flame left behind')
        local logoFlame=find(launcher,'UpdraftCore')
        assert(logoFlame.ImageTransparency<1)
        click(gui,'Launcher');w.step(30);assert(logoFlame.ImageTransparency==1)
        close(w,gui)
    end)
    test('Ultra High stays fixed under sustained load; performance controls are absent',function()
        local w,gui=launch(844,354);w.step(30)
        assert(gui:GetAttribute('VisualQuality')=='Ultra High' and gui:GetAttribute('VFXRate')==60)
        for _,name in ipairs({'QualityCard','QualityStatus','Quality_Low','Quality_Medium','Quality_High','LauncherHalo','ContactShadow'}) do
            assert(not gui:FindFirstChild(name,true),'obsolete visual/control '..name)
        end
        local win=find(gui,'Window');local pos,size=win.Position,win.Size;local objects=#w.objects
        click(gui,'Tab_Settings');w.step(30)
        assert(#find(gui,'Page_Settings'):GetChildren()==0)
        for _,dt in ipairs({1/20,1/30,1/120}) do
            w.step(240,dt)
            assert(gui:GetAttribute('EffectiveQuality')=='Ultra High' and gui:GetAttribute('VFXRate')==60)
            local active=0
            for _,auraName in ipairs({'DockAura','PanelAura','LauncherAura'}) do
                for _,o in ipairs(find(gui,auraName):GetChildren()) do
                    if o.Name=='UpdraftRoot' and o.Visible then active+=1 end
                end
            end
            assert(active==63 and #w.objects==objects,'window quality was reduced or pools recreated')
        end
        near(win.Position.X.Offset,pos.X.Offset);near(win.Position.Y.Offset,pos.Y.Offset)
        near(win.Size.X.Offset,size.X.Offset);near(win.Size.Y.Offset,size.Y.Offset)
        close(w,gui)
    end)
    test('supplied icons map correctly; exact transparencies survive reversed transitions',function()
        local w,gui=launch();w.step(30)
        for _,name in ipairs({'Home','Main','Visuals','Scripts','Settings'}) do
            local tab=find(gui,'Tab_'..name)
            local art=find(tab,'OptionArtwork')
            assert(art.Image=='mock://ReyznX-icon-'..name:lower()..'-v1.png')
            near(art.ImageTransparency,.85)
            assert(art.ScaleType.Name=='Fit' and not art.Active)
            assert(not art.Parent:FindFirstChild('Line').Visible,'native icon overlaps PNG')
        end
        assert(not find(gui,'Launcher'):FindFirstChildOfClass('UIStroke'))
        for cycle=1,5 do
            click(gui,'Minimize');w.step(cycle%2==0 and 6 or 30)
            click(gui,'Launcher');w.step(30)
            click(gui,'Collapse');w.step(5);click(gui,'Tab_Main');w.step(30)
            near(find(find(gui,'Tab_Main'),'OptionArtwork').ImageTransparency,.85)
            for _,surface in ipairs({'Dock','Panel','Hero'}) do
                local bg=find(find(gui,surface),'InterfaceBackground')
                assert(bg.Image=='mock://ReyznX-background-cyber-v2.jpg' and bg.ScaleType.Name=='Crop')
                near(bg.ImageTransparency,.83);assert(not bg.Active)
            end
        end
        close(w,gui)
        local broken=setup();broken.http[URL..'icon-home-v1.png']='invalid'
        local g=broken.run(source);broken.step(90)
        assert(find(find(g,'Tab_Home'),'Icon_home'):FindFirstChild('Line').Visible)
        click(g,'Tab_Main');broken.step(30);assert(g:GetAttribute('Page')=='Main')
        close(broken,g)
    end)
    test('fire crossfades continuously; inward lights remain inside panels without bottom shadows',function()
        local w,gui=launch();w.step(30)
        local slot=find(find(gui,'DockAura'),'UpdraftRoot')
        local core,haze=find(slot,'UpdraftBody'),find(slot,'UpdraftVeil')
        local last=core.ImageTransparency;local changed=0
        for i=1,180 do
            w.step(1,1/60)
            local value=core.ImageTransparency
            assert(math.abs(value-last)<.06,'fire opacity popped at a cycle boundary')
            assert((1-value)+(1-haze.ImageTransparency)>.59,'both layers faded out together')
            if value~=last then changed+=1 end
            last=value
        end
        assert(changed>170,'fire still updates only at the old 30 Hz rate')
        for _,name in ipairs({'Dock','Panel'}) do
            local light=find(find(gui,name),'InwardLight')
            local field=light:FindFirstChild('InwardGlow');local p=field.Position
            w.step(10)
            assert(field.Position.X.Scale~=p.X.Scale,'inner illumination is static')
            for _,child in ipairs(light:GetChildren()) do
                if child:IsA('GuiObject') then
                    assert(not child.Active)
                    local lp,ls=light.AbsolutePosition,light.AbsoluteSize
                    local cp,cs=child.AbsolutePosition,child.AbsoluteSize
                    assert(cp.X>=lp.X and cp.Y>=lp.Y and cp.X+cs.X<=lp.X+ls.X+.01 and cp.Y+cs.Y<=lp.Y+ls.Y+.01,'light escapes surface')
                end
            end
        end
        close(w,gui)
    end)
    test('Home retains the large X, removes only requested actions and fixes version at 1.0',function()
        local w,gui=launch();w.step(30)
        for _,name in ipairs({'OpenMain','Shortcut_Main','Shortcut_Visuals','SilverAccent','HeroGlint'}) do
            assert(not gui:FindFirstChild(name,true),'removed Home element survived: '..name)
        end
        assert(find(gui,'BrandText').Text=='Reyzn' and find(gui,'HeroTitle').Text=='Reyzn')
        assert(find(gui,'Credit').Text=='Made By Reyzn')
        assert(find(gui,'EmblemX').Image=='mock://ReyznX-emblem-x-v1.png')
        assert(find(gui,'StatusValue').Text=='Active' and gui:GetAttribute('ScriptStatus')=='Active')
        assert(find(gui,'VersionValue').Text=='1.0' and gui:GetAttribute('Version')=='1.0')
        assert(find(gui,'Tab_Main') and find(gui,'Tab_Visuals'),'sidebar actions removed')
        for _,name in ipairs({'Main','Visuals','Home'}) do click(gui,'Tab_'..name);w.step(30) end
        click(gui,'Minimize');w.step(30);click(gui,'Launcher');w.step(30)
        assert(find(gui,'VersionValue').Text=='1.0')
        local again=w.run(source);w.step(30)
        assert(find(again,'VersionValue').Text=='1.0' and again:GetAttribute('Version')=='1.0')
        close(w,again)
    end)
    test('actual JPEG background is accepted, cached, and layered below Home content',function()
        local w,gui=launch();w.step(30)
        assert(gui:GetAttribute('AssetBackground')=='ready')
        assert(w.files['ReyznX-background-cyber-v2.jpg']==artwork['background-cyber-v2.jpg'])
        local assetCount=0
        for _,parentName in ipairs({'Dock','Panel','Hero'}) do
            local parent=find(gui,parentName);local bg=parent:FindFirstChild('InterfaceBackground')
            assert(bg and bg.Image=='mock://ReyznX-background-cyber-v2.jpg')
            near(bg.ImageTransparency,.83);assert(not bg.Active)
            for _,name in ipairs({'Navigation','Content','HeroTitle','EmblemHost','ScriptInfo'}) do
                local child=parent:FindFirstChild(name)
                if child then assert(child.ZIndex>bg.ZIndex,'background obscures interactive content') end
            end
            assetCount+=1
        end
        assert(assetCount==3)
        close(w,gui)
        local invalid=setup()
        invalid.http[URL..'background-cyber-v2.jpg']=png(167325)
        local g=invalid.run(source);invalid.step(100)
        assert(g:GetAttribute('AssetBackground')=='failed','PNG bytes accepted as supplied JPEG')
        assert(find(g,'VersionValue').Text=='1.0')
        click(g,'Tab_Visuals');invalid.step(30);assert(g:GetAttribute('Page')=='Visuals')
        close(invalid,g)
    end)
    test('emblem neon travels left to right, resets invisibly and pauses outside Home',function()
        local w,gui=launch();w.step(30)
        local sweep=find(gui,'EmblemSweep');local wash=sweep:FindFirstChildOfClass('UIGradient')
        local objects=#w.objects;local lastX=wash.Offset.X;local wraps,moves=0,0
        for i=1,360 do
            w.step(1)
            local x=wash.Offset.X
            if x<lastX then wraps+=1;assert(sweep.ImageTransparency>.99,'neon jumps visibly at loop seam')
            else moves+=1 end
            lastX=x
        end
        assert(wraps>=1 and moves>350 and #w.objects==objects,'loop reversed, froze or allocated instances')
        assert(not sweep.Active and sweep.Image==find(gui,'EmblemX').Image)
        assert(find(gui,'EmblemX').ImageTransparency==0,'original artwork was dimmed')
        click(gui,'Tab_Visuals');w.step(30);local paused=wash.Offset.X
        w.step(60);near(wash.Offset.X,paused)
        click(gui,'Tab_Home');w.step(30);assert(wash.Offset.X~=paused)
        click(gui,'Minimize');w.step(30);near(sweep.ImageTransparency,1)
        click(gui,'Launcher');w.step(30);close(w,gui)
    end)
    test('button press scales its face only, retains action and releases owned touch',function()
        local w,gui=launch();w.step(30);local e=w.env
        local b=find(gui,'Tab_Main');local scale=find(b,'PressScale')
        local x,y=b.AbsolutePosition.X,b.AbsolutePosition.Y;local width=b.AbsoluteSize.X
        local finger={UserInputType=e.Enum.UserInputType.Touch,Position=e.Vector3.new(0,0)}
        b.InputBegan:Fire(finger);w.step(6)
        assert(scale.Scale<1 and scale.Scale>.96)
        near(b.AbsolutePosition.X,x);near(b.AbsolutePosition.Y,y);near(b.AbsoluteSize.X,width)
        w.services.UserInputService.InputEnded:Fire({UserInputType=e.Enum.UserInputType.Touch});w.step(15)
        assert(scale.Scale<1,'unrelated finger released press')
        b.Activated:Fire();w.services.UserInputService.InputEnded:Fire(finger);w.step(30)
        assert(gui:GetAttribute('Page')=='Main' and gui:GetAttribute('PanelOpen'));near(scale.Scale,1)
        b.InputBegan:Fire(finger);w.step(8);w.services.UserInputService.WindowFocusReleased:Fire();w.step(30)
        near(scale.Scale,1)
        close(w,gui)
    end)
    test('only one scheduled/interactive reflection shines and hidden effects stop work',function()
        local w,gui=launch();w.step(30)
        for _,name in ipairs({'Tab_Main','Tab_Visuals','Tab_Scripts'})do find(gui,name).MouseEnter:Fire();w.step(5)end
        local visible=0
        for _,o in ipairs(gui:GetDescendants())do
            if (o.Name=='Sheen' or o.Name=='SurfaceReflection' or o.Name=='HeroReflection' or o.Name=='ControlReflection') and o.BackgroundTransparency<.999 then visible+=1 end
        end
        assert(visible<=1,'reflections compete simultaneously')
        click(gui,'Minimize');w.step(30)
        local plume=find(find(gui,'DockAura'),'UpdraftBody');local p=plume.Position
        w.step(90);near(plume.Position.X.Offset,p.X.Offset);near(plume.Position.Y.Offset,p.Y.Offset)
        close(w,gui)
    end)
    test('launcher fire has a continuous bottom source, upward flow and fixed reusable layers',function()
        local w,gui=launch();w.step(310);click(gui,'Minimize');w.step(30)
        local launcher,aura=find(gui,'Launcher'),find(gui,'LauncherAura')
        assert(not aura:FindFirstChild('FlameSlot') and not aura:FindFirstChild('EdgeEnergy'))
        local roots,layers,wisps,embers=0,0,0,0
        for _,o in ipairs(aura:GetDescendants())do
            if o:IsA('GuiObject')then assert(not o.Active,'fire must not intercept touches')end
            if o.Name=='UpdraftRoot'then
                roots+=1;near(o.Position.Y.Offset,70)
                assert(o.Rotation==nil or o.Rotation==0,'root points sideways or down')
            elseif o.Name=='UpdraftVeil' or o.Name=='UpdraftBody'then
                layers+=1;assert(o.Image=='mock://ReyznX-flame-wisp-v1.png')
                assert(o.ImageRectSize.Y>0 and o.ImageRectOffset.Y+o.ImageRectSize.Y<=1254)
            elseif o.Name=='RisingWisp'then wisps+=1
            elseif o.Name=='RisingEmber'then embers+=1 end
        end
        assert(roots==8 and layers==16 and wisps==6 and embers==8,'pool budget changed')
        assert(find(gui,'LauncherArtwork').ZIndex>aura.ZIndex and find(gui,'LauncherR').ImageTransparency==0)
        near(launcher.Size.X.Offset,68);near(launcher.Size.Y.Offset,68)
        local wisp=find(aura,'RisingWisp');local ribbon=find(aura,'UpdraftBody');local veil=find(aura,'UpdraftVeil')
        local y,opacity=wisp.Position.Y.Offset,1-wisp.ImageTransparency
        local x=ribbon.Position.X.Offset;local objects=#w.objects
        for _=1,240 do
            w.step(1)
            local nextY,nextOpacity=wisp.Position.Y.Offset,1-wisp.ImageTransparency
            if nextY>y then assert(opacity<.01 and nextOpacity<.01,'visible reset in rising flame') end
            y=nextY;opacity=nextOpacity
            assert(2-ribbon.ImageTransparency-veil.ImageTransparency>.86,'root fire disappears between cycles')
        end
        assert(#w.objects==objects and ribbon.Position.X.Offset~=x,'frozen fire or per-frame allocation')
        click(gui,'Launcher');w.step(30);near(ribbon.ImageTransparency,1)
        local position=ribbon.Position;w.step(60)
        near(ribbon.Position.X.Offset,position.X.Offset);near(ribbon.Position.Y.Offset,position.Y.Offset)
        close(w,gui)
    end)
    test('launcher artwork presses independently of its drag target and returns to full scale',function()
        local w,gui=launch();w.step(30);click(gui,'Minimize');w.step(30)
        local launcher,press=find(gui,'Launcher'),find(gui,'LauncherPressScale')
        local e=w.env;local size=launcher.AbsoluteSize
        local finger={UserInputType=e.Enum.UserInputType.Touch,Position=e.Vector3.new(20,160)}
        launcher.InputBegan:Fire(finger);w.step(5)
        assert(press.Scale<1 and press.Scale>=.965)
        near(launcher.AbsoluteSize.X,size.X);near(launcher.AbsoluteSize.Y,size.Y)
        w.services.UserInputService.InputEnded:Fire({UserInputType=e.Enum.UserInputType.Touch});w.step(10)
        assert(press.Scale<1,'unrelated touch released the press')
        w.services.UserInputService.WindowFocusReleased:Fire();w.step(20);near(press.Scale,1)
        for _=1,3 do click(gui,'Launcher');w.step(7);click(gui,'Minimize');w.step(30) end
        near(find(gui,'LauncherR').ImageTransparency,0)
        assert(not launcher:FindFirstChildOfClass('UIStroke') and launcher.BackgroundTransparency==1)
        close(w,gui)
    end)
    test('load toast enters from right, holds four seconds, fades right and releases its resources',function()
        local w,gui=launch(844,390)
        local toast=find(gui,'LoadNotification');local face=find(toast,'NotificationFace')
        local message=find(toast,'NotificationMessage');local progress=find(gui,'ToastProgress')
        assert(message.Text:gsub('\n',' ')=='The script has loaded successfully :))' and message.TextWrapped)
        assert(toast.AbsolutePosition.X>844 and message.TextTransparency==1)
        for _,o in ipairs(toast:GetDescendants())do
            if o:IsA('GuiObject')then assert(not o.Active,'notification blocks game controls')end
        end
        local x=toast.AbsolutePosition.X
        w.step(8)
        assert(toast.AbsolutePosition.X<x and progress.Value>0 and progress.Value<1)
        w.step(22)
        assert(gui:GetAttribute('LoadNotification')=='holding');near(progress.Value,1)
        near(toast.AbsolutePosition.X+toast.AbsoluteSize.X,828)
        near(toast.AbsolutePosition.Y+toast.AbsoluteSize.Y,364)
        near(message.TextTransparency,0);assert(face.ZIndex>find(toast,'NotificationAura').ZIndex)
        x=toast.AbsolutePosition.X
        w.step(236);assert(gui:GetAttribute('LoadNotification')=='holding');near(toast.AbsolutePosition.X,x)
        w.step(4);assert(gui:GetAttribute('LoadNotification')=='exiting')
        w.step(8);assert(toast.AbsolutePosition.X>x and message.TextTransparency>0 and message.TextTransparency<1)
        w.step(30)
        assert(gui:GetAttribute('LoadNotification')=='done' and toast.Parent==nil and progress.Parent==nil)
        assert(not gui:FindFirstChild('NotificationAura',true) and not gui:FindFirstChild('ToastProgress'))
        local opacity=message.TextTransparency
        click(gui,'Tab_Main');w.step(15);click(gui,'Minimize');w.step(30)
        near(message.TextTransparency,opacity,'expired toast still belongs to alpha compositor')
        assert(w.services.RunService.Heartbeat:Count()==1)
        close(w,gui)
    end)
    test('load toast remains independent of minimization, offscreen drag and viewport changes',function()
        local w,gui=launch(844,390);w.step(30);click(gui,'Minimize');w.step(30)
        drag(w,gui,'Launcher',2000,-1200,true)
        local toast=find(gui,'LoadNotification');local wisp=find(toast,'RisingWisp')
        local y=wisp.Position.Y.Offset;w.step(20)
        assert(wisp.Position.Y.Offset~=y,'offscreen GUI paused notification fire')
        w.viewport={X=320,Y=568};find(gui,'SafeArea'):GetPropertyChangedSignal('AbsoluteSize'):Fire()
        w.step(2)
        near(toast.AbsolutePosition.X,16);near(toast.AbsolutePosition.X+toast.AbsoluteSize.X,304)
        assert(gui:GetAttribute('Minimized') and gui:GetAttribute('LoadNotification')=='holding')
        w.step(240)
        assert(gui:GetAttribute('LoadNotification')=='done' and gui:GetAttribute('Minimized'))
        close(w,gui)
    end)
    test('expired toast cannot be revived by delayed artwork and closing/reexecution cancel it',function()
        local slow=setup();slow.httpDelay=6
        local g=slow.run(source);slow.step(310)
        assert(g:GetAttribute('LoadNotification')=='done' and not g:FindFirstChild('LoadNotification',true))
        slow.step(120);assert(g:GetAttribute('AssetFire')=='ready' and #slow.requests==14)
        assert(find(find(g,'LauncherAura'),'UpdraftBody').Image=='mock://ReyznX-flame-wisp-v1.png')
        close(slow,g)
        for _,seconds in ipairs({.1,1,4.6})do
            local w,gui=launch();w.step(math.floor(seconds*60))
            local old=find(gui,'LoadNotification')
            local again=w.run(source);w.step(5)
            assert(old.Parent==nil and gui.Parent==nil and w.services.RunService.Heartbeat:Count()==1)
            local current=find(again,'LoadNotification');click(again,'Close');w.step(8)
            assert(again:GetAttribute('LoadNotification')=='exiting')
            assert(find(again,'ToastProgress').Value<1)
            w.step(30);assert(current.Parent==nil and w.services.RunService.Heartbeat:Count()==0)
        end
    end)
    test('window fire matches launcher colors and sends all perimeter flames upwards',function()
        local w,gui=launch();w.step(30)
        local expected=find(find(gui,'LauncherAura'),'UpdraftBody'):FindFirstChildOfClass('UIGradient').Color[1]
        for _,name in ipairs({'DockAura','PanelAura'}) do
            local aura=find(gui,name)
            assert(not aura:FindFirstChild('FlameSlot') and not aura:FindFirstChild('EdgeEnergy'))
            local seen={top=false,bottom=false,left=false,right=false}
            for _,root in ipairs(aura:GetChildren())do
                if root.Name=='UpdraftRoot' then
                    assert(root.Rotation==nil or root.Rotation==0,'root rotates fire outwards')
                    local p=root.Position
                    if p.Y.Offset==4 then seen.top=true
                    elseif p.Y.Offset>aura.Size.Y.Offset then seen.bottom=true
                    elseif p.X.Offset<0 then seen.left=true
                    elseif p.X.Offset>aura.Size.X.Offset then seen.right=true end
                    local body=find(root,'UpdraftBody')
                    assert(body.AnchorPoint.Y==1 and body.Position.Y.Offset<=0 and math.abs(body.Rotation)<9)
                    local colors=body:FindFirstChildOfClass('UIGradient').Color[1]
                    assert(#colors==#expected)
                    for i,key in ipairs(colors)do
                        for _,channel in ipairs({'R','G','B'})do near(key[2][channel],expected[i][2][channel])end
                    end
                end
            end
            assert(seen.top and seen.bottom and seen.left and seen.right)
        end
        close(w,gui)
    end)
    test('cyan neon is animated below content, never a theme option, and pauses with hidden surfaces',function()
        local w,gui=launch();w.step(30)
        local flows={find(find(gui,'Dock'),'SurfaceNeon'),find(find(gui,'Panel'),'SurfaceNeon'),find(gui,'HeroNeon')}
        for _,name in ipairs({'Home','Main','Visuals','Scripts','Settings'})do
            local tab=find(gui,'Tab_'..name);local fill=find(tab,'OptionNeon')
            assert(fill.ZIndex<find(tab,'Caption').ZIndex and not fill.Active)
            flows[#flows+1]=fill
        end
        local offsets={};local objects=#w.objects
        for i,fill in ipairs(flows)do
            local wash=fill:FindFirstChildOfClass('UIGradient');offsets[i]=wash.Offset.X
            local cyan=false
            for _,key in ipairs(wash.Color[1])do
                local c=key[2]
                if math.abs(c.R-141/255)<.001 and math.abs(c.G-220/255)<.001 and c.B==1 then cyan=true end
            end
            assert(cyan,'neon differs from approved fire blue')
        end
        w.step(25)
        for i,fill in ipairs(flows)do
            assert(fill:FindFirstChildOfClass('UIGradient').Offset.X~=offsets[i],'neon is static')
            assert(fill.BackgroundTransparency>.7 and fill.BackgroundTransparency<1,'neon obscures content or is invisible')
        end
        assert(#w.objects==objects and not gui:FindFirstChild('Theme_Cyan',true))
        local panel=flows[2]:FindFirstChildOfClass('UIGradient')
        click(gui,'Collapse');w.step(30);local x=panel.Offset.X;w.step(30);near(panel.Offset.X,x)
        click(gui,'Minimize');w.step(30)
        for i,fill in ipairs(flows)do offsets[i]=fill:FindFirstChildOfClass('UIGradient').Offset.X end
        w.step(30)
        for i,fill in ipairs(flows)do near(fill:FindFirstChildOfClass('UIGradient').Offset.X,offsets[i]);near(fill.BackgroundTransparency,1) end
        click(gui,'Launcher');w.step(30);click(gui,'Tab_Main');w.step(30)
        assert(flows[2].BackgroundTransparency<1 and find(find(gui,'Tab_Main'),'OptionNeon').BackgroundTransparency<.85)
        assert(gui:GetAttribute('Version')=='1.0')
        close(w,gui)
    end)
    test('clean toast keeps two message lines above neon and removes every transient decoration',function()
        for _,width in ipairs({320,390,844})do
            local w,gui=launch(width,780);w.step(30)
            local toast=find(gui,'LoadNotification');local fill=find(toast,'NotificationNeon')
            local message=find(toast,'NotificationMessage');local badge=find(toast,'SuccessBadge')
            assert(message.Text=='The script has loaded\nsuccessfully :))')
            assert(message.ZIndex>fill.ZIndex and badge.ZIndex>fill.ZIndex)
            local mp,ms=message.AbsolutePosition,message.AbsoluteSize
            assert(mp.X>=toast.AbsolutePosition.X+55 and mp.X+ms.X<=toast.AbsolutePosition.X+toast.AbsoluteSize.X-16)
            assert(ms.Y>=2*message.TextSize and not badge.Active and not message.Active)
            local wash=fill:FindFirstChildOfClass('UIGradient');local x=wash.Offset.X
            w.step(20);assert(wash.Offset.X~=x and gui:GetAttribute('LoadNotification')=='holding')
            w.step(300);assert(fill.Parent==nil and badge.Parent==nil and not gui:FindFirstChild('NotificationNeon',true))
            local opacity=fill.BackgroundTransparency
            click(gui,'Tab_Settings');w.step(30);near(fill.BackgroundTransparency,opacity)
            assert(w.services.RunService.Heartbeat:Count()==1)
            close(w,gui)
        end
    end)
    test('No Fall Damage is a compact OFF control with only its name and status',function()
        for _,size in ipairs({{1280,720},{844,390},{390,780},{320,640}})do
            local w,gui=launch(size[1],size[2]);w.step(30);click(gui,'Tab_Main');w.step(30)
            local control=find(gui,'NoFallDamage');local page=find(gui,'Page_Main')
            local caption=find(control,'ToggleCaption');local status=find(control,'ToggleStatus')
            assert(not control:GetAttribute('Enabled') and not gui:GetAttribute('NoFallDamageEnabled'))
            assert(caption.Text=='No Fall Damage' and status.Text=='OFF')
            assert(caption.FontFace.Family=='rbxassetid://12187375422')
            local textCount=0
            for _,o in ipairs(control:GetDescendants())do
                if o:IsA('TextLabel')then textCount+=1;assert(o==caption or o==status)end
                if o:IsA('GuiObject') and o~=control then assert(not o.Active,'decoration takes touches')end
            end
            assert(textCount==2 and control.Active and control.Selectable)
            assert(control.Size.X.Offset<=340 and control.Size.Y.Offset<=88)
            assert(control.AbsolutePosition.X+control.AbsoluteSize.X<=page.AbsolutePosition.X+page.AbsoluteSize.X-4)
            assert(page.CanvasSize.Y.Offset>=control.Size.Y.Offset+12)
            near(find(control,'ToggleNeon').BackgroundTransparency,1)
            near(find(control,'ToggleGlow'):FindFirstChildOfClass('UIStroke').Transparency,1)
            assert(w.services.RunService.Heartbeat:Count()==1 and w.services.RunService.RenderStepped:Count()==0)
            assert(w.player.CharacterAdded:Count()==0 and w.player.CharacterRemoving:Count()==0)
            close(w,gui)
        end
    end)
    test('No Fall Damage pairs each velocity pulse with restoration and adds no frame tasks',function()
        local w,gui=launch();local _,_,root=w.character();w.step(30)
        local v=w.env.Vector3.new(17,-96,4);root.AssemblyLinearVelocity=v
        w.services.RunService.Heartbeat:Fire(1/60);assert(root.AssemblyLinearVelocity==v,'OFF modifies velocity')
        click(gui,'NoFallDamage')
        assert(find(gui,'ToggleStatus').Text=='ON' and gui:GetAttribute('NoFallDamageEnabled'))
        assert(w.services.RunService.Heartbeat:Count()==2 and w.services.RunService.RenderStepped:Count()==1)
        assert(w.services.RunService.PreSimulation:Count()==1 and w.player.CharacterAdded:Count()==1)
        w.services.RunService.Heartbeat:Fire(1/60);assert(root.AssemblyLinearVelocity==w.env.Vector3.zero)
        w.services.RunService.RenderStepped:Fire(1/60);assert(root.AssemblyLinearVelocity==v)
        local objects=#w.objects;w.step(150)
        assert(#w.objects==objects and #w.tasks==0,'physics pulse allocates instances or starts yielding tasks')
        assert(root.AssemblyLinearVelocity==v)
        click(gui,'NoFallDamage');assert(find(gui,'ToggleStatus').Text=='OFF')
        assert(w.services.RunService.Heartbeat:Count()==1 and w.services.RunService.RenderStepped:Count()==0)
        assert(w.services.RunService.PreSimulation:Count()==0 and w.player.CharacterAdded:Count()==0)
        root.AssemblyLinearVelocity=w.env.Vector3.new(0,-125,9);w.step(50)
        assert(root.AssemblyLinearVelocity.Y==-125)
        close(w,gui)
    end)
    test('No Fall Damage remains ON through death, delayed respawn and root replacement',function()
        local w,gui=launch();local old,hum,root=w.character();w.step(30);click(gui,'NoFallDamage')
        hum.Health=0;hum.Died:Fire();assert(gui:GetAttribute('NoFallDamageEnabled'))
        w.player.CharacterRemoving:Fire(old);old.Parent=nil;w.player.Character=nil;w.step(30)
        assert(gui:GetAttribute('NoFallDamageEnabled') and find(gui,'ToggleStatus').Text=='ON')
        local e=w.env;local character=e.Instance.new('Model');character.Parent=e.workspace
        w.player.Character=character;w.player.CharacterAdded:Fire(character);w.step(40)
        local fresh=e.Instance.new('Part');fresh.Name='HumanoidRootPart';fresh.AssemblyLinearVelocity=e.Vector3.new(5,-77,2);fresh.Parent=character
        w.services.RunService.Heartbeat:Fire(1/60);assert(fresh.AssemblyLinearVelocity==e.Vector3.zero)
        w.services.RunService.RenderStepped:Fire(1/60);assert(fresh.AssemblyLinearVelocity.Y==-77)
        assert(old.ChildAdded:Count()==0 and old.ChildRemoved:Count()==0)
        fresh:Destroy()
        local replacement=e.Instance.new('Part');replacement.Name='HumanoidRootPart';replacement.Parent=character
        replacement.AssemblyLinearVelocity=e.Vector3.new(8,-61,0)
        w.services.RunService.Heartbeat:Fire(1/60);assert(replacement.AssemblyLinearVelocity==e.Vector3.zero)
        w.services.RunService.RenderStepped:Fire(1/60);assert(replacement.AssemblyLinearVelocity.Y==-61)
        assert(gui:GetAttribute('NoFallDamageEnabled') and w.services.RunService.Heartbeat:Count()==2)
        click(gui,'NoFallDamage');local _,_,after=w.character();after.AssemblyLinearVelocity=e.Vector3.new(0,-90,0)
        w.step(40);assert(after.AssemblyLinearVelocity.Y==-90 and not gui:GetAttribute('NoFallDamageEnabled'))
        close(w,gui)
    end)
    test('No Fall Damage runs while Main is hidden, folded, minimized and offscreen',function()
        local w,gui=launch();local _,_,root=w.character();w.step(30);click(gui,'Tab_Main');w.step(30)
        click(gui,'NoFallDamage')
        for _,action in ipairs({'Tab_Home','Collapse','Minimize'})do
            click(gui,action);w.step(30)
            root.AssemblyLinearVelocity=w.env.Vector3.new(4,-82,7)
            w.services.RunService.Heartbeat:Fire(1/60);assert(root.AssemblyLinearVelocity==w.env.Vector3.zero)
            w.services.RunService.RenderStepped:Fire(1/60);assert(root.AssemblyLinearVelocity.Y==-82)
            assert(gui:GetAttribute('NoFallDamageEnabled'))
        end
        drag(w,gui,'Launcher',2400,1900,true);w.step(30)
        root.AssemblyLinearVelocity=w.env.Vector3.new(0,-112,0)
        w.services.RunService.Heartbeat:Fire(1/60);assert(root.AssemblyLinearVelocity==w.env.Vector3.zero)
        w.services.RunService.RenderStepped:Fire(1/60);assert(root.AssemblyLinearVelocity.Y==-112)
        close(w,gui)
    end)
    test('pending velocity is restored on OFF without overwriting a newer controller write',function()
        local w,gui=launch();local _,_,root=w.character();w.step(30);click(gui,'NoFallDamage')
        local e=w.env;local v=e.Vector3.new(9,-73,8);root.AssemblyLinearVelocity=v
        w.services.RunService.Heartbeat:Fire(1/60);click(gui,'NoFallDamage')
        assert(root.AssemblyLinearVelocity==v,'OFF left the root stopped')
        w.services.RunService.RenderStepped:Fire(1/60);assert(root.AssemblyLinearVelocity==v)
        click(gui,'NoFallDamage');w.services.RunService.Heartbeat:Fire(1/60)
        local other=e.Vector3.new(20,35,12);root.AssemblyLinearVelocity=other
        w.services.RunService.RenderStepped:Fire(1/60);assert(root.AssemblyLinearVelocity==other,'stale restoration overwrote another script')
        root.AssemblyLinearVelocity=v;w.services.RunService.Heartbeat:Fire(1/60)
        w.services.RunService.PreSimulation:Fire(1/60);assert(root.AssemblyLinearVelocity==v,'skipped render left zero velocity for physics')
        w.services.RunService.Heartbeat:Fire(1/60);w.services.RunService.Heartbeat:Fire(1/60)
        w.services.RunService.RenderStepped:Fire(1/60);assert(root.AssemblyLinearVelocity==v,'multiple heartbeats captured a stale zero')
        root.Anchored=true;w.services.RunService.Heartbeat:Fire(1/60);assert(root.AssemblyLinearVelocity==v)
        root.Anchored=false;close(w,gui)
    end)
    test('rapid No Fall Damage toggles keep bounded listeners and discard old queued callbacks',function()
        local w,gui=launch();local _,_,root=w.character();w.step(30)
        local rs=w.services.RunService;local objects=#w.objects
        for _=1,20 do
            click(gui,'NoFallDamage');assert(rs.Heartbeat:Count()==2 and rs.RenderStepped:Count()==1)
            click(gui,'NoFallDamage');assert(rs.Heartbeat:Count()==1 and rs.RenderStepped:Count()==0)
        end
        assert(#w.objects==objects and w.player.CharacterAdded:Count()==0)
        click(gui,'NoFallDamage')
        local oldPulse=rs.Heartbeat.links[#rs.Heartbeat.links].fn
        local oldRestore=rs.RenderStepped.links[#rs.RenderStepped.links].fn
        click(gui,'NoFallDamage');click(gui,'NoFallDamage')
        root.AssemblyLinearVelocity=w.env.Vector3.new(2,-67,1)
        oldPulse();assert(root.AssemblyLinearVelocity.Y==-67,'stale callback survived a new activation')
        rs.Heartbeat:Fire(1/60);oldRestore();assert(root.AssemblyLinearVelocity==w.env.Vector3.zero)
        rs.RenderStepped:Fire(1/60);assert(root.AssemblyLinearVelocity.Y==-67)
        close(w,gui)
    end)
    test('closing, external destruction and reexecution release active No Fall Damage',function()
        for _,mode in ipairs({'close','destroy','reexecute','missing-root'})do
            local w,gui=launch();local character,_,root=w.character();w.step(30);click(gui,'NoFallDamage')
            local v=w.env.Vector3.new(5,-110,3);root.AssemblyLinearVelocity=v
            w.services.RunService.Heartbeat:Fire(1/60)
            local again
            if mode=='close' then close(w,gui)
            elseif mode=='reexecute' then again=w.run(source);w.step(30)
            elseif mode=='missing-root' then root:Destroy();gui:Destroy()
            else gui:Destroy() end
            if mode~='missing-root' then assert(root.AssemblyLinearVelocity==v,'cleanup did not restore pending velocity')end
            assert(w.player.CharacterAdded:Count()==0 and w.player.CharacterRemoving:Count()==0)
            assert(character.ChildAdded:Count()==0 and character.ChildRemoved:Count()==0)
            assert(w.services.RunService.RenderStepped:Count()==0 and w.services.RunService.PreSimulation:Count()==0)
            assert(w.services.RunService.Heartbeat:Count()==(again and 1 or 0))
            if again then assert(find(again,'ToggleStatus').Text=='OFF' and not again:GetAttribute('NoFallDamageEnabled'));close(w,again)end
            local _,_,nextRoot=w.character();nextRoot.AssemblyLinearVelocity=w.env.Vector3.new(0,-81,0);w.step(60)
            assert(nextRoot.AssemblyLinearVelocity.Y==-81)
        end
    end)
    test('unsupported places keep No Fall Damage OFF without blocking the GUI',function()
        local w=setup();w.env.game.PlaceId=12345;local gui=w.run(source);w.character();w.step(30)
        click(gui,'Tab_Main');w.step(30);click(gui,'NoFallDamage');w.step(30)
        assert(not gui:GetAttribute('NoFallDamageSupported') and not gui:GetAttribute('NoFallDamageEnabled'))
        assert(find(gui,'ToggleStatus').Text=='OFF' and find(gui,'ToggleFlash').BackgroundTransparency==1)
        assert(w.services.RunService.Heartbeat:Count()==1 and w.services.RunService.RenderStepped:Count()==0)
        assert(w.player.CharacterAdded:Count()==0 and #w.warnings==1)
        click(gui,'Tab_Settings');w.step(30);assert(gui:GetAttribute('Page')=='Settings');close(w,gui)
    end)
    test('No Fall Damage lights up with one flash, dims fully and keeps touch targets stationary',function()
        local w,gui=launch();w.character();w.step(30);click(gui,'Tab_Main');w.step(30)
        local b=find(gui,'NoFallDamage');local neon=find(b,'ToggleNeon');local flash=find(b,'ToggleFlash')
        local p=b.AbsolutePosition;local size=b.AbsoluteSize;local e=w.env
        local pointer={UserInputType=e.Enum.UserInputType.Touch,Position=e.Vector3.new(300,250)}
        b.InputBegan:Fire(pointer);w.step(4);assert(find(b,'TogglePressScale').Scale<1)
        near(b.AbsolutePosition.X,p.X);near(b.AbsoluteSize.X,size.X)
        w.services.UserInputService.InputEnded:Fire(pointer);click(gui,'NoFallDamage')
        assert(flash.BackgroundTransparency<1 and find(b,'ToggleStatus').Text=='ON')
        w.step(10);assert(neon.BackgroundTransparency<1 and find(b,'ToggleBlend').Value<1)
        w.step(35);near(flash.BackgroundTransparency,1);near(find(b,'TogglePressScale').Scale,1)
        local wash=neon:FindFirstChildOfClass('UIGradient');local x=wash.Offset.X
        w.step(25);assert(wash.Offset.X~=x)
        click(gui,'NoFallDamage');assert(flash.BackgroundTransparency==1 and find(b,'ToggleStatus').Text=='OFF')
        w.step(20);near(neon.BackgroundTransparency,1)
        near(find(b,'ToggleGlow'):FindFirstChildOfClass('UIStroke').Transparency,1)
        x=wash.Offset.X;w.step(30);near(wash.Offset.X,x)
        close(w,gui)
    end)
    print(tostring(count)..' scenarios passed. Rendering, real touch and game damage still require Roblox.')
end
