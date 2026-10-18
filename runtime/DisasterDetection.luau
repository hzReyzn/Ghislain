-- Pure evidence model. A list of available disaster modules is never evidence.
local Detection={}
local definitions={
    {"Acidrain","Acid Rain"},{"Avalanche","Avalanche"},{"Blizzard","Blizzard"},
    {"Earthquake","Earthquake"},{"Fire","Fire"},{"Flood","Flash Flood"},
    {"Lightning","Thunderstorm"},{"Meteor","Meteor Shower"},{"Sandstorm","Sandstorm"},
    {"Tornado","Tornado"},{"Tsunami","Tsunami"},{"Virus","Deadly Virus"},{"Volcano","Volcanic Eruption"},
}
local aliases={}
function Detection.normalize(value) return type(value)=="string" and value:lower():gsub("[^%w]","") or "" end
for _,item in ipairs(definitions) do aliases[Detection.normalize(item[1])]=item[2];aliases[Detection.normalize(item[2])]=item[2] end
Detection.valueKeys={survivaltag=true,disaster=true,disasters=true,currentdisaster=true,currentdisasters=true,
    selecteddisaster=true,selecteddisasters=true,nextdisaster=true,nextdisasters=true,
    activedisaster=true,activedisasters=true,disastertype=true,disastername=true}
Detection.roundKeys={roundid=true,roundnumber=true,roundindex=true}
Detection.phaseKeys={roundstate=true,roundphase=true,gamestate=true,gamephase=true}
Detection.clearPhases={intermission=true,waiting=true,roundend=true,roundended=true,ended=true,lobby=true}

function Detection.parse(value)
    local found,visited={},{}
    local budget=64
    local function visit(v,depth)
        if budget<=0 or depth>4 then return end
        budget-=1
        if type(v)=="string" then
            if #v>512 then return end
            local exact=aliases[Detection.normalize(v)]
            if exact then found[exact]=true;return end
            -- Structured lists only. No substring guesses from prose or asset paths.
            local list=v:gsub("%s+[Aa][Nn][Dd]%s+","|")
            local pending={}
            for token in list:gmatch("[^,;|+&\n]+") do
                local name=aliases[Detection.normalize(token)]
                if not name then return end
                pending[name]=true
            end
            for name in pairs(pending) do found[name]=true end
        elseif type(v)=="table" and not visited[v] then
            visited[v]=true
            for key,item in pairs(v) do
                if budget<=0 then break end
                budget-=1
                if type(key)=="number" or Detection.valueKeys[Detection.normalize(key)] then visit(item,depth+1) end
            end
        end
    end
    visit(value,0)
    local result={}
    for _,item in ipairs(definitions) do if found[item[2]] then result[#result+1]=item[2] end end
    return result
end

function Detection.warning(text)
    if type(text)~="string" or #text>2048 then return {} end
    local cleaned=text:gsub("<[^>]*>",""):lower():gsub("^%s+","")
    cleaned=cleaned:gsub("^disaster%s+warning[%s:!%-]*","")
    for _,item in ipairs(definitions) do
        for _,alias in ipairs({item[2]:lower(),item[1]:lower()}) do
            if cleaned:sub(1,#alias)==alias then
                local nextChar=cleaned:sub(#alias+1,#alias+1)
                if nextChar=="" or nextChar:match("[%s%p]") then return {item[2]} end
            end
        end
    end
    return {}
end

function Detection.new(clock,changed,reset)
    local self={records={},order={},round=0,alive=true}
    function self:observe(names,source,kind,initial)
        if not self.alive then return end
        local now=clock()
        for _,name in ipairs(names) do
            local record=self.records[name]
            if not record then
                record={name=name,source=source,kind=kind,first=now,
                    eligible=not initial and kind~="warning",initial=initial==true}
                if kind=="warning" then record.warningAt=now end
                self.records[name]=record;self.order[#self.order+1]=name
                changed(record,"detected")
            elseif kind=="warning" and not record.warningAt then
                record.warningAt=now
                -- Below 250ms, polling/render order is too close to claim a lead.
                if record.eligible and now-record.first>=.25 then record.lead=now-record.first end
                changed(record,"timing")
            end
        end
    end
    function self:reset(reason)
        if not self.alive then return end
        self.round+=1;table.clear(self.records);table.clear(self.order)
        if reset then reset(reason) end
    end
    function self:summary()
        return table.concat(self.order," · ")
    end
    function self:destroy() self.alive=false;table.clear(self.records);table.clear(self.order) end
    return self
end
return Detection
