local newWorld=require('./mock_roblox')
return function(source)
    local count=0
    local URL='https://raw.githubusercontent.com/hzReyzn/Ghislain/main/assets/reyzn-x/'
    local function png(bytes) return '\137PNG\13\10\26\10'..'\0\0\0\13IHDR'..string.rep('a',bytes-24)..'IEND\174\66\96\130' end
    local artwork={['launcher-r-v1.png']=png(2136070),['emblem-x-v1.png']=png(1699126),['flame-wisp-v1.png']=png(1172326),['minimize-v1.png']=png(1283532),['collapse-v1.png']=png(1337784),['close-v1.png']=png(1570916)}
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
        assert(gui.ResetOnSpawn==false and gui:GetAttribute('Version')=='2.2.0')
        assert(find(gui,'UserID').Text=='ID  123' and find(gui,'SessionTime').Text=='00:00:00')
        assert(w.thumbnailRequest.id==123 and w.thumbnailRequest.kind.Name=='HeadShot')
        assert(find(gui,'Avatar').Image=='rbxthumb://test-avatar')
        assert(find(gui,'Credit').Text=='Made By Reyzn')
        for _,name in ipairs({'Main','Visuals','Scripts','Settings'}) do
            assert(find(gui,'Tab_'..name):FindFirstChild('Caption',true).Font.Name=='BuilderSansMedium')
            if name~='Settings' then assert(#find(gui,'Page_'..name):GetChildren()==0,'section should be empty') end
        end
        assert(find(gui,'Tab_Home'):FindFirstChild('Caption',true).Font.Name=='GothamMedium')
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
        assert(#w.requests==6 and #w.writes==6)
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
        assert(gui.Parent==nil and #w.requests==6 and #w.writes==6,'valid cache was downloaded again')
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
            assert(settings:FindFirstChild('Caption',true).TextSize>=15)
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
        assert(broken.files['ReyznX-emblem-x-v1.png']==nil and #broken.requests==7)
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
            assert(#w.requests<=12,'unbounded retries')
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
            assert(title.ClassName=='TextLabel' and title.Text:gsub('<.->','')=='Reyzn X' and title.RichText)
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
        local w,gui=launch();w.step(30);gui:SetAttribute('VisualQuality','High');w.step(20)
        local dock,panel,launcher=find(gui,'DockAura'),find(gui,'PanelAura'),find(gui,'LauncherAura')
        assert(dock.Parent==find(gui,'Window') and panel.Parent==find(gui,'Window'))
        assert(not panel:IsDescendantOf(find(gui,'PanelReveal')) and launcher.Parent==find(gui,'Launcher'))
        assert(not gui:FindFirstChild('AuraHalo',true) and not gui:FindFirstChild('AuraWisp',true),'old rings survived')
        local fire,particles=0,0
        for _,aura in ipairs({dock,panel,launcher}) do
            assert(not aura.Active and not aura.ClipsDescendants)
            for _,o in ipairs(aura:GetDescendants())do
                if o:IsA('GuiObject')then assert(not o.Active,'VFX captures input')end
                if o.Name=='FlameCore'then fire+=1;assert(o.Image=='mock://ReyznX-flame-wisp-v1.png')end
                if o.Name=='EdgeParticle'then particles+=1 end
            end
        end
        assert(fire==52 and particles==26,'unbounded effect pools')
        local plume=dock:FindFirstChild('FlameSlot');local length=plume.Size.Y.Offset
        local objects=#w.objects;w.step(120)
        assert(#w.objects==objects and plume.Size.Y.Offset~=length,'frozen or allocating effect')
        for _,aura in ipairs({dock,panel})do
            for _,particle in ipairs(aura:GetChildren())do
                if particle.Name=='EdgeParticle' and particle.Visible then
                    local p=particle.Position;local s=aura.Size
                    assert(p.X.Offset<-4 or p.Y.Offset<-4 or p.X.Offset>s.X.Offset+4 or p.Y.Offset>s.Y.Offset+4,'particle over content')
                end
            end
        end
        click(gui,'Collapse');w.step(30);assert(not panel.Visible)
        click(gui,'Tab_Main');w.step(30);assert(panel.Visible)
        click(gui,'Minimize');w.step(30)
        assert(plume:FindFirstChild('FlameCore').ImageTransparency==1,'window flame left behind')
        local logoFlame=launcher:FindFirstChild('FlameSlot'):FindFirstChild('FlameCore')
        assert(logoFlame.ImageTransparency<1)
        click(gui,'Launcher');w.step(30);assert(logoFlame.ImageTransparency==1)
        close(w,gui)
    end)
    test('quality selector changes budgets, preserves geometry and never recreates pools',function()
        local w,gui=launch(844,354);w.step(30)
        assert(gui:GetAttribute('VisualQuality')=='Medium','touch default too costly')
        local win=find(gui,'Window');local x,y=win.Position.X.Offset,win.Position.Y.Offset
        local width,height=win.Size.X.Offset,win.Size.Y.Offset;local objects=#w.objects
        local previousCount=0
        click(gui,'Tab_Settings');w.step(30)
        for _,name in ipairs({'Low','Medium','High'})do
            click(gui,'Quality_'..name);w.step(30)
            assert(gui:GetAttribute('VisualQuality')==name and gui:GetAttribute('EffectiveQuality')==name)
            local active=0
            for _,auraName in ipairs({'DockAura','PanelAura','LauncherAura'})do
                for _,o in ipairs(find(gui,auraName):GetChildren())do
                    if o.Visible and (o.Name=='FlameSlot' or o.Name=='EdgeParticle')then active+=1 end
                end
            end
            assert(active>previousCount);previousCount=active
            assert(find(gui,'DockAura'):FindFirstChild('FlameSlot'):FindFirstChild('FlameHaze').Visible==(name~='Low'))
            near(win.Position.X.Offset,x);near(win.Position.Y.Offset,y)
            near(win.Size.X.Offset,width);near(win.Size.Y.Offset,height)
            assert(#w.objects==objects)
        end
        close(w,gui)
    end)
    test('adaptive quality has hysteresis and respects the chosen maximum',function()
        local w,gui=launch();w.step(30)
        w.step(200,1/30)
        assert(gui:GetAttribute('EffectiveQuality')=='Low','sustained low FPS did not lower budget')
        assert(gui:GetAttribute('VisualQuality')=='Medium','adaptation overwrote user choice')
        w.step(180,1/60)
        assert(gui:GetAttribute('EffectiveQuality')=='Low','quality bounced back too soon')
        w.step(900,1/60)
        assert(gui:GetAttribute('EffectiveQuality')=='Medium','budget did not recover')
        click(gui,'Quality_Low');w.step(850,1/60)
        assert(gui:GetAttribute('EffectiveQuality')=='Low','exceeded selected cap')
        gui:SetAttribute('VisualQuality','High');w.step(30)
        assert(gui:GetAttribute('EffectiveQuality')=='High')
        w.step(1,.8);w.step(60)
        assert(gui:GetAttribute('EffectiveQuality')=='High','one background stall downgraded quality')
        close(w,gui)
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
        local plume=find(gui,'DockAura'):FindFirstChild('FlameSlot');local p=plume.Position
        w.step(90);near(plume.Position.X.Offset,p.X.Offset);near(plume.Position.Y.Offset,p.Y.Offset)
        close(w,gui)
    end)
    print(tostring(count)..' scenarios passed. Rendering and real touch input still require Roblox.')
end
