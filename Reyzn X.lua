-- Reyzn X | Made By Reyzn
-- Client interface only. No gameplay changes or remote script loaders.
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
if not player then return end
local startedAt = os.clock()
local playerGui = player:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("ReyznX")
if old then old:Destroy() end

local VERSION = "1.0.0"
local state = {alive=true, closing=false, minimized=false, maximized=false, busy=false,
    page="Home", theme="Amethyst", motion=true, glow=true, uiScale=1,
    lastSecond=-1, phase=0, budget=0}
local connections, threads, tweens = {}, {}, {}
local palette = {
    Amethyst={accent=Color3.fromRGB(174,73,255), light=Color3.fromRGB(228,172,255), deep=Color3.fromRGB(92,22,178)},
    Moonstone={accent=Color3.fromRGB(77,184,255), light=Color3.fromRGB(178,229,255), deep=Color3.fromRGB(28,76,171)},
    Ember={accent=Color3.fromRGB(255,123,65), light=Color3.fromRGB(255,206,156), deep=Color3.fromRGB(153,45,48)},
}
local C = {base=Color3.fromRGB(10,9,17), panel=Color3.fromRGB(15,13,24), raised=Color3.fromRGB(22,18,34),
    white=Color3.fromRGB(247,243,255), muted=Color3.fromRGB(166,158,186), dim=Color3.fromRGB(105,96,125),
    line=Color3.fromRGB(52,43,70), green=Color3.fromRGB(116,232,160)}
