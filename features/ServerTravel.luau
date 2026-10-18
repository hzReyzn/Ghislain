-- Click-only travel. One in-flight request, bounded pagination/retries, no
-- periodic server polling and no code execution from HTTP responses.
return function(context)
    local self={destroyed=false,busy=false,epoch=0,attempts=0,candidates={}}
    local random=Random.new()
    local function current(epoch)return not self.destroyed and self.busy and self.epoch==epoch end
    local function finish(message)
        if self.destroyed then return end
        self.busy=false;self.epoch+=1;self.target=nil;table.clear(self.candidates)
        context.status(false,message and "error" or "idle")
        if message then context.notify(message) end
    end
    local function validServer(s)
        return type(s)=="table" and type(s.id)=="string" and #s.id>0 and #s.id<=128
            and s.id:match("^[%w%-]+$") and s.id~=context.jobId
            and type(s.playing)=="number" and s.playing>=0 and s.playing%1==0
            and type(s.maxPlayers)=="number" and s.maxPlayers>0 and s.maxPlayers%1==0
            and s.playing<s.maxPlayers
    end
    local function readPage(url,epoch)
        for attempt=1,2 do
            if not current(epoch) then return end
            local ok,body=pcall(context.get,url)
            if not current(epoch) then return end
            if ok and type(body)=="string" and #body>0 and #body<=2000000 then
                local parsed,data=pcall(context.decode,body)
                if parsed and type(data)=="table" and type(data.data)=="table" then return data end
            end
            if attempt==1 then task.wait(.75) end
        end
    end
    local attemptTeleport
    local function retry(epoch)
        if not current(epoch) or self.retryPending then return end
        self.target=nil;self.retryPending=true
        if self.mode~="rejoin" and self.attempts<3 and #self.candidates>0 then
            context.spawn(function()task.wait(.6);if current(epoch) then attemptTeleport(epoch) end end)
        else finish("Unable to join this server. Please try again.") end
    end
    attemptTeleport=function(epoch)
        if not current(epoch) then return end
        self.retryPending=false
        local target
        if self.mode=="rejoin" then target=context.jobId
        else
            if #self.candidates==0 then finish("No other public server is available.");return end
            local index=self.mode=="few" and 1 or random:NextInteger(1,#self.candidates)
            target=table.remove(self.candidates,index).id
        end
        if type(target)~="string" or target=="" then finish("This server cannot be rejoined.");return end
        self.attempts+=1;local attempt=self.attempts;self.target=target
        context.status(true,"joining",target)
        local ok=pcall(function()context.teleport:TeleportToPlaceInstance(context.placeId,target,context.player)end)
        if not current(epoch) then return end
        if not ok then retry(epoch);return end
        context.spawn(function()
            task.wait(18)
            if current(epoch) and self.attempts==attempt then finish("The server did not respond. Please try again.") end
        end)
    end
    self.failure=context.teleport.TeleportInitFailed:Connect(function(who,_,_,placeId,options)
        if who~=context.player or placeId~=context.placeId or not self.busy or not self.target then return end
        if options then
            local ok,id=pcall(function()return options.ServerInstanceId end)
            if ok and type(id)=="string" and id~="" and id~=self.target then return end
        end
        retry(self.epoch)
    end)
    function self:start(mode)
        if self.destroyed or self.busy or (mode~="rejoin" and mode~="random" and mode~="few") then return false end
        self.busy=true;self.epoch+=1;self.mode=mode;self.attempts=0;self.target=nil;self.retryPending=false;table.clear(self.candidates)
        local epoch=self.epoch
        context.status(true,mode=="rejoin" and "joining" or "searching")
        context.spawn(function()
            if mode=="rejoin" then attemptTeleport(epoch);return end
            local cursor,seen,seenCursors=nil,{},{}
            for _=1,5 do
                if not current(epoch) then return end
                local url="https://games.roblox.com/v1/games/"..context.placeId.."/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100"
                if cursor then url..="&cursor="..context.encode(cursor) end
                local page=readPage(url,epoch)
                if not current(epoch) then return end
                if not page then
                    if #self.candidates==0 then finish("Unable to load the server list. Please try again.");return end
                    break
                end
                for index,s in ipairs(page.data)do
                    if index>100 then break end
                    if validServer(s) and not seen[s.id] then
                        seen[s.id]=true;self.candidates[#self.candidates+1]={id=s.id,playing=s.playing}
                    end
                end
                -- Ascending population: the first eligible page already has
                -- the lowest available counts; don't scan every server for it.
                if mode=="few" and #self.candidates>0 then break end
                cursor=page.nextPageCursor
                if type(cursor)~="string" or cursor=="" or #cursor>2048 or seenCursors[cursor] then break end
                seenCursors[cursor]=true;task.wait(.2)
            end
            table.sort(self.candidates,function(a,b)return a.playing<b.playing or (a.playing==b.playing and a.id<b.id)end)
            attemptTeleport(epoch)
        end)
        context.spawn(function()
            task.wait(20)
            if current(epoch) and self.attempts==0 then finish("Server search timed out. Please try again.") end
        end)
        return true
    end
    function self:destroy()
        if self.destroyed then return end
        self.destroyed=true;self.busy=false;self.epoch+=1;self.failure:Disconnect();table.clear(self.candidates)
    end
    return self
end
