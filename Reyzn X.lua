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

local VERSION = "2.2.0"
local C = {
    base=Color3.fromRGB(10,10,15), panel=Color3.fromRGB(16,15,23),
    black=Color3.fromRGB(8,8,12), steel=Color3.fromRGB(71,68,85),
    silver=Color3.fromRGB(217,219,233), white=Color3.fromRGB(245,244,251),
    muted=Color3.fromRGB(184,181,201), line=Color3.fromRGB(66,59,85),
    violet=Color3.fromRGB(157,103,239), light=Color3.fromRGB(213,181,255),
    deep=Color3.fromRGB(60,31,99), green=Color3.fromRGB(132,225,179), ice=Color3.fromRGB(180,207,255),
    rose=Color3.fromRGB(212,152,219), chrome=Color3.fromRGB(235,237,247),
}
-- This is a maximum, not a layout setting. Android starts with a smaller budget.
local DEFAULT_QUALITY = Input.TouchEnabled and "Medium" or "High"
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
-- VFX modules share the existing lifecycle and alpha compositor. No downloaded
-- modules, global render bindings, or full-window CanvasGroup render targets.
local VFX={images={},auras={},buttons={},reflections={items={},nextAt=5,serial=0}}
local Quality={names={"Low","Medium","High"},requested=DEFAULT_QUALITY,level=DEFAULT_QUALITY=="High" and 3 or 2,
    smooth=1/60,bad=0,good=0,cooldown=3}
Quality.presets={
    {fps=15,density=.38,particles=.24,glow=false,reflections=false},
    {fps=30,density=.55,particles=.58,glow=true,reflections=true},
    {fps=30,density=1,particles=1,glow=true,reflections=true},
}
local function shown(object)
    while object and object~=UI.gui do
        if object:IsA("GuiObject") and not object.Visible then return false end
        object=object.Parent
    end
    return object~=nil
