-- Headless adaptation of the working standalone detector. No physics, GUI,
-- network requests or shared globals. Each activation owns its observers.
return function(ctx)
    local player,playerGui,storage,rs=ctx.player,ctx.playerGui,ctx.storage,ctx.runService
    local Detection=ctx.detection
    local self={enabled=false,destroyed=false,supported=game.PlaceId==189707,manualReadyAt=0,manualBusy=false}
    local session
    local limits={watchers=192,remotes=48,labels=48,candidates=192}
    local normalize=Detection.normalize
    local membershipKeys={inround=true,inactiveround=true,participatinginround=true,playinground=true}
    local activePhases={active=true,playing=true,surviving=true,disaster=true,inprogress=true}
    local function disconnect(list)
        for _,c in ipairs(list)do c:Disconnect()end
        table.clear(list)
    end
    local function staticContainer(o)
        local node=o
        while node and node~=workspace and node~=storage and node~=player do
            local name=normalize(node.Name)
            if node:IsA('LuaSourceContainer') or name=='labhandler' or name=='templates' or name=='assets'
                or name=='catalog' or name=='modules' or name=='configuration' or name=='config' then return true end
            node=node.Parent
        end
        return false
    end
    local function excluded(o)
        return o==ctx.gui or o:IsDescendantOf(ctx.gui) or staticContainer(o)
    end
    local function localOwner(o)
        return o==player or o==player.Character or o.Parent==player or o.Parent==player.Character
    end
    local function liveCharacter()
        local c=player.Character
        if not c or not c:IsDescendantOf(workspace) then return nil end
        local h=c:FindFirstChildOfClass('Humanoid')
        local root=c:FindFirstChild('HumanoidRootPart')
        if not h or h.Health<=0 or not root or not root:IsA('BasePart') then return nil end
        if root.Position.Y<=workspace.FallenPartsDestroyHeight+4 then return nil end
        return c
    end
    local function isInRound(s)
        local c=liveCharacter()
        if not c or s.roundOpen==false or s.leftRound then return false end
        local positive=false
        -- Explicit local participation takes priority over global announcements.
        for _,o in ipairs({player,c}) do
            for key,value in pairs(o:GetAttributes()) do
                if membershipKeys[normalize(key)] then
                    if value==false then return false end
                    if value==true then positive=true end
                end
            end
            for _,child in ipairs(o:GetChildren()) do
                if membershipKeys[normalize(child.Name)] and child:IsA('BoolValue') then
                    if not child.Value then return false end
                    positive=true
                end
            end
        end
        local tag=c:FindFirstChild('SurvivalTag')
        if tag then
            if tag:IsA('StringValue') and #Detection.parse(tag.Value)>0 then positive=true
            elseif tag:IsA('BoolValue') and tag.Value then positive=true end
        end
        return positive
    end
    local function stop()
        local s=session;if not s then return end
        session=nil;s.alive=false;s.model:destroy();disconnect(s.links);disconnect(s.characterLinks)
        for _,entry in pairs(s.watchers)do disconnect(entry.links)end
        for _,bucket in pairs(s.candidates)do disconnect(bucket)end
        if s.scan and coroutine.status(s.scan)~='dead' and s.scan~=coroutine.running() then pcall(task.cancel,s.scan)end
        table.clear(s.watchers);table.clear(s.candidates);table.clear(s.labels);table.clear(s.roundValues)
        self.manualBusy=false
    end
    local function notice(kind,text)
        if not self.destroyed then ctx.notify(kind,text) end
    end
    local function manualResult(s)
        if session~=s or not s.alive or not s.ready or not self.manualBusy then return end
        self.manualBusy=false
        local kind,text='error','Error, You are not in an active round'
        if isInRound(s) then
            local c=player.Character
            local tag=c and c:FindFirstChild('SurvivalTag')
            local current=tag and tag:IsA('StringValue') and Detection.parse(tag.Value) or {}
            -- The current character tag supersedes an older/global cache.
            text=#current>0 and table.concat(current,' · ') or s.model:summary()
            kind=text~='' and 'detected' or 'waiting'
            if text=='' then text='Disaster data is not available yet' end
        end
        s.pending=false
        if not self.enabled then stop()end
        notice(kind,text)
    end
    local function start()
        if session then return session end
        local s={alive=true,links={},characterLinks={},watchers={},candidates={},labels={},roundValues={},
            counts={watchers=0,remotes=0,labels=0,candidates=0},pending=false,ready=false,roundOpen=nil,leftRound=false}
        session=s
        local function valid()return s.alive and session==s and not self.destroyed end
        local function connect(signal,fn,bucket)
            local c=signal:Connect(function(...)if valid()then fn(...)end end)
            local list=bucket or s.links;list[#list+1]=c;return c
        end
        s.model=Detection.new(os.clock,function(_,kind)
            if kind=='detected' then s.pending=true end
        end,function()
            s.pending=false
            if self.enabled and ctx.dismiss then ctx.dismiss()end
        end)
        local function reset(reason)
            s.model:reset(reason);s.pending=false
        end
        local function field(o,key,value,initial)
            local n=normalize(key)
            if Detection.valueKeys[n] then
                if n=='survivaltag' and o.Parent~=player.Character and o~=player.Character then return end
                local names=Detection.parse(value)
                if #names>0 then
                    if n=='survivaltag' then s.leftRound=false end
                    if s.roundOpen~=false then s.model:observe(names,o:GetFullName()..'.'..key,'state',initial)end
                elseif n=='survivaltag' and value=='' and not initial then
                    s.leftRound=true;reset('SurvivalTag cleared')
                end
            elseif Detection.roundKeys[n] then
                s.roundValues[o]=s.roundValues[o] or {}
                local old=s.roundValues[o][key];s.roundValues[o][key]=value
                if not initial and old~=nil and old~=value then
                    s.roundOpen=nil;s.leftRound=true;reset('Round changed')
                end
            elseif Detection.phaseKeys[n] then
                local phase=normalize(value)
                if Detection.clearPhases[phase] then
                    s.roundOpen=false;s.leftRound=true;reset('Round ended')
                elseif activePhases[phase] then s.roundOpen=true;s.leftRound=false end
            elseif membershipKeys[n] and localOwner(o) then
                if value==false then s.leftRound=true;reset('Player left round')
                elseif value==true then s.leftRound=false end
            end
        end
        local function remove(o)
            local entry=s.watchers[o]
            if entry then
                disconnect(entry.links);s.watchers[o]=nil;s.counts.watchers-=1
                if entry.remote then s.counts.remotes-=1 end
                s.roundValues[o]=nil
            end
            if s.labels[o] then s.labels[o]=nil;s.counts.labels-=1 end
            if s.candidates[o] then disconnect(s.candidates[o]);s.candidates[o]=nil;s.counts.candidates-=1 end
        end
        local containers={round=true,roundstate=true,rounddata=true,gamestate=true,disasterstate=true,disasterdata=true,activedisasters=true}
        local function watch(o,initial)
            if not valid() or s.watchers[o] or excluded(o) then return end
            local n=normalize(o.Name)
            local inState=o==workspace or o==storage or o:IsDescendantOf(storage) or o:IsDescendantOf(workspace)
            local scalar=(o:IsA('StringValue') or o:IsA('IntValue') or o:IsA('NumberValue'))
                and (Detection.valueKeys[n] or Detection.roundKeys[n] or Detection.phaseKeys[n])
            if n=='survivaltag' and o.Parent~=player.Character then scalar=false end
            local membership=membershipKeys[n] and localOwner(o) and o:IsA('BoolValue')
            local remote=inState and (o:IsA('RemoteEvent') or o:IsA('UnreliableRemoteEvent'))
                and (n:find('disaster',1,true) or n=='roundstate' or n=='roundchanged' or n=='roundended')
            local attrs=o==workspace or o==storage or o==player or o==player.Character or containers[n]
            if not ((inState and scalar) or membership or remote or attrs) then return end
            if s.counts.watchers>=limits.watchers or (remote and s.counts.remotes>=limits.remotes) then return end
            local entry={links={},remote=remote};s.watchers[o]=entry;s.counts.watchers+=1
            connect(o.Destroying,function()remove(o)end,entry.links)
            if scalar or membership then
                connect(o:GetPropertyChangedSignal('Value'),function()
                    if o.Parent then field(o,o.Name,o.Value,false)end
                end,entry.links)
                field(o,o.Name,o.Value,initial)
            end
            if attrs then
                connect(o.AttributeChanged,function(key)field(o,key,o:GetAttribute(key),false)end,entry.links)
                -- Apply phase/membership first: stale values in an intermission
                -- must not become new alerts because table iteration is unordered.
                local attributes=o:GetAttributes()
                for key,value in pairs(attributes)do if not Detection.valueKeys[normalize(key)]then field(o,key,value,initial)end end
                for key,value in pairs(attributes)do if Detection.valueKeys[normalize(key)]then field(o,key,value,initial)end end
            end
            if remote then
                s.counts.remotes+=1
                connect(o.OnClientEvent,function(...)
                    local args=table.pack(...)
                    if n=='roundended' then s.roundOpen=false;s.leftRound=true;reset('Round ended');return end
                    if n=='disasterended' or n=='disasterend' or n=='enddisaster' or n=='stopdisaster' or n=='disasterstop' then return end
                    for i=1,args.n do
                        local value=args[i]
                        local phase=normalize(type(value)=='table' and (value.Phase or value.phase or value.State or value.state or value.Action or value.action) or value)
                        if Detection.clearPhases[phase] or phase=='stop' or phase=='end' or phase=='cancelled' then
                            if n=='roundstate' or n=='roundchanged' then s.roundOpen=false;s.leftRound=true;reset('Round ended')end
                            return
                        elseif activePhases[phase] and (n=='roundstate' or n=='roundchanged') then s.roundOpen=true;s.leftRound=false end
                    end
                    local names=Detection.parse(args)
                    if #names>0 and s.roundOpen~=false then s.model:observe(names,o:GetFullName(),'event',false)end
                end,entry.links)
            end
        end
        local function warningContext(o)
            if o:IsA('Message')then return true end
            if (not o:IsA('TextLabel') and not o:IsA('TextButton')) or not o:IsDescendantOf(playerGui) or excluded(o) then return false end
            local node=o;local matched=false
            while node and node~=playerGui do
                local n=normalize(node.Name)
                if n:find('chat',1,true) or n=='reyzndisasterprediction' then return false end
                if n:find('disasterwarning',1,true) or n=='disasteralert' then matched=true end
                node=node.Parent
            end
            return matched or o.Text:lower():find('disaster warning',1,true)~=nil
        end
        local function indexWarning(o)
            if s.labels[o] or s.counts.labels>=limits.labels or not warningContext(o)then return end
            s.labels[o]={last=''};s.counts.labels+=1
        end
        local function watchWarning(o)
            indexWarning(o)
            if s.candidates[o] or s.counts.candidates>=limits.candidates or excluded(o) or not o:IsDescendantOf(playerGui)
                or (not o:IsA('TextLabel') and not o:IsA('TextButton'))then return end
            local node=o
            while node and node~=playerGui do
                if normalize(node.Name):find('chat',1,true) then return end
                node=node.Parent
            end
            local bucket={};s.candidates[o]=bucket;s.counts.candidates+=1
            connect(o:GetPropertyChangedSignal('Text'),function()indexWarning(o)end,bucket)
            connect(o.Destroying,function()remove(o)end,bucket)
        end
        local function visible(o)
            if not o.Parent then return false end
            if (o:IsA('TextLabel') or o:IsA('TextButton')) and o.TextTransparency>=.98 then return false end
            local node=o
            while node do
                if node:IsA('GuiObject') and not node.Visible then return false end
                if node:IsA('ScreenGui') and not node.Enabled then return false end
                if node:IsA('CanvasGroup') and node.GroupTransparency>=.98 then return false end
                node=node.Parent
            end
            return true
        end
        local function pollWarnings()
            for o,entry in pairs(s.labels)do
                if not o.Parent then remove(o)
                elseif visible(o)then
                    local names=Detection.warning(o.Text);local signature=table.concat(names,'|')
                    if signature~='' and signature~=entry.last and s.roundOpen~=false then s.model:observe(names,o:GetFullName(),'warning',false)end
                    entry.last=signature
                else entry.last='' end
            end
        end
        local function inspect(o,initial)watch(o,initial);watchWarning(o)end
        local structure=workspace:FindFirstChild('Structure')
        connect(workspace.ChildAdded,function(o)
            if o.Name=='Structure' and o~=structure then
                structure=o;s.roundOpen=nil;s.leftRound=false;reset('New Structure')
            end
        end)
        connect(workspace.ChildRemoved,function(o)
            if o==structure then structure=nil;s.roundOpen=false;s.leftRound=true;reset('Structure removed')end
        end)
        for _,root in ipairs({workspace,storage,playerGui})do
            connect(root.DescendantAdded,function(o)inspect(o,false)end)
            connect(root.DescendantRemoving,function(o)
                if o.Parent==player.Character and o.Name=='SurvivalTag' then s.leftRound=true;reset('SurvivalTag removed')end
                remove(o)
            end)
        end
        connect(player.ChildAdded,function(o)watch(o,false)end)
        connect(player.ChildRemoved,remove)
        local currentCharacter
        local function bindCharacter(c,initial)
            disconnect(s.characterLinks)
            if currentCharacter then
                for o in pairs(s.watchers)do if o==currentCharacter or o:IsDescendantOf(currentCharacter)then remove(o)end end
                reset('Character replaced');s.leftRound=true
            end
            currentCharacter=c
            if not c then return end
            local hum
            local function watchHumanoid(o)
                if o:IsA('Humanoid') and o~=hum then
                    hum=o
                    connect(o.Died,function()s.leftRound=true;reset('Character died')end,s.characterLinks)
                end
            end
            connect(c.ChildAdded,watchHumanoid,s.characterLinks)
            watch(c,initial)
            for _,o in ipairs(c:GetChildren())do inspect(o,initial);watchHumanoid(o)end
        end
        connect(player.CharacterAdded,function(c)bindCharacter(c,true)end)
        connect(player.CharacterRemoving,function(c)if currentCharacter==c then bindCharacter(nil,true)end end)
        -- Separate clock from all visual effects: minimized/off-screen Hub still listens.
        local accumulator=0
        connect(rs.Heartbeat,function(dt)
            accumulator+=dt;if accumulator<.1 then return end;accumulator=0
            pollWarnings()
            if s.ready and s.pending and self.enabled and not self.manualBusy then
                s.pending=false;notice('detected',s.model:summary())
            end
            manualResult(s)
        end)
        for _,o in ipairs(playerGui:GetDescendants())do watchWarning(o)end
        for _,o in ipairs(workspace:GetChildren())do watchWarning(o)end
        watch(workspace,true);watch(storage,true);watch(player,true)
        for _,o in ipairs(player:GetChildren())do watch(o,true)end
        bindCharacter(player.Character,true);pollWarnings()
        s.scan=task.defer(function()
            for _,root in ipairs({storage,workspace})do
                for i,o in ipairs(root:GetDescendants())do
                    if not valid()then return end
                    if o:IsDescendantOf(root)then inspect(o,true)end
                    if i%256==0 then task.wait()end
                end
            end
            if valid()then s.ready=true;manualResult(s)end
        end)
        return s
    end
    function self:setEnabled(enabled)
        if self.destroyed then return false end
        if enabled and not self.supported then notice('error','Available in Natural Disaster Survival');return false end
        if enabled==self.enabled then return self.enabled end
        self.enabled=enabled
        if enabled then start()
        else stop();if ctx.dismiss then ctx.dismiss()end end
        return self.enabled
    end
    function self:manual()
        if self.destroyed or self.manualBusy or os.clock()<self.manualReadyAt then return false end
        self.manualReadyAt=os.clock()+4
        if not self.supported then notice('error','Error, You are not in an active round');return true end
        self.manualBusy=true
        local s=start();manualResult(s)
        return true
    end
    function self:destroy()
        if self.destroyed then return end
        self.destroyed=true;self.enabled=false;stop()
    end
    return self
end
