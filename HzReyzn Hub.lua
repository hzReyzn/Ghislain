-- HzReyzn Hub: interface foundation
-- Creado x Lord SIX seven Rey del Gore carlitos omg

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

for _, name in ipairs({"HzReyznInterface", "HzReyznMaintenance", "HzReyznHalloweenLoading"}) do
    local old = playerGui:FindFirstChild(name)
    if old then old:Destroy() end
end

local connections = {}
local destroyed = false

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

local function make(class, parent, properties)
    local object = Instance.new(class)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function round(object, radius)
    make("UICorner", object, {
        CornerRadius = UDim.new(0, radius)
    })
end

local white = Color3.fromRGB(249, 250, 252)
local muted = Color3.fromRGB(148, 151, 164)
local pink = Color3.fromRGB(255, 128, 38)
local dark = Color3.fromRGB(10, 11, 15)
local accentColor = pink
local selectedBackground = Color3.fromRGB(57, 19, 27)
local theme = "Halloween"
local animatedColors = true
local themeMarks = {}
local themeButtons = {}
local paintColors
local colorClock = 0
local panelColor = Color3.fromRGB(21, 22, 29)
local idleTabColor = Color3.fromRGB(16, 17, 23)

local function label(parent, text, position, size, fontSize, color)
    return make("TextLabel", parent, {
        BackgroundTransparency = 1,
        Text = text,
        Position = position,
        Size = size,
        Font = Enum.Font.GothamMedium,
        TextSize = fontSize,
        TextColor3 = color or white,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
end

local function button(parent, text, position, size)
    local object = make("TextButton", parent, {
        Position = position,
        Size = size,
        Text = text,
        TextColor3 = white,
        BackgroundColor3 = panelColor,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        TextSize = 15,
        AutoButtonColor = true,
    })
    round(object, 8)
    return object
end

local gui = make("ScreenGui", playerGui, {
    Name = "HzReyznInterface",
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
    DisplayOrder = 30,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

connect(gui.Destroying, function()
    if destroyed then return end
    destroyed = true

    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    table.clear(connections)
end)

local surface = make("Frame", gui, {
    ZIndex = 1,
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
})


-- Artwork only: this GUI never downloads or executes other scripts.
local function createHalloweenMedia(isAlive)
    local base = "https://raw.githubusercontent.com/hzReyzn/Ghislain/main/assets/halloween/"
    local specs = {
        background = {file="cemetery-background-v1.jpg", bytes=267109, signature="\255\216\255"},
        logo = {file="hz-logo-v1.jpg", bytes=514147, signature="\255\216\255"},
    }
    local resolved = {}
    local function valid(bytes, spec)
        local start = spec.offset or 1
        return type(bytes)=="string" and #bytes==spec.bytes
            and bytes:sub(start,start+#spec.signature-1)==spec.signature
    end
    return function(key)
        if not isAlive() then return "" end
        if resolved[key] then return resolved[key] end
        local spec = specs[key]
        local register = getcustomasset or getsynasset
        if not spec or type(register)~="function" or type(writefile)~="function" then return "" end
        local path = "HzReyzn_"..spec.file
        local exists = false
        if type(isfile)=="function" then
            local ok, found = pcall(isfile,path)
            exists = ok and found==true
        end
        if exists and type(readfile)=="function" then
            local ok, bytes = pcall(readfile,path)
            exists = ok and valid(bytes,spec)
        end
        if not exists then
            -- Bound the wait; a late HTTP response cannot write after cancellation.
            local pending, body, failed = true, nil, false
            task.spawn(function()
                local ok, data = pcall(function() return game:HttpGet(base..spec.file) end)
                if not pending or not isAlive() then return end
                if ok and valid(data,spec) then body=data else failed=true end
                pending=false
            end)
            local deadline=os.clock()+18
            while pending and isAlive() and os.clock()<deadline do task.wait(.05) end
            pending=false
            if failed or not body or not isAlive() then return "" end
            local ok=pcall(writefile,path,body)
            if not ok then return "" end
        end
        if not isAlive() then return "" end
        local ok, uri=pcall(register,path)
        if ok and type(uri)=="string" and uri~="" then resolved[key]=uri;return uri end
        return ""
    end
end

local media={logo="",background=""}
media.resolve=createHalloweenMedia(function() return not destroyed and gui.Parent~=nil end)

-- The supplied Halloween logo is reused in the header, launcher and theme preview.
local function themeLogo(host)
    host.ImageTransparency = 1
    local plate = make("Frame",host,{Name="ThemeLogo",Size=UDim2.fromScale(1,1),
        BackgroundColor3=dark,BackgroundTransparency=.12,BorderSizePixel=0})
    round(plate,12)
    local edge=make("UIStroke",plate,{Thickness=1.2,Transparency=.18,Color=white})
    local gradient=make("UIGradient",edge,{Rotation=25})
    local pumpkin=make("Frame",plate,{Name="Pumpkin",Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
    local lobes={}
    for _,x in ipairs({.12,.3,.48}) do
        local lobe=make("Frame",pumpkin,{Position=UDim2.fromScale(x,.23),Size=UDim2.fromScale(.4,.58),
            BackgroundColor3=accentColor,BackgroundTransparency=.77,BorderSizePixel=0})
        round(lobe,20);lobes[#lobes+1]=lobe
    end
    local stem=make("Frame",pumpkin,{Position=UDim2.fromScale(.49,.12),Size=UDim2.fromScale(.07,.16),
        Rotation=18,BackgroundColor3=accentColor,BorderSizePixel=0})
    local mark=label(plate,"HZ",UDim2.fromScale(.09,.12),UDim2.fromScale(.82,.78),24,white)
    mark.TextScaled=true;mark.Font=Enum.Font.GrenzeGotisch;mark.TextXAlignment=Enum.TextXAlignment.Center
    local ink=make("UIGradient",mark,{Rotation=90})
    local art=make("ImageLabel",host,{Name="HalloweenLogo",Size=UDim2.fromScale(1,1),
        BackgroundTransparency=1,Image=media.logo,ScaleType=Enum.ScaleType.Fit,Visible=false,ZIndex=2})
    round(art,12)
    local entry={plate=plate,edge=gradient,mark=mark,ink=ink,pumpkin=pumpkin,lobes=lobes,stem=stem,art=art}
    function entry:Update()
        -- Visibility must initiate loading, not depend on IsLoaded becoming true.
        -- Some local-asset clients never update IsLoaded: the artwork still renders
        -- above the native fallback, which remains behind it until confirmed ready.
        local show=theme=="Halloween" and self.art.Image~=""
        self.art.Visible=show
        self.plate.Visible=not (show and self.art.IsLoaded)
    end
    connect(art:GetPropertyChangedSignal("IsLoaded"),function() entry:Update() end)
    themeMarks[#themeMarks+1]=entry
    entry:Update()
end

-- Keep text and controls native: the persistent window is not a canvas texture.
local windowAnimating = false
local window = make("Frame", surface, {
    Name = "Window",
    Visible = false,
    Size = UDim2.fromOffset(760, 450),
    BackgroundColor3 = dark,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    ClipsDescendants = true,
})
round(window, 16)

local scale = make("UIScale", window, {Scale = 1})
local gradients = {}

local function gradientBorder(object, thickness, transparency)
    local stroke = make("UIStroke", object, {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = thickness,
        Transparency = transparency,
        Color = Color3.new(1, 1, 1),
    })
    local gradient = make("UIGradient", stroke, {})
    table.insert(gradients, gradient)
    return stroke
end

gradientBorder(window, 2, 0)

-- Native controls: black when off, illuminated by the selected theme when on.
local function controlPalette()
    if theme=="Halloween" then
        return Color3.fromRGB(255,125,32),Color3.fromRGB(126,50,186),Color3.fromRGB(255,221,168)
    elseif theme=="Crimson" then
        return Color3.fromRGB(250,35,60),Color3.fromRGB(130,12,34),Color3.fromRGB(211,215,224)
    elseif theme=="Ocean Theme" then
        return Color3.fromRGB(58,137,255),Color3.fromRGB(51,227,240),Color3.fromRGB(166,239,255)
    elseif theme=="Original" then
        return Color3.fromRGB(181,67,255),Color3.fromRGB(250,85,185),Color3.fromRGB(232,184,255)
    elseif theme=="Black / Grey / White" then
        return Color3.fromRGB(235,237,241),Color3.fromRGB(109,117,133),Color3.fromRGB(253,253,255)
    end
    return accentColor,Color3.fromHSV((colorClock+.3)%1,.8,1),Color3.fromHSV((colorClock+.65)%1,.75,1)
end
local function styleMotionToggle(target)
    target.Text = ""; target.BackgroundTransparency = 1; target.AutoButtonColor = false
    local track = make("Frame", target, {Name = "SwitchTrack", Position = UDim2.fromOffset(5, 5),
        Size = UDim2.fromOffset(68, 30), BackgroundColor3 = white, BorderSizePixel = 0})
    round(track, 15)
    local edge = make("UIStroke", track, {Color = accentColor, Thickness = 1, Transparency = .3})
    local fill = make("UIGradient", track, {Rotation = 18})
    local state = label(track, "OFF", UDim2.fromOffset(27, 0), UDim2.fromOffset(38, 30), 11, white)
    state.Name = "ControlState"; state.Font = Enum.Font.GothamBold; state.TextXAlignment = Enum.TextXAlignment.Center
    local knob = make("Frame", track, {Name = "SwitchKnob", Position = UDim2.fromOffset(4, 4),
        Size = UDim2.fromOffset(22, 22), BackgroundColor3 = white, BorderSizePixel = 0})
    round(knob, 11)
    make("UIGradient", knob, {Rotation = 90, Color = ColorSequence.new(white, Color3.fromRGB(190, 200, 220))})
    local blend = make("NumberValue", target, {Value = 0})
    local skin = {Active = false, Initialized = false}
    local animation
    function skin:Refresh()
        if destroyed or windowAnimating or not target.Parent then return end
        local a, b = controlPalette()
        local black = Color3.new(0, 0, 0)
        fill.Color = ColorSequence.new(black:Lerp(a, blend.Value * .46), black:Lerp(b, blend.Value * .34))
        edge.Color = muted:Lerp(a, blend.Value)
        edge.Transparency = .5 - blend.Value * .35
        knob.Position = UDim2.fromOffset(4 + 38 * blend.Value, 4)
        state.Text = self.Active and "ON" or "OFF"
        state.Position = UDim2.fromOffset(self.Active and 3 or 27, 0)
    end
    function skin:SetActive(on)
        on = on == true
        if self.Initialized and self.Active == on then self:Refresh(); return end
        local animate = self.Initialized
        self.Initialized = true; self.Active = on
        if animation then animation:Cancel() end
        if animate then
            animation = TweenService:Create(blend, TweenInfo.new(.26, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Value = on and 1 or 0})
            animation:Play()
        else blend.Value = on and 1 or 0 end
        self:Refresh()
    end
    connect(blend.Changed, function() skin:Refresh() end)
    connect(target.Destroying, function() if animation then animation:Cancel() end end)
    return skin
end

local design={leds={},inward={},embers={},clock=0}
do
    local backdrop=make("Frame",window,{Name="HalloweenBackdrop",Size=UDim2.fromScale(1,1),
        BackgroundTransparency=1,ClipsDescendants=true,ZIndex=0})
    round(backdrop,16)
    design.backdrop=backdrop
    design.art=make("ImageLabel",backdrop,{Name="CemeteryArtwork",Position=UDim2.fromOffset(-12,-8),
        Size=UDim2.new(1,24,1,16),Image="",BackgroundTransparency=1,ImageTransparency=.14,
        ScaleType=Enum.ScaleType.Crop,ZIndex=0})
    local veil=make("Frame",backdrop,{Name="ReadabilityVeil",Size=UDim2.fromScale(1,1),
        BackgroundColor3=Color3.fromRGB(10,7,5),BackgroundTransparency=.25,BorderSizePixel=0,ZIndex=1})
    make("UIGradient",veil,{Rotation=90,Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,.15),NumberSequenceKeypoint.new(.32,.5),
        NumberSequenceKeypoint.new(.7,.55),NumberSequenceKeypoint.new(1,.25)})})
    local sweep=make("Frame",backdrop,{Name="AmberReflection",Position=UDim2.fromScale(-.5,0),
        Size=UDim2.fromScale(.6,1),BackgroundColor3=Color3.fromRGB(255,155,62),
        BackgroundTransparency=.94,BorderSizePixel=0,ZIndex=2})
    make("UIGradient",sweep,{Rotation=18,Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(1,1)})})
    design.sweep=sweep
    for i=1,12 do
        local dot=make("Frame",backdrop,{Name="Ember"..i,Size=UDim2.fromOffset(i%3==0 and 3 or 2,i%3==0 and 3 or 2),
            BackgroundColor3=Color3.fromRGB(255,171+i*4,80),BackgroundTransparency=.7,
            BorderSizePixel=0,ZIndex=3})
        round(dot,3)
        design.embers[i]={dot=dot,x=((i*61)%720)+20,phase=i*.618,speed=9+(i%4)*3}
    end
end
do
    local inset=make("Frame",window,{Position=UDim2.fromOffset(6,6),Size=UDim2.new(1,-12,1,-12),
        BackgroundTransparency=1,BorderSizePixel=0,ZIndex=0})
    round(inset,12)
    make("UIStroke",inset,{Thickness=1,Color=Color3.fromRGB(123,129,142),Transparency=.65})
    for _,edge in ipairs({{7,96,2,74},{751,279,2,96}}) do
        local glow=make("Frame",window,{Position=UDim2.fromOffset(edge[1]-2,edge[2]),
            Size=UDim2.fromOffset(6,edge[4]),BackgroundColor3=accentColor,BackgroundTransparency=.9,BorderSizePixel=0})
        round(glow,3)
        local led=make("Frame",window,{Position=UDim2.fromOffset(edge[1],edge[2]),
            Size=UDim2.fromOffset(edge[3],edge[4]),BackgroundColor3=accentColor,BorderSizePixel=0})
        round(led,1);design.leds[#design.leds+1]={core=led,glow=glow,mix=0}
    end
    for _,data in ipairs({
        {UDim2.fromScale(0,0),UDim2.new(1,0,0,38),90},
        {UDim2.new(0,0,1,-38),UDim2.new(1,0,0,38),270},
        {UDim2.fromScale(0,0),UDim2.new(0,28,1,0),0},
        {UDim2.new(1,-28,0,0),UDim2.new(0,28,1,0),180},
    }) do
        local glow=make("Frame",window,{Name="InwardNeon",Position=data[1],Size=data[2],
            BackgroundColor3=accentColor,BackgroundTransparency=.89,BorderSizePixel=0,ZIndex=0})
        make("UIGradient",glow,{Rotation=data[3],Transparency=NumberSequence.new({
            NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.3,.65),NumberSequenceKeypoint.new(1,1)})})
        design.inward[#design.inward+1]=glow
    end
    design.footer=label(window,"Made By hzReyzn",UDim2.fromOffset(204,427),UDim2.fromOffset(300,14),10,muted)
    design.footer.TextXAlignment=Enum.TextXAlignment.Right
    design.footer.Size=UDim2.fromOffset(530,14)
end

local accent = make("Frame", window, {
    Position = UDim2.fromOffset(20, 0),
    Size = UDim2.new(1, -40, 0, 3),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BorderSizePixel = 0,
})
local accentGradient = make("UIGradient", accent, {})

local header = make("Frame", window, {
    Size = UDim2.new(1, 0, 0, 64),
    BackgroundTransparency = 1,
})
for i=0,4 do
    local led=make("Frame",header,{Position=UDim2.fromOffset(490+i*14,31),Size=UDim2.fromOffset(9,2),
        BackgroundColor3=white,BorderSizePixel=0})
    design.leds[#design.leds+1]={core=led,mix=(i%3)/2}
end

local logo=make("ImageLabel",header,{
    Name="HeaderLogo",Position=UDim2.fromOffset(20,9),Size=UDim2.fromOffset(46,46),
    BackgroundTransparency=1,Image="rbxassetid://115928147610604",ScaleType=Enum.ScaleType.Fit,
})
themeLogo(logo)
local hubTitle=label(header,"HzReyzn Hub",UDim2.fromOffset(78,19),UDim2.fromOffset(360,27),21,white)
hubTitle.Font=Enum.Font.GothamBold
design.titleInk=make("UIGradient",hubTitle,{Name="TitleReflection",Rotation=15})
design.divider=make("Frame",header,{Position=UDim2.fromOffset(20,63),Size=UDim2.new(1,-40,0,1),BackgroundColor3=muted,BackgroundTransparency=.5,BorderSizePixel=0})

local minimize = button(
    header, "−", UDim2.new(1, -104, 0, 14),
    UDim2.fromOffset(36, 36)
)
local close = button(
    header, "×", UDim2.new(1, -56, 0, 14),
    UDim2.fromOffset(36, 36)
)
minimize.Name = "Minimize"
close.Name = "Close"
close.TextSize = 24

local dragArea = make("Frame", header, {
    Name = "DragArea",
    Size = UDim2.new(1, -125, 1, 0),
    BackgroundTransparency = 1,
    Active = true,
})

local body = make("Frame", window, {
    Position = UDim2.fromOffset(0, 64),
    Size = UDim2.fromOffset(760, 386),
    BackgroundTransparency = 1,
})

local sidebar = make("Frame", body, {
    Position = UDim2.fromOffset(16, 10),
    Size = UDim2.fromOffset(164, 354),
    BackgroundColor3 = idleTabColor,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
})
round(sidebar, 15)

label(
    sidebar, "OPTIONS", UDim2.fromOffset(16, 9),
    UDim2.fromOffset(120, 20), 11, muted
)
local refreshProfile = function() end
do
    local card=make("Frame",sidebar,{
        Name="LocalPlayerProfile",Position=UDim2.fromOffset(8,309),
        Size=UDim2.fromOffset(148,38),BackgroundColor3=panelColor,
        BackgroundTransparency=0.15,BorderSizePixel=0,
    })
    round(card,10)
    local avatar=make("ImageLabel",card,{
        Name="Avatar",Position=UDim2.fromOffset(4,4),Size=UDim2.fromOffset(30,30),
        BackgroundColor3=selectedBackground,BorderSizePixel=0,
        Image="",ScaleType=Enum.ScaleType.Fit,
    })
    round(avatar,15)
    local edge=make("UIStroke",avatar,{Thickness=1,Color=accentColor,Transparency=0.2})
    local name=label(card,player.DisplayName,UDim2.fromOffset(40,3),UDim2.fromOffset(100,17),12,white)
    name.Font=Enum.Font.GothamBold
    name.TextTruncate=Enum.TextTruncate.AtEnd
    local id=label(card,"ID: "..tostring(player.UserId),UDim2.fromOffset(40,21),UDim2.fromOffset(100,12),9,muted)
    refreshProfile=function()
        card.BackgroundColor3=panelColor
        avatar.BackgroundColor3=selectedBackground
        edge.Color=accentColor
        id.TextColor3=muted
    end
    connect(player:GetPropertyChangedSignal("DisplayName"),function()
        name.Text=player.DisplayName
    end)
    task.defer(function()
        for attempt=1,3 do
            if destroyed or not avatar.Parent then return end
            local ok,url,ready=pcall(function()
                return Players:GetUserThumbnailAsync(player.UserId,
                    Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)
            end)
            if destroyed or not avatar.Parent then return end
            if ok and ready and type(url)=="string" and url~="" then
                avatar.Image=url
                return
            end
            if attempt<3 then task.wait(1) end
        end
    end)
end

local content = make("Frame", body, {
    Position = UDim2.fromOffset(200, 10),
    Size = UDim2.fromOffset(538, 354),
    BackgroundTransparency = 1,
})

local eyebrow = label(
    content, "MAIN", UDim2.fromOffset(0, 4),
    UDim2.fromOffset(530, 20), 11, pink
)
local title = label(
    content, "More Features soon", UDim2.fromOffset(0, 32),
    UDim2.fromOffset(530, 34), 25
)
title.Font = Enum.Font.GothamBold

local description = label(
    content, "", UDim2.fromOffset(0, 72),
    UDim2.fromOffset(530, 25), 12, muted
)

local function scrollingPage(name)
    local scroll = make("ScrollingFrame", content, {
        Name = name,
        Position = UDim2.fromOffset(0, 105),
        Size = UDim2.fromOffset(538, 241),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = pink,
        ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
        ClipsDescendants = true,
        Active = true,
        Visible = false,
    })

    make("UIPadding", scroll, {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 3),
        PaddingRight = UDim.new(0, 12),
    })
    make("UIListLayout", scroll, {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 12),
    })
    return scroll
end

local mainScroll = scrollingPage("ShadersScroll")
local ndsScroll = scrollingPage("NDSScroll")
ndsScroll.Position = UDim2.fromOffset(0, 78)
ndsScroll.Size = UDim2.fromOffset(538, 264)
local othersScroll = scrollingPage("OthersScriptsScroll")
local serverScroll = scrollingPage("ServerScroll")
serverScroll.Position=UDim2.fromOffset(0,78)
serverScroll.Size=UDim2.fromOffset(538,264)
local changelogScroll = scrollingPage("ChangelogScroll")
changelogScroll.Position=UDim2.fromOffset(0,78)
changelogScroll.Size=UDim2.fromOffset(500,230)

local settingsPage = make("Frame", content, {
    Name = "SettingsPage",
    Position = UDim2.fromOffset(0, 94),
    Size = UDim2.fromOffset(538, 250),
    BackgroundTransparency = 1,
    Visible = false,
})

-- Empty pages are reserved for the next development phase.
local emptyLabels = {}
for _, page in ipairs({mainScroll, ndsScroll, othersScroll, serverScroll, changelogScroll}) do
    local empty = label(page, "Nothing here yet.", UDim2.fromOffset(0, 0), UDim2.new(1, -16, 0, 44), 14, muted)
    empty.Name = "EmptyPage"; empty.LayoutOrder = 1
    emptyLabels[#emptyLabels + 1] = empty
end

local refreshSettings=function() end
local closeThemes=function() end
local colorButton
local themeDisplay={Halloween="Halloween",Crimson="Crimson",Original="Original",["Black / Grey / White"]="Monochrome",RGB="RGB",["Ocean Theme"]="Ocean"}
do
    local function settingCard(y,titleText,detail)
        local card=make("Frame",settingsPage,{Position=UDim2.fromOffset(0,y),Size=UDim2.fromOffset(526,74),
            BackgroundColor3=panelColor,BorderSizePixel=0})
        round(card,10);gradientBorder(card,1,.4)
        local title=label(card,titleText,UDim2.fromOffset(16,13),UDim2.fromOffset(225,24),14,white)
        title.Font=Enum.Font.GothamBold
        local hint=label(card,detail,UDim2.fromOffset(16,40),UDim2.fromOffset(248,18),11,muted)
        return card,hint
    end
    local themeCard,themeHint=settingCard(0,"Theme","Choose your interface colors.")
    local picker=button(themeCard,"Halloween   +",UDim2.fromOffset(280,17),UDim2.fromOffset(228,40))
    picker.Name="ThemePicker";picker.TextSize=13
    local motionCard,motionHint=settingCard(88,"Animated accents","Ambient motion, lights and reflections.")
    colorButton=button(motionCard,"ON",UDim2.fromOffset(430,17),UDim2.fromOffset(78,40))
    colorButton.Name="AnimatedAccents"
    local motionSkin=styleMotionToggle(colorButton)
    local preview=make("Frame",settingsPage,{Position=UDim2.fromOffset(0,176),Size=UDim2.fromOffset(526,61),
        BackgroundColor3=panelColor,BorderSizePixel=0})
    round(preview,10)
    local previewLogo=make("ImageLabel",preview,{Position=UDim2.fromOffset(12,9),Size=UDim2.fromOffset(43,43),BackgroundTransparency=1,
        Image="rbxassetid://115928147610604",ScaleType=Enum.ScaleType.Fit})
    themeLogo(previewLogo)
    local previewTitle=label(preview,"HzReyzn Hub",UDim2.fromOffset(68,11),UDim2.fromOffset(260,22),14,white)
    previewTitle.Font=Enum.Font.GothamBold
    local previewText=label(preview,"Halloween",UDim2.fromOffset(68,34),UDim2.fromOffset(320,15),10,accentColor)
    local outside=make("TextButton",window,{Name="ThemeDismiss",Size=UDim2.fromScale(1,1),Text="",
        BackgroundTransparency=1,Visible=false,AutoButtonColor=false,ZIndex=20})
    local menu=make("Frame",window,{Name="ThemeMenu",Position=UDim2.fromOffset(472,190),
        Size=UDim2.fromOffset(264,242),BackgroundColor3=dark,BorderSizePixel=0,Visible=false,
        ZIndex=21,ClipsDescendants=true})
    round(menu,12);local menuEdge=gradientBorder(menu,1.3,.15)
    label(menu,"SELECT THEME",UDim2.fromOffset(14,8),UDim2.fromOffset(230,20),9,muted)
    local menuOpen,menuTween=false,nil
    local function setOpen(on)
        menuOpen=on
        if menuTween then menuTween:Cancel() end
        outside.Visible=on
        if on then
            menu.Visible=true;menu.Position=UDim2.fromOffset(472,182);menu.Size=UDim2.fromOffset(264,0)
            menuTween=TweenService:Create(menu,TweenInfo.new(.18,Enum.EasingStyle.Quart),
                {Position=UDim2.fromOffset(472,190),Size=UDim2.fromOffset(264,242)})
        else
            menuTween=TweenService:Create(menu,TweenInfo.new(.12),{Position=UDim2.fromOffset(472,182),Size=UDim2.fromOffset(264,0)})
            task.delay(.12,function() if not destroyed and not menuOpen then menu.Visible=false end end)
        end
        menuTween:Play()
        picker.Text=(themeDisplay[theme] or theme)..(on and "   −" or "   +")
    end
    closeThemes=function() if menuOpen then setOpen(false) end end
    connect(picker.Activated,function() setOpen(not menuOpen) end)
    connect(outside.Activated,closeThemes)
    local options={
        {"Halloween",Color3.fromRGB(255,128,38)},
        {"Crimson",Color3.fromRGB(242,28,52)},
        {"Black / Grey / White",Color3.fromRGB(216,218,225)},
        {"Ocean Theme",Color3.fromRGB(55,193,244)},
        {"Original",Color3.fromRGB(207,120,252)},
        {"RGB",Color3.fromRGB(91,235,171)},
    }
    for index,option in ipairs(options) do
        local name=option[1]
        local choice=button(menu,themeDisplay[name],UDim2.fromOffset(8,31+(index-1)*33),UDim2.fromOffset(248,29))
        choice.Name="Theme_"..name;choice.TextSize=12;choice.TextXAlignment=Enum.TextXAlignment.Left
        make("UIPadding",choice,{PaddingLeft=UDim.new(0,34)})
        local swatch=make("Frame",choice,{Position=UDim2.fromOffset(-22,9),Size=UDim2.fromOffset(11,11),
            BackgroundColor3=option[2],BorderSizePixel=0});round(swatch,4)
        local edge=make("UIStroke",choice,{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Color=option[2],Thickness=1,Transparency=.7})
        themeButtons[name]={button=choice,edge=edge}
        connect(choice.Activated,function()
            theme=name
            if paintColors then paintColors(colorClock) end
            setOpen(false)
        end)
    end
    connect(colorButton.Activated,function()
        animatedColors=not animatedColors
        if paintColors then paintColors(colorClock) end
    end)
    refreshSettings=function()
        for _,card in ipairs({themeCard,motionCard,preview}) do
            card.BackgroundColor3=panelColor;card.BackgroundTransparency=theme=="Halloween" and .2 or 0
        end
        themeHint.TextColor3=muted;motionHint.TextColor3=muted
        picker.BackgroundColor3=selectedBackground;picker.TextColor3=white
        picker.Text=(themeDisplay[theme] or theme)..(menuOpen and "   −" or "   +")
        previewText.Text=themeDisplay[theme] or theme;previewText.TextColor3=accentColor
        menu.BackgroundColor3=dark
        motionSkin:SetActive(animatedColors)
    end
end

local tabs = {}
local tabMarks={}
local selectedTab = 1
local pages = {
    {"Shaders", "VISUALS", "Shaders", ""},
    {"NDS", "NDS", "Natural Disaster", ""},
    {"Other scripts", "NOT MINE", "Other scripts", ""},
    {"Server", "SERVER", "Server", ""},
    {"Settings", "SETTINGS", "Appearance", ""},
    {"CHANGELOG", "CHANGELOG", "Changelog", ""},
}

local function selectTab(index)
    if destroyed or windowAnimating then return end
    closeThemes()
    if design.pageTween then design.pageTween:Cancel() end
    content.Position=UDim2.fromOffset(200,18)
    design.pageTween=TweenService:Create(content,TweenInfo.new(.28,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),
        {Position=UDim2.fromOffset(200,10)})
    design.pageTween:Play()
    selectedTab = index
    mainScroll.Visible = index == 1
    ndsScroll.Visible = index == 2
    othersScroll.Visible = index == 3
    serverScroll.Visible = index == 4
    settingsPage.Visible = index == 5
    changelogScroll.Visible = index == 6

    for i, tab in ipairs(tabs) do
        tab.BackgroundColor3 = i == index
            and selectedBackground or idleTabColor
        tab.TextColor3 = i == index and white or muted
        tab.BackgroundTransparency=theme=="Halloween" and (i==index and .12 or .62) or 0
        if tabMarks[i] then tabMarks[i].Visible=i==index end
    end

    local page = pages[index]
    eyebrow.Text = page[2]
    title.Text = page[3]
    description.Text = page[4]
    description.Visible = page[4] ~= ""
    title.TextSize = index == 6 and 22 or index == 5 and 23 or 25
    local top = index == 1 and 78 or 105
    mainScroll.Position = UDim2.fromOffset(0, top)
    mainScroll.Size = UDim2.fromOffset(538, 342 - top)
end

for index, page in ipairs(pages) do
    local tab = button(
        sidebar, page[1],
        UDim2.fromOffset(10, 39 + (index - 1) * 44),
        UDim2.fromOffset(144, 38)
    )
    tab.Name = "Tab_" .. index
    if index == 3 then tab.TextSize = 13 end
    tab.TextXAlignment=Enum.TextXAlignment.Left;tab.Font=Enum.Font.GothamBold;tab.TextSize=13
    make("UIPadding",tab,{PaddingLeft=UDim.new(0,16)})
    tabMarks[index]=make("Frame",tab,{Position=UDim2.fromOffset(-16,9),Size=UDim2.fromOffset(3,20),
        BackgroundColor3=accentColor,BorderSizePixel=0,Visible=index==1})
    round(tabMarks[index],2)
    tabs[index] = tab
    connect(tab.Activated, function() selectTab(index) end)
end

selectTab(1)
-- Logo HZ, animación de colores y movimiento.

local launcher = button(
    surface, "HZ", UDim2.fromOffset(24, 100),
    UDim2.fromOffset(58, 58)
)
launcher.Name = "HZLauncher"
launcher.Visible = false
launcher.AutoButtonColor = false
launcher.Font = Enum.Font.GothamBold
launcher.TextSize = 21
launcher.ZIndex = 5
launcher.BackgroundTransparency = 0.08

gradientBorder(launcher, 2.2, 0.06)
launcher.Text=""
do
    local image=make("ImageLabel",launcher,{
        Name="LauncherLogo",Position=UDim2.fromOffset(2,2),Size=UDim2.new(1,-4,1,-4),
        BackgroundTransparency=1,BorderSizePixel=0,ZIndex=6,
        Image="rbxassetid://115928147610604",ImageColor3=Color3.new(1,1,1),
        ScaleType=Enum.ScaleType.Fit,Active=false,
    })
    round(image,10)
    themeLogo(image)
end

local COLOR_CYCLE_SECONDS = 10
local TAU = math.pi * 2
local neutral = Color3.new(1, 1, 1)
local function paletteColor(phase)
    if theme == "Halloween" then
        local colors={Color3.fromRGB(255,123,32),Color3.fromRGB(255,178,70),Color3.fromRGB(167,77,241)}
        local pos=(phase%1)*#colors;local i=math.floor(pos)
        return colors[i+1]:Lerp(colors[(i+1)%#colors+1],pos-i)
    elseif theme == "Crimson" then
        local pulse=.5+.5*math.sin(phase*TAU)
        return Color3.fromRGB(220,18,38):Lerp(Color3.fromRGB(255,48,58),pulse)
    elseif theme == "Black / Grey / White" then
        local value = 0.42 + 0.58 * (0.5 + 0.5 * math.sin(phase * TAU))
        return Color3.new(value, value, value)
    elseif theme == "Ocean Theme" then
        local ocean = {
            Color3.fromRGB(115, 205, 255),
            Color3.fromRGB(18, 55, 125),
            Color3.fromRGB(35, 235, 220),
        }
        local position = (phase % 1) * #ocean
        local index = math.floor(position)
        return ocean[index + 1]:Lerp(ocean[(index + 1) % #ocean + 1], position - index)
    elseif theme == "RGB" then
        return Color3.fromHSV(phase % 1, 0.85, 1)
    end
    local hue = (0.90 + 0.18 * math.sin(phase * TAU)) % 1

    return Color3.fromHSV(
        hue,
        0.72 + 0.06 * math.cos(phase * TAU),
        1
    )
end

paintColors = function(phase)
    dark = theme == "Original" and Color3.fromRGB(12, 9, 18)
        or Color3.fromRGB(10, 10, 12)
    if theme == "Black / Grey / White" then dark = Color3.fromRGB(10, 10, 10) end
    muted = theme == "Original" and Color3.fromRGB(159, 146, 175)
        or Color3.fromRGB(175, 175, 175)
    panelColor = theme == "Original" and Color3.fromRGB(31, 23, 40)
        or Color3.fromRGB(28, 28, 28)
    idleTabColor = theme == "Original" and Color3.fromRGB(27, 20, 35)
        or Color3.fromRGB(23, 23, 23)
    if theme == "Ocean Theme" then
        dark = Color3.fromRGB(5, 15, 35)
        panelColor = Color3.fromRGB(12, 32, 61)
        idleTabColor = Color3.fromRGB(9, 25, 48)
        muted = Color3.fromRGB(166, 204, 227)
    end
    if theme=="Crimson" then
        dark=Color3.fromRGB(8,9,12);panelColor=Color3.fromRGB(30,32,38)
        idleTabColor=Color3.fromRGB(20,22,27);muted=Color3.fromRGB(187,191,202)
    end
    if theme=="Halloween" then
        dark=Color3.fromRGB(12,8,6);panelColor=Color3.fromRGB(29,19,15)
        idleTabColor=Color3.fromRGB(23,15,12);muted=Color3.fromRGB(210,182,157)
    end
    local a = paletteColor(phase)
    local b = paletteColor(phase + 0.25)
    local c = paletteColor(phase + 0.5)

    local sequence = ColorSequence.new({
        ColorSequenceKeypoint.new(0, a),
        ColorSequenceKeypoint.new(0.25, paletteColor(phase + 0.125)),
        ColorSequenceKeypoint.new(0.5, b),
        ColorSequenceKeypoint.new(0.75, paletteColor(phase + 0.375)),
        ColorSequenceKeypoint.new(1, c),
    })

    if theme == "Crimson" then
        sequence=ColorSequence.new({
            ColorSequenceKeypoint.new(0,a),
            ColorSequenceKeypoint.new(.24,Color3.fromRGB(255,35,51)),
            ColorSequenceKeypoint.new(.42,Color3.fromRGB(128,136,151)),
            ColorSequenceKeypoint.new(.52,white),
            ColorSequenceKeypoint.new(.66,b),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(155,12,29)),
        })
    elseif theme == "Black / Grey / White" then
        sequence = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(65, 65, 65)),
            ColorSequenceKeypoint.new(0.25, Color3.fromRGB(170, 170, 170)),
            ColorSequenceKeypoint.new(0.5, neutral),
            ColorSequenceKeypoint.new(0.75, Color3.fromRGB(170, 170, 170)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(65, 65, 65)),
        })
    end
    for _, gradient in ipairs(gradients) do
        gradient.Color = sequence
        gradient.Rotation = 25 + phase * 360
    end

    accentGradient.Color = sequence
    accentColor = a:Lerp(neutral, 0.16)
    selectedBackground = dark:Lerp(a, 0.32)
    if theme == "Crimson" then
        accentColor=a:Lerp(white,.04)
        selectedBackground=dark:Lerp(a,.42)
    elseif theme == "Black / Grey / White" then
        accentColor = neutral
    elseif theme == "Ocean Theme" then
        accentColor = a:Lerp(neutral, 0.40)
    end

    if theme=="Halloween" then accentColor=Color3.fromRGB(255,145,55) end
    gui:SetAttribute("Theme",theme)
    gui:SetAttribute("AccentColor",accentColor)
    gui:SetAttribute("PanelColor",panelColor)
    gui:SetAttribute("SecondaryColor",theme=="Halloween" and Color3.fromRGB(165,74,228) or b)
    for _,mark in ipairs(themeMarks) do
        mark:Update()
        mark.plate.BackgroundColor3=dark
        mark.edge.Color=sequence
        mark.ink.Color=ColorSequence.new(white,accentColor)
        mark.mark.Font=theme=="Halloween" and Enum.Font.GrenzeGotisch or Enum.Font.GothamBlack
        mark.pumpkin.Visible=theme=="Halloween"
        mark.stem.BackgroundColor3=accentColor
        for _,lobe in ipairs(mark.lobes) do lobe.BackgroundColor3=accentColor end
    end
    for i,glow in ipairs(design.inward) do
        glow.BackgroundColor3=i%2==0 and b or accentColor
        glow.BackgroundTransparency=.89+(animatedColors and math.sin(phase*TAU+i)*.025 or 0)
    end
    design.backdrop.Visible=theme=="Halloween"
    design.titleInk.Color=theme=="Halloween" and ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(255,178,94)),ColorSequenceKeypoint.new(.45,white),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(255,178,94))}) or ColorSequence.new(white,white)
    hubTitle.Font=theme=="Halloween" and Enum.Font.GrenzeGotisch or Enum.Font.GothamBold
    hubTitle.TextColor3=theme=="Halloween" and Color3.fromRGB(255,218,173) or white
    window.BackgroundColor3 = dark:Lerp(b, 0.018)
    sidebar.BackgroundColor3 = theme=="Crimson" and Color3.fromRGB(16,17,21) or dark:Lerp(c,0.04)
    sidebar.BackgroundTransparency=theme=="Halloween" and .22 or 0
    header.BackgroundColor3=dark;header.BackgroundTransparency=theme=="Halloween" and .4 or 1

    design.divider.BackgroundColor3=accentColor;design.footer.TextColor3=muted
    for _,entry in ipairs(design.leds) do
        entry.core.BackgroundColor3=accentColor:Lerp(white,entry.mix)
        if entry.glow then entry.glow.BackgroundColor3=accentColor end
    end
    for _,mark in ipairs(tabMarks) do mark.BackgroundColor3=accentColor:Lerp(white,.6) end
    close.TextColor3 = accentColor
    eyebrow.TextColor3 = accentColor
    colorButton.TextColor3 = accentColor

    launcher.BackgroundColor3 = dark:Lerp(b, 0.16)
    launcher.TextColor3 = a:Lerp(neutral, 0.25)

    mainScroll.ScrollBarImageColor3 = accentColor
    othersScroll.ScrollBarImageColor3 = accentColor
    ndsScroll.ScrollBarImageColor3 = accentColor
    refreshProfile()
    refreshSettings()
    for _, empty in ipairs(emptyLabels) do empty.TextColor3 = muted end
    changelogScroll.ScrollBarImageColor3=accentColor
    serverScroll.ScrollBarImageColor3=accentColor

    minimize.BackgroundColor3 = panelColor
    close.BackgroundColor3 = panelColor
    description.TextColor3 = muted
    for index, tab in ipairs(tabs) do
        tab.TextColor3 = index == selectedTab and white or muted
        tab.BackgroundTransparency=theme=="Halloween" and (index==selectedTab and .12 or .62) or 0
        tab.BackgroundColor3 = index == selectedTab
            and selectedBackground or idleTabColor
    end
    for name, entry in pairs(themeButtons) do
        local active = name == theme
        entry.button.BackgroundColor3 = active and selectedBackground or panelColor
        entry.button.TextColor3 = active and accentColor or white
        entry.edge.Color = active and accentColor or muted
        entry.edge.Transparency = active and 0.05 or 0.7
        entry.edge.Thickness = active and 2 or 1
    end

end

paintColors(0)

-- Motion runs every rendered frame; full theme painting runs only on theme changes
-- for Halloween. Avoid hundreds of property/attribute writes every animation frame.
local paletteElapsed=0
connect(RunService.RenderStepped, function(dt)
    if not animatedColors or windowAnimating or (not window.Visible and not launcher.Visible) then return end
    dt=math.min(dt,.1)
    design.clock=design.clock+dt
    colorClock=(colorClock+dt/COLOR_CYCLE_SECONDS)%1
    paletteElapsed=paletteElapsed+dt
    if theme~="Halloween" and paletteElapsed>=.15 then
        paletteElapsed=0;paintColors(colorClock)
    end
    local t=design.clock
    for _,gradient in ipairs(gradients) do
        gradient.Rotation=25+math.sin(t*.25)*32
        gradient.Offset=Vector2.new(math.sin(t*.38)*.28,0)
    end
    accentGradient.Offset=Vector2.new(math.sin(t*.4)*.5,0)
    if theme=="Halloween" and window.Visible then
        design.art.Position=UDim2.fromOffset(-12+math.sin(t*.2)*4,-8+math.cos(t*.17)*3)
        design.sweep.Position=UDim2.fromScale((t*.08)%1.8-.6,0)
        design.titleInk.Offset=Vector2.new(math.sin(t*.45)*.38,0)
        for i,glow in ipairs(design.inward) do
            glow.BackgroundTransparency=.84+math.sin(t*.8+i)*.045
        end
        for _,ember in ipairs(design.embers) do
            local progress=(t*ember.speed+ember.phase*450)%480
            ember.dot.Position=UDim2.fromOffset(ember.x+math.sin(t*.6+ember.phase)*13,460-progress)
            ember.dot.BackgroundTransparency=1-math.sin(math.clamp(progress/480,0,1)*math.pi)*.65
        end
        for i,entry in ipairs(design.leds) do
            entry.core.BackgroundTransparency=.12+(.5+.5*math.sin(t*1.4+i))*.38
        end
    end
end)

-- Load GUI artwork in the background; the window opens immediately.
task.spawn(function()
    media.background=media.resolve("background")
    if destroyed then return end
    design.art.Image=media.background
    pcall(function() game:GetService("ContentProvider"):PreloadAsync({design.art}) end)
end)
task.spawn(function()
    media.logo=media.resolve("logo")
    if destroyed then return end
    local images={}
    for _,mark in ipairs(themeMarks) do
        mark.art.Image=media.logo;mark:Update();images[#images+1]=mark.art
    end
    pcall(function() game:GetService("ContentProvider"):PreloadAsync(images) end)
end)

local minimized = false
local launcherPlaced = false

local function clampLauncher(x, y)
    local bounds = surface.AbsoluteSize

    launcher.Position = UDim2.fromOffset(
        math.clamp(x, 6, math.max(6, bounds.X - 64)),
        math.clamp(y, 6, math.max(6, bounds.Y - 64))
    )
end

local function clampWindow(x, y)
    if windowAnimating then return end
    local bounds = surface.AbsoluteSize

    window.Position = UDim2.fromOffset(
        math.floor(math.clamp(x, 0, math.max(0, bounds.X - 760 * scale.Scale))+.5),
        math.floor(math.clamp(y, 0, math.max(0, bounds.Y - 450 * scale.Scale))+.5)
    )
end

local function resize(center)
    if windowAnimating then return end
    local bounds = surface.AbsoluteSize
    if bounds.X < 1 or bounds.Y < 1 then return end

    scale.Scale = math.max(0.05, math.min(
        1,
        (bounds.X - 20) / 760,
        (bounds.Y - 20) / 450
    ))

    if center then
        clampWindow(
            (bounds.X - 760 * scale.Scale) / 2,
            (bounds.Y - 450 * scale.Scale) / 2
        )
    else
        clampWindow(
            window.Position.X.Offset,
            window.Position.Y.Offset
        )
    end

    clampLauncher(
        launcher.Position.X.Offset,
        launcher.Position.Y.Offset
    )
end

local launcherScale=make("UIScale",launcher,{Scale=1})
local transitionShield=make("TextButton",window,{Name="TransitionShield",Size=UDim2.fromScale(1,1),
    BackgroundTransparency=1,Text="",Visible=false,Active=true,AutoButtonColor=false,ZIndex=90})
-- A short local bloom. No Lighting effects or scene-wide flash is used.
local function neonFlash(target)
    local position=target.AbsolutePosition-surface.AbsolutePosition
    local size=target.AbsoluteSize
    local fx=make("CanvasGroup",surface,{Name="ThemeFlash",Position=UDim2.fromOffset(position.X-14,position.Y-14),
        Size=UDim2.fromOffset(size.X+28,size.Y+28),BackgroundTransparency=1,ZIndex=80,GroupTransparency=0})
    local hot=accentColor
    for i=1,3 do
        local ring=make("Frame",fx,{Position=UDim2.fromOffset(14-i*2,14-i*2),
            Size=UDim2.new(1,-28+i*4,1,-28+i*4),BackgroundTransparency=1})
        round(ring,16+i*2)
        local edge=make("UIStroke",ring,{Thickness=i==1 and 2 or 5,Transparency=i==1 and .06 or .8,Color=white})
        make("UIGradient",edge,{Rotation=20,Color=ColorSequence.new(hot,hot:Lerp(white,.6))})
        TweenService:Create(ring,TweenInfo.new(.58,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
            Position=UDim2.fromOffset(3-i*2,3-i*2),Size=UDim2.new(1,-6+i*4,1,-6+i*4)}):Play()
    end
    local ray=make("Frame",fx,{Position=UDim2.new(.12,0,0,13),Size=UDim2.new(.76,0,0,3),
        BackgroundColor3=hot:Lerp(white,.55),BorderSizePixel=0})
    make("UIGradient",ray,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),
        NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(1,1)})})
    TweenService:Create(fx,TweenInfo.new(.6,Enum.EasingStyle.Sine,Enum.EasingDirection.In),{GroupTransparency=1}):Play()
    task.delay(.62,function() if fx.Parent then fx:Destroy() end end)