end
local function addReflection(object,light,strength)
    local item={object=object,light=light,strength=strength or .1}
    VFX.reflections.items[#VFX.reflections.items+1]=item
    alpha(object,"BackgroundTransparency",1)
    return item
end
function VFX.reflections:request(item)
    if not item or not shown(item.object) or not Quality.presets[Quality.level].reflections then return end
    if self.active then alpha(self.active.object,"BackgroundTransparency",1) end
    self.active=item;self.elapsed=0;self.nextAt=state.phase+6.5
end
function VFX.reflections:update(dt)
    local item=self.active
    if item then
        self.elapsed+=dt
        local t=math.min(1,self.elapsed/.95)
        if not shown(item.object) or not Quality.presets[Quality.level].reflections or t>=1 then
            alpha(item.object,"BackgroundTransparency",1);self.active=nil
        else
            -- Only ONE diagonal highlight is active, regardless of hover spam.
            item.light.Offset=Vector2.new(-1.15+2.3*t,0)
            alpha(item.object,"BackgroundTransparency",1-math.sin(t*math.pi)^2*item.strength)
        end
    elseif state.phase>=self.nextAt and state.target=="open" then
        self.nextAt=state.phase+7.5
        for _=1,#self.items do
            self.serial=self.serial%#self.items+1
            local candidate=self.items[self.serial]
            if shown(candidate.object) then self:request(candidate);break end
        end
    end
end
local buttons=VFX.buttons
local function updateButtonLight(record)
    local selected=record.selection.Value
    local energy=record.energy.Value
    alpha(record.selectionWash,"BackgroundTransparency",1-selected*.17)
    alpha(record.edge,"Transparency",.58-selected*.32-energy*.18)
    alpha(record.lip,"BackgroundTransparency",.84-selected*.19-energy*.18)
end
local function button(parent,name,pos,size)
    local b=make("TextButton",parent,{Name=name,Text="",Position=pos,Size=size,BackgroundTransparency=1,AutoButtonColor=false,Selectable=true})
    local face=frame(b,"MetalFace",UDim2.fromScale(.5,.5),UDim2.fromScale(1,1),Color3.new(1,1,1))
    face.AnchorPoint=Vector2.new(.5,.5);corner(face,10)
    local scale=make("UIScale",face,{Name="PressScale",Scale=1})
    local wash=gradient(face,metallicColors,108)
    local selectedWash=frame(face,"SelectionWash",UDim2.fromScale(0,0),UDim2.fromScale(1,1),C.violet,1)
    corner(selectedWash,10);gradient(selectedWash,{C.light,C.deep,C.violet},110)
    local edge=stroke(face,Color3.new(1,1,1),.58,1)
    gradient(edge,{C.steel,C.silver,C.deep,C.violet},34)
    local lip=frame(face,"MetalLip",UDim2.fromOffset(11,1),UDim2.new(1,-22,0,1),C.chrome,.84)
    local lipGradient=gradient(lip,{C.steel,C.chrome,C.violet},0);fadeGradient(lipGradient)
    local sheen=frame(face,"Sheen",UDim2.fromOffset(2,2),UDim2.new(1,-4,1,-4),C.white,1)
    corner(sheen,9); local light=gradient(sheen,{C.white,C.light},25); fadeGradient(light)
    local record={button=b,face=face,scale=scale,edge=edge,wash=wash,sheen=sheen,light=light,lip=lip,
        selectionWash=selectedWash,hover=false,selected=false,pressed=false,
        energy=make("NumberValue",b,{Name="InteractionLight",Value=0}),
        selection=make("NumberValue",b,{Name="SelectionBlend",Value=0})}
    record.reflection=addReflection(sheen,light,.13)
    buttons[#buttons+1]=record
    connect(record.energy.Changed,function() updateButtonLight(record) end)
    connect(record.selection.Changed,function() updateButtonLight(record) end)
    connect(b.MouseEnter,function() record.hover=true;tween(record.energy,.2,{Value=.65});VFX.reflections:request(record.reflection) end)
    connect(b.MouseLeave,function() record.hover=false;if not record.pressed then tween(record.energy,.28,{Value=0}) end end)
    connect(b.InputBegan,function(input)
        if record.pressed then return end
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            record.pressed=true;record.pointer=input
            tween(scale,.09,{Scale=.977});tween(record.energy,.12,{Value=1})
            VFX.reflections:request(record.reflection)
        end
    end)
    connect(b.Activated,function() VFX.reflections:request(record.reflection) end)
    return b,record
end
local function releaseButtons(input,force)
    for _,record in ipairs(buttons) do
        if record.pressed and (force or input==record.pointer or
            (record.pointer.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1)) then
            record.pressed=false;record.pointer=nil
            tween(record.scale,.22,{Scale=1});tween(record.energy,.28,{Value=force and 0 or (record.hover and .65 or 0)})
        end
    end
end
connect(Input.InputEnded,function(input) releaseButtons(input,false) end)
connect(Input.WindowFocusReleased,function() releaseButtons(nil,true) end)

local function brandText(parent,name,pos,size,pixels)
    local text=label(parent,name,'Reyzn <font face="GothamBold">X</font>',pos,size,pixels,C.white,Enum.Font.GrenzeGotisch)
    text.RichText=true
    text.TextColor3=Color3.new(1,1,1)
    text.TextTruncate=Enum.TextTruncate.None
    -- Static chrome bands keep the lettering crisp; only a rare separate sweep
    -- moves. Text stays native and readable even when images cannot be loaded.
    local metal=make("UIGradient",text,{Rotation=90,Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,C.chrome),ColorSequenceKeypoint.new(.30,C.white),
        ColorSequenceKeypoint.new(.50,C.muted),ColorSequenceKeypoint.new(.57,C.chrome),
        ColorSequenceKeypoint.new(1,C.light)})})
    local outline=make("UIStroke",text,{Color=C.black,Transparency=.28,Thickness=.8,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
    return text,metal,outline
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
    -- A soft contact shadow, not six bright nested rectangles.
    local shadow=frame(o,"ContactShadow",UDim2.new(0,12,1,1),UDim2.new(1,-24,0,20),C.black,.35)
    local shadowFade=gradient(shadow,{C.black,C.black},90)
    shadowFade.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.15),NumberSequenceKeypoint.new(.4,.72),NumberSequenceKeypoint.new(1,1)})
    local edge=stroke(o,Color3.new(1,1,1),.36,1)
    local metal=gradient(edge,{C.steel,C.silver,C.violet,C.black,C.violet},24)
    local inner=frame(o,"InnerRim",UDim2.fromOffset(2,2),UDim2.new(1,-4,1,-4),nil,1)
    corner(inner,14);stroke(inner,C.silver,.94,1)
    local beam=frame(o,"EdgeLight",UDim2.fromOffset(16,0),UDim2.new(1,-32,0,1),C.white,.65)
    local beamGradient=gradient(beam,{C.light,C.silver,C.violet},0);fadeGradient(beamGradient)
    local sheen=frame(o,"SurfaceReflection",UDim2.fromOffset(3,3),UDim2.new(1,-6,1,-6),C.chrome,1)
    corner(sheen,14);local sweep=gradient(sheen,{C.chrome,C.ice},28);fadeGradient(sweep)
    addReflection(sheen,sweep,.035)
    return o,{edge=edge,metal=metal,beam=beam,beamGradient=beamGradient}
