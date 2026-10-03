-- FREEZY COMPLETE PANEL-ONLY CLIENT
-- Install as a LocalScript in StarterPlayer > StarterPlayerScripts.
-- This creates ONLY the panel, egg scanner, targeting, ESP and Auto-Get controller.
-- It creates no map, eggs, inventory, pets, coins, spawns or rewards.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local C = {
    bg=Color3.fromRGB(4,7,12), bg2=Color3.fromRGB(8,13,21),
    card=Color3.fromRGB(10,23,38), card2=Color3.fromRGB(13,31,50),
    blue=Color3.fromRGB(18,133,255), cyan=Color3.fromRGB(42,190,255),
    white=Color3.fromRGB(245,249,255), gray=Color3.fromRGB(165,181,198),
    green=Color3.fromRGB(54,226,142), red=Color3.fromRGB(255,76,92),
    yellow=Color3.fromRGB(255,202,70), purple=Color3.fromRGB(167,108,255)
}

local state = {
    page="COMMAND CENTER", open=true, scale=1,
    eggs={}, target=nil, automation=false, autoMode="ONE", autoInterval=2,
    maxDistance=250, rarityFilter="ALL", mutationFilter="ALL", sizeFilter="ALL",
    targetMode="NEAREST", espEgg=false, espTarget=false, espDistance=false,
    animation=true, showFPS=true, returnAfter=true, scans=0, pickups=0, failures=0,
    startedAt=os.clock(), lastAction="Ready", logs={}, fps=0, currentJob=false,
    _esp={}, queue={}
}

local function New(className, props, parent)
    local object=Instance.new(className)
    for k,v in pairs(props or {}) do object[k]=v end
    object.Parent=parent
    return object
end
local function Corner(object,r) New("UICorner",{CornerRadius=UDim.new(0,r or 8)},object) end
local function Stroke(object,color,thickness) New("UIStroke",{Color=color or C.blue,Thickness=thickness or 1,Transparency=.15},object) end
local function Tween(object,time,props)
    if not state.animation then for k,v in pairs(props) do object[k]=v end return end
    TweenService:Create(object,TweenInfo.new(time,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),props):Play()
end
local function label(parent,text,pos,size,color,textSize,bold)
    return New("TextLabel",{Position=pos,Size=size,BackgroundTransparency=1,Text=tostring(text),
        TextColor3=color or C.white,TextSize=textSize or 11,Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center},parent)
end
local function button(parent,text,pos,size,callback,color)
    local b=New("TextButton",{Position=pos,Size=size or UDim2.fromOffset(150,36),BackgroundColor3=color or C.card2,
        BorderSizePixel=0,Text=text,TextColor3=C.white,TextSize=10,Font=Enum.Font.GothamBold,AutoButtonColor=false},parent)
    Corner(b,8); Stroke(b,color or C.blue,1)
    b.MouseEnter:Connect(function() if b.Active then Tween(b,.1,{BackgroundColor3=C.blue}) end end)
    b.MouseLeave:Connect(function() Tween(b,.1,{BackgroundColor3=color or C.card2}) end)
    b.Activated:Connect(function() if callback then callback() end end)
    return b
end
local function toggle(parent,text,pos,on,callback)
    local b=button(parent,"",pos,UDim2.fromOffset(185,34),nil)
    local function paint() b.Text=(on and "●  " or "○  ")..text; b.TextColor3=on and C.cyan or C.white end
    paint()
    b.Activated:Connect(function() on=not on; paint(); if callback then callback(on) end end)
    return b
end
local function stat(parent,name,value,pos,w)
    local f=New("Frame",{Position=pos,Size=UDim2.fromOffset(w or 150,78),BackgroundColor3=C.card2,BorderSizePixel=0},parent)
    Corner(f,9); Stroke(f,C.blue,1)
    label(f,name,UDim2.fromOffset(10,8),UDim2.new(1,-20,0,18),C.gray,9,true)
    label(f,value,UDim2.fromOffset(10,28),UDim2.new(1,-20,0,34),C.white,15,true)
    return f
end
local function panel(parent,height)
    local f=New("Frame",{Size=UDim2.new(1,0,0,height or 90),BackgroundColor3=C.card,BorderSizePixel=0},parent)
    Corner(f,10); Stroke(f,C.blue,1); return f
end

local gui=New("ScreenGui",{Name="FREEZY",ResetOnSpawn=false,IgnoreGuiInset=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=999},playerGui)
local launcher=New("TextButton",{Name="FREEZYLauncher",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-16,0,16),Size=UDim2.fromOffset(62,62),BackgroundColor3=C.bg,Text="❄",TextColor3=C.cyan,TextSize=28,Font=Enum.Font.GothamBold,AutoButtonColor=false,Visible=false},gui)
Corner(launcher,16); Stroke(launcher,C.blue,2)

