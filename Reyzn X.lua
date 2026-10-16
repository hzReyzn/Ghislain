-- Reyzn X | Made By Reyzn
-- Client GUI only. The fixed HTTP resources below are PNG artwork, never code.
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local player = Players.LocalPlayer
if not player then return end
local startedAt = os.clock()
local playerGui = player:WaitForChild("PlayerGui")
local previous = playerGui:FindFirstChild("ReyznX")
if previous then previous:Destroy() end

local VERSION = "2.1.0"
local C = {
    base=Color3.fromRGB(10,10,15), panel=Color3.fromRGB(16,15,23),
    black=Color3.fromRGB(8,8,12), steel=Color3.fromRGB(71,68,85),
    silver=Color3.fromRGB(217,219,233), white=Color3.fromRGB(245,244,251),
    muted=Color3.fromRGB(184,181,201), line=Color3.fromRGB(66,59,85),
    violet=Color3.fromRGB(157,103,239), light=Color3.fromRGB(213,181,255),
    deep=Color3.fromRGB(60,31,99), green=Color3.fromRGB(132,225,179), ice=Color3.fromRGB(180,207,255),
}
local state = {alive=true, target="open", page="Home", paneOpen=true,
    lastSecond=-1, phase=0, budget=0, burst=0, finishAt=0, launcherMoved=false}
local UI, connections, threads, tweens = {}, {}, {}, {}
local scopes, alphaEntries, alphaLookup = {}, {}, {}
local factors = {window=0, pane=0, page=0, launcher=0, fixed=1}