end
UI.dock,UI.dockFx=surface(UI.window,"Dock",UDim2.fromOffset(0,0),UDim2.fromOffset(170,420))
UI.dock.ZIndex=2
UI.dockCrown=icon(UI.dock,"crown",UDim2.fromOffset(17,20),24,C.light)
UI.brand=brandText(UI.dock,"BrandText",UDim2.fromOffset(46,8),UDim2.fromOffset(116,44),25)
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
    local controlSheen=frame(b,"ControlReflection",UDim2.fromOffset(2,8),UDim2.new(1,-4,0,20),C.chrome,1)
    corner(controlSheen,8);local controlSweep=gradient(controlSheen,{C.white,C.ice},25);fadeGradient(controlSweep)
    record.reflection=addReflection(controlSheen,controlSweep,.17)
    connect(b.MouseEnter,function() record.hover=true;alpha(glow,"ImageTransparency",.82);VFX.reflections:request(record.reflection);if not record.pressed then tween(artScale,.18,{Scale=1.025}) end end)
    connect(b.MouseLeave,function() record.hover=false;alpha(glow,"ImageTransparency",.95);if not record.pressed then tween(artScale,.18,{Scale=1}) end end)
    connect(b.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            if record.pressed then return end
            record.pressed=true;record.pointer=input;tween(artScale,.09,{Scale=.97});alpha(glow,"ImageTransparency",.74);VFX.reflections:request(record.reflection)
        end
    end)
    connect(Input.InputEnded,function(input)
        if record.pressed and (input==record.pointer or (record.pointer.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1)) then
            record.pressed=false;record.pointer=nil;tween(artScale,.22,{Scale=record.hover and 1.025 or 1});alpha(glow,"ImageTransparency",record.hover and .82 or .95)
        end
    end)
    connect(Input.WindowFocusReleased,function() record.pressed=false;record.pointer=nil;tween(artScale,.16,{Scale=1}) end)
    UI[data[1]]=b
end
UI.reveal=frame(UI.window,"PanelReveal",UDim2.fromOffset(180,0),UDim2.fromOffset(700,420),nil,1,"pane")
UI.reveal.ZIndex=2
UI.reveal.ClipsDescendants=true
UI.panel,UI.panelFx=surface(UI.reveal,"Panel",UDim2.fromOffset(4,4),UDim2.fromOffset(692,412))
VFX.surfaces={UI.dockFx,UI.panelFx}
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
-- Main, Visuals and Scripts retain their empty content. Settings only adds the
-- requested visual-quality control; no gameplay modules are installed here.
UI.hero=frame(pages.Home,"Hero",UDim2.fromOffset(1,1),UDim2.new(1,-8,0,200),Color3.new(1,1,1))
corner(UI.hero,13);stroke(UI.hero,C.violet,.62)
gradient(UI.hero,{Color3.fromRGB(28,22,40),C.black,Color3.fromRGB(26,17,39)},32)
local heroSheen=frame(UI.hero,"HeroReflection",UDim2.fromOffset(2,2),UDim2.new(1,-4,1,-4),C.chrome,1)
corner(heroSheen,12);local heroSweep=gradient(heroSheen,{C.chrome,C.light},28);fadeGradient(heroSweep)
addReflection(heroSheen,heroSweep,.05)
UI.heroTitle=brandText(UI.hero,"HeroTitle",UDim2.fromOffset(20,10),UDim2.fromOffset(268,100),48)
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