local function connect(signal, callback)
    local c=signal:Connect(function(...) if state.alive then callback(...) end end)
    connections[#connections+1]=c
    return c
end
local function spawn(callback)
    local thread=task.spawn(callback)
    threads[#threads+1]=thread
end
local function make(class,parent,props)
    local o=Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    if o:IsA("GuiObject") then o.BorderSizePixel=0; o.AutoLocalize=false end
    o.Parent=parent
    return o
end
local function tween(object,duration,props)
    if not state.alive then return end
    if tweens[object] then tweens[object]:Cancel() end
    if not state.motion then for k,v in pairs(props) do object[k]=v end; return end
    local t=TweenService:Create(object,TweenInfo.new(duration,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),props)
    tweens[object]=t; t:Play()
end
local function corner(parent,radius)
    return make("UICorner",parent,{CornerRadius=UDim.new(0,radius or 12)})
end
local function stroke(parent,tint,alpha,thickness)
    return make("UIStroke",parent,{Color=tint or C.line,Transparency=alpha or 0,Thickness=thickness or 1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
end
local function gradient(parent,a,b,rotation)
    return make("UIGradient",parent,{Color=ColorSequence.new(a,b),Rotation=rotation or 90})
end
local function frame(parent,name,pos,size,tint,alpha)
    return make("Frame",parent,{Name=name,Position=pos,Size=size,BackgroundColor3=tint or C.panel,BackgroundTransparency=alpha or 0})
end
local function label(parent,name,text,pos,size,pixels,tint,font)
    return make("TextLabel",parent,{Name=name,Text=text,Position=pos,Size=size,BackgroundTransparency=1,
        TextColor3=tint or C.white,TextSize=pixels or 14,Font=font or Enum.Font.GothamMedium,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd})
end
local function button(parent,name,pos,size)
    local o=make("TextButton",parent,{Name=name,Text="",Position=pos,Size=size,BackgroundColor3=C.raised,AutoButtonColor=false,Selectable=true})
    corner(o,12); return o
end

-- All icons and abstract artwork use native UI objects. No asset download.
local paths={
    crown={{{3,7},{6,17},{18,17},{21,7},{16,11},{12,3},{8,11},{3,7}},{{6,21},{18,21}}},
    home={{{3,11},{12,3},{21,11}},{{6,9},{6,21},{10,21},{10,15},{14,15},{14,21},{18,21},{18,9}}},
    cube={{{12,2},{22,7},{22,18},{12,23},{2,18},{2,7},{12,2}},{{2,7},{12,12},{22,7}},{{12,12},{12,23}}},
    spark={{{12,2},{15,9},{22,12},{15,15},{12,22},{9,15},{2,12},{9,9},{12,2}}},
    code={{{8,6},{2,12},{8,18}},{{16,6},{22,12},{16,18}},{{14,3},{10,21}}},
    settings={{{4,6},{20,6}},{{4,12},{20,12}},{{4,18},{20,18}},{{9,3},{9,9}},{{16,9},{16,15}},{{8,15},{8,21}}},
    pulse={{{2,13},{6,13},{9,5},{12,21},{15,9},{18,13},{22,13}}},
    arrow={{{4,12},{20,12}},{{14,6},{20,12},{14,18}}},
    close={{{6,6},{18,18}},{{18,6},{6,18}}}, minimize={{{5,12},{19,12}}},
    maximize={{{5,5},{19,5},{19,19},{5,19},{5,5}}},
    clock={{{12,3},{18,5},{21,12},{18,19},{12,21},{6,19},{3,12},{6,5},{12,3}},{{12,7},{12,12},{16,14}}},
}
local function line(parent,a,b,tint,width,alpha)
    local dx,dy=b[1]-a[1],b[2]-a[2]
    local o=frame(parent,"Line",UDim2.fromOffset((a[1]+b[1])/2,(a[2]+b[2])/2),UDim2.fromOffset(math.sqrt(dx*dx+dy*dy),width or 1.7),tint,alpha or 0)
    o.AnchorPoint=Vector2.new(.5,.5); o.Rotation=math.deg(math.atan2(dy,dx)); corner(o,2)
    return o
end
local function icon(parent,kind,pos,size,tint)
    local host=frame(parent,"Icon_"..kind,pos,UDim2.fromOffset(size,size),nil,1)
    local f=size/24
    for _,path in ipairs(paths[kind] or paths.spark) do
        for i=1,#path-1 do
            line(host,{path[i][1]*f,path[i][2]*f},{path[i+1][1]*f,path[i+1][2]*f},tint or C.muted,math.max(1.5,f*1.7))
        end
    end
    return host
end
local function tintIcon(host,tint)
    for _,o in ipairs(host:GetChildren()) do if o:IsA("Frame") then o.BackgroundColor3=tint end end
end
local themeBindings={}
local function bind(object,property,key)
    themeBindings[#themeBindings+1]={object,property,key}
    object[property]=palette[state.theme][key]
    return object
end
local UI={}
UI.gui=make("ScreenGui",playerGui,{Name="ReyznX",ResetOnSpawn=false,DisplayOrder=50,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,IgnoreGuiInset=false})
pcall(function() UI.gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets end)
UI.gui:SetAttribute("Version",VERSION)
local function cleanup()
    if not state.alive then return end
    state.alive=false
    for _,c in ipairs(connections) do c:Disconnect() end
    for _,t in pairs(tweens) do t:Cancel() end
    for _,thread in ipairs(threads) do if coroutine.status(thread)~="dead" then pcall(task.cancel,thread) end end
    table.clear(connections); table.clear(threads); table.clear(tweens)
    state.drag=nil
end
connections[#connections+1]=UI.gui.Destroying:Connect(cleanup)
UI.screen=frame(UI.gui,"SafeArea",UDim2.fromScale(0,0),UDim2.fromScale(1,1),nil,1)
UI.window=frame(UI.screen,"Window",UDim2.fromScale(.5,.5),UDim2.fromOffset(1080,690),C.base)
UI.window.AnchorPoint=Vector2.new(.5,.5); UI.window.Active=true; corner(UI.window,20)
UI.scale=make("UIScale",UI.window,{Scale=1})
UI.windowRim=bind(stroke(UI.window,nil,.28,1.2),"Color","accent")
UI.rimGradient=gradient(UI.windowRim,C.white,Color3.fromRGB(60,37,87),25)
UI.outerGlow=frame(UI.window,"OuterGlow",UDim2.fromOffset(-4,-4),UDim2.new(1,8,1,8),nil,1)
corner(UI.outerGlow,24); UI.glowStroke=bind(stroke(UI.outerGlow,nil,.88,5),"Color","accent")
UI.innerGlow=frame(UI.window,"InnerGlow",UDim2.fromOffset(2,2),UDim2.new(1,-4,1,-4),nil,1)
corner(UI.innerGlow,18); bind(stroke(UI.innerGlow,nil,.89,2),"Color","accent")

UI.header=frame(UI.window,"Header",UDim2.fromOffset(14,14),UDim2.new(1,-28,0,116),C.panel)
UI.header.BackgroundColor3=Color3.new(1,1,1)
corner(UI.header,14); bind(stroke(UI.header,nil,.53),"Color","accent")
UI.headerGradient=gradient(UI.header,Color3.fromRGB(28,16,46),C.base,8)
UI.headerArt=frame(UI.header,"HeaderEnergy",UDim2.fromScale(.54,0),UDim2.fromScale(.46,1),nil,1)
UI.headerArt.ClipsDescendants=true
local energy={}
for _,path in ipairs({
    {{0,104},{45,90},{59,101},{98,64},{122,70},{150,27},{174,40},{198,8},{250,0}},
    {{160,116},{183,91},{217,98},{252,61},{270,74},{304,38},{340,49},{380,15},{460,6}},
}) do
    for i=1,#path-1 do
        bind(line(UI.headerArt,path[i],path[i+1],nil,9,.94),"BackgroundColor3","accent")
        energy[#energy+1]=bind(line(UI.headerArt,path[i],path[i+1],nil,1.2,.35),"BackgroundColor3","accent")
    end
end
UI.crown=icon(UI.header,"crown",UDim2.fromOffset(22,19),42,palette.Amethyst.accent)
UI.title=label(UI.header,"Brand","Reyzn X",UDim2.fromOffset(80,11),UDim2.fromOffset(300,49),38,C.white,Enum.Font.GothamBold)
UI.title.RichText=true
UI.avatarPlate=frame(UI.header,"AvatarPlate",UDim2.fromOffset(82,70),UDim2.fromOffset(32,32),C.raised)
corner(UI.avatarPlate,100); bind(stroke(UI.avatarPlate,nil,.15),"Color","accent")
UI.avatarFallback=label(UI.avatarPlate,"AvatarFallback",string.upper(string.sub(player.Name,1,1)),UDim2.fromScale(0,0),UDim2.fromScale(1,1),14)
UI.avatarFallback.TextXAlignment=Enum.TextXAlignment.Center
UI.avatar=make("ImageLabel",UI.avatarPlate,{Name="Avatar",Image="",BackgroundTransparency=1,Position=UDim2.fromOffset(2,2),Size=UDim2.new(1,-4,1,-4),ScaleType=Enum.ScaleType.Crop})
corner(UI.avatar,100)
UI.userID=label(UI.header,"UserID","ID  "..tostring(player.UserId),UDim2.fromOffset(124,72),UDim2.fromOffset(196,28),13,C.muted)
UI.profileDivider=frame(UI.header,"ProfileDivider",UDim2.fromOffset(330,78),UDim2.fromOffset(1,16),C.line)
UI.clockIcon=icon(UI.header,"clock",UDim2.fromOffset(344,77),18,C.muted)
UI.session=label(UI.header,"SessionTime","00:00:00",UDim2.fromOffset(370,72),UDim2.fromOffset(104,28),14,C.muted,Enum.Font.RobotoMono)
UI.headerTag=label(UI.header,"Edition","AMETHYST EDITION",UDim2.new(1,-270,1,-40),UDim2.fromOffset(246,20),10,C.muted)
UI.headerTag.TextXAlignment=Enum.TextXAlignment.Right
UI.dragArea=frame(UI.header,"DragArea",UDim2.fromScale(0,0),UDim2.new(1,-146,1,0),nil,1)
UI.dragArea.Active=true; UI.dragArea.ZIndex=4
UI.controls=frame(UI.header,"WindowControls",UDim2.new(1,-142,0,14),UDim2.fromOffset(130,38),nil,1)
UI.controls.ZIndex=5
for i,data in ipairs({{"Minimize","minimize"},{"Maximize","maximize"},{"Close","close"}}) do
    local b=button(UI.controls,data[1],UDim2.fromOffset((i-1)*44,0),UDim2.fromOffset(38,38))
    corner(b,10); stroke(b,C.line,.2); icon(b,data[2],UDim2.fromOffset(8,8),22,C.muted)
    connect(b.MouseEnter,function() tween(b,.16,{BackgroundColor3=data[1]=="Close" and Color3.fromRGB(79,29,57) or palette[state.theme].deep}) end)
    connect(b.MouseLeave,function() tween(b,.2,{BackgroundColor3=C.raised}) end)
    UI[data[1]]=b
end

-- Only Home, Main, Visuals, Scripts and Settings remain in the navigation.
UI.sidebar=frame(UI.window,"Sidebar",UDim2.fromOffset(14,144),UDim2.fromOffset(184,490),C.panel)
corner(UI.sidebar,14); stroke(UI.sidebar,C.line,.2)
UI.navCaption=label(UI.sidebar,"NavigationCaption","WORKSPACE",UDim2.fromOffset(18,18),UDim2.new(1,-36,0,20),10,C.dim)
UI.navScroll=make("ScrollingFrame",UI.sidebar,{Name="Navigation",Position=UDim2.fromOffset(8,52),Size=UDim2.new(1,-16,1,-60),BackgroundTransparency=1,
    CanvasSize=UDim2.fromOffset(0,310),ScrollBarThickness=0,ScrollingDirection=Enum.ScrollingDirection.Y,AutomaticCanvasSize=Enum.AutomaticSize.None})
local navigation={}
for i,data in ipairs({{"Home","home"},{"Main","cube"},{"Visuals","spark"},{"Scripts","code"},{"Settings","settings"}}) do
    local b=button(UI.navScroll,"Tab_"..data[1],UDim2.fromOffset(0,(i-1)*62),UDim2.new(1,0,0,54))
    b.BackgroundTransparency=1
    local edge=stroke(b,palette.Amethyst.accent,1)
    local wash=gradient(b,palette.Amethyst.accent,palette.Amethyst.deep,24)
    local glyph=icon(b,data[2],UDim2.fromOffset(16,16),22)
    local caption=label(b,"Caption",data[1],UDim2.fromOffset(50,0),UDim2.new(1,-60,1,0),15,C.muted)
    local marker=frame(b,"ActiveMarker",UDim2.fromOffset(0,17),UDim2.fromOffset(3,20),C.white)
    corner(marker,3); marker.Visible=false
    navigation[data[1]]={button=b,edge=edge,wash=wash,icon=glyph,caption=caption,marker=marker}
end
UI.content=frame(UI.window,"Content",UDim2.fromOffset(214,144),UDim2.new(1,-228,1,-200),nil,1)
UI.footer=frame(UI.window,"Footer",UDim2.new(0,22,1,-42),UDim2.new(1,-44,0,28),nil,1)
frame(UI.footer,"Divider",UDim2.fromOffset(0,-8),UDim2.new(1,0,0,1),C.line,.45)
UI.footerCrown=icon(UI.footer,"crown",UDim2.fromOffset(0,4),19,palette.Amethyst.accent)
label(UI.footer,"Brand","Reyzn X",UDim2.fromOffset(30,0),UDim2.fromOffset(140,28),12,C.white,Enum.Font.GothamBold)
UI.credit=label(UI.footer,"Credit","Made By Reyzn",UDim2.new(1,-160,0,0),UDim2.fromOffset(160,28),12,C.muted)
UI.credit.TextXAlignment=Enum.TextXAlignment.Right

local pages={}
local function page(name)
    local p=make("ScrollingFrame",UI.content,{Name="Page_"..name,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
        CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=3,ScrollBarImageColor3=palette.Amethyst.accent,
        ScrollingDirection=Enum.ScrollingDirection.Y,Visible=name=="Home",AutomaticCanvasSize=Enum.AutomaticSize.None})
    pages[name]=p; return p
end
local function card(parent,name,pos,size)
    local o=frame(parent,name,pos,size,C.panel); corner(o,14); stroke(o,C.line,.1); return o
end
local function action(parent,name,text,pos,size)
    local b=button(parent,name,pos,size); b.BackgroundColor3=Color3.new(1,1,1)
    local wash=gradient(b,palette.Amethyst.accent,palette.Amethyst.deep,85)
    local edge=bind(stroke(b,nil,.25),"Color","light")
    label(b,"Caption",text,UDim2.fromOffset(16,0),UDim2.new(1,-52,1,0),13,C.white,Enum.Font.GothamBold)
    icon(b,"arrow",UDim2.new(1,-34,.5,-10),20,C.white)
    connect(b.MouseEnter,function() tween(edge,.15,{Transparency=0}) end)
    connect(b.MouseLeave,function() tween(edge,.2,{Transparency=.25}) end)
    return {button=b,wash=wash}
end
local home=page("Home")
UI.hero=card(home,"Welcome",UDim2.fromOffset(0,0),UDim2.fromOffset(582,300)); UI.hero.ClipsDescendants=true
UI.hero.BackgroundColor3=Color3.new(1,1,1)
UI.heroGradient=gradient(UI.hero,Color3.fromRGB(23,16,38),C.panel,20)
bind(label(UI.hero,"Eyebrow","A NEW BEGINNING",UDim2.fromOffset(26,25),UDim2.fromOffset(270,20),10),"TextColor3","light")
label(UI.hero,"WelcomeText","Welcome to",UDim2.fromOffset(26,62),UDim2.fromOffset(270,28),19,C.white)
UI.heroTitle=label(UI.hero,"Title","Reyzn X",UDim2.fromOffset(24,96),UDim2.fromOffset(320,56),43,C.white,Enum.Font.GothamBold)
UI.heroTitle.RichText=true
UI.heroSubtitle=label(UI.hero,"Subtitle","Your personal workspace.",UDim2.fromOffset(26,165),UDim2.fromOffset(290,28),14,C.muted)
UI.openMain=action(UI.hero,"OpenMain","Open Main",UDim2.fromOffset(26,224),UDim2.fromOffset(156,44))
UI.heroArt=frame(UI.hero,"AmethystPrism",UDim2.new(1,-248,.5,-125),UDim2.fromOffset(250,250),nil,1)
local facets,specks={},{}
for i,size in ipairs({174,144,112}) do
    local prism=frame(UI.heroArt,"Prism"..i,UDim2.fromOffset(130,125),UDim2.fromOffset(size,size),nil,1)
    prism.AnchorPoint=Vector2.new(.5,.5); prism.Rotation=45; corner(prism,14)
    local rim=bind(stroke(prism,nil,.82-i*.14),"Color","accent")
    gradient(rim,C.white,Color3.fromRGB(38,24,54),70)
end
for _,angle in ipairs({-34,34}) do
    local halo=bind(frame(UI.heroArt,"XGlow",UDim2.fromOffset(130,125),UDim2.fromOffset(33,137),nil,.92),"BackgroundColor3","accent")
    halo.AnchorPoint=Vector2.new(.5,.5); halo.Rotation=angle; corner(halo,12); bind(stroke(halo,nil,.94,12),"Color","accent")
    local bar=frame(UI.heroArt,"XFacet",UDim2.fromOffset(130,125),UDim2.fromOffset(16,126),C.white)
    bar.AnchorPoint=Vector2.new(.5,.5); bar.Rotation=angle; corner(bar,4)
    facets[#facets+1]=gradient(bar,palette.Amethyst.light,palette.Amethyst.deep,0)
    bind(stroke(bar,nil,.1),"Color","accent")
end
for i=1,12 do
    local x,y=25+(i*61%205),20+(i*37%211)
    local size=i%3==0 and 3 or 2
    local dot=bind(frame(UI.heroArt,"Mote"..i,UDim2.fromOffset(x,y),UDim2.fromOffset(size,size),nil,.35),"BackgroundColor3","light")
    dot.Rotation=45; specks[#specks+1]={object=dot,x=x,y=y,phase=i*.8}
end
UI.heroArt.ZIndex=1
for _,child in ipairs(UI.hero:GetChildren()) do if child:IsA("GuiObject") and child~=UI.heroArt then child.ZIndex=2 end end

UI.status=card(home,"ScriptStatus",UDim2.fromOffset(598,0),UDim2.fromOffset(234,216))
UI.statusIcon=icon(UI.status,"pulse",UDim2.fromOffset(18,22),22,palette.Amethyst.accent)
label(UI.status,"Heading","Script Status",UDim2.fromOffset(50,18),UDim2.new(1,-60,0,30),15,C.white,Enum.Font.GothamBold)
local dot=frame(UI.status,"ActiveDot",UDim2.fromOffset(20,66),UDim2.fromOffset(6,6),C.green); corner(dot,5)
label(UI.status,"State","Active",UDim2.fromOffset(34,56),UDim2.fromOffset(130,24),12,C.green)
frame(UI.status,"Divider",UDim2.fromOffset(18,94),UDim2.new(1,-36,0,1),C.line,.3)
local function statusRow(name,text,value,y)
    label(UI.status,name.."Label",text,UDim2.fromOffset(18,y),UDim2.fromOffset(80,24),12,C.muted)
    local result=label(UI.status,name,value,UDim2.new(1,-133,0,y),UDim2.fromOffset(115,24),12,C.white)
    result.TextXAlignment=Enum.TextXAlignment.Right; return result
end
statusRow("Version","Version","v"..VERSION,110)
UI.themeStatus=statusRow("Theme","Theme","Amethyst",143)
statusRow("Build","Build","Interface",176)
UI.note=card(home,"SessionNote",UDim2.fromOffset(598,232),UDim2.fromOffset(234,184))
UI.noteIcon=icon(UI.note,"spark",UDim2.fromOffset(18,20),24,palette.Amethyst.accent)
label(UI.note,"Title","Make it yours.",UDim2.fromOffset(18,60),UDim2.new(1,-36,0,28),16,C.white,Enum.Font.GothamBold)
local copy=label(UI.note,"Copy","Choose your accent.\nFind your atmosphere.",UDim2.fromOffset(18,96),UDim2.new(1,-36,0,48),12,C.muted)
copy.TextWrapped=true; copy.TextTruncate=Enum.TextTruncate.None
UI.workspaceCaption=label(home,"WorkspaceCaption","YOUR WORKSPACE",UDim2.fromOffset(2,326),UDim2.fromOffset(400,20),10,C.dim)
local shortcuts={}
for i,data in ipairs({{"Main","cube","Start with a clean space."},{"Visuals","spark","Shape the way it feels."}}) do
    local b=button(home,"Shortcut_"..data[1],UDim2.fromOffset((i-1)*298,360),UDim2.fromOffset(284,112)); b.BackgroundColor3=C.panel
    local edge=stroke(b,C.line,.1)
    local glyph=icon(b,data[2],UDim2.fromOffset(18,20),24,palette.Amethyst.accent)
    label(b,"Title",data[1],UDim2.fromOffset(56,18),UDim2.new(1,-100,0,28),16,C.white,Enum.Font.GothamBold)
    label(b,"Copy",data[3],UDim2.fromOffset(18,66),UDim2.new(1,-36,0,25),12,C.muted)
    icon(b,"arrow",UDim2.new(1,-38,0,24),18,C.muted)
    connect(b.MouseEnter,function() tween(edge,.2,{Color=palette[state.theme].accent}) end)
    connect(b.MouseLeave,function() tween(edge,.2,{Color=C.line}) end)
    shortcuts[#shortcuts+1]={button=b,icon=glyph,page=data[1]}
end
local emptyCards={}
for _,data in ipairs({{"Main","cube","A fresh start.","Your main workspace is ready."},{"Scripts","code","A clean slate.","No scripts have been added yet."}}) do
    local host=page(data[1])
    label(host,"Heading",data[1],UDim2.fromOffset(2,0),UDim2.new(1,-10,0,42),28,C.white,Enum.Font.GothamBold)
    local empty=card(host,"EmptyState",UDim2.fromOffset(0,62),UDim2.new(1,-6,0,340))
    local emblem=frame(empty,"Emblem",UDim2.new(.5,-32,0,66),UDim2.fromOffset(64,64),C.raised)
    corner(emblem,18); bind(stroke(emblem,nil,.65),"Color","accent")
    local glyph=icon(emblem,data[2],UDim2.fromOffset(18,18),28,palette.Amethyst.light)
    local title=label(empty,"Title",data[3],UDim2.new(0,20,0,164),UDim2.new(1,-40,0,32),22,C.white,Enum.Font.GothamBold)
    title.TextXAlignment=Enum.TextXAlignment.Center
    local desc=label(empty,"Copy",data[4],UDim2.new(0,20,0,208),UDim2.new(1,-40,0,46),13,C.muted)
    desc.TextXAlignment=Enum.TextXAlignment.Center; desc.TextWrapped=true
    emptyCards[#emptyCards+1]={card=empty,icon=glyph}; host.CanvasSize=UDim2.fromOffset(0,412)
end
local visuals=page("Visuals")
label(visuals,"Heading","Visuals",UDim2.fromOffset(2,0),UDim2.new(1,-10,0,42),28,C.white,Enum.Font.GothamBold)
label(visuals,"Subtitle","Set the atmosphere of your workspace.",UDim2.fromOffset(2,46),UDim2.new(1,-10,0,30),13,C.muted)
UI.themeCard=card(visuals,"AccentThemes",UDim2.fromOffset(0,96),UDim2.new(1,-6,0,180))
label(UI.themeCard,"Heading","Accent color",UDim2.fromOffset(20,16),UDim2.new(1,-40,0,28),16,C.white,Enum.Font.GothamBold)
local themeButtons={}
for i,name in ipairs({"Amethyst","Moonstone","Ember"}) do
    local b=button(UI.themeCard,"Theme_"..name,UDim2.new((i-1)/3,18,0,62),UDim2.new(1/3,-24,0,98))
    local edge=stroke(b,palette[name].accent,name=="Amethyst" and 0 or .75,1.5)
    local swatch=frame(b,"Swatch",UDim2.fromOffset(12,12),UDim2.new(1,-24,0,24),C.white)
    corner(swatch,6); gradient(swatch,palette[name].accent,palette[name].deep,0)
    local caption=label(b,"Caption",name,UDim2.fromOffset(8,48),UDim2.new(1,-16,0,30),12,C.white)
    caption.TextXAlignment=Enum.TextXAlignment.Center
    themeButtons[name]={button=b,edge=edge}
end
local toggles={}
local function toggle(parent,name,title,detail,y,key)
    local row=button(parent,name,UDim2.fromOffset(0,y),UDim2.new(1,-6,0,92)); row.BackgroundColor3=C.panel; stroke(row,C.line,.1)
    label(row,"Title",title,UDim2.fromOffset(20,14),UDim2.new(1,-110,0,28),15,C.white,Enum.Font.GothamBold)
    local desc=label(row,"Description",detail,UDim2.fromOffset(20,44),UDim2.new(1,-110,0,34),12,C.muted); desc.TextWrapped=true
    local track=frame(row,"Track",UDim2.new(1,-74,.5,-14),UDim2.fromOffset(50,28),palette.Amethyst.deep); corner(track,20)
    local edge=stroke(track,palette.Amethyst.accent,.3)
    local knob=frame(track,"Knob",UDim2.fromOffset(26,4),UDim2.fromOffset(20,20),C.white); corner(knob,20)
    toggles[key]={button=row,track=track,edge=edge,knob=knob}
end
toggle(visuals,"AmbientGlow","Ambient glow","A soft neon halo around the interface.",292,"glow")
toggle(visuals,"Motion","Animated effects","Gentle light, particles and transitions.",400,"motion")
visuals.CanvasSize=UDim2.fromOffset(0,504)
local settings=page("Settings")
label(settings,"Heading","Settings",UDim2.fromOffset(2,0),UDim2.new(1,-10,0,42),28,C.white,Enum.Font.GothamBold)
label(settings,"Subtitle","Make the interface feel right.",UDim2.fromOffset(2,46),UDim2.new(1,-10,0,30),13,C.muted)
UI.sizingCard=card(settings,"InterfaceSize",UDim2.fromOffset(0,96),UDim2.new(1,-6,0,156))
label(UI.sizingCard,"Heading","Interface size",UDim2.fromOffset(20,16),UDim2.new(1,-40,0,30),16,C.white,Enum.Font.GothamBold)
local sizeButtons={}
for i,data in ipairs({{"Compact",.88},{"Default",1},{"Large",1.12}}) do
    local b=button(UI.sizingCard,"Size_"..data[1],UDim2.new((i-1)/3,18,0,76),UDim2.new(1/3,-24,0,52))
    local edge=stroke(b,palette.Amethyst.accent,data[2]==1 and 0 or 1)
    local caption=label(b,"Caption",data[1],UDim2.fromScale(0,0),UDim2.fromScale(1,1),12,C.white); caption.TextXAlignment=Enum.TextXAlignment.Center
    sizeButtons[#sizeButtons+1]={button=b,edge=edge,value=data[2]}
end
UI.recenter=action(settings,"Recenter","Center window",UDim2.fromOffset(0,276),UDim2.fromOffset(206,48))
UI.about=card(settings,"About",UDim2.fromOffset(0,350),UDim2.new(1,-6,0,122))
label(UI.about,"Brand","Reyzn X",UDim2.fromOffset(20,20),UDim2.new(1,-40,0,28),18,C.white,Enum.Font.GothamBold)
label(UI.about,"Credit","Made By Reyzn",UDim2.fromOffset(20,59),UDim2.new(1,-40,0,24),13,C.muted)
local version=label(UI.about,"Version","v"..VERSION,UDim2.new(1,-120,0,22),UDim2.fromOffset(100,24),12,C.muted); version.TextXAlignment=Enum.TextXAlignment.Right
settings.CanvasSize=UDim2.fromOffset(0,484)

UI.launcher=button(UI.screen,"Launcher",UDim2.new(0,18,.5,-30),UDim2.fromOffset(60,60))
UI.launcher.Visible=false; UI.launcher.ZIndex=20; UI.launcher.BackgroundColor3=C.base; corner(UI.launcher,18)
bind(stroke(UI.launcher,nil,.1,1.5),"Color","accent")
UI.launcherIcon=icon(UI.launcher,"crown",UDim2.fromOffset(15,14),30,palette.Amethyst.accent)
local function refreshNavigation()
    local theme=palette[state.theme]
    for name,e in pairs(navigation) do
        local selected=name==state.page
        e.button.BackgroundColor3=Color3.new(1,1,1); e.wash.Color=ColorSequence.new(theme.accent,theme.deep)
        e.button.BackgroundTransparency=selected and .12 or 1; e.edge.Color=theme.light; e.edge.Transparency=selected and .35 or 1
        e.caption.TextColor3=selected and C.white or C.muted; tintIcon(e.icon,selected and C.white or C.muted); e.marker.Visible=selected
    end
end
local function refreshToggles()
    for key,e in pairs(toggles) do
        local enabled=state[key]
        tween(e.track,.2,{BackgroundColor3=enabled and palette[state.theme].deep or C.raised})
        tween(e.edge,.2,{Color=palette[state.theme].accent,Transparency=enabled and .2 or .85})
        tween(e.knob,.2,{Position=UDim2.fromOffset(enabled and 26 or 4,4),BackgroundColor3=enabled and C.white or C.muted})
        e.button:SetAttribute("Enabled",enabled)
    end
end
local function applyTheme(name)
    if not palette[name] then return end
    state.theme=name; local theme=palette[name]; UI.gui:SetAttribute("Theme",name)
    local rich=string.format('Reyzn <font color="rgb(%d,%d,%d)">X</font>',math.floor(theme.accent.R*255),math.floor(theme.accent.G*255),math.floor(theme.accent.B*255))
    UI.title.Text=rich; UI.heroTitle.Text=rich; UI.headerTag.Text=string.upper(name).." EDITION"; UI.themeStatus.Text=name
    for _,e in ipairs(themeBindings) do e[1][e[2]]=theme[e[3]] end
    for _,o in ipairs({UI.crown,UI.footerCrown,UI.statusIcon,UI.noteIcon,UI.launcherIcon}) do tintIcon(o,theme.accent) end
    for _,e in ipairs(shortcuts) do tintIcon(e.icon,theme.accent) end
    for _,e in ipairs(emptyCards) do tintIcon(e.icon,theme.light) end
    for _,wash in ipairs(facets) do wash.Color=ColorSequence.new(theme.light,theme.deep) end
    for _,e in ipairs({UI.openMain,UI.recenter}) do e.wash.Color=ColorSequence.new(theme.accent,theme.deep) end
    UI.headerGradient.Color=ColorSequence.new(C.base:Lerp(theme.deep,.23),C.base)
    UI.heroGradient.Color=ColorSequence.new(C.panel:Lerp(theme.deep,.16),C.panel)
    for key,e in pairs(themeButtons) do e.edge.Transparency=key==name and 0 or .75; e.button:SetAttribute("Selected",key==name) end
    for _,e in ipairs(sizeButtons) do e.edge.Color=theme.accent end
    for _,p in pairs(pages) do p.ScrollBarImageColor3=theme.accent end
    refreshNavigation(); refreshToggles()
end
local function selectPage(name)
    if state.closing or not pages[name] then return end
    state.page=name; UI.gui:SetAttribute("Page",name)
    for key,p in pairs(pages) do p.Visible=key==name end
    refreshNavigation()
end
for name,e in pairs(navigation) do
    connect(e.button.Activated,function() selectPage(name) end)
    connect(e.button.MouseEnter,function() if state.page~=name then tween(e.button,.15,{BackgroundTransparency=.85}) end end)
    connect(e.button.MouseLeave,function() if state.page~=name then tween(e.button,.2,{BackgroundTransparency=1}) end end)
end
connect(UI.openMain.button.Activated,function() selectPage("Main") end)
for _,e in ipairs(shortcuts) do connect(e.button.Activated,function() selectPage(e.page) end) end
for name,e in pairs(themeButtons) do connect(e.button.Activated,function() applyTheme(name) end) end
for key,e in pairs(toggles) do
    connect(e.button.Activated,function()
        state[key]=not state[key]; UI.outerGlow.Visible=state.glow; UI.innerGlow.Visible=state.glow
        refreshToggles()
    end)
end

-- Reflow content inside the safe area. Narrow screens use a compact icon rail.
local layout={width=1080,height=690,scale=1}
local function clampWindow()
    local bounds=UI.screen.AbsoluteSize
    local hw,hh=layout.width*UI.scale.Scale/2,layout.height*UI.scale.Scale/2
    local pos=UI.window.Position
    local x,y=pos.X.Scale*bounds.X+pos.X.Offset,pos.Y.Scale*bounds.Y+pos.Y.Offset
    x=math.clamp(x,math.min(hw+10,bounds.X/2),math.max(bounds.X/2,bounds.X-hw-10))
    y=math.clamp(y,math.min(hh+10,bounds.Y/2),math.max(bounds.Y/2,bounds.Y-hh-10))
    UI.window.Position=UDim2.fromOffset(x,y)
end
local function resize(center)
    local size=UI.screen.AbsoluteSize
    if size.X<100 or size.Y<100 then local camera=workspace.CurrentCamera; size=camera and camera.ViewportSize or Vector2.new(1280,720) end
    local scale=math.clamp((size.X-24)/1080,.68,1)*state.uiScale
    local width=math.min(state.maximized and 1440 or 1080,(size.X-24)/scale)
    local height=math.min(state.maximized and 960 or 690,(size.Y-24)/scale)
    layout.width=width; layout.height=height; layout.scale=scale
    UI.scale.Scale=scale; UI.window.Size=UDim2.fromOffset(width,height)
    local compact=width<740; local side=compact and 64 or 184; local header=compact and 142 or 116
    local top=header+28
    UI.header.Size=UDim2.new(1,-28,0,header); UI.headerTag.Visible=not compact; UI.headerArt.Visible=not compact
    UI.crown.Position=UDim2.fromOffset(compact and 16 or 22,19)
    UI.title.Position=UDim2.fromOffset(compact and 70 or 80,11); UI.title.TextSize=compact and (width<460 and 28 or 32) or 38
    UI.title.Size=UDim2.fromOffset(math.max(100,width-252),49)
    UI.avatarPlate.Position=UDim2.fromOffset(compact and 18 or 82,70)
    UI.userID.Position=UDim2.fromOffset(compact and 60 or 124,72); UI.userID.Size=UDim2.fromOffset(compact and width-110 or 196,28)
    UI.profileDivider.Visible=not compact
    UI.clockIcon.Position=UDim2.fromOffset(compact and 60 or 344,compact and 111 or 77)
    UI.session.Position=UDim2.fromOffset(compact and 86 or 370,compact and 106 or 72)
    UI.sidebar.Position=UDim2.fromOffset(14,top); UI.sidebar.Size=UDim2.fromOffset(side,math.max(80,height-top-56))
    UI.navCaption.Visible=not compact; UI.navScroll.Position=UDim2.fromOffset(8,compact and 10 or 52)
    UI.navScroll.Size=UDim2.new(1,-16,1,compact and -20 or -60)
    for _,e in pairs(navigation) do e.caption.Visible=not compact; e.icon.Position=UDim2.fromOffset(compact and 13 or 16,16) end
    local left=side+30; local contentW=width-left-14
    UI.content.Position=UDim2.fromOffset(left,top); UI.content.Size=UDim2.fromOffset(contentW,math.max(80,height-top-56))
    local stacked=contentW<720; local primary=stacked and contentW-6 or contentW-254
    UI.hero.Size=UDim2.fromOffset(primary,300); UI.heroArt.Visible=primary>=470
    UI.heroTitle.TextSize=primary<360 and 36 or 43; UI.heroTitle.Size=UDim2.fromOffset(primary-48,56)
    UI.heroSubtitle.Size=UDim2.fromOffset(primary-48,28)
    local vertical=primary<460
    for i,e in ipairs(shortcuts) do
        e.button.Position=UDim2.fromOffset(vertical and 0 or (i-1)*(primary+14)/2,360+(vertical and (i-1)*126 or 0))
        e.button.Size=UDim2.fromOffset(vertical and primary or (primary-14)/2,112)
    end
    local bottom=vertical and 598 or 472
    UI.status.Position=UDim2.fromOffset(stacked and 0 or primary+14,stacked and bottom+18 or 0)
    UI.status.Size=UDim2.fromOffset(stacked and primary or 234,216)
    UI.note.Position=UDim2.fromOffset(stacked and 0 or primary+14,stacked and bottom+250 or 232)
    UI.note.Size=UDim2.fromOffset(stacked and primary or 234,184)
    home.CanvasSize=UDim2.fromOffset(0,stacked and bottom+446 or 484)
    UI.window:SetAttribute("Compact",compact); UI.window:SetAttribute("Stacked",stacked)
    if center or state.maximized then UI.window.Position=UDim2.fromOffset(size.X/2,size.Y/2) end
    clampWindow()
    local p=UI.launcher.Position
    UI.launcher.Position=UDim2.fromOffset(math.clamp(p.X.Scale*size.X+p.X.Offset,8,math.max(8,size.X-68)),math.clamp(p.Y.Scale*size.Y+p.Y.Offset,8,math.max(8,size.Y-68)))
end
connect(UI.screen:GetPropertyChangedSignal("AbsoluteSize"),function() resize(false) end)
for _,e in ipairs(sizeButtons) do
    connect(e.button.Activated,function()
        state.uiScale=e.value
        for _,other in ipairs(sizeButtons) do other.edge.Transparency=other==e and 0 or 1 end
        resize(true)
    end)
end
connect(UI.recenter.button.Activated,function() resize(true) end)
connect(UI.Maximize.Activated,function()
    if state.closing then return end
    state.maximized=not state.maximized; UI.Maximize:SetAttribute("Maximized",state.maximized); resize(true)
end)

-- Fade native objects rather than allocating a large off-screen CanvasGroup texture.
UI.opacity=make("NumberValue",UI.gui,{Name="WindowOpacity",Value=0})
local fadeTargets={}
local function snapshotOpacity()
    table.clear(fadeTargets)
    local objects=UI.window:GetDescendants(); objects[#objects+1]=UI.window
    for _,o in ipairs(objects) do
        if o:IsA("GuiObject") then
            fadeTargets[#fadeTargets+1]={o,"BackgroundTransparency",o.BackgroundTransparency}
            if o:IsA("TextLabel") or o:IsA("TextButton") then fadeTargets[#fadeTargets+1]={o,"TextTransparency",o.TextTransparency}
            elseif o:IsA("ImageLabel") then fadeTargets[#fadeTargets+1]={o,"ImageTransparency",o.ImageTransparency} end
        elseif o:IsA("UIStroke") then fadeTargets[#fadeTargets+1]={o,"Transparency",o.Transparency} end
    end
end
local function setOpacity(value)
    for _,e in ipairs(fadeTargets) do if e[1].Parent then e[1][e[2]]=1-(1-e[3])*value end end
end
connect(UI.opacity:GetPropertyChangedSignal("Value"),function() setOpacity(UI.opacity.Value) end)
local function flash()
    if not state.motion then return end
    local ring=frame(UI.screen,"NeonFlash",UI.window.Position,UDim2.fromOffset(layout.width*UI.scale.Scale,layout.height*UI.scale.Scale),nil,1)
    ring.AnchorPoint=Vector2.new(.5,.5); ring.ZIndex=30; corner(ring,20*UI.scale.Scale)
    local edge=stroke(ring,palette[state.theme].light,.1,2)
    tween(ring,.4,{Size=UDim2.fromOffset(layout.width*UI.scale.Scale+26,layout.height*UI.scale.Scale+26)})
    tween(edge,.4,{Transparency=1})
    spawn(function() task.wait(.42); if state.alive then tweens[ring]=nil; tweens[edge]=nil; ring:Destroy() end end)
end
local function minimize()
    if state.busy or state.closing or state.minimized then return end
    state.busy=true; snapshotOpacity(); flash(); tween(UI.opacity,.25,{Value=0})
    spawn(function()
        if state.motion then task.wait(.26) end
        if not state.alive then return end
        UI.window.Visible=false; UI.launcher.Visible=true; state.minimized=true; state.busy=false
        UI.gui:SetAttribute("Minimized",true)
    end)
end
local function restore()
    if state.busy or state.closing or not state.minimized then return end
    state.busy=true; UI.launcher.Visible=false; UI.window.Visible=true; state.minimized=false
    tween(UI.opacity,.3,{Value=1})
    spawn(function() if state.motion then task.wait(.31) end; state.busy=false end)
    UI.gui:SetAttribute("Minimized",false)
end
connect(UI.Minimize.Activated,minimize)
connect(UI.Close.Activated,function()
    if state.closing or state.busy then return end
    state.closing=true; snapshotOpacity(); flash(); tween(UI.opacity,.3,{Value=0})
    -- This short callback is deliberately not cancelled from its own Destroying event.
    task.delay(state.motion and .36 or 0,function() if state.alive then UI.gui:Destroy() end end)
end)
local launcherDragged=false
local function beginDrag(input,target)
    if state.closing or state.busy then return end
    if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
    if target==UI.window and state.maximized then return end
    state.drag={target=target,input=input,start=input.Position,position=target.Position,moved=false}
    if target==UI.launcher then launcherDragged=false end
end
connect(UI.dragArea.InputBegan,function(input) beginDrag(input,UI.window) end)
connect(UI.launcher.InputBegan,function(input) beginDrag(input,UI.launcher) end)
connect(Input.InputChanged,function(input)
    local d=state.drag; if not d then return end
    local touch=d.input.UserInputType==Enum.UserInputType.Touch
    if touch and input~=d.input then return end
    if not touch and input.UserInputType~=Enum.UserInputType.MouseMovement then return end
    local delta=input.Position-d.start
    if delta.Magnitude>6 then d.moved=true end
    if not d.moved then return end
    d.target.Position=UDim2.new(d.position.X.Scale,d.position.X.Offset+delta.X,d.position.Y.Scale,d.position.Y.Offset+delta.Y)
    if d.target==UI.window then clampWindow()
    else
        launcherDragged=true; local size=UI.screen.AbsoluteSize; local p=d.target.Position
        d.target.Position=UDim2.fromOffset(math.clamp(p.X.Scale*size.X+p.X.Offset,8,math.max(8,size.X-68)),math.clamp(p.Y.Scale*size.Y+p.Y.Offset,8,math.max(8,size.Y-68)))
    end
end)
connect(Input.InputEnded,function(input)
    local d=state.drag
    if d and (input==d.input or (d.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1)) then state.drag=nil end
end)
connect(Input.WindowFocusReleased,function() state.drag=nil end)
connect(UI.launcher.Activated,function() if not launcherDragged then restore() end end)
connect(Input.InputBegan,function(input,processed)
    if processed or Input:GetFocusedTextBox() then return end
    if input.KeyCode==Enum.KeyCode.RightShift then if state.minimized then restore() else minimize() end end
end)
spawn(function()
    -- Unready thumbnails never block the interface or the session timer.
    for attempt=1,3 do
        local ok,content,ready=pcall(function() return Players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150) end)
        if not state.alive then return end
        if ok and type(content)=="string" and content~="" then
            UI.avatar.Image=content; UI.avatarFallback.Visible=false; if ready then return end
        end
        if attempt<3 then task.wait(2) end
    end
end)
connect(RunService.Heartbeat,function(delta)
    local elapsed=math.max(0,math.floor(os.clock()-startedAt))
    if elapsed~=state.lastSecond then
        state.lastSecond=elapsed
        UI.session.Text=string.format("%02d:%02d:%02d",math.floor(elapsed/3600),math.floor(elapsed/60)%60,elapsed%60)
        UI.gui:SetAttribute("ElapsedSeconds",elapsed)
    end
    if not state.motion or state.minimized or state.closing or state.busy then return end
    state.budget+=delta; if state.budget<1/30 then return end
    state.phase+=state.budget; state.budget=0; local t=state.phase
    UI.rimGradient.Rotation=25+math.sin(t*.24)*30; UI.glowStroke.Transparency=.9+math.sin(t*.8)*.025
    for i,beam in ipairs(energy) do beam.BackgroundTransparency=.55+math.sin(t*.8+i*.27)*.18 end
    if state.page=="Home" then
        UI.heroArt.Position=UDim2.new(1,-248,.5,-125+math.sin(t*.75)*4)
        for _,mote in ipairs(specks) do
            mote.object.Position=UDim2.fromOffset(mote.x+math.sin(t*.25+mote.phase)*4,mote.y+math.sin(t*.5+mote.phase)*7)
            mote.object.BackgroundTransparency=.5+math.sin(t+mote.phase)*.25
        end
    end
end)
applyTheme("Amethyst"); selectPage("Home"); resize(true)
UI.gui:SetAttribute("ElapsedSeconds",0); UI.gui:SetAttribute("Minimized",false)
snapshotOpacity(); setOpacity(0); state.busy=true; tween(UI.opacity,.4,{Value=1})
spawn(function() task.wait(.41); state.busy=false end)
return UI.gui
