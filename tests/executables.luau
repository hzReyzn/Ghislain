local newWorld=require('./mock_roblox')
return function(source)
    local count=0
    local urls={
        TelekinesisUI='https://scriptblox.com/raw/Universal-Script-Telekinesis-Ui-95037',
        SuperBlackHole='https://scriptblox.com/raw/Natural-Disaster-Survival-Ultra-Blackhole-and-Super-ring-no-lying-Full-FE+Keyless-228862',
    }
    local function test(name,fn)fn();count+=1;print('PASS executable: '..name)end
    local function find(p,n)return assert(p:FindFirstChild(n,true),'missing '..n)end
    local function click(p,n)find(p,n).Activated:Fire()end
    local function requested(w)
        local result={}
        for _,url in ipairs(w.requests) do if url:find('scriptblox.com',1,true) then result[#result+1]=url end end
        return result
    end
    local function launch(width,height)
        local w=newWorld();w.httpFailure=true;w.viewport={X=width or 1280,Y=height or 720}
        w.character();local g=w.run(source);w.step(40)
        w.httpFailure=false;w.env.remoteRuns={}
        for name,url in pairs(urls) do
            w.http[url]='remoteRuns.'..name..'=(remoteRuns.'..name..' or 0)+1'
        end
        return w,g
    end
    test('only the two exact titles appear on compact buttons in Scripts',function()
        for _,size in ipairs({{1280,720},{844,390},{390,780},{320,640}}) do
            local w,g=launch(size[1],size[2]);click(g,'Tab_Scripts');w.step(30)
            local list=find(g,'ScriptExecutables');assert(list.Parent==find(g,'Page_Scripts'))
            for name,title in pairs({TelekinesisUI='Telekinesis UI',SuperBlackHole='Super Black Hole'}) do
                local b=find(g,name);assert(b.Parent==list and b.Active and b.Size.Y.Offset>=44)
                local labels=0
                for _,o in ipairs(b:GetDescendants()) do
                    if o:IsA('TextLabel') then
                        labels+=1;assert(o.Text==title and o.FontFace.Family=='rbxassetid://12187375422')
                    end
                    if o:IsA('GuiObject') then assert(not o.Active,'decoration intercepts input') end
                end
                assert(labels==1 and not b:FindFirstChild('ToggleStatus',true))
                assert(find(b,'OptionNeon') and find(b,'PressScale'))
                assert(b.Position.X.Offset+b.Size.X.Offset<=list.Size.X.Offset)
            end
            local top,bottom=find(g,'TelekinesisUI'),find(g,'SuperBlackHole')
            assert(bottom.Position.Y.Offset>=top.Position.Y.Offset+top.Size.Y.Offset+12)
            assert(find(g,'Page_Scripts').CanvasSize.Y.Offset>=bottom.Position.Y.Offset+bottom.Size.Y.Offset)
            assert(g:GetAttribute('Version')=='1.0');g:Destroy()
        end
    end)
    test('startup, navigation and respawn never download or execute external scripts',function()
        local w,g=launch();click(g,'Tab_Scripts');w.character();w.step(40)
        assert(#requested(w)==0 and not next(w.env.remoteRuns))
        for name in pairs(urls) do assert(find(g,name):GetAttribute('ExecutableState')=='idle') end
        g:Destroy()
    end)
    test('a click fetches and executes exactly its supplied URL; later clicks can run again',function()
        local w,g=launch()
        for _,name in ipairs({'TelekinesisUI','SuperBlackHole'}) do
            click(g,name);w.step(1)
            assert(w.env.remoteRuns[name]==1 and find(g,name):GetAttribute('ExecutableState')=='ready')
            assert(requested(w)[#requested(w)]==urls[name])
            for _=1,8 do click(g,name) end
            w.step(2);assert(w.env.remoteRuns[name]==1,'rapid taps duplicated execution')
            w.step(45);click(g,name);w.step(1);assert(w.env.remoteRuns[name]==2)
            w.step(45)
        end
        assert(#requested(w)==4);g:Destroy()
    end)
    test('in-flight downloads are independently locked and do not block each other',function()
        local w,g=launch();w.httpDelay=1
        click(g,'TelekinesisUI');w.step(1)
        for _=1,8 do click(g,'TelekinesisUI') end
        click(g,'SuperBlackHole');w.step(1)
        assert(#requested(w)==2 and not next(w.env.remoteRuns))
        for name in pairs(urls) do assert(find(g,name):GetAttribute('ExecutableState')=='loading') end
        w.step(70)
        assert(w.env.remoteRuns.TelekinesisUI==1 and w.env.remoteRuns.SuperBlackHole==1);g:Destroy()
    end)
    test('network, empty response, compilation and runtime failures allow retry',function()
        for _,mode in ipairs({'network','empty','syntax','runtime'}) do
            local w,g=launch();local b=find(g,'TelekinesisUI');local before=#w.warnings
            if mode=='network' then w.httpFailure=true
            elseif mode=='empty' then w.http[urls.TelekinesisUI]='   \n'
            elseif mode=='syntax' then w.http[urls.TelekinesisUI]='local = bad syntax'
            else w.http[urls.TelekinesisUI]='error("fixture failed")' end
            click(g,'TelekinesisUI');w.step(1)
            assert(b:GetAttribute('ExecutableState')=='error' and #w.warnings>before)
            assert(not w.env.remoteRuns.TelekinesisUI)
            w.httpFailure=false;w.http[urls.TelekinesisUI]='remoteRuns.TelekinesisUI=1'
            w.step(45);click(g,'TelekinesisUI');w.step(1)
            assert(b:GetAttribute('ExecutableState')=='ready' and w.env.remoteRuns.TelekinesisUI==1)
            g:Destroy()
        end
    end)
    test('closing or reexecuting during a download prevents a late remote launch',function()
        for _,action in ipairs({'close','destroy','rerun'}) do
            local w,g=launch();w.httpDelay=1;click(g,'TelekinesisUI');w.step(1)
            if action=='close' then click(g,'Close')
            elseif action=='destroy' then g:Destroy()
            else w.run(source) end
            w.step(100);assert(not w.env.remoteRuns.TelekinesisUI,'late launch after '..action)
            if action=='rerun' then find(w.pg,'ReyznX'):Destroy() end
            for _,signal in pairs(w.services.RunService) do assert(signal:Count()==0,'Hub listener leaked') end
        end
    end)
    test('already-started remote code keeps its independent lifecycle after Hub close',function()
        local w,g=launch()
        w.http[urls.TelekinesisUI]='remoteRuns.TelekinesisUI=1;task.wait(1);remoteRuns.finished=true'
        click(g,'TelekinesisUI');w.step(1)
        assert(w.env.remoteRuns.TelekinesisUI==1 and find(g,'TelekinesisUI'):GetAttribute('ExecutableState')=='running')
        g:Destroy();w.step(70);assert(w.env.remoteRuns.finished)
    end)
    test('executables leave Main switches and the FLY instance untouched',function()
        local w,g=launch();click(g,'NoFallDamage');click(g,'WalkOnWater');click(g,'Antifling')
        click(g,'FlySS3FE');local fly=find(w.pg,'FlyDBZ');click(fly,'FlightToggle')
        click(g,'TelekinesisUI');click(g,'SuperBlackHole');w.step(1)
        for _,name in ipairs({'NoFallDamage','WalkOnWater','Antifling'}) do assert(g:GetAttribute(name..'Enabled')) end
        assert(find(w.pg,'FlyDBZ')==fly and fly:GetAttribute('FlightEnabled'))
        g:Destroy();fly:Destroy()
    end)
    print(tostring(count)..' executable scenarios passed using fixtures, not live ScriptBlox code.')
end