-- FireAura: two tinted texture layers per plume, with independent lifetimes.
-- ParticlePool: fixed crystal/silver slots; all emit OUTSIDE the panel bounds.
-- Each aura is behind the opaque UI surface, never above text or hit targets.
local FireAura={};FireAura.__index=FireAura
local ParticlePool={};ParticlePool.__index=ParticlePool
local function noise(seed) return (math.sin(seed*12.9898+78.233)*43758.5453)%1 end
local function sidePoint(side,fraction,w,h,distance,sway)
    local inset=math.min(18,math.min(w,h)*.22)
    if side==1 then return inset+(w-2*inset)*fraction+sway,-distance,0
    elseif side==2 then return w+distance,inset+(h-2*inset)*fraction+sway,90
    elseif side==3 then return inset+(w-2*inset)*fraction+sway,h+distance,180
    else return -distance,inset+(h-2*inset)*fraction+sway,-90 end
end
local function contourPoint(progress,w,h)
    local r=math.min(16,w/3,h/3)
    local horizontal,vertical,arc=w-2*r,h-2*r,math.pi*r/2
    local distance=progress*(2*horizontal+2*vertical+4*arc)
    for side=1,4 do
        local length=side%2==1 and horizontal or vertical
        if distance<length then
            if side==1 then return r+distance,-1,0
            elseif side==2 then return w+1,r+distance,90
            elseif side==3 then return w-r-distance,h+1,180
            else return -1,h-r-distance,270 end
        end
        distance-=length
        if distance<arc then
            local angle=(side-2)*math.pi/2+distance/r
            local cx=side<=2 and w-r or r
            local cy=(side==1 or side==4) and r or h-r
            return cx+(r+1)*math.cos(angle),cy+(r+1)*math.sin(angle),math.deg(angle)+90
        end
        distance-=arc
    end
    return r,-1,0
end
function ParticlePool.new(host,count,small)
    local self=setmetatable({slots={},small=small},ParticlePool)
    for i=1,count do
        local size=(i%3==0) and 2 or 3
        local node=frame(host,"EdgeParticle",UDim2.fromOffset(0,0),UDim2.fromOffset(size,i%3==0 and 5 or size),i%3==0 and C.silver or (i%2==0 and C.ice or C.light),1)
        node.Active=false;node.AnchorPoint=Vector2.new(.5,.5);node.ZIndex=1
        gradient(node,{C.chrome,C.light,C.violet},35)
        local cross
        if i%4==0 then
            node.Size=UDim2.fromOffset(6,1)
            cross=frame(node,"SilverCross",UDim2.fromScale(.5,.5),UDim2.fromOffset(1,6),C.chrome,1)
            cross.AnchorPoint=Vector2.new(.5,.5);cross.Active=false
        end
        self.slots[i]={node=node,cross=cross,seed=i*1.731,cycle=-1,side=1+(i-1)%4,enabled=true}
    end
    return self