local window=New("Frame",{Name="FREEZYWindow",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(920,600),BackgroundColor3=C.bg,BorderSizePixel=0,ClipsDescendants=true},gui)
Corner(window,16); Stroke(window,C.blue,1.5)
local uiScale=New("UIScale",{Scale=1},window)
local header=New("Frame",{Size=UDim2.new(1,0,0,66),BackgroundColor3=C.bg2,BorderSizePixel=0},window)
New("Frame",{Position=UDim2.new(0,0,1,-2),Size=UDim2.new(1,0,0,2),BackgroundColor3=C.blue,BorderSizePixel=0},header)
label(header,"❄ FREEZY",UDim2.fromOffset(18,8),UDim2.fromOffset(220,29),C.white,23,true)
label(header,"CYBER EGG CONTROL PANEL",UDim2.fromOffset(20,37),UDim2.fromOffset(260,18),C.gray,9)
local online=label(header,"●  CLIENT ONLINE",UDim2.new(1,-315,0,20),UDim2.fromOffset(210,25),C.green,11,true); online.TextXAlignment=Enum.TextXAlignment.Right
local close=New("TextButton",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-14,.5,0),Size=UDim2.fromOffset(38,38),BackgroundColor3=C.card,Text="×",TextColor3=C.white,TextSize=23,Font=Enum.Font.GothamBold,AutoButtonColor=false},header)
Corner(close,9); Stroke(close,C.blue)
local nav=New("ScrollingFrame",{Position=UDim2.fromOffset(10,76),Size=UDim2.new(0,190,1,-128),BackgroundColor3=C.bg2,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.blue,CanvasSize=UDim2.new()},window)
Corner(nav,11); Stroke(nav,C.blue,1)
local navList=New("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},nav)
local content=New("Frame",{Position=UDim2.fromOffset(210,76),Size=UDim2.new(1,-220,1,-128),BackgroundTransparency=1},window)
local title=label(content,"COMMAND CENTER",UDim2.fromOffset(3,0),UDim2.new(1,-6,0,31),C.white,19,true)
local desc=label(content,"Live egg scanning, filters, targeting and pickup controls",UDim2.fromOffset(4,31),UDim2.new(1,-8,0,24),C.gray,10)
local body=New("ScrollingFrame",{Position=UDim2.fromOffset(4,60),Size=UDim2.new(1,-8,1,-60),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=C.blue,CanvasSize=UDim2.new()},content)
local stop=New("TextButton",{AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-10,1,-10),Size=UDim2.fromOffset(155,44),BackgroundColor3=C.red,Text="■  STOP ALL",TextColor3=C.white,TextSize=12,Font=Enum.Font.GothamBold,AutoButtonColor=false},window)
Corner(stop,10); Stroke(stop,C.red,2)
local resize=New("TextButton",{AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-2,1,-2),Size=UDim2.fromOffset(24,24),BackgroundTransparency=1,Text="↘",TextColor3=C.cyan,TextSize=18,Font=Enum.Font.GothamBold,AutoButtonColor=false},window)

local remotes=ReplicatedStorage:WaitForChild("FREEZYRemotes",8)
local GetSnapshot=remotes and remotes:FindFirstChild("GetSnapshot")
local RequestAction=remotes and remotes:FindFirstChild("RequestAction")
local ActionResult=remotes and remotes:FindFirstChild("ActionResult")

local function log(message,kind)
    table.insert(state.logs,1,{t=os.date("%H:%M:%S"),msg=tostring(message),kind=kind or "INFO"})
    if #state.logs>100 then table.remove(state.logs) end
    state.lastAction=tostring(message)
end
local function request(action,payload)
    if not RequestAction then state.failures+=1; log("Server bridge not found","ERROR"); return false end
    RequestAction:FireServer(action,payload)
    return true
end
local function posOf(o)
    if not o then return nil end
    if o:IsA("BasePart") then return o.Position end
    if o:IsA("Attachment") then return o.WorldPosition end
    if o:IsA("Model") then
        if o.PrimaryPart then return o.PrimaryPart.Position end
        local p=o:FindFirstChildWhichIsA("BasePart",true); return p and p.Position or nil
    end
end
local function attrs(o,names)
    for _,n in ipairs(names) do local v=o:GetAttribute(n); if v~=nil then return v end end
end
local function boolAttr(o,names,default)
    local v=attrs(o,names); if v==nil then return default end
    return v==true or v==1 or v=="1" or v=="true"
end
local function verifiedEgg(o)
    return o and o:IsDescendantOf(Workspace) and (CollectionService:HasTag(o,"Egg") or o:GetAttribute("IsEgg")==true or o:GetAttribute("EggId")~=nil)
end
local function promptOf(o) return o and o:FindFirstChildWhichIsA("ProximityPrompt",true) or nil end
local function available(o) return boolAttr(o,{"Available","Availability","IsAvailable"},true) end
local function playerRoot() local c=player.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function distanceTo(o) local r=playerRoot(); local p=posOf(o); return r and p and (r.Position-p).Magnitude or nil end

local function addEgg(out,seen,o)
    if seen[o] or not verifiedEgg(o) then return end
    local p=posOf(o); if not p then return end
    seen[o]=true
    local pr=promptOf(o)
    table.insert(out,{object=o,name=o.Name,position=p,distance=distanceTo(o),
        rarity=attrs(o,{"Rarity","EggRarity","rarity"}) or "Unknown",
        mutation=attrs(o,{"Mutation","EggMutation","mutation"}) or "None",
        size=attrs(o,{"Size","EggSize","size"}) or "Unknown",available=available(o),
        hasPrompt=pr~=nil,promptEnabled=pr and pr.Enabled or false,promptDistance=pr and pr.MaxActivationDistance or nil,verified=true})