end
local function toggleMinimize()
    if windowAnimating or destroyed then return end
    closeThemes()
    neonFlash(minimized and launcher or window)
    windowAnimating=true
    transitionShield.Visible=true
    local home=window.Position
    local duration=.42
    local easing=TweenInfo.new(duration,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
    local restingScale=scale.Scale
    local closing=not minimized
    if closing and not launcherPlaced then
        clampLauncher(home.X.Offset,home.Y.Offset)
        launcherPlaced=true
    end
    -- Fade individual native properties; no low-resolution canvas is created.
    local opacity={}
    local function capture(object,property)
        opacity[#opacity+1]={object=object,property=property,base=object[property]}
    end
    local objects=window:GetDescendants()
    objects[#objects+1]=window
    for _,object in ipairs(objects) do
        if object:IsA("GuiObject") then capture(object,"BackgroundTransparency") end
        if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
            capture(object,"TextTransparency")
        elseif object:IsA("ImageLabel") or object:IsA("ImageButton") then
            capture(object,"ImageTransparency")
        elseif object:IsA("UIStroke") then capture(object,"Transparency") end
        if object:IsA("ScrollingFrame") then capture(object,"ScrollBarImageTransparency") end
    end
    local fade=make("NumberValue",window,{Name="WindowFade",Value=closing and 0 or 1})
    local function applyFade(value)
        for _,entry in ipairs(opacity) do
            if entry.object.Parent then entry.object[entry.property]=entry.base+(1-entry.base)*value end
        end
    end
    local fadeConnection=fade.Changed:Connect(applyFade)
    local shifted=UDim2.fromOffset(home.X.Offset,home.Y.Offset+12)
    if not closing then
        launcher.Visible=false;window.Position=shifted;scale.Scale=restingScale*.97
        applyFade(1);window.Visible=true
    end
    TweenService:Create(scale,easing,{Scale=closing and restingScale*.97 or restingScale}):Play()
    local motion=TweenService:Create(window,easing,{Position=closing and shifted or home})
    TweenService:Create(fade,easing,{Value=closing and 1 or 0}):Play()
    motion:Play()
    task.spawn(function()
        motion.Completed:Wait()
        fadeConnection:Disconnect()
        if destroyed then return end
        if closing then window.Visible=false end
        applyFade(0);fade:Destroy()
        window.Position=home;scale.Scale=restingScale
        minimized=closing;windowAnimating=false;transitionShield.Visible=false
        paintColors(colorClock)
        if closing then
            launcherScale.Scale=.92;launcher.Visible=true
            TweenService:Create(launcherScale,TweenInfo.new(.18,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{Scale=1}):Play()
        end
        resize(false)
    end)
end

local function draggable(handle, target, clamp, onTap)
    local held, startPoint, startPosition
    local moved = false

    connect(handle.InputBegan, function(input)
        if held then return end

        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            held = input
            startPoint = input.Position
            startPosition = target.Position
            moved = false
        end
    end)

    connect(UIS.InputChanged, function(input)
        if not held then return end

        local mouse = held.UserInputType
            == Enum.UserInputType.MouseButton1

        if input == held
            or (mouse and input.UserInputType
                == Enum.UserInputType.MouseMovement) then

            local delta = input.Position - startPoint
            if delta.Magnitude > 8 then moved = true end

            if moved then
                clamp(
                    startPosition.X.Offset + delta.X,
                    startPosition.Y.Offset + delta.Y
                )
            end
        end
    end)

    connect(UIS.InputEnded, function(input)
        if input ~= held then return end

        local wasMoved = moved
            or (input.Position - startPoint).Magnitude > 8

        held = nil

        if onTap and not wasMoved then
            local point = input.Position
            local origin = handle.AbsolutePosition
            local size = handle.AbsoluteSize

            if point.X >= origin.X
                and point.X <= origin.X + size.X
                and point.Y >= origin.Y
                and point.Y <= origin.Y + size.Y then
                onTap()
            end
        end
    end)

    connect(UIS.WindowFocusReleased, function()
        held = nil
    end)
end

draggable(dragArea, window, clampWindow)

draggable(launcher, launcher, clampLauncher, function()
    if minimized then toggleMinimize() end
end)

connect(minimize.Activated, toggleMinimize)

connect(close.Activated, function()
    if destroyed or windowAnimating then return end
    closeThemes();windowAnimating=true;transitionShield.Visible=true
    neonFlash(window)
    local opacity={}
    for _,object in ipairs(window:GetDescendants()) do
        local properties={}
        if object:IsA("GuiObject") then properties[#properties+1]="BackgroundTransparency" end
        if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
            properties[#properties+1]="TextTransparency"
        elseif object:IsA("ImageLabel") or object:IsA("ImageButton") then properties[#properties+1]="ImageTransparency"
        elseif object:IsA("UIStroke") then properties[#properties+1]="Transparency" end
        for _,property in ipairs(properties) do opacity[#opacity+1]={object,property,object[property]} end
    end
    opacity[#opacity+1]={window,"BackgroundTransparency",window.BackgroundTransparency}
    local fade=make("NumberValue",window,{Value=0})
    connect(fade.Changed,function(value)
        for _,entry in ipairs(opacity) do
            if entry[1].Parent then entry[1][entry[2]]=entry[3]+(1-entry[3])*value end
        end
    end)
    TweenService:Create(fade,TweenInfo.new(.48,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Value=1}):Play()
    TweenService:Create(scale,TweenInfo.new(.48,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Scale=scale.Scale*.97}):Play()
    TweenService:Create(window,TweenInfo.new(.48,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),
        {Position=UDim2.fromOffset(window.Position.X.Offset,window.Position.Y.Offset+12)}):Play()
    task.delay(.62,function() if gui.Parent then gui:Destroy() end end)
end)

connect(surface:GetPropertyChangedSignal("AbsoluteSize"), function()
    resize(false)
end)

task.defer(function()
    if not destroyed and gui.Parent then
        resize(true)
    end
end)

-- Open the interface directly. All feature pages intentionally start empty.
resize(true)
window.Visible = true