local function connect(signal, callback)
    local c = signal:Connect(function(...) if state.alive then callback(...) end end)
    connections[#connections+1] = c
    return c
end
local function spawn(callback)
    local thread
    thread = task.defer(function() callback(); threads[thread]=nil end)
    threads[thread] = true
end
-- Transparency is composed from immutable base values. Transitions never sample
-- a half-faded frame, so repeated/reversed animations cannot progressively dim it.
local function registerAlpha(o, property, base, scope)
    local entry={object=o, property=property, base=base, scope=scope}
    alphaEntries[#alphaEntries+1]=entry
    alphaLookup[o]=alphaLookup[o] or {}; alphaLookup[o][property]=entry
    o[property]=1-(1-base)*(factors[scope] or 1)
end
local function alpha(o, property, base)
    local entry=alphaLookup[o] and alphaLookup[o][property]
    if entry then
        entry.base=base; o[property]=1-(1-base)*(factors[entry.scope] or 1)
    else o[property]=base end
end
local function refreshAlpha()
    factors.window=UI.windowFade.Value
    factors.pane=factors.window*UI.paneProgress.Value
    factors.page=factors.pane*UI.pageFade.Value
    factors.launcher=UI.launcherFade.Value
    for _,entry in ipairs(alphaEntries) do
        entry.object[entry.property]=1-(1-entry.base)*(factors[entry.scope] or 1)
    end
end
local function make(class, parent, props, scope)
    local o=Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    if o:IsA("GuiObject") then o.BorderSizePixel=0; o.AutoLocalize=false end
    scopes[o]=scope or scopes[parent] or "fixed"
    o.Parent=parent
    if o:IsA("GuiObject") then
        registerAlpha(o,"BackgroundTransparency",o.BackgroundTransparency,scopes[o])
        if o:IsA("TextLabel") or o:IsA("TextButton") then
            o.TextStrokeTransparency=1
            registerAlpha(o,"TextTransparency",o.TextTransparency,scopes[o])
        end
        if o:IsA("ImageLabel") or o:IsA("ImageButton") then
            registerAlpha(o,"ImageTransparency",o.ImageTransparency,scopes[o])
        end
        if o:IsA("ScrollingFrame") then registerAlpha(o,"ScrollBarImageTransparency",o.ScrollBarImageTransparency,scopes[o]) end
    elseif o:IsA("UIStroke") then registerAlpha(o,"Transparency",o.Transparency,scopes[o]) end
    return o
end
local function tween(o, seconds, props)
    if not state.alive then return end
    if tweens[o] then tweens[o]:Cancel() end
    local t=TweenService:Create(o,TweenInfo.new(seconds,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),props)
    tweens[o]=t; t:Play()
end
local function corner(o,r) return make("UICorner",o,{CornerRadius=UDim.new(0,r or 12)}) end
local function stroke(o,color,opacity,width)
    return make("UIStroke",o,{Color=color or C.line,Transparency=opacity or 0,Thickness=width or 1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
end
local function gradient(o,colors,rotation)
    local keys={}
    for i,color in ipairs(colors) do keys[i]=ColorSequenceKeypoint.new((i-1)/(#colors-1),color) end
    return make("UIGradient",o,{Color=ColorSequence.new(keys),Rotation=rotation or 90})
end
local function fadeGradient(g)
    g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.48,.08),NumberSequenceKeypoint.new(.52,.08),NumberSequenceKeypoint.new(1,1)})
end
local function frame(parent,name,pos,size,color,transparency,scope)
    return make("Frame",parent,{Name=name,Position=pos,Size=size,BackgroundColor3=color or C.panel,BackgroundTransparency=transparency or 0},scope)
end
local function label(parent,name,text,pos,size,pixels,color,font)
    return make("TextLabel",parent,{Name=name,Text=text,Position=pos,Size=size,BackgroundTransparency=1,
        TextColor3=color or C.white,TextSize=pixels or 14,Font=font or Enum.Font.GothamMedium,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd})
end
local function imageLabel(parent,name,pos,size)
    return make("ImageLabel",parent,{Name=name,Image="",Position=pos,Size=size,BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit})
end
local paths={
    crown={{{3,7},{6,17},{18,17},{21,7},{16,11},{12,3},{8,11},{3,7}},{{6,21},{18,21}}},
    home={{{3,11},{12,3},{21,11}},{{6,9},{6,21},{10,21},{10,15},{14,15},{14,21},{18,21},{18,9}}},
    cube={{{12,2},{22,7},{22,18},{12,23},{2,18},{2,7},{12,2}},{{2,7},{12,12},{22,7}},{{12,12},{12,23}}},
    spark={{{12,2},{15,9},{22,12},{15,15},{12,22},{9,15},{2,12},{9,9},{12,2}}},
    code={{{8,6},{2,12},{8,18}},{{16,6},{22,12},{16,18}},{{14,3},{10,21}}},
    settings={{{4,6},{20,6}},{{4,12},{20,12}},{{4,18},{20,18}},{{9,3},{9,9}},{{16,9},{16,15}},{{8,15},{8,21}}},
    arrow={{{4,12},{20,12}},{{14,6},{20,12},{14,18}}},
    close={{{6,6},{18,18}},{{18,6},{6,18}}},
    minimize={{{5,16},{19,16}}}, fold={{{14,5},{7,12},{14,19}}},
}
local function icon(parent,kind,pos,size,color)
    local host=frame(parent,"Icon_"..kind,pos,UDim2.fromOffset(size,size),nil,1)
    for _,path in ipairs(paths[kind]) do
        for i=1,#path-1 do
            local a,b=path[i],path[i+1]; local dx,dy=(b[1]-a[1])*size/24,(b[2]-a[2])*size/24
            local line=frame(host,"Line",UDim2.fromOffset((a[1]+b[1])*size/48,(a[2]+b[2])*size/48),UDim2.fromOffset(math.sqrt(dx*dx+dy*dy),1.7),color or C.silver)
            line.AnchorPoint=Vector2.new(.5,.5); line.Rotation=math.deg(math.atan2(dy,dx)); corner(line,2)
        end
    end
    return host
end
local function tintIcon(host,color)
    for _,line in ipairs(host:GetChildren()) do if line:IsA("Frame") then line.BackgroundColor3=color end end
end
local metallicColors={Color3.fromRGB(39,37,49),Color3.fromRGB(23,22,32),C.black,Color3.fromRGB(25,20,36)}
local activeColors={Color3.fromRGB(83,59,119),Color3.fromRGB(45,32,65),Color3.fromRGB(24,20,35),Color3.fromRGB(53,32,80)}
local buttons={}
local function button(parent,name,pos,size)
    local b=make("TextButton",parent,{Name=name,Text="",Position=pos,Size=size,BackgroundColor3=Color3.new(1,1,1),AutoButtonColor=false,Selectable=true})
    corner(b,10)
    local wash=gradient(b,metallicColors,105)
    local edge=stroke(b,Color3.new(1,1,1),.36,1)
    gradient(edge,{C.steel,C.silver,C.deep,C.violet},32)
    local sheen=frame(b,"Sheen",UDim2.fromOffset(2,2),UDim2.new(1,-4,1,-4),C.white,.96)
    corner(sheen,9); local light=gradient(sheen,{C.white,C.light},25); fadeGradient(light)
    local record={button=b,edge=edge,wash=wash,sheen=sheen,light=light,hover=false,selected=false}
    buttons[#buttons+1]=record
    connect(b.MouseEnter,function() record.hover=true; alpha(sheen,"BackgroundTransparency",.88);alpha(edge,"Transparency",.08) end)
    connect(b.MouseLeave,function() record.hover=false;alpha(sheen,"BackgroundTransparency",.96);alpha(edge,"Transparency",record.selected and .12 or .36) end)
    return b,record
end

UI.gui=make("ScreenGui",playerGui,{Name="ReyznX",ResetOnSpawn=false,DisplayOrder=50,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,IgnoreGuiInset=false})
pcall(function() UI.gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets end)
UI.gui:SetAttribute("Version",VERSION)
local function cleanup()
    if not state.alive then return end
    state.alive=false; state.drag=nil
    for _,c in ipairs(connections) do c:Disconnect() end
    for _,t in pairs(tweens) do t:Cancel() end
    for thread in pairs(threads) do if coroutine.status(thread)~="dead" then pcall(task.cancel,thread) end end
    table.clear(connections);table.clear(threads);table.clear(tweens)
end
connections[#connections+1]=UI.gui.Destroying:Connect(cleanup)
UI.windowFade=make("NumberValue",UI.gui,{Name="WindowOpacity",Value=0})
UI.launcherFade=make("NumberValue",UI.gui,{Name="LauncherOpacity",Value=0})
UI.paneProgress=make("NumberValue",UI.gui,{Name="PaneProgress",Value=1})
UI.pageFade=make("NumberValue",UI.gui,{Name="PageOpacity",Value=1})
UI.zoom=make("NumberValue",UI.gui,{Name="WindowZoom",Value=.985})
UI.screen=frame(UI.gui,"SafeArea",UDim2.fromScale(0,0),UDim2.fromScale(1,1),nil,1)
UI.screen.ClipsDescendants=false
UI.window=frame(UI.screen,"Window",UDim2.fromOffset(100,100),UDim2.fromOffset(880,420),nil,1,"window")
UI.window.ClipsDescendants=false
UI.scale=make("UIScale",UI.window,{Scale=.985})

local function surface(parent,name,pos,size,scope)
    local o=frame(parent,name,pos,size,Color3.new(1,1,1),0,scope);corner(o,16)
    gradient(o,{C.panel,C.base,C.black},100)
    local halo=frame(o,"OuterGlow",UDim2.fromOffset(-3,-3),UDim2.new(1,6,1,6),nil,1)
    corner(halo,19);local glow=stroke(halo,C.violet,.87,5)
    local edge=stroke(o,Color3.new(1,1,1),.22,1.1)
    local metal=gradient(edge,{C.steel,C.silver,C.violet,C.black,C.violet},24)
    local inner=frame(o,"InnerRim",UDim2.fromOffset(2,2),UDim2.new(1,-4,1,-4),nil,1)
    corner(inner,14);stroke(inner,C.silver,.94,1)
    local beam=frame(o,"EdgeLight",UDim2.fromOffset(16,0),UDim2.new(1,-32,0,1),C.white,.3)
    local beamGradient=gradient(beam,{C.light,C.silver,C.violet},0);fadeGradient(beamGradient)
    return o,{glow=glow,edge=edge,metal=metal,beam=beam,beamGradient=beamGradient}
end
UI.dock,UI.dockFx=surface(UI.window,"Dock",UDim2.fromOffset(0,0),UDim2.fromOffset(170,420))
UI.dock.ZIndex=2
UI.dockCrown=icon(UI.dock,"crown",UDim2.fromOffset(17,20),24,C.light)
UI.brandFallback=label(UI.dock,"BrandFallback","Reyzn <font color=\"rgb(188,141,255)\">X</font>",UDim2.fromOffset(49,13),UDim2.fromOffset(110,36),22,C.white,Enum.Font.GothamBold)
UI.brandFallback.RichText=true
UI.brand=imageLabel(UI.dock,"BrandWordmark",UDim2.fromOffset(46,8),UDim2.fromOffset(116,48))
UI.dragArea=frame(UI.dock,"DragArea",UDim2.fromOffset(0,0),UDim2.new(1,0,0,60),nil,1)
UI.dragArea.Active=true;UI.dragArea.ZIndex=5
UI.dockDivider=frame(UI.dock,"Divider",UDim2.fromOffset(14,62),UDim2.new(1,-28,0,1),C.line,.25)
gradient(UI.dockDivider,{C.black,C.violet,C.black},0)
UI.nav=make("ScrollingFrame",UI.dock,{Name="Navigation",Position=UDim2.fromOffset(9,76),Size=UDim2.new(1,-18,1,-138),
    BackgroundTransparency=1,CanvasSize=UDim2.fromOffset(0,240),CanvasPosition=Vector2.zero,ScrollBarThickness=2,
    ScrollBarImageColor3=C.violet,ScrollBarImageTransparency=.65,Active=true,ScrollingEnabled=true,
    ClipsDescendants=true,ScrollingDirection=Enum.ScrollingDirection.Y,AutomaticCanvasSize=Enum.AutomaticSize.None})
local navigation={}
local optionFont=Enum.Font.BuilderSansMedium
for i,data in ipairs({{"Home","home"},{"Main","cube"},{"Visuals","spark"},{"Scripts","code"},{"Settings","settings"}}) do
    local b,fx=button(UI.nav,"Tab_"..data[1],UDim2.fromOffset(0,(i-1)*48),UDim2.new(1,-3,0,42))
    local glyph=icon(b,data[2],UDim2.fromOffset(12,10),22,C.muted)
    local caption=label(b,"Caption",data[1],UDim2.fromOffset(45,0),UDim2.new(1,-51,1,0),17,C.muted,data[1]=="Home" and Enum.Font.GothamMedium or optionFont)
    navigation[data[1]]={button=b,fx=fx,icon=glyph,caption=caption,index=i}
end
UI.selectionLight=frame(UI.nav,"SelectionLight",UDim2.fromOffset(0,12),UDim2.fromOffset(2,18),C.white,0)
UI.selectionLight.ZIndex=4;corner(UI.selectionLight,2)
UI.controls=frame(UI.dock,"WindowControls",UDim2.new(0,12,1,-50),UDim2.new(1,-24,0,36),nil,1)
local controlArtwork={}
for i,data in ipairs({{"Minimize","minimize"},{"Collapse","fold"},{"Close","close"}}) do
    local b=make("ImageButton",UI.controls,{Name=data[1],Image="",BackgroundTransparency=1,Position=UDim2.fromOffset((i-1)*46,0),Size=UDim2.fromOffset(40,36),AutoButtonColor=false,Active=true,Selectable=true})
    local fallback=frame(b,"ControlFallback",UDim2.fromScale(0,0),UDim2.fromScale(1,1),Color3.new(1,1,1))
    corner(fallback,10);gradient(fallback,metallicColors,105);stroke(fallback,C.silver,.6)
    local glyph=icon(fallback,data[2],UDim2.fromOffset(9,7),22,C.silver)
    if data[1]=="Collapse" then UI.foldIcon=glyph end
    local glow=imageLabel(b,"ControlGlow",UDim2.fromScale(.5,.5),UDim2.new(1,8,1,6))
    glow.AnchorPoint=Vector2.new(.5,.5);glow.ImageColor3=C.ice;alpha(glow,"ImageTransparency",.95)
    local art=imageLabel(b,"ControlArtwork",UDim2.fromScale(.5,.5),UDim2.new(1,4,1,0))
    art.AnchorPoint=Vector2.new(.5,.5)
    local artScale=make("UIScale",art,{Scale=1})
    local record={image=art,glow=glow,fallback=fallback,glyph=glyph,scale=artScale,pressed=false,hover=false}
    controlArtwork[data[1]]=record
    connect(b.MouseEnter,function() record.hover=true;alpha(glow,"ImageTransparency",.76);if not record.pressed then tween(artScale,.14,{Scale=1.06}) end end)
    connect(b.MouseLeave,function() record.hover=false;alpha(glow,"ImageTransparency",.95);if not record.pressed then tween(artScale,.18,{Scale=1}) end end)
    connect(b.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            record.pressed=true;record.pointer=input;tween(artScale,.08,{Scale=.93});alpha(glow,"ImageTransparency",.65)
        end
    end)
    connect(Input.InputEnded,function(input)
        if record.pressed and (input==record.pointer or (record.pointer.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1)) then
            record.pressed=false;record.pointer=nil;tween(artScale,.16,{Scale=record.hover and 1.06 or 1});alpha(glow,"ImageTransparency",record.hover and .76 or .95)
        end
    end)
    connect(Input.WindowFocusReleased,function() record.pressed=false;record.pointer=nil;tween(artScale,.16,{Scale=1}) end)
    UI[data[1]]=b
end
UI.reveal=frame(UI.window,"PanelReveal",UDim2.fromOffset(180,0),UDim2.fromOffset(700,420),nil,1,"pane")
UI.reveal.ZIndex=2
UI.reveal.ClipsDescendants=true
UI.panel,UI.panelFx=surface(UI.reveal,"Panel",UDim2.fromOffset(4,4),UDim2.fromOffset(692,412))
UI.header=frame(UI.panel,"Header",UDim2.fromOffset(20,8),UDim2.new(1,-40,0,58),nil,1)
UI.pageTitle=label(UI.header,"PageTitle","Home",UDim2.fromOffset(0,0),UDim2.fromOffset(130,54),20,C.white,Enum.Font.GothamBold)
UI.avatarPlate=frame(UI.header,"AvatarPlate",UDim2.fromOffset(190,11),UDim2.fromOffset(32,32),C.panel)
corner(UI.avatarPlate,100);stroke(UI.avatarPlate,C.light,.18)
UI.avatarFallback=label(UI.avatarPlate,"AvatarFallback",string.upper(string.sub(player.Name,1,1)),UDim2.fromScale(0,0),UDim2.fromScale(1,1),14)
UI.avatarFallback.TextXAlignment=Enum.TextXAlignment.Center
UI.avatar=imageLabel(UI.avatarPlate,"Avatar",UDim2.fromOffset(2,2),UDim2.new(1,-4,1,-4))
UI.avatar.ScaleType=Enum.ScaleType.Crop;corner(UI.avatar,100)
UI.userID=label(UI.header,"UserID","ID  "..tostring(player.UserId),UDim2.fromOffset(232,0),UDim2.fromOffset(170,54),12,C.muted)
UI.sessionDot=frame(UI.header,"SessionDot",UDim2.fromOffset(422,24),UDim2.fromOffset(5,5),C.violet)
corner(UI.sessionDot,5)
UI.session=label(UI.header,"SessionTime","00:00:00",UDim2.fromOffset(436,0),UDim2.fromOffset(94,54),12,C.silver,Enum.Font.RobotoMono)
UI.panelDrag=frame(UI.panel,"PanelDragArea",UDim2.fromOffset(0,0),UDim2.new(1,0,0,68),nil,1)
UI.panelDrag.Active=true;UI.panelDrag.ZIndex=5
UI.headerLine=frame(UI.panel,"HeaderLine",UDim2.fromOffset(18,67),UDim2.new(1,-36,0,1),C.line,.2)
gradient(UI.headerLine,{C.steel,C.deep,C.silver},0)
UI.content=frame(UI.panel,"Content",UDim2.fromOffset(16,80),UDim2.new(1,-32,1,-116),nil,1)
UI.content.ClipsDescendants=true
UI.credit=label(UI.panel,"Credit","Made By Reyzn",UDim2.new(0,20,1,-30),UDim2.new(1,-40,0,22),11,C.muted)
UI.credit.TextXAlignment=Enum.TextXAlignment.Right
local pages={}
for _,name in ipairs({"Home","Main","Visuals","Scripts","Settings"}) do
    local page=make("ScrollingFrame",UI.content,{Name="Page_"..name,Position=UDim2.fromOffset(0,0),Size=UDim2.fromScale(1,1),
        BackgroundTransparency=1,CanvasSize=UDim2.fromOffset(0,0),CanvasPosition=Vector2.zero,ScrollBarThickness=3,
        ScrollBarImageColor3=C.violet,ScrollBarImageTransparency=.5,Active=true,ScrollingEnabled=true,
        ClipsDescendants=true,ScrollingDirection=Enum.ScrollingDirection.Y,AutomaticCanvasSize=Enum.AutomaticSize.None,Visible=name=="Home"},"page")
    pages[name]=page
end
-- Main, Visuals, Scripts and Settings intentionally contain no features or filler.
UI.hero=frame(pages.Home,"Hero",UDim2.fromOffset(1,1),UDim2.new(1,-8,0,200),Color3.new(1,1,1))
corner(UI.hero,13);stroke(UI.hero,C.violet,.62)
gradient(UI.hero,{Color3.fromRGB(28,22,40),C.black,Color3.fromRGB(26,17,39)},32)
UI.heroTitleFallback=label(UI.hero,"HeroTitleFallback","Reyzn <font color=\"rgb(188,141,255)\">X</font>",UDim2.fromOffset(22,32),UDim2.fromOffset(236,52),32,C.white,Enum.Font.GothamBold)
UI.heroTitleFallback.RichText=true
UI.heroTitle=imageLabel(UI.hero,"HeroTitle",UDim2.fromOffset(20,10),UDim2.fromOffset(268,100))
UI.heroUnderline=frame(UI.hero,"SilverAccent",UDim2.fromOffset(24,94),UDim2.fromOffset(46,2),C.silver,.08)
gradient(UI.heroUnderline,{C.light,C.silver,C.deep},0)
UI.openMain=button(UI.hero,"OpenMain",UDim2.fromOffset(22,128),UDim2.fromOffset(154,42))
label(UI.openMain,"Caption","Main",UDim2.fromOffset(16,0),UDim2.new(1,-48,1,0),17,C.white,optionFont)
icon(UI.openMain,"arrow",UDim2.new(1,-33,0,11),20,C.light)
UI.emblemHost=frame(UI.hero,"EmblemHost",UDim2.new(1,-224,0,2),UDim2.fromOffset(220,196),nil,1)
UI.xFallback=label(UI.emblemHost,"XFallback","X",UDim2.fromScale(0,0),UDim2.fromScale(1,1),92,C.light,Enum.Font.GothamBold)
UI.xFallback.TextXAlignment=Enum.TextXAlignment.Center
UI.xGlow=imageLabel(UI.emblemHost,"EmblemGlow",UDim2.new(0,-5,0,-5),UDim2.new(1,10,1,10))
UI.xGlow.ImageColor3=C.violet;alpha(UI.xGlow,"ImageTransparency",.87)
UI.xImage=imageLabel(UI.emblemHost,"EmblemX",UDim2.fromScale(0,0),UDim2.fromScale(1,1))
UI.heroGlint=frame(UI.hero,"HeroGlint",UDim2.new(.65,0,0,0),UDim2.fromOffset(80,1),C.silver,.12)
local glintGradient=gradient(UI.heroGlint,{C.violet,C.white,C.deep},0);fadeGradient(glintGradient)
UI.shortcuts={}
for i,data in ipairs({{"Main","cube"},{"Visuals","spark"}}) do
    local b=button(pages.Home,"Shortcut_"..data[1],UDim2.new((i-1)*.5,1,0,214),UDim2.new(.5,-9,0,58))
    icon(b,data[2],UDim2.fromOffset(15,17),24,C.light)
    local caption=label(b,"Caption",data[1],UDim2.fromOffset(51,0),UDim2.new(1,-80,1,0),17,C.white,optionFont)
    local arrow=icon(b,"arrow",UDim2.new(1,-32,0,19),20,C.muted)
    UI.shortcuts[data[1]]={button=b,caption=caption,arrow=arrow}
end

UI.launcher=make("ImageButton",UI.screen,{Name="Launcher",Image="",BackgroundTransparency=1,Size=UDim2.fromOffset(68,68),Position=UDim2.fromOffset(20,150),AutoButtonColor=false,Visible=false,Selectable=true},"launcher")
UI.launcherScale=make("UIScale",UI.launcher,{Scale=.92})
UI.rFallback=label(UI.launcher,"RFallback","R",UDim2.fromScale(0,0),UDim2.fromScale(1,1),34,C.white,Enum.Font.GothamBold)
UI.rFallback.TextXAlignment=Enum.TextXAlignment.Center
UI.launcherImage=imageLabel(UI.launcher,"LauncherR",UDim2.fromScale(0,0),UDim2.fromScale(1,1))
UI.launcherImage.ZIndex=2;UI.rFallback.ZIndex=2
UI.launcherHalo=frame(UI.launcher,"LauncherHalo",UDim2.fromOffset(3,3),UDim2.new(1,-6,1,-6),nil,1)
corner(UI.launcherHalo,16);UI.launcherRim=stroke(UI.launcherHalo,C.violet,.65,2)
gradient(UI.launcherRim,{C.violet,C.silver,C.deep},30)
UI.recovery=make("ImageButton",UI.screen,{Name="Recover",Image="",BackgroundColor3=C.panel,Size=UDim2.fromOffset(40,40),Position=UDim2.new(0,8,.5,-20),AutoButtonColor=false,Visible=false})
corner(UI.recovery,10);stroke(UI.recovery,C.light,.3)
UI.recoveryFallback=label(UI.recovery,"RecoveryFallback","R",UDim2.fromScale(0,0),UDim2.fromScale(1,1),22,C.white,Enum.Font.GothamBold)
UI.recoveryFallback.TextXAlignment=Enum.TextXAlignment.Center
UI.recoveryImage=imageLabel(UI.recovery,"RecoveryR",UDim2.fromScale(0,0),UDim2.fromScale(1,1))

-- A small reusable pool of native UI wisps. No per-frame instances, textures,
-- particle emitters or fullscreen post-processing. The panel aura is a sibling
-- of the clipped reveal, so its light can extend OUTSIDE the visible frame.
local function createAura(parent,name,scope,counts,small)
    local host=frame(parent,name,UDim2.fromOffset(0,0),UDim2.fromOffset(100,100),nil,1,scope)
    host.ZIndex=0;host.Active=false;host.ClipsDescendants=false
    local aura={host=host,rings={},wisps={},small=small}
    for i,spread in ipairs(small and {2,4,6,9,13,18} or {2,5,9,14,20,27}) do
        local ring=frame(host,"AuraHalo",UDim2.fromOffset(-spread,-spread),UDim2.new(1,spread*2,1,spread*2),nil,1)
        ring.Active=false;corner(ring,16+spread)
        local edge=stroke(ring,i<=2 and C.silver or (i<=4 and C.ice or C.violet),.9,small and 4 or 7)
        local color=gradient(edge,{C.violet,C.ice,C.white,C.light,C.violet},25+i*35)
        aura.rings[#aura.rings+1]={edge=edge,color=color,index=i}
    end
    for side,count in ipairs(counts) do
        for index=1,count do
            local plume=frame(host,"AuraWisp",UDim2.fromOffset(0,0),UDim2.fromOffset(8,24),C.ice,.9)
            plume.Active=false;plume.AnchorPoint=Vector2.new(.5,.5);corner(plume,100)
            local wash=gradient(plume,{C.violet,C.ice,C.white},90)
            wash.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,.4),NumberSequenceKeypoint.new(.65,.05),NumberSequenceKeypoint.new(1,1)})
            local core=frame(plume,"AuraCore",UDim2.fromScale(.5,.55),UDim2.fromScale(.23,.78),C.white,.65)
            core.Active=false;core.AnchorPoint=Vector2.new(.5,.5);corner(core,100)
            local coreGradient=gradient(core,{C.ice,C.white},90);fadeGradient(coreGradient)
            aura.wisps[#aura.wisps+1]={plume=plume,core=core,side=side,fraction=(index-.5)/count,seed=side*.173+index*.319}
        end
    end
    return aura
end
local function animateAura(aura,phase,burst)
    local w,h=aura.host.Size.X.Offset,aura.host.Size.Y.Offset
    if w<1 or h<1 then return end
    for _,ring in ipairs(aura.rings) do
        local pulse=.5+.5*math.sin(phase*1.7-ring.index*.7)
        alpha(ring.edge,"Transparency",math.clamp(.79+ring.index*.029-pulse*.025-burst*.06,.65,.985))
        ring.color.Offset=Vector2.new(math.sin(phase*.45+ring.index)*.28,0)
    end
    for _,item in ipairs(aura.wisps) do
        local travel=(phase*(.25+item.seed%0.13)+item.seed)%1
        local envelope=math.sin(travel*math.pi)^1.4
        local scale=aura.small and .54 or 1
        local length=(15+travel*17+math.sin(phase*2.2+item.seed)*3)*scale
        local distance=(1+travel*4)*scale+length*.5
        local sway=math.sin(phase*1.9+item.seed*9)*4*scale
        local side=item.side
        local x,y,rotation
        if side==1 then x=w*item.fraction+sway;y=-distance;rotation=0
        elseif side==2 then x=w+distance;y=h*item.fraction+sway;rotation=90
        elseif side==3 then x=w*item.fraction+sway;y=h+distance;rotation=180
        else x=-distance;y=h*item.fraction+sway;rotation=-90 end
        item.plume.Position=UDim2.fromOffset(x,y)
        item.plume.Size=UDim2.fromOffset((6+envelope*5)*scale,length)
        item.plume.Rotation=rotation+math.sin(phase*1.6+item.seed*7)*9
        alpha(item.plume,"BackgroundTransparency",1-envelope*(.2+burst*.08))
        alpha(item.core,"BackgroundTransparency",1-envelope*(.48+burst*.15))
    end
end
UI.dockAura=createAura(UI.window,"DockAura","window",{3,4,3,4},false)
UI.panelAura=createAura(UI.window,"PanelAura","pane",{7,4,7,4},false)
UI.launcherAura=createAura(UI.launcher,"LauncherAura","launcher",{2,2,2,2},true)
UI.launcherAura.host.Size=UDim2.fromOffset(68,68)

local layout={}
local function applyPane()
    if not layout.width then return end
    local p=UI.paneProgress.Value
    UI.reveal.Size=UDim2.fromOffset(layout.panelWidth*p,layout.height)
    UI.reveal.Visible=p>.001
    UI.window.Size=UDim2.fromOffset(layout.dockWidth+(layout.gap+layout.panelWidth)*p,layout.height)
    UI.panel.Position=UDim2.fromOffset(4-12*(1-p),4)
    UI.panelAura.host.Position=UDim2.fromOffset(layout.dockWidth+layout.gap+4,4)
    UI.panelAura.host.Size=UDim2.fromOffset(math.max(0,layout.panelWidth*p-8),layout.height-8)
    UI.panelAura.host.Visible=p>.03
    UI.foldIcon.Rotation=180*(1-p)
    UI.selectionLight.Visible=state.paneOpen
    refreshAlpha()
end
local function applyPage()
    pages[state.page].Position=UDim2.fromOffset(-8*(1-UI.pageFade.Value),0)
    refreshAlpha()
end
local function recenter()
    local v=UI.screen.AbsoluteSize
    UI.window.Position=UDim2.fromOffset(math.floor((v.X-UI.window.Size.X.Offset)/2),math.floor((v.Y-layout.height)/2))
    UI.launcher.Position=UDim2.fromOffset(18,math.max(12,math.floor(v.Y*.5-34)))
end
local function resize(initial)
    local v=UI.screen.AbsoluteSize
    if v.X<1 or v.Y<1 then return end
    layout.width=math.min(880,math.floor(v.X*(v.X<600 and .94 or .86)))
    layout.height=math.min(420,math.floor(v.Y*.82))
    layout.dockWidth=v.X<320 and 110 or (v.X<600 and 126 or 170)
    layout.gap=8;layout.panelWidth=math.max(150,layout.width-layout.dockWidth-layout.gap)
    local dw,h=layout.dockWidth,layout.height
    UI.dock.Size=UDim2.fromOffset(dw,h)
    UI.dockAura.host.Size=UDim2.fromOffset(dw,h)
    UI.dockCrown.Visible=dw>=150
    UI.brand.Position=UDim2.fromOffset(dw>=150 and 46 or 8,8)
    UI.brand.Size=UDim2.fromOffset(dw-(dw>=150 and 52 or 16),44)
    UI.brandFallback.Position=UDim2.fromOffset(dw>=150 and 49 or 14,13)
    UI.brandFallback.Size=UDim2.fromOffset(dw-(dw>=150 and 55 or 24),36)
    UI.brandFallback.TextSize=dw>=150 and 22 or (dw<120 and 18 or 21)
    local top=h<320 and 58 or 76
    UI.dockDivider.Position=UDim2.fromOffset(14,top-12)
    UI.dragArea.Size=UDim2.new(1,0,0,top-12)
    UI.nav.Position=UDim2.fromOffset(9,top)
    local available=h-top-60
    local step=math.clamp(math.floor(available/5),30,50)
    UI.nav.Size=UDim2.new(1,-18,0,available)
    UI.nav.CanvasSize=UDim2.fromOffset(0,5*step)
    layout.navStep=step
    for _,n in pairs(navigation) do
        n.button.Position=UDim2.fromOffset(0,(n.index-1)*step)
        n.button.Size=UDim2.new(1,-3,0,step-5)
        n.icon.Position=UDim2.fromOffset(dw>=150 and 12 or 8,(step-5-20)/2)
        n.icon.Visible=dw>=120
        n.caption.Position=UDim2.fromOffset(dw>=150 and 45 or (dw<120 and 12 or 36),0)
        n.caption.Size=UDim2.new(1,dw>=150 and -51 or (dw<120 and -20 or -39),1,0)
        n.caption.TextSize=dw>=150 and 17 or 15
    end
    UI.selectionLight.Position=UDim2.fromOffset(0,(navigation[state.page].index-1)*step+(step-23)/2)
    local controlW=math.floor((dw-24-12)/3)
    UI.controls.Size=UDim2.fromOffset(dw-24,36)
    for i,name in ipairs({"Minimize","Collapse","Close"}) do
        UI[name].Position=UDim2.fromOffset((i-1)*(controlW+6),0);UI[name].Size=UDim2.fromOffset(controlW,36)
        controlArtwork[name].glyph.Position=UDim2.fromOffset((controlW-22)/2,7)
    end
    UI.reveal.Position=UDim2.fromOffset(dw+layout.gap,0)
    local pw=layout.panelWidth-8
    UI.panel.Size=UDim2.fromOffset(pw,h-8)
    local wide=pw>=440
    local headerH=wide and 66 or (pw>=310 and 92 or 114)
    UI.header.Size=UDim2.new(1,-32,0,headerH)
    UI.header.Position=UDim2.fromOffset(16,0)
    UI.pageTitle.Position=UDim2.fromOffset(0,wide and 6 or 4)
    UI.pageTitle.Size=UDim2.fromOffset(wide and (pw>=570 and 116 or 80) or pw-32,wide and 54 or 36)
    local profileY=wide and 17 or 44
    local profileX=wide and (pw>=570 and 132 or 96) or 0
    UI.avatarPlate.Position=UDim2.fromOffset(profileX,profileY)
    UI.avatarPlate.Visible=pw>=160
    UI.userID.Position=UDim2.fromOffset(profileX+41,profileY)
    UI.userID.Size=UDim2.fromOffset(wide and pw-32-profileX-41-110 or math.max(84,pw-78),32)
    UI.sessionDot.Position=UDim2.fromOffset(wide and pw-136 or (pw>=310 and pw-136 or 4),wide and 30 or (pw>=310 and 57 or 89))
    UI.session.Position=UDim2.fromOffset(wide and pw-122 or (pw>=310 and pw-122 or 17),wide and 17 or (pw>=310 and 44 or 76))
    UI.session.Size=UDim2.fromOffset(94,32)
    if not wide and pw>=310 then UI.userID.Size=UDim2.fromOffset(pw-196,32) end
    if pw<160 then UI.userID.Position=UDim2.fromOffset(0,profileY);UI.userID.Size=UDim2.fromOffset(pw-32,32) end
    UI.panelDrag.Size=UDim2.new(1,0,0,headerH)
    UI.headerLine.Position=UDim2.fromOffset(16,headerH)
    UI.content.Position=UDim2.fromOffset(12,headerH+12)
    UI.content.Size=UDim2.new(1,-24,1,-headerH-48)
    local cw=pw-24
    local narrow=cw<360
    local heroHeight=narrow and 248 or math.min(200,math.max(136,h-8-headerH-54))
    UI.hero.Size=UDim2.new(1,-8,0,heroHeight)
    UI.heroTitleFallback.TextSize=narrow and 25 or 32
    UI.heroTitleFallback.Position=UDim2.fromOffset(narrow and 15 or 22,narrow and 10 or (heroHeight<180 and 14 or 32))
    UI.heroTitleFallback.Size=UDim2.fromOffset(narrow and cw-38 or math.min(236,cw*.51),48)
    UI.heroTitle.Position=UDim2.fromOffset(narrow and 10 or 18,narrow and 4 or 10)
    UI.heroTitle.Size=UDim2.fromOffset(narrow and cw-28 or math.min(268,cw*.52),narrow and 50 or math.min(100,heroHeight-86))
    UI.heroUnderline.Visible=not narrow
    UI.heroUnderline.Position=UDim2.fromOffset(24,heroHeight<180 and heroHeight-72 or 124)
    UI.emblemHost.Size=UDim2.fromOffset(narrow and math.min(cw-28,152) or math.min(cw*.45,220),narrow and 138 or heroHeight-6)
    UI.emblemHost.Position=narrow and UDim2.new(.5,-UI.emblemHost.Size.X.Offset/2,0,52) or UDim2.new(1,-UI.emblemHost.Size.X.Offset-5,0,3)
    UI.openMain.Position=UDim2.fromOffset(narrow and 15 or 22,narrow and 192 or heroHeight-60)
    UI.openMain.Size=UDim2.fromOffset(narrow and cw-38 or math.min(154,cw*.46),40)
    for i,name in ipairs({"Main","Visuals"}) do
        local item=UI.shortcuts[name]
        item.button.Position=narrow and UDim2.fromOffset(1,260+(i-1)*62) or UDim2.new((i-1)*.5,1,0,heroHeight+14)
        item.button.Size=narrow and UDim2.new(1,-8,0,54) or UDim2.new(.5,-9,0,58)
        item.arrow.Visible=cw>=220
        item.caption.Size=UDim2.new(1,cw>=220 and -80 or -58,1,0)
    end
    pages.Home.CanvasSize=UDim2.fromOffset(0,narrow and 384 or heroHeight+78)
    UI.gui:SetAttribute("NavigationStep",step)
    applyPane();applyPage()
    -- Resize adapts dimensions only. It never forces a dragged position on-screen.
    if initial then recenter() end
end
local function setPane(open)
    if state.target=="closed" then return end
    state.paneOpen=open;UI.gui:SetAttribute("PanelOpen",open)
    tween(UI.paneProgress,.32,{Value=open and 1 or 0})
    UI.selectionLight.Visible=open
end
local function selectPage(name,toggle)
    if state.target=="closed" then return end
    if toggle and name==state.page and state.paneOpen then setPane(false);return end
    local changed=state.page~=name
    state.page=name;UI.gui:SetAttribute("Page",name)
    for other,page in pairs(pages) do page.Visible=other==name end
    local page=pages[name];page.CanvasPosition=Vector2.zero
    pcall(function() page:ResetScrollVelocity() end)
    UI.pageTitle.Text=name
    UI.pageTitle.Font=name=="Home" and Enum.Font.GothamBold or optionFont
    for other,n in pairs(navigation) do
        local selected=other==name
        n.fx.selected=selected
        n.fx.wash.Color=selected and ColorSequence.new({ColorSequenceKeypoint.new(0,activeColors[1]),ColorSequenceKeypoint.new(.35,activeColors[2]),ColorSequenceKeypoint.new(.7,activeColors[3]),ColorSequenceKeypoint.new(1,activeColors[4])}) or ColorSequence.new({ColorSequenceKeypoint.new(0,metallicColors[1]),ColorSequenceKeypoint.new(.35,metallicColors[2]),ColorSequenceKeypoint.new(.7,metallicColors[3]),ColorSequenceKeypoint.new(1,metallicColors[4])})
        n.caption.TextColor3=selected and C.white or C.muted
        tintIcon(n.icon,selected and C.light or C.silver)
        alpha(n.fx.edge,"Transparency",selected and .12 or .55)
    end
    tween(UI.selectionLight,.22,{Position=UDim2.fromOffset(0,(navigation[name].index-1)*layout.navStep+(layout.navStep-23)/2)})
    if changed then UI.pageFade.Value=0;tween(UI.pageFade,.24,{Value=1}) end
    setPane(true)
end
for name,n in pairs(navigation) do connect(n.button.Activated,function() selectPage(name,true) end) end
connect(UI.openMain.Activated,function() selectPage("Main",false) end)
for name,item in pairs(UI.shortcuts) do connect(item.button.Activated,function() selectPage(name,false) end) end
connect(UI.Collapse.Activated,function() setPane(not state.paneOpen) end)

-- Only the requested view extends to the right; folding leaves the dock alone.
connect(UI.paneProgress.Changed,applyPane)
connect(UI.pageFade.Changed,applyPage)
connect(UI.windowFade.Changed,refreshAlpha)
connect(UI.launcherFade.Changed,function()
    UI.launcherScale.Scale=.94+.06*UI.launcherFade.Value;refreshAlpha()
end)
connect(UI.zoom.Changed,function() UI.scale.Scale=UI.zoom.Value end)
connect(UI.screen:GetPropertyChangedSignal("AbsoluteSize"),function() resize(false) end)
local function offscreen(object)
    local p,s=object.AbsolutePosition,object.AbsoluteSize;local v=UI.screen.AbsoluteSize
    return p.X+s.X<8 or p.Y+s.Y<8 or p.X>v.X-8 or p.Y>v.Y-8
end
local function transition(target)
    if not state.alive or state.target=="closed" then return end
    state.drag=nil
    state.target=target;state.burst=1;state.finishAt=os.clock()+.34
    UI.gui:SetAttribute("Minimized",target=="minimized")
    UI.gui:SetAttribute("Transition",target=="closed" and "closing" or target=="minimized" and "minimizing" or "opening")
    UI.recovery.Visible=false
    if target=="open" then
        UI.window.Visible=true
        tween(UI.windowFade,.28,{Value=1});tween(UI.zoom,.32,{Value=1})
        tween(UI.launcherFade,.2,{Value=0})
    else
        if target=="minimized" then UI.launcher.Visible=true end
        tween(UI.windowFade,.25,{Value=0});tween(UI.zoom,.3,{Value=.985})
        tween(UI.launcherFade,target=="minimized" and .3 or .22,{Value=target=="minimized" and 1 or 0})
    end
end
connect(UI.Minimize.Activated,function() transition("minimized") end)
connect(UI.Close.Activated,function() transition("closed") end)
connect(UI.launcher.Activated,function()
    if state.suppressLauncherUntil and os.clock()<state.suppressLauncherUntil then return end
    if offscreen(UI.window) then recenter() end
    transition("open")
end)
connect(UI.recovery.Activated,function() recenter();transition("open") end)

-- Drag uses screen-pixel deltas, with no viewport clamp or fullscreen constraint.
-- Only the initiating pointer can move/end a drag; scrolling content never does.
local function beginDrag(target,input)
    if state.target=="closed" or state.drag then return end
    local kind=input.UserInputType
    if kind~=Enum.UserInputType.MouseButton1 and kind~=Enum.UserInputType.Touch then return end
    if target==UI.launcher then state.suppressLauncherUntil=nil end
    state.drag={target=target,input=input,touch=kind==Enum.UserInputType.Touch,start=input.Position,position=target.Position,moved=false}
end
connect(UI.dragArea.InputBegan,function(input) beginDrag(UI.window,input) end)
connect(UI.panelDrag.InputBegan,function(input) beginDrag(UI.window,input) end)
connect(UI.launcher.InputBegan,function(input) beginDrag(UI.launcher,input) end)
connect(Input.InputChanged,function(input)
    local drag=state.drag
    if not drag then return end
    if drag.touch and input~=drag.input then return end
    if not drag.touch and input.UserInputType~=Enum.UserInputType.MouseMovement then return end
    local delta=input.Position-drag.start
    if not drag.moved and delta.Magnitude<5 then return end
    drag.moved=true
    drag.target.Position=UDim2.new(drag.position.X.Scale,drag.position.X.Offset+delta.X,drag.position.Y.Scale,drag.position.Y.Offset+delta.Y)
    if drag.target==UI.launcher then state.launcherMoved=true end
end)
local function endDrag(input,force)
    local drag=state.drag
    if not drag then return end
    if not force and ((drag.touch and input~=drag.input) or (not drag.touch and input.UserInputType~=Enum.UserInputType.MouseButton1)) then return end
    if drag.target==UI.launcher and drag.moved then state.suppressLauncherUntil=os.clock()+.4 end
    state.drag=nil
end
connect(Input.InputEnded,function(input) endDrag(input,false) end)
connect(Input.WindowFocusReleased,function() endDrag(nil,true) end)
connect(Input.InputBegan,function(input,processed)
    if processed or Input:GetFocusedTextBox() then return end
    if input.KeyCode==Enum.KeyCode.RightShift then
        if offscreen(state.target=="minimized" and UI.launcher or UI.window) then recenter();transition("open")
        else transition(state.target=="open" and "minimized" or "open") end
    end
end)

-- Original transparent artwork, copied byte-for-byte from the supplied images.
-- Custom PNGs need the executor's local asset API; failure never blocks the GUI.
local ASSETS={
    R={url="https://raw.githubusercontent.com/hzReyzn/Ghislain/main/assets/reyzn-x/launcher-r-v1.png",file="ReyznX-launcher-r-v1.png",bytes=2136070,images={UI.launcherImage,UI.recoveryImage}},
    X={url="https://raw.githubusercontent.com/hzReyzn/Ghislain/main/assets/reyzn-x/emblem-x-v1.png",file="ReyznX-emblem-x-v1.png",bytes=1699126,images={UI.xImage,UI.xGlow}},
    Wordmark={url="https://raw.githubusercontent.com/hzReyzn/Ghislain/main/assets/reyzn-x/wordmark-v1.png",file="ReyznX-wordmark-v1.png",bytes=1399207,images={UI.brand,UI.heroTitle},rect={Vector2.new(0,170),Vector2.new(1672,656)}},
    Minimize={url="https://raw.githubusercontent.com/hzReyzn/Ghislain/main/assets/reyzn-x/minimize-v1.png",file="ReyznX-minimize-v1.png",bytes=1283532,images={controlArtwork.Minimize.image,controlArtwork.Minimize.glow},rect={Vector2.new(260,101),Vector2.new(1253,680)}},
    Collapse={url="https://raw.githubusercontent.com/hzReyzn/Ghislain/main/assets/reyzn-x/collapse-v1.png",file="ReyznX-collapse-v1.png",bytes=1337784,images={controlArtwork.Collapse.image,controlArtwork.Collapse.glow},rect={Vector2.new(254,103),Vector2.new(1268,683)}},
    Close={url="https://raw.githubusercontent.com/hzReyzn/Ghislain/main/assets/reyzn-x/close-v1.png",file="ReyznX-close-v1.png",bytes=1570916,images={controlArtwork.Close.image,controlArtwork.Close.glow},rect={Vector2.new(187,84),Vector2.new(1401,713)}},
}
local function validPng(body,asset)
    return type(body)=="string" and #body==asset.bytes and body:sub(1,8)=="\137PNG\13\10\26\10" and body:sub(13,16)=="IHDR" and body:sub(-8,-5)=="IEND"
end
local function loadAsset(key,asset)
    local customAsset=getcustomasset or getsynasset
    if type(customAsset)~="function" or type(writefile)~="function" then
        UI.gui:SetAttribute("Asset"..key,"unavailable")
        warn("Reyzn X: custom PNG artwork requires getcustomasset/getsynasset and writefile.")
        return
    end
    local cached=false
    if type(isfile)=="function" and type(readfile)=="function" then
        local ok,body=pcall(function() if isfile(asset.file) then return readfile(asset.file) end end)
        cached=ok and validPng(body,asset)
    end
    local uri
    if cached then local ok,value=pcall(customAsset,asset.file);if ok and type(value)=="string" and value~="" then uri=value end end
    if not uri then
        for attempt=1,2 do
            if not state.alive then return end
            local ok,body=pcall(function() return game:HttpGet(asset.url) end)
            if not state.alive then return end
            if ok and validPng(body,asset) then
                local wrote=pcall(writefile,asset.file,body)
                if wrote then
                    local registered,value=pcall(customAsset,asset.file)
                    if registered and type(value)=="string" and value~="" then uri=value;break end
                end
            end
            if attempt==1 then task.wait(.6) end
        end
    end
    if not state.alive then return end
    if not uri then UI.gui:SetAttribute("Asset"..key,"failed");warn("Reyzn X: could not load the "..key.." PNG.");return end
    for _,o in ipairs(asset.images) do
        -- Use only the visible artwork region; original PNG bytes are unchanged.
        if asset.rect then o.ImageRectOffset=asset.rect[1];o.ImageRectSize=asset.rect[2] end
        o.Image=uri
    end
    UI.gui:SetAttribute("Asset"..key,"assigned")
    -- Preloading runs separately from input, animation and the session clock.
    pcall(function() ContentProvider:PreloadAsync(asset.images) end)
end
for key,asset in pairs(ASSETS) do spawn(function() loadAsset(key,asset) end) end
spawn(function()
    local ok,uri=pcall(function() return Players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150) end)
    if state.alive and ok and type(uri)=="string" and uri~="" then UI.avatar.Image=uri end
end)
local function updateClock()
    local seconds=math.max(0,math.floor(os.clock()-startedAt))
    if seconds~=state.lastSecond then
        state.lastSecond=seconds;UI.gui:SetAttribute("ElapsedSeconds",seconds)
        UI.session.Text=string.format("%02d:%02d:%02d",math.floor(seconds/3600),math.floor(seconds/60)%60,seconds%60)
    end
end
resize(true)
selectPage("Home",false)
UI.gui:SetAttribute("PanelOpen",true)
UI.gui:SetAttribute("Minimized",false)
updateClock();refreshAlpha();transition("open")
connect(RunService.Heartbeat,function(dt)
    updateClock()
    if state.finishAt>0 and os.clock()>=state.finishAt then
        state.finishAt=0
        if state.target=="closed" then UI.gui:Destroy();return end
        UI.window.Visible=state.target=="open"
        UI.launcher.Visible=state.target=="minimized"
        UI.gui:SetAttribute("Transition",state.target)
    end
    state.budget+=dt
    if state.budget<1/30 then return end
    local elapsed=state.budget;state.budget=0;state.phase+=elapsed
    state.burst=math.max(0,state.burst-elapsed*3)
    local p=state.phase
    local pulse=.5+.5*math.sin(p*1.8)
    UI.recovery.Visible=state.target~="closed" and state.finishAt==0 and offscreen(state.target=="minimized" and UI.launcher or UI.window)
    UI.avatarFallback.Visible=UI.avatar.Image=="" or not UI.avatar.IsLoaded
    UI.rFallback.Visible=UI.launcherImage.Image=="" or not UI.launcherImage.IsLoaded
    UI.recoveryFallback.Visible=UI.recoveryImage.Image=="" or not UI.recoveryImage.IsLoaded
    UI.xFallback.Visible=UI.xImage.Image=="" or not UI.xImage.IsLoaded
    UI.brandFallback.Visible=UI.brand.Image=="" or not UI.brand.IsLoaded
    UI.heroTitleFallback.Visible=UI.heroTitle.Image=="" or not UI.heroTitle.IsLoaded
    if not UI.brandFallback.Visible and not UI.heroTitleFallback.Visible then UI.gui:SetAttribute("AssetWordmark","ready") end
    for name,control in pairs(controlArtwork) do
        control.fallback.Visible=control.image.Image=="" or not control.image.IsLoaded
        if not control.fallback.Visible then UI.gui:SetAttribute("Asset"..name,"ready") end
    end
    if not UI.xFallback.Visible then UI.gui:SetAttribute("AssetX","ready") end
    if not UI.rFallback.Visible then UI.gui:SetAttribute("AssetR","ready") end
    alpha(UI.launcherRim,"Transparency",.5+pulse*.18-.2*state.burst)
    if UI.launcher.Visible then animateAura(UI.launcherAura,p,state.burst) end
    if state.target=="minimized" and state.finishAt==0 then return end
    animateAura(UI.dockAura,p,state.burst)
    if UI.panelAura.host.Visible then animateAura(UI.panelAura,p+.23,state.burst) end
    for _,fx in ipairs({UI.dockFx,UI.panelFx}) do
        alpha(fx.glow,"Transparency",.9-.07*pulse-.24*state.burst)
        alpha(fx.beam,"BackgroundTransparency",.32-.16*pulse-.15*state.burst)
        fx.beamGradient.Offset=Vector2.new(math.sin(p*.38)*.42,0)
        fx.metal.Offset=Vector2.new(math.sin(p*.25)*.12,0)
    end
    if state.page=="Home" and state.paneOpen then
        alpha(UI.xGlow,"ImageTransparency",.91-.06*pulse)
        UI.heroGlint.Position=UDim2.new(.5+.32*math.sin(p*.38),-40,0,0)
    end
    for _,b in ipairs(buttons) do
        if b.hover or b.selected then b.light.Offset=Vector2.new(math.sin(p*.7)*.6,0) end
    end
end)
return UI.gui