end
function ParticlePool:quality(preset)
    local limit=math.max(1,math.floor(#self.slots*preset.particles))
    for i,p in ipairs(self.slots) do p.enabled=i<=limit;p.node.Visible=p.enabled end
end
function ParticlePool:update(time,w,h)
    for _,p in ipairs(self.slots) do
        if p.enabled then
            local lifetime=3.6+noise(p.seed)*2.8
            local age=(time+p.seed)/lifetime
            local cycle=math.floor(age);local progress=age-cycle
            if p.cycle~=cycle then
                p.cycle=cycle;p.fraction=.04+.92*noise(p.seed+cycle*7.19)
                p.speed=6+noise(cycle+p.seed*4)*8
                p.rotation=noise(p.seed+cycle)*150
            end
            local envelope=math.sin(progress*math.pi)^2
            local x,y=sidePoint(p.side,p.fraction,w,h,9+progress*p.speed,math.sin(progress*math.pi*1.2+p.seed)*3)
            p.node.Position=UDim2.fromOffset(x,y)
            p.node.Rotation=p.rotation+progress*24
            alpha(p.node,"BackgroundTransparency",1-envelope*(self.small and .38 or .54))
            if p.cross then alpha(p.cross,"BackgroundTransparency",1-envelope*.52) end
        end
    end
end
function FireAura.new(parent,name,scope,counts,particleCount,small)
    local host=frame(parent,name,UDim2.fromOffset(0,0),UDim2.fromOffset(100,100),nil,1,scope)
    host.ZIndex=0;host.Active=false;host.ClipsDescendants=false
    local self=setmetatable({host=host,plumes={},veils={},small=small,seed=#VFX.auras*.937},FireAura)
    self.particles=ParticlePool.new(host,particleCount,small)
    for side=1,4 do
        -- A very faint continuous flame bed connects the brighter local wisps.
        -- This is a textured silhouette, never a rectangular outline/stroke.
        local veil=imageLabel(host,"FlameVeil",UDim2.fromOffset(0,0),UDim2.fromOffset(80,24))
        veil.AnchorPoint=Vector2.new(.5,.5);veil.ScaleType=Enum.ScaleType.Stretch
        veil.ImageColor3=side%2==0 and C.rose or C.ice
        alpha(veil,"ImageTransparency",.9)
        local wash=gradient(veil,{C.violet,C.ice,C.light},0)
        wash.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.18,.12),NumberSequenceKeypoint.new(.77,.2),NumberSequenceKeypoint.new(1,1)})
        self.veils[side]=veil;VFX.images[#VFX.images+1]=veil
    end
    for side,count in ipairs(counts) do
        for index=1,count do
            local seed=side*.973+index*1.171+self.seed
            local root=frame(host,"FlameSlot",UDim2.fromOffset(0,0),UDim2.fromOffset(48,44),nil,1)
            root.AnchorPoint=Vector2.new(.5,.5);root.Active=false
            local haze=imageLabel(root,"FlameHaze",UDim2.fromScale(.5,.5),UDim2.fromScale(1.45,1.18))
            haze.AnchorPoint=Vector2.new(.5,.5);haze.ScaleType=Enum.ScaleType.Stretch
            haze.ImageColor3=({C.violet,C.ice,C.rose})[1+(side+index)%3]
            local core=imageLabel(root,"FlameCore",UDim2.fromScale(.5,.5),UDim2.fromScale(1,1))
            core.AnchorPoint=Vector2.new(.5,.5);core.ScaleType=Enum.ScaleType.Stretch
            -- One immutable color ramp per sprite, not a new ColorSequence/frame.
            gradient(core,{index%3==0 and C.rose or C.violet,C.ice,C.chrome},90)
            alpha(haze,"ImageTransparency",1);alpha(core,"ImageTransparency",1)
            VFX.images[#VFX.images+1]=haze;VFX.images[#VFX.images+1]=core
            self.plumes[#self.plumes+1]={root=root,haze=haze,core=core,side=side,seed=seed,
                fraction=(index-.5)/count,count=count,index=index,enabled=true}
        end
    end
    self.stream=frame(host,"EdgeEnergy",UDim2.fromOffset(0,0),UDim2.fromOffset(small and 15 or 28,1),C.chrome,.65)
    self.stream.AnchorPoint=Vector2.new(.5,.5);self.stream.Active=false
    local flow=gradient(self.stream,{C.violet,C.chrome,C.ice},0);fadeGradient(flow)
    self.glint=frame(host,"CornerGlint",UDim2.fromOffset(-3,-3),UDim2.fromOffset(8,1),C.chrome,1)
    self.glint.AnchorPoint=Vector2.new(.5,.5);self.glint.Active=false;self.glint.Rotation=25
    self.glintCross=frame(self.glint,"Cross",UDim2.fromScale(.5,.5),UDim2.fromOffset(1,8),C.chrome,1)
    self.glintCross.AnchorPoint=Vector2.new(.5,.5);self.glintCross.Active=false
    VFX.auras[#VFX.auras+1]=self
    return self
end
function FireAura:quality(preset)
    self.preset=preset
    for _,p in ipairs(self.plumes) do
        -- Rank samples are interleaved so all four edges retain coverage at Low.
        local rank=(p.index-1)*.61803398875%1
        p.enabled=rank<preset.density;p.root.Visible=p.enabled;p.haze.Visible=preset.glow
    end
    self.particles:quality(preset)
    self.glint.Visible=preset.reflections
end
function FireAura:update(time,burst)
    local w,h=self.host.Size.X.Offset,self.host.Size.Y.Offset
    if w<20 or h<20 then return end
    local scale=self.small and .6 or 1
    for side,veil in ipairs(self.veils) do
        local length=(20+math.sin(time*.8+self.seed+side)*3)*scale
        local x,y,rotation=sidePoint(side,.5,w,h,length*.28,0)
        veil.Position=UDim2.fromOffset(x,y);veil.Rotation=rotation
        veil.Size=UDim2.fromOffset(math.max(12,(side%2==1 and w or h)-12),length)
        alpha(veil,"ImageTransparency",.89-math.sin(time*.7+side+self.seed)^2*.035-burst*.025)
    end
    for _,p in ipairs(self.plumes) do
        if p.enabled then
            local age=(time*(.22+noise(p.seed)*.11)+p.seed)%1
            local envelope=math.sin(age*math.pi)^1.3
            local breath=math.sin(time*1.8+p.seed*4)*.5+math.sin(time*2.7+p.seed)*.25
            local length=(24+age*17+breath*4)*scale
            local span=(p.side%2==1 and w or h)-36
            local width=math.max(30*scale,span/p.count)*(1.12+noise(p.seed+1)*.28)+breath*3*scale
            local x,y,rotation=sidePoint(p.side,p.fraction,w,h,length*.34+age*4,math.sin(time*.8+p.seed*5)*4*scale)
            p.root.Position=UDim2.fromOffset(x,y)
            p.root.Size=UDim2.fromOffset(width,length)
            p.root.Rotation=rotation+math.sin(time*1.3+p.seed)*7
            p.core.Position=UDim2.fromScale(.5+math.sin(time*1.1+p.seed)*.035,.5)
            alpha(p.core,"ImageTransparency",1-envelope*(.46+burst*.07))
            if self.preset.glow then alpha(p.haze,"ImageTransparency",1-envelope*(.16+burst*.035)) end
        end
    end
    self.particles:update(time,w,h)
    -- Local energy travels around the contour. The whole rim never flashes.
    local x,y,angle=contourPoint((time*.055+self.seed)%1,w,h)
    self.stream.Position=UDim2.fromOffset(x,y);self.stream.Rotation=angle
    alpha(self.stream,"BackgroundTransparency",.65-.1*math.sin(time*.9+self.seed)^2-burst*.1)
    if self.preset.reflections then
        local cycle=(time+self.seed*4)%7.7
        local intensity=cycle<.8 and math.sin(cycle/.8*math.pi)^2*.5 or 0
        local c=math.floor((time+self.seed*4)/7.7)%4
        self.glint.Position=UDim2.fromOffset(c%2==0 and -4 or w+4,c<2 and -4 or h+4)
        alpha(self.glint,"BackgroundTransparency",1-intensity)
        alpha(self.glintCross,"BackgroundTransparency",1-intensity)
    end
end
UI.dockAura=FireAura.new(UI.window,"DockAura","window",{3,6,3,6},8,false)
UI.panelAura=FireAura.new(UI.window,"PanelAura","pane",{9,4,9,4},14,false)
UI.launcherAura=FireAura.new(UI.launcher,"LauncherAura","launcher",{2,2,2,2},4,true)
UI.launcherAura.host.Size=UDim2.fromOffset(68,68)

-- Quality changes only VFX budgets. All control positions, dimensions, icons,
-- hitboxes and content remain identical. Recovery is slower than degradation.
UI.qualityCard=frame(pages.Settings,"QualityCard",UDim2.fromOffset(1,1),UDim2.new(1,-8,0,208),Color3.new(1,1,1))
corner(UI.qualityCard,13);gradient(UI.qualityCard,{C.panel,C.black},105);stroke(UI.qualityCard,C.line,.3)
UI.qualityTitle=label(UI.qualityCard,"QualityTitle","Visual quality",UDim2.fromOffset(14,8),UDim2.new(1,-28,0,30),17,C.white,optionFont)
UI.qualityHint=label(UI.qualityCard,"QualityHint","Adapts to performance",UDim2.fromOffset(14,38),UDim2.new(1,-28,0,30),12,C.muted)
UI.qualityHint.TextWrapped=true
UI.qualityButtons={}
for i,name in ipairs(Quality.names) do
    local b,fx=button(UI.qualityCard,"Quality_"..name,UDim2.fromOffset(12,76+(i-1)*42),UDim2.new(1,-24,0,36))
    local caption=label(b,"Caption",name,UDim2.fromOffset(12,0),UDim2.new(1,-24,1,0),15,C.silver,optionFont)
    UI.qualityButtons[name]={button=b,fx=fx,caption=caption}
end
UI.qualityStatus=label(pages.Settings,"QualityStatus","",UDim2.fromOffset(4,221),UDim2.new(1,-12,0,44),12,C.muted)
UI.qualityStatus.TextWrapped=true
pages.Settings.CanvasSize=UDim2.fromOffset(0,276)
function Quality:apply(level)
    self.level=level
    local preset=self.presets[level]
    for _,aura in ipairs(VFX.auras) do aura:quality(preset) end
    UI.gui:SetAttribute("EffectiveQuality",self.names[level])
    UI.gui:SetAttribute("VFXRate",preset.fps)
    UI.qualityStatus.Text="Active: "..self.names[level]..(self.names[level]~=self.requested and " · adjusted for performance" or "")
    for name,option in pairs(UI.qualityButtons) do
        local selected=name==self.requested;option.fx.selected=selected
        tween(option.fx.selection,.22,{Value=selected and 1 or 0})
        option.caption.TextColor3=selected and C.white or C.muted
    end
end
function Quality:choose(name)
    local level=table.find(self.names,name)
    if not level then UI.gui:SetAttribute("VisualQuality",self.requested);return end
    self.requested=name;self.bad=0;self.good=0;self.cooldown=3
    UI.gui:SetAttribute("VisualQuality",name);self:apply(level)
end
function Quality:sample(dt)
    -- Ignore resume/debugger stalls; they are not sustained rendering pressure.
    if dt<=0 or dt>.25 then self.bad=0;self.good=0;return end
    self.smooth+=(dt-self.smooth)*math.min(1,dt*2)
    self.cooldown=math.max(0,self.cooldown-dt)
    if self.cooldown>0 then return end
    self.bad=self.smooth>1/42 and self.bad+dt or 0
    self.good=self.smooth<1/55 and self.good+dt or 0
    if self.bad>=2.5 and self.level>1 then
        self.bad=0;self.good=0;self.cooldown=4;self:apply(self.level-1)
    elseif self.good>=10 and self.level<table.find(self.names,self.requested) then
        self.bad=0;self.good=0;self.cooldown=8;self:apply(self.level+1)
    end
end
for name,option in pairs(UI.qualityButtons) do connect(option.button.Activated,function() Quality:choose(name) end) end
connect(UI.gui:GetAttributeChangedSignal("VisualQuality"),function()
    local requested=UI.gui:GetAttribute("VisualQuality")
    if requested~=Quality.requested then Quality:choose(requested) end
end)
Quality:choose(DEFAULT_QUALITY)
-- Put the existing labels/icons inside the press surface, while the original
-- TextButton's touch/click rectangle remains stationary and full-sized.
for _,record in ipairs(buttons) do
    for _,child in ipairs(record.button:GetChildren()) do
        if child:IsA("GuiObject") and child~=record.face then child.Parent=record.face end
    end
end

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
    UI.brand.TextSize=dw>=150 and 25 or (dw<120 and 22 or 24)
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
    UI.heroTitle.TextSize=narrow and math.min(32,math.floor((cw-28)/4.1)) or math.min(48,math.floor(cw*.52/4.1))
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
        tween(n.fx.selection,.24,{Value=selected and 1 or 0})
        tween(n.caption,.22,{TextColor3=selected and C.white or C.muted})
        tintIcon(n.icon,selected and C.light or C.silver)
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

-- Original transparent logos/controls plus one purpose-made fire sprite.
-- The previous wordmark PNG remains in the repository but is no longer loaded.
-- Custom PNGs need the executor's local asset API; failure never blocks the GUI.
local ASSETS={
    R={url="https://raw.githubusercontent.com/hzReyzn/Ghislain/main/assets/reyzn-x/launcher-r-v1.png",file="ReyznX-launcher-r-v1.png",bytes=2136070,images={UI.launcherImage,UI.recoveryImage}},
    X={url="https://raw.githubusercontent.com/hzReyzn/Ghislain/main/assets/reyzn-x/emblem-x-v1.png",file="ReyznX-emblem-x-v1.png",bytes=1699126,images={UI.xImage,UI.xGlow}},
    Fire={url="https://raw.githubusercontent.com/hzReyzn/Ghislain/main/assets/reyzn-x/flame-wisp-v1.png",file="ReyznX-flame-wisp-v1.png",bytes=1172326,images=VFX.images},
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
    Quality:sample(dt)
    if state.finishAt>0 and os.clock()>=state.finishAt then
        state.finishAt=0
        if state.target=="closed" then UI.gui:Destroy();return end
        UI.window.Visible=state.target=="open"
        UI.launcher.Visible=state.target=="minimized"
        UI.gui:SetAttribute("Transition",state.target)
    end
    state.budget+=dt
    state.effectElapsed=(state.effectElapsed or 0)+dt
    local interval=1/Quality.presets[Quality.level].fps
    if state.budget<interval then return end
    local elapsed=state.effectElapsed;state.effectElapsed=0
    state.budget=state.budget%interval;state.phase+=elapsed
    state.burst=math.max(0,state.burst-elapsed*3)
    local p=state.phase
    local pulse=.5+.5*math.sin(p*1.8)
    UI.recovery.Visible=state.target~="closed" and state.finishAt==0 and offscreen(state.target=="minimized" and UI.launcher or UI.window)
    if p>=(state.assetPoll or 0) then
        state.assetPoll=p+.2
        UI.avatarFallback.Visible=UI.avatar.Image=="" or not UI.avatar.IsLoaded
        UI.rFallback.Visible=UI.launcherImage.Image=="" or not UI.launcherImage.IsLoaded
        UI.recoveryFallback.Visible=UI.recoveryImage.Image=="" or not UI.recoveryImage.IsLoaded
        UI.xFallback.Visible=UI.xImage.Image=="" or not UI.xImage.IsLoaded
        for name,control in pairs(controlArtwork) do
            control.fallback.Visible=control.image.Image=="" or not control.image.IsLoaded
            if not control.fallback.Visible then UI.gui:SetAttribute("Asset"..name,"ready") end
        end
        if not UI.xFallback.Visible then UI.gui:SetAttribute("AssetX","ready") end
        if not UI.rFallback.Visible then UI.gui:SetAttribute("AssetR","ready") end
        if VFX.images[1].Image~="" and VFX.images[1].IsLoaded then UI.gui:SetAttribute("AssetFire","ready") end
    end
    local visibleTarget=state.target=="minimized" and UI.launcher or UI.window
    if state.finishAt==0 and offscreen(visibleTarget) then return end
    alpha(UI.launcherRim,"Transparency",.5+pulse*.18-.2*state.burst)
    if UI.launcher.Visible then UI.launcherAura:update(p,state.burst) end
    VFX.reflections:update(elapsed)
    if state.target=="minimized" and state.finishAt==0 then return end
    UI.dockAura:update(p,state.burst)
    if UI.panelAura.host.Visible then UI.panelAura:update(p+.63,state.burst) end
    for i,fx in ipairs(VFX.surfaces) do
        if i==1 or UI.panelAura.host.Visible then
            local breath=.5+.5*math.sin(p*.65+i*1.7)
            alpha(fx.beam,"BackgroundTransparency",.72-.12*breath-.12*state.burst)
            fx.beamGradient.Offset=Vector2.new(math.sin(p*.18+i)*.34,0)
        end
    end
    if state.page=="Home" and state.paneOpen then
        alpha(UI.xGlow,"ImageTransparency",.91-.06*pulse)
        UI.heroGlint.Position=UDim2.new(.5+.32*math.sin(p*.38),-40,0,0)
    end
end)
return UI.gui
