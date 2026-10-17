-- Each switch owns its connections, body generation and temporary resources.
-- Enabled is user intent; losing a body suspends work without changing intent.
return function(player, runService, options)
    local self = {enabled=false, destroyed=false, epoch=0, generation=0,
        links={}, characterLinks={}, bodyLinks={}, options=options}
    local function disconnect(list)
        for _, connection in ipairs(list) do connection:Disconnect() end
        table.clear(list)
    end
    function self:listen(list, signal, callback)
        local epoch=self.epoch
        list[#list+1]=signal:Connect(function(...)
            if self.enabled and not self.destroyed and self.epoch==epoch then callback(...) end
        end)
    end
    function self:reset(reason)
        self.operational=false
        if options.reset then options.reset(self,reason) end
    end
    function self:refresh()
        local character=self.character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local root=character and character:FindFirstChild("HumanoidRootPart")
        if root and not root:IsA("BasePart") then root=nil end
        if humanoid==self.humanoid and root==self.root then return end
        self:reset("body-replaced")
        disconnect(self.bodyLinks)
        self.generation+=1
        self.humanoid,self.root=humanoid,root
        if self.retiredHumanoid~=humanoid then self.retiredHumanoid=nil end
        local generation=self.generation
        if humanoid then
            local function died()
                if self.generation~=generation or self.humanoid~=humanoid then return end
                self.retiredHumanoid=humanoid
                self:reset("death")
            end
            self:listen(self.bodyLinks,humanoid.Died,died)
            self:listen(self.bodyLinks,humanoid:GetPropertyChangedSignal("Health"),function()
                if humanoid.Health<=0 then died() end
            end)
            if humanoid.Health<=0 then died() end
        end
    end
    function self:bind(character)
        self:reset("character-changed")
        disconnect(self.characterLinks);disconnect(self.bodyLinks)
        self.generation+=1
        self.character=character;self.humanoid=nil;self.root=nil;self.retiredHumanoid=nil
        if not character then return end
        self:listen(self.characterLinks,character.ChildAdded,function()
            if self.character==character then self:refresh() end
        end)
        self:listen(self.characterLinks,character.ChildRemoved,function()
            if self.character==character then self:refresh() end
        end)
        self:refresh()
    end
    function self:valid()
        local c,h,r=self.character,self.humanoid,self.root
        if not self.enabled or self.destroyed or not c or c~=player.Character or not c.Parent
            or not c:IsDescendantOf(workspace) or not h or h.Parent~=c or h.Health<=0
            or self.retiredHumanoid==h or not r or r.Parent~=c then return false end
        local p=r.Position
        local bottom=workspace.FallenPartsDestroyHeight
        if p.X~=p.X or p.Y~=p.Y or p.Z~=p.Z or math.abs(p.X)==math.huge
            or math.abs(p.Y)==math.huge or math.abs(p.Z)==math.huge
            or (type(bottom)=="number" and p.Y<=bottom+4) then return false end
        return true
    end
    function self:step(dt,phase)
        self:refresh()
        if not self:valid() then
            if self.operational then self:reset("unavailable") end
            return
        end
        self.operational=true
        options.step(self,dt,phase)
    end
    function self:setEnabled(enabled)
        if self.destroyed then return false end
        enabled=enabled==true
        if enabled==self.enabled then return enabled end
        self.enabled=enabled;self.epoch+=1
        if not enabled then
            disconnect(self.links);self:bind(nil)
            if options.stop then options.stop(self) end
            return false
        end
        self:listen(self.links,player.CharacterAdded,function(character)
            if player.Character==character then self:bind(character) end
        end)
        self:listen(self.links,player.CharacterRemoving,function(character)
            if self.character==character then self:bind(nil) end
        end)
        if options.start then options.start(self) end
        self:bind(player.Character)
        self:listen(self.links,runService.PreSimulation,function(dt) self:step(dt,"pre") end)
        if options.post then self:listen(self.links,runService.PostSimulation,function(dt) self:step(dt,"post") end) end
        return true
    end
    function self:destroy()
        if self.destroyed then return end
        self:setEnabled(false);self.destroyed=true
    end
    return self
end