end
local function localScan()
    local out,seen={},{}
    for _,o in ipairs(CollectionService:GetTagged("Egg")) do addEgg(out,seen,o) end
    for _,o in ipairs(Workspace:GetDescendants()) do
        if o:GetAttribute("IsEgg")==true or o:GetAttribute("EggId")~=nil then addEgg(out,seen,o) end
    end
    table.sort(out,function(a,b) return (a.distance or math.huge)<(b.distance or math.huge) end)
    return out
end
local function scan()
    state.scans+=1
    if GetSnapshot then
        local ok,data=pcall(function() return GetSnapshot:InvokeServer() end)
        if ok and type(data)=="table" then state.eggs=data; log("Server scan: "..#data.." verified eggs","OK"); return data end
    end
    state.eggs=localScan(); log("Local scan: "..#state.eggs.." verified eggs","OK"); return state.eggs
end
local rarityRank={Common=1,Uncommon=2,Rare=3,Epic=4,Legendary=5,Mythic=6,Divine=7,Secret=8}
local sizeRank={Tiny=1,Small=2,Medium=3,Large=4,Huge=5,Giant=6,Massive=7,Colossal=8}
local function rankRarity(v) return rarityRank[tostring(v)] or 0 end
local function rankSize(v)
    local n=tonumber(v); if n then return n end
    return sizeRank[tostring(v)] or 0
end
local function mutationRank(v)
    local s=tostring(v)
    if s=="None" or s=="Normal" then return 0 end
    return 1
end
local function passes(e)
    if state.rarityFilter~="ALL" and tostring(e.rarity)~=state.rarityFilter then return false end
    if state.mutationFilter~="ALL" and tostring(e.mutation)~=state.mutationFilter then return false end
    if state.sizeFilter~="ALL" and tostring(e.size)~=state.sizeFilter then return false end
    if e.available==false then return false end
    if e.distance and e.distance>state.maxDistance then return false end
    return true
end
local function filtered()
    local result={}
    for _,e in ipairs(state.eggs) do if passes(e) then table.insert(result,e) end end
    return result
end
local function chooseTarget()
    local list=filtered(); if #list==0 then return nil end
    if state.targetMode=="NEAREST" then
        table.sort(list,function(a,b) return (a.distance or math.huge)<(b.distance or math.huge) end)
    elseif state.targetMode=="RARITY" then
        table.sort(list,function(a,b) local ar,br=rankRarity(a.rarity),rankRarity(b.rarity); if ar==br then return (a.distance or math.huge)<(b.distance or math.huge) end; return ar>br end)
    elseif state.targetMode=="LARGEST" then
        table.sort(list,function(a,b) local as,bs=rankSize(a.size),rankSize(b.size); if as==bs then return (a.distance or math.huge)<(b.distance or math.huge) end; return as>bs end)
    elseif state.targetMode=="MUTATION" then
        table.sort(list,function(a,b) local am,bm=mutationRank(a.mutation),mutationRank(b.mutation); if am==bm then return (a.distance or math.huge)<(b.distance or math.huge) end; return am>bm end)
    end
    return list[1]
end
local function uniqueValues(field)
    local seen={ALL=true}
    for _,e in ipairs(state.eggs) do seen[tostring(e[field])]=true end
    local result={}; for k in pairs(seen) do table.insert(result,k) end; table.sort(result,function(a,b) if a=="ALL" then return true elseif b=="ALL" then return false end return a<b end); return result
end

local function clearBody()
    for _,x in ipairs(body:GetChildren()) do if x:IsA("GuiObject") then x:Destroy() end end
end
local function layout(padding)
    local l=New("UIListLayout",{Padding=UDim.new(0,padding or 8),SortOrder=Enum.SortOrder.LayoutOrder},body)
    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() body.CanvasSize=UDim2.fromOffset(0,l.AbsoluteContentSize.Y+12) end)
end

local function clearESP()
    for _,v in ipairs(state._esp) do if v and v.Parent then v:Destroy() end end
    state._esp={}
end
local function applyESP()
    clearESP()
    if not (state.espEgg or state.espTarget or state.espDistance) then return end
    local targetObject=state.target and state.target.object
    for _,e in ipairs(state.eggs) do
        if e.object and e.object.Parent and (state.espEgg or (state.espTarget and e.object==targetObject)) then
            local h=Instance.new("Highlight")
            h.Name="FREEZY_EggESP"; h.Adornee=e.object; h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
            h.FillColor=e.object==targetObject and C.yellow or C.blue; h.OutlineColor=C.cyan; h.FillTransparency=.75; h.Parent=gui
            table.insert(state._esp,h)
        end
        if state.espDistance and e.object and e.object.Parent then
            local bb=New("BillboardGui",{Name="FREEZYDistance",Adornee=e.object,Size=UDim2.fromOffset(120,28),StudsOffset=Vector3.new(0,3,0),AlwaysOnTop=true,MaxDistance=2000},gui)
            local txt=label(bb,"—",UDim2.fromOffset(0,0),UDim2.fromOffset(120,28),C.cyan,11,true); txt.TextXAlignment=Enum.TextXAlignment.Center
            table.insert(state._esp,bb)
        end
    end
end

local renderPage
local function setPage(page) state.page=page; renderPage() end
local pages={"COMMAND CENTER","EGG SCANNER","TARGETING","RARITY","MUTATIONS","SIZE","AUTO PICKUP","VISUALS","ANALYSIS","STATISTICS","SYSTEM","UI SETTINGS"}

local function renderCommand()
    layout(9)
    local p=panel(body,185)
    stat(p,"BRIDGE",RequestAction and "READY" or "OFFLINE",UDim2.fromOffset(12,12),145)
    stat(p,"VERIFIED EGGS",#state.eggs,UDim2.fromOffset(168,12),145)
    stat(p,"TARGET",state.target and state.target.name or "NONE",UDim2.fromOffset(324,12),180)
    stat(p,"PICKUPS",state.pickups,UDim2.fromOffset(515,12),125)
    stat(p,"FAILURES",state.failures,UDim2.fromOffset(650,12),125)
    label(p,"LAST ACTION",UDim2.fromOffset(14,103),UDim2.fromOffset(100,18),C.gray,9,true)
    label(p,state.lastAction,UDim2.fromOffset(14,123),UDim2.new(1,-28,0,28),C.white,11)
    button(p,"SCAN EGGS",UDim2.new(1,-185,0,106),UDim2.fromOffset(170,36),function() scan(); renderPage() end,C.blue)
    local q=panel(body,145)
    label(q,"QUICK CONTROLS",UDim2.fromOffset(14,10),UDim2.new(1,-28,0,22),C.cyan,12,true)
    button(q,"SCAN NOW",UDim2.fromOffset(14,43),nil,function() scan(); renderPage() end)
    button(q,"SELECT TARGET",UDim2.fromOffset(178,43),nil,function() state.target=chooseTarget(); log(state.target and ("Target: "..state.target.name) or "No valid target","OK"); applyESP(); renderPage() end)
    button(q,"START AUTO",UDim2.fromOffset(342,43),nil,function() state.automation=true; state.target=state.target or chooseTarget(); log(state.target and ("Auto active: "..state.target.name) or "Auto: no valid target",state.target and "OK" or "ERROR"); renderPage() end,C.blue)
    button(q,"CLEAR TARGET",UDim2.fromOffset(506,43),nil,function() state.target=nil; log("Target cleared","OK"); applyESP(); renderPage() end)
    label(q,"Auto-Pickup: "..(state.automation and "ACTIVE" or "IDLE"),UDim2.fromOffset(14,91),UDim2.new(1,-28,0,22),state.automation and C.green or C.gray,10,true)
end

local function renderEggs()
    layout(8)
    local tools=panel(body,118)
    label(tools,"VERIFIED EGG SCANNER",UDim2.fromOffset(14,10),UDim2.new(1,-28,0,22),C.cyan,12,true)
    label(tools,"Detects Egg tags plus IsEgg/EggId-marked existing objects; no game content is created.",UDim2.fromOffset(14,35),UDim2.new(1,-28,0,20),C.gray,10)
    button(tools,"RESCAN",UDim2.fromOffset(14,65),nil,function() scan(); renderPage() end,C.blue)
    button(tools,state.espEgg and "EGG ESP: ON" or "EGG ESP: OFF",UDim2.fromOffset(178,65),nil,function() state.espEgg=not state.espEgg; applyESP(); renderPage() end)
    button(tools,"CLEAR TARGET",UDim2.fromOffset(342,65),nil,function() state.target=nil; applyESP(); renderPage() end)
    for i,e in ipairs(filtered()) do
        if i>100 then break end
        local f=panel(body,92)
        label(f,"✓  "..e.name,UDim2.fromOffset(12,9),UDim2.new(1,-240,0,22),C.white,12,true)
        label(f,string.format("%s  •  %s  •  %s",e.rarity,e.mutation,e.size),UDim2.fromOffset(12,35),UDim2.new(1,-250,0,18),C.gray,9)
        label(f,e.available==false and "UNAVAILABLE" or (e.hasPrompt and "PROMPT READY" or "NO PROMPT"),UDim2.fromOffset(12,58),UDim2.fromOffset(120,18),e.available==false and C.red or (e.hasPrompt and C.green or C.yellow),9,true)
        label(f,e.distance and string.format("%.1fm",e.distance) or "—",UDim2.new(1,-205,0,14),UDim2.fromOffset(70,22),C.cyan,11,true)
        button(f,"TARGET",UDim2.new(1,-125,0,18),UDim2.fromOffset(110,32),function() state.target=e; log("Target set: "..e.name,"OK"); applyESP(); renderPage() end)
    end
end

local function renderTargeting()
    layout(8)
    local p=panel(body,220)
    label(p,"TARGET MANAGER",UDim2.fromOffset(14,10),UDim2.new(1,-28,0,22),C.cyan,12,true)
    label(p,"PRIORITY",UDim2.fromOffset(14,43),UDim2.fromOffset(70,20),C.gray,10,true)
    for i,m in ipairs({"NEAREST","RARITY","LARGEST","MUTATION"}) do button(p,(state.targetMode==m and "● " or "○ ")..m,UDim2.fromOffset(85+(i-1)*135,36),UDim2.fromOffset(125,34),function() state.targetMode=m; renderPage() end,state.targetMode==m and C.blue or C.card2) end
    label(p,"Max distance: "..state.maxDistance.." studs",UDim2.fromOffset(14,88),UDim2.fromOffset(180,20),C.white,10,true)
    button(p,"− 25",UDim2.fromOffset(205,80),UDim2.fromOffset(90,32),function() state.maxDistance=math.max(25,state.maxDistance-25); renderPage() end)
    button(p,"+ 25",UDim2.fromOffset(302,80),UDim2.fromOffset(90,32),function() state.maxDistance=math.min(2000,state.maxDistance+25); renderPage() end)
    button(p,"AUTO SELECT",UDim2.fromOffset(14,132),UDim2.fromOffset(160,36),function() state.target=chooseTarget(); log(state.target and ("Selected "..state.target.name) or "No valid target","OK"); applyESP(); renderPage() end,C.blue)
    button(p,"CLEAR",UDim2.fromOffset(182,132),UDim2.fromOffset(110,36),function() state.target=nil; applyESP(); renderPage() end)
    local t=panel(body,100)
    label(t,"CURRENT TARGET",UDim2.fromOffset(14,10),UDim2.new(1,-28,0,20),C.gray,9,true)
    label(t,state.target and state.target.name or "NONE",UDim2.fromOffset(14,31),UDim2.new(1,-250,0,28),C.white,15,true)
    label(t,state.target and string.format("%s • %s • %s",state.target.rarity,state.target.mutation,state.target.size) or "Choose a target",UDim2.fromOffset(14,62),UDim2.new(1,-28,0,20),C.gray,10)
end

local function renderFilter(field,titleText,current,setter)
    layout(8)
    local p=panel(body,150)
    label(p,titleText,UDim2.fromOffset(14,10),UDim2.new(1,-28,0,22),C.cyan,12,true)
    label(p,"Current: "..current,UDim2.fromOffset(14,38),UDim2.new(1,-28,0,20),C.white,10,true)
    local x=14; local y=70
    for _,v in ipairs(uniqueValues(field)) do
        if x+135>body.AbsoluteSize.X then x=14; y+=38 end
        button(p,v,UDim2.fromOffset(x,y),UDim2.fromOffset(130,32),function() setter(v); renderPage() end,v==current and C.blue or C.card2)
        x+=137
    end
    p.Size=UDim2.new(1,0,0,math.max(150,y+42))
    local q=panel(body,82)
    label(q,"MATCHING EGGS",UDim2.fromOffset(14,10),UDim2.fromOffset(150,18),C.gray,9,true)
    label(q,#filtered(),UDim2.fromOffset(14,29),UDim2.fromOffset(120,28),C.white,17,true)
    label(q,"Filters apply immediately to Targeting and Auto-Pickup.",UDim2.fromOffset(150,31),UDim2.new(1,-165,0,24),C.gray,10)
end

local function renderAuto()
    layout(8)
    local p=panel(body,255)
    label(p,"AUTO-PICKUP ENGINE",UDim2.fromOffset(14,10),UDim2.new(1,-28,0,22),C.cyan,12,true)
    label(p,"MODE",UDim2.fromOffset(14,43),UDim2.fromOffset(60,20),C.gray,10,true)
    for i,m in ipairs({"ONE","CONTINUOUS","QUEUE"}) do button(p,(state.autoMode==m and "● " or "○ ")..m,UDim2.fromOffset(70+(i-1)*140,36),UDim2.fromOffset(130,34),function() state.autoMode=m; renderPage() end,state.autoMode==m and C.blue or C.card2) end
    label(p,"Interval: "..state.autoInterval.."s",UDim2.fromOffset(14,88),UDim2.fromOffset(110,20),C.white,10,true)
    button(p,"−",UDim2.fromOffset(125,82),UDim2.fromOffset(38,30),function() state.autoInterval=math.max(.5,state.autoInterval-.5); renderPage() end)
    button(p,"+",UDim2.fromOffset(168,82),UDim2.fromOffset(38,30),function() state.autoInterval=math.min(15,state.autoInterval+.5); renderPage() end)
    toggle(p,"RETURN TO START",UDim2.fromOffset(220,80),state.returnAfter,function(v) state.returnAfter=v end)
    label(p,"Auto-Pickup only acts on verified available eggs with an enabled ProximityPrompt.",UDim2.fromOffset(14,126),UDim2.new(1,-28,0,22),C.gray,9)
    button(p,state.automation and "STOP AUTO-PICKUP" or "START AUTO-PICKUP",UDim2.fromOffset(14,174),UDim2.fromOffset(205,38),function()
        if state.automation then state.automation=false; state.currentJob=false; request("STOP_ALL"); log("Auto-Pickup stopped","WARN")
        else state.automation=true; state.target=chooseTarget(); log(state.target and ("Auto-Pickup active: "..state.target.name) or "No valid target","OK") end
        renderPage()
    end,state.automation and C.red or C.blue)
    button(p,"SELECT TARGET",UDim2.fromOffset(230,174),UDim2.fromOffset(155,38),function() state.target=chooseTarget(); applyESP(); renderPage() end)
    local q=panel(body,135)
    label(q,"CURRENT JOB",UDim2.fromOffset(14,10),UDim2.new(1,-28,0,20),C.gray,9,true)
    label(q,state.target and state.target.name or "NO TARGET",UDim2.fromOffset(14,31),UDim2.new(1,-28,0,26),C.white,14,true)
    label(q,"Flow: scan → filter → target → move → normal prompt input → verify → return",UDim2.fromOffset(14,62),UDim2.new(1,-28,0,20),C.cyan,9)
    label(q,"Job state: "..(state.currentJob and "WAITING FOR PICKUP VERIFICATION" or "IDLE"),UDim2.fromOffset(14,90),UDim2.new(1,-28,0,20),state.currentJob and C.yellow or C.gray,9,true)
end

local function renderVisuals()
    layout(8)
    local p=panel(body,165)
    label(p,"EGG VISUALS",UDim2.fromOffset(14,10),UDim2.new(1,-28,0,22),C.cyan,12,true)
    toggle(p,"EGG ESP",UDim2.fromOffset(14,43),state.espEgg,function(v) state.espEgg=v; applyESP() end)
    toggle(p,"TARGET ESP",UDim2.fromOffset(207,43),state.espTarget,function(v) state.espTarget=v; applyESP() end)
    toggle(p,"DISTANCE LABELS",UDim2.fromOffset(400,43),state.espDistance,function(v) state.espDistance=v; applyESP() end)
    label(p,"Only verified eggs are highlighted.",UDim2.fromOffset(14,91),UDim2.new(1,-28,0,20),C.gray,10)
    button(p,"REFRESH ESP",UDim2.fromOffset(14,120),UDim2.fromOffset(150,34),function() scan(); applyESP() end,C.blue)
    button(p,"CLEAR ESP",UDim2.fromOffset(174,120),UDim2.fromOffset(150,34),clearESP)
end

local function renderAnalysis()
    layout(8)
    local p=panel(body,175)
    label(p,"EGG ANALYZER",UDim2.fromOffset(14,10),UDim2.new(1,-28,0,22),C.cyan,12,true)
    local availableCount,promptCount,rarities,mutations,sizes=0,0,{},{},{}
    for _,e in ipairs(state.eggs) do
        if e.available~=false then availableCount+=1 end
        if e.hasPrompt and e.promptEnabled~=false then promptCount+=1 end
        rarities[tostring(e.rarity)]=true; mutations[tostring(e.mutation)]=true; sizes[tostring(e.size)]=true
    end
    stat(p,"TOTAL",#state.eggs,UDim2.fromOffset(14,45),120)
    stat(p,"AVAILABLE",availableCount,UDim2.fromOffset(144,45),120)
    stat(p,"PROMPTS",promptCount,UDim2.fromOffset(274,45),120)
    stat(p,"RARITIES",#(function() local a={}; for k in pairs(rarities) do a[#a+1]=k end return a end)(),UDim2.fromOffset(404,45),120)
    stat(p,"MUTATIONS",#(function() local a={}; for k in pairs(mutations) do a[#a+1]=k end return a end)(),UDim2.fromOffset(534,45),120)
    button(p,"RESCAN",UDim2.fromOffset(14,122),UDim2.fromOffset(150,34),function() scan(); renderPage() end,C.blue)
    local t=panel(body,150)
    label(t,"TARGET DETAILS",UDim2.fromOffset(14,10),UDim2.new(1,-28,0,20),C.gray,9,true)
    if state.target then
        label(t,state.target.name,UDim2.fromOffset(14,32),UDim2.new(1,-28,0,25),C.white,14,true)
        label(t,string.format("Rarity: %s   Mutation: %s   Size: %s",state.target.rarity,state.target.mutation,state.target.size),UDim2.fromOffset(14,61),UDim2.new(1,-28,0,22),C.cyan,10)
        label(t,string.format("Distance: %s   Available: %s   Prompt: %s",state.target.distance and string.format("%.1f",state.target.distance) or "—",tostring(state.target.available),tostring(state.target.hasPrompt)),UDim2.fromOffset(14,90),UDim2.new(1,-28,0,22),C.gray,10)
    else label(t,"No target selected.",UDim2.fromOffset(14,42),UDim2.new(1,-28,0,25),C.gray,11) end
end

local function renderStatistics()
    layout(8)
    local p=panel(body,180)
    label(p,"SESSION STATISTICS",UDim2.fromOffset(14,10),UDim2.new(1,-28,0,22),C.cyan,12,true)
    stat(p,"SCANS",state.scans,UDim2.fromOffset(14,45),125); stat(p,"PICKUPS",state.pickups,UDim2.fromOffset(149,45),125); stat(p,"FAILURES",state.failures,UDim2.fromOffset(284,45),125); stat(p,"LOGS",#state.logs,UDim2.fromOffset(419,45),125)
    local elapsed=math.floor(os.clock()-state.startedAt); stat(p,"SESSION",string.format("%02dm %02ds",math.floor(elapsed/60),elapsed%60),UDim2.fromOffset(554,45),125)
    local q=panel(body,255); label(q,"ACTIVITY HISTORY",UDim2.fromOffset(14,10),UDim2.new(1,-28,0,22),C.cyan,12,true)
    local y=40; for i=1,math.min(#state.logs,8) do local e=state.logs[i]; label(q,e.t.."  "..e.msg,UDim2.fromOffset(14,y),UDim2.new(1,-28,0,22),e.kind=="ERROR" and C.red or (e.kind=="OK" and C.green or C.gray),9); y+=25 end
end

local function renderSystem()
    layout(8)
    local p=panel(body,220)
    label(p,"SYSTEM DIAGNOSTICS",UDim2.fromOffset(14,10),UDim2.new(1,-28,0,22),C.cyan,12,true)
    label(p,"Client: "..player.Name,UDim2.fromOffset(14,43),UDim2.new(1,-28,0,20),C.white,10)
    label(p,"PlaceId: "..tostring(game.PlaceId),UDim2.fromOffset(14,67),UDim2.new(1,-28,0,20),C.gray,10)
    label(p,"Bridge: "..(RequestAction and "READY" or "MISSING"),UDim2.fromOffset(14,91),UDim2.new(1,-28,0,20),RequestAction and C.green or C.red,10,true)
    label(p,"Tagged eggs: "..#CollectionService:GetTagged("Egg"),UDim2.fromOffset(14,115),UDim2.new(1,-28,0,20),C.white,10)
    label(p,"Verified scan: "..#state.eggs,UDim2.fromOffset(14,139),UDim2.new(1,-28,0,20),C.white,10)
    button(p,"RUN DIAGNOSTIC",UDim2.fromOffset(14,165),UDim2.fromOffset(180,34),function() scan(); log("Diagnostic completed","OK"); renderPage() end,C.blue)
end

local function renderSettings()
    layout(8)
    local p=panel(body,155)
    label(p,"UI SETTINGS",UDim2.fromOffset(14,10),UDim2.new(1,-28,0,22),C.cyan,12,true)
    label(p,"Scale: "..string.format("%.1fx",state.scale),UDim2.fromOffset(14,43),UDim2.fromOffset(100,20),C.white,10,true)
    button(p,"UI −",UDim2.fromOffset(125,39),UDim2.fromOffset(90,34),function() state.scale=math.max(.7,state.scale-.1); uiScale.Scale=state.scale; renderPage() end)
    button(p,"UI +",UDim2.fromOffset(222,39),UDim2.fromOffset(90,34),function() state.scale=math.min(1.5,state.scale+.1); uiScale.Scale=state.scale; renderPage() end)
    button(p,"RESET",UDim2.fromOffset(319,39),UDim2.fromOffset(90,34),function() state.scale=1; uiScale.Scale=1; renderPage() end)
    toggle(p,"ANIMATIONS",UDim2.fromOffset(14,91),state.animation,function(v) state.animation=v end)
    toggle(p,"FPS DISPLAY",UDim2.fromOffset(207,91),state.showFPS,function(v) state.showFPS=v end)
end

renderPage=function()
    clearBody(); title.Text=state.page
    local descriptions={
        ["COMMAND CENTER"]="Live overview and quick controls",
        ["EGG SCANNER"]="Detect and inspect verified existing eggs",
        ["TARGETING"]="Choose nearest, rarity, largest or mutated targets",
        ["RARITY"]="Filter eggs by detected rarity",
        ["MUTATIONS"]="Filter eggs by detected mutation",
        ["SIZE"]="Filter eggs by detected size",
        ["AUTO PICKUP"]="Automated targeting and normal prompt interaction",
        ["VISUALS"]="Verified egg and target visualization",
        ["ANALYSIS"]="Live egg statistics and target details",
        ["STATISTICS"]="Session counters and activity history",
        ["SYSTEM"]="Bridge and scanner diagnostics",
        ["UI SETTINGS"]="Panel scale and presentation settings"
    }
    desc.Text=descriptions[state.page] or ""
    if state.page=="COMMAND CENTER" then renderCommand()
    elseif state.page=="EGG SCANNER" then renderEggs()
    elseif state.page=="TARGETING" then renderTargeting()
    elseif state.page=="RARITY" then renderFilter("rarity","RARITY FILTER",state.rarityFilter,function(v) state.rarityFilter=v end)
    elseif state.page=="MUTATIONS" then renderFilter("mutation","MUTATION FILTER",state.mutationFilter,function(v) state.mutationFilter=v end)
    elseif state.page=="SIZE" then renderFilter("size","SIZE FILTER",state.sizeFilter,function(v) state.sizeFilter=v end)
    elseif state.page=="AUTO PICKUP" then renderAuto()
    elseif state.page=="VISUALS" then renderVisuals()
    elseif state.page=="ANALYSIS" then renderAnalysis()
    elseif state.page=="STATISTICS" then renderStatistics()
    elseif state.page=="SYSTEM" then renderSystem()
    elseif state.page=="UI SETTINGS" then renderSettings() end
end

for i,pageName in ipairs(pages) do
    local b=New("TextButton",{LayoutOrder=i,Size=UDim2.new(1,-12,0,34),BackgroundColor3=C.bg2,BorderSizePixel=0,Text="  "..pageName,TextColor3=C.gray,TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false},nav)
    Corner(b,7)
    b.Activated:Connect(function() setPage(pageName) end)
    b.MouseEnter:Connect(function() Tween(b,.1,{BackgroundColor3=C.card2,TextColor3=C.white}) end)
    b.MouseLeave:Connect(function() if state.page~=pageName then Tween(b,.1,{BackgroundColor3=C.bg2,TextColor3=C.gray}) end end)
end
navList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() nav.CanvasSize=UDim2.fromOffset(0,navList.AbsoluteContentSize.Y+10) end)

-- Dragging
local dragging,dragStart,startPos=false,nil,nil
header.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        dragging=true; dragStart=input.Position; startPos=window.Position
        input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local delta=input.Position-dragStart
        window.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
    end
end)

-- Resizing
local resizing,resizeStart,resizeSize=false,nil,nil
resize.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        resizing=true; resizeStart=input.Position; resizeSize=window.AbsoluteSize
        input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then resizing=false end end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local delta=input.Position-resizeStart
        window.Size=UDim2.fromOffset(math.max(650,resizeSize.X+delta.X),math.max(430,resizeSize.Y+delta.Y))
    end
end)

local function closePanel()
    state.open=false; Tween(window,.22,{Size=UDim2.fromOffset(20,20),BackgroundTransparency=1})
    task.delay(.23,function() window.Visible=false; launcher.Visible=true end)
end
local function openPanel()
    state.open=true; launcher.Visible=false; window.Visible=true; window.BackgroundTransparency=0
    window.Size=UDim2.fromOffset(20,20); Tween(window,.28,{Size=UDim2.fromOffset(920,600)})
end
close.Activated:Connect(closePanel); launcher.Activated:Connect(openPanel)
stop.Activated:Connect(function() state.automation=false; state.currentJob=false; state.queue={}; request("STOP_ALL"); log("STOP ALL executed","WARN"); renderPage() end)

local function activatePrompt(prompt)
    if not prompt or not prompt.Parent or not prompt.Enabled then return false,"Prompt unavailable" end
    local hold=math.max(0,prompt.HoldDuration or 0)
    local okBegin=pcall(function() prompt:InputHoldBegin() end)
    if not okBegin then return false,"Prompt input could not begin" end
    if hold>0 then task.wait(hold+0.05) end
    pcall(function() prompt:InputHoldEnd() end)
    return true
end

if ActionResult then
    ActionResult.OnClientEvent:Connect(function(result)
        if type(result)~="table" then return end
        if result.status=="TRAVEL" then
            state.currentJob=true
            local object=result.egg or (state.target and state.target.object)
            local prompt=object and promptOf(object)
            task.spawn(function()
                local ok,reason=activatePrompt(prompt)
                if not ok then
                    state.currentJob=false; state.failures+=1; log(reason,"ERROR"); request("CANCEL_AUTO_GET"); renderPage(); return
                end
                task.wait(.15)
                request("VERIFY_AND_RETURN",{egg=object,name=result.name,returnAfter=state.returnAfter})
            end)
        elseif result.status=="PICKUP_CONFIRMED" then
            state.currentJob=false; state.pickups+=1; log("Pickup verified: "..tostring(result.name or "Egg"),"OK")
            state.target=nil; applyESP()
        elseif result.status=="RETURNED" then
            log("Returned to starting position","OK")
        elseif result.status=="FAILED" then
            state.currentJob=false; state.failures+=1; log("Action failed: "..tostring(result.reason or "Unknown"),"ERROR")
        elseif result.status=="STOPPED" then
            state.currentJob=false; log("Automation stopped","WARN")
        end
        renderPage()
    end)
end

-- Single worker: prevents overlapping pickup requests and implements a real queue.
task.spawn(function()
    local nextRun=0
    while gui.Parent do
        task.wait(.15)
        if state.automation and not state.currentJob and os.clock()>=nextRun then
            nextRun=os.clock()+state.autoInterval
            scan()

            if state.autoMode=="QUEUE" then
                state.queue={}
                for _,egg in ipairs(filtered()) do table.insert(state.queue,egg) end
            end

            local target
            if state.autoMode=="QUEUE" and #state.queue>0 then
                target=table.remove(state.queue,1)
            else
                target=state.target
                if not target or not target.object or not target.object.Parent or not passes(target) then target=chooseTarget() end
            end

            state.target=target
            applyESP()

            if target and target.object then
                local prompt=promptOf(target.object)
                if not prompt or not prompt.Enabled then
                    state.failures+=1; log("Target has no enabled pickup prompt: "..target.name,"ERROR")
                    if state.autoMode=="ONE" then state.automation=false end
                else
                    request("AUTO_GET",{egg=target.object,returnAfter=state.returnAfter})
                    if state.autoMode=="ONE" then
                        -- Do not allow a second job after the first request.
                        state.automation=false
                    end
                end
            else
                state.failures+=1; log("Auto-Pickup: no valid target","ERROR"); state.automation=false
            end
            renderPage()
        end
    end
end)

local frames,lastFPS=0,os.clock()
RunService.RenderStepped:Connect(function()
    frames+=1
    local now=os.clock()
    if now-lastFPS>=1 then
        state.fps=frames; frames=0; lastFPS=now
        online.Text=state.showFPS and ("●  ONLINE   FPS "..state.fps) or "●  CLIENT ONLINE"
        if state.espDistance then
            for _,object in ipairs(state._esp) do
                if object:IsA("BillboardGui") and object.Adornee then
                    local distance=distanceTo(object.Adornee)
                    local text=object:FindFirstChildWhichIsA("TextLabel",true)
                    if text then text.Text=distance and string.format("%.1fm",distance) or "—" end
                end
            end
        end
    end
end)

scan()
renderPage()
log("FREEZY complete panel initialized","OK")
