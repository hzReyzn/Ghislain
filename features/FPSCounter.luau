-- Counts rendered frames, independent of character/Hub visibility. The half-
-- second measurement is not an FPS cap and does not change graphics settings.
return function(context)
    local self={enabled=false,destroyed=false,epoch=0,frames=0,elapsed=0}
    function self:setEnabled(enabled)
        if self.destroyed then return false end
        enabled=enabled==true
        if enabled==self.enabled then return enabled end
        self.enabled=enabled;self.epoch+=1
        if self.connection then self.connection:Disconnect();self.connection=nil end
        self.frames,self.elapsed=0,0
        context.visibility(enabled)
        if enabled then
            context.display(nil)
            local epoch=self.epoch
            self.connection=context.render:Connect(function(dt)
                if not self.enabled or self.destroyed or self.epoch~=epoch then return end
                if type(dt)~="number" or dt<=0 or dt~=dt or dt==math.huge then return end
                self.frames+=1;self.elapsed+=dt
                if self.elapsed>=.5 then
                    context.display(self.frames/self.elapsed)
                    self.frames,self.elapsed=0,0
                end
            end)
        end
        return enabled
    end
    function self:destroy()
        if self.destroyed then return end
        self:setEnabled(false);self.destroyed=true
    end
    return self
end
