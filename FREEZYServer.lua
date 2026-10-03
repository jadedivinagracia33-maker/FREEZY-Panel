-- FREEZY COMPLETE SERVER BRIDGE
-- Install as a Script in ServerScriptService.
-- This file creates NO maps, eggs, rewards, inventory, pets, or other game content.
-- It only scans existing egg objects and validates movement/pickup state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local folder = ReplicatedStorage:FindFirstChild("FREEZYRemotes")
if not folder then
    folder = Instance.new("Folder")
    folder.Name = "FREEZYRemotes"
    folder.Parent = ReplicatedStorage
end

local function ensure(className, name)
    local r = folder:FindFirstChild(name)
    if r and not r:IsA(className) then
        r:Destroy()
        r = nil
    end
    if not r then
        r = Instance.new(className)
        r.Name = name
        r.Parent = folder
    end
    return r
end

local GetSnapshot = ensure("RemoteFunction", "GetSnapshot")
local RequestAction = ensure("RemoteEvent", "RequestAction")
local ActionResult = ensure("RemoteEvent", "ActionResult")

local lastRequest = {}
local startCFrames = {}
local MAX_DISTANCE = 2500
local REQUEST_COOLDOWN = 0.20

local function root(player)
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function positionOf(instance)
    if not instance then return nil end
    if instance:IsA("BasePart") then return instance.Position end
    if instance:IsA("Attachment") then return instance.WorldPosition end
    if instance:IsA("Model") then
        if instance.PrimaryPart then return instance.PrimaryPart.Position end
        local part = instance:FindFirstChildWhichIsA("BasePart", true)
        return part and part.Position or nil
    end
    return nil
end

local function attribute(instance, names)
    for _, name in ipairs(names) do
        local value = instance:GetAttribute(name)
        if value ~= nil then return value end
    end
    return nil
end

local function truthy(value, default)
    if value == nil then return default end
    return value == true or value == 1 or value == "1" or value == "true"
end

local function isVerifiedEgg(instance)
    if not instance or not instance:IsDescendantOf(Workspace) then return false end
    return CollectionService:HasTag(instance, "Egg")
        or instance:GetAttribute("IsEgg") == true
        or instance:GetAttribute("EggId") ~= nil
end

local function getPrompt(instance)
    return instance and instance:FindFirstChildWhichIsA("ProximityPrompt", true) or nil
end

local function isAvailable(instance)
    return truthy(attribute(instance, {"Available", "Availability", "IsAvailable"}), true)
end

local function snapshot(player)
    local result = {}
    local seen = {}
    local playerRoot = root(player)

    local function add(instance)
        if seen[instance] or not isVerifiedEgg(instance) then return end
        local position = positionOf(instance)
        if not position then return end
        seen[instance] = true

        local distance = playerRoot and (playerRoot.Position - position).Magnitude or nil
        if distance and distance > MAX_DISTANCE then return end

        local prompt = getPrompt(instance)
        table.insert(result, {
            object = instance,
            name = instance.Name,
            position = position,
            rarity = attribute(instance, {"Rarity", "EggRarity", "rarity"}) or "Unknown",
            mutation = attribute(instance, {"Mutation", "EggMutation", "mutation"}) or "None",
            size = attribute(instance, {"Size", "EggSize", "size"}) or "Unknown",
            available = isAvailable(instance),
            hasPrompt = prompt ~= nil,
            promptEnabled = prompt and prompt.Enabled or false,
            promptDistance = prompt and prompt.MaxActivationDistance or nil,
            verified = true,
            distance = distance,
        })
    end

    for _, instance in ipairs(CollectionService:GetTagged("Egg")) do
        add(instance)
    end

    -- Also support existing game objects that use FREEZY's documented
    -- IsEgg/EggId attributes without an Egg CollectionService tag.
    for _, instance in ipairs(Workspace:GetDescendants()) do
        if instance:GetAttribute("IsEgg") == true or instance:GetAttribute("EggId") ~= nil then
            add(instance)
        end
    end

    table.sort(result, function(a, b)
        return (a.distance or math.huge) < (b.distance or math.huge)
    end)
    return result
end

GetSnapshot.OnServerInvoke = function(player)
    return snapshot(player)
end

local function rateLimited(player)
    local now = os.clock()
    local previous = lastRequest[player]
    if previous and now - previous < REQUEST_COOLDOWN then
        return true
    end
    lastRequest[player] = now
    return false
end

local function sendFailure(player, reason)
    ActionResult:FireClient(player, {status = "FAILED", reason = reason})
end

local function validateEgg(player, egg)
    if typeof(egg) ~= "Instance" then return false, "Invalid target" end
    if not egg:IsDescendantOf(Workspace) then return false, "Egg no longer exists" end
    if not isVerifiedEgg(egg) then return false, "Target is not a verified egg" end
    if not isAvailable(egg) then return false, "Egg is unavailable" end

    local position = positionOf(egg)
    if not position then return false, "Egg position unavailable" end

    local playerRoot = root(player)
    if not playerRoot then return false, "Character unavailable" end

    local distance = (playerRoot.Position - position).Magnitude
    if distance > MAX_DISTANCE then return false, "Target is too far away" end

    local prompt = getPrompt(egg)
    if not prompt then return false, "No ProximityPrompt found" end
    if not prompt.Enabled then return false, "Pickup prompt is disabled" end

    return true, prompt
end

RequestAction.OnServerEvent:Connect(function(player, action, payload)
    if action ~= "STOP_ALL" and rateLimited(player) then return end

    if action == "STOP_ALL" or action == "CANCEL_AUTO_GET" then
        startCFrames[player] = nil
        ActionResult:FireClient(player, {status = "STOPPED"})
        return
    end

    if action == "RETURN_TO_START" then
        local playerRoot = root(player)
        local saved = startCFrames[player]
        if playerRoot and saved then
            playerRoot.CFrame = saved
            startCFrames[player] = nil
            ActionResult:FireClient(player, {status = "RETURNED", returned = true})
        else
            sendFailure(player, "No saved starting position")
        end
        return
    end

    if action == "AUTO_GET" or action == "TELEPORT_TO_EGG" then
        if type(payload) ~= "table" then
            sendFailure(player, "Invalid action payload")
            return
        end

        local egg = payload.egg
        local valid, promptOrReason = validateEgg(player, egg)
        if not valid then
            sendFailure(player, promptOrReason)
            return
        end

        local playerRoot = root(player)
        local position = positionOf(egg)
        if not playerRoot or not position then
            sendFailure(player, "Position unavailable")
            return
        end

        if payload.saveStart ~= false then
            startCFrames[player] = playerRoot.CFrame
        end

        -- Keep the player close enough for the normal ProximityPrompt system.
        -- The actual pickup/reward remains owned by the existing game's prompt handler.
        local offset = math.max(2, math.min(4, (promptOrReason.MaxActivationDistance or 10) * 0.35))
        playerRoot.CFrame = CFrame.new(position + Vector3.new(0, offset, 0))
        ActionResult:FireClient(player, {
            status = "TRAVEL",
            name = egg.Name,
            egg = egg,
            prompt = promptOrReason,
        })
        return
    end

    if action == "VERIFY_AND_RETURN" then
        if type(payload) ~= "table" then
            sendFailure(player, "Invalid verification payload")
            return
        end

        local egg = payload.egg
        if typeof(egg) ~= "Instance" then
            sendFailure(player, "Invalid target")
            return
        end

        local gone = not egg:IsDescendantOf(Workspace)
        local unavailable = not isAvailable(egg)
        local promptGone = getPrompt(egg) == nil

        if not (gone or unavailable or promptGone) then
            sendFailure(player, "Pickup was not verified")
            return
        end

        local returned = false
        if payload.returnAfter ~= false then
            local playerRoot = root(player)
            local saved = startCFrames[player]
            if playerRoot and saved then
                playerRoot.CFrame = saved
                returned = true
            end
        end

        startCFrames[player] = nil
        ActionResult:FireClient(player, {
            status = "PICKUP_CONFIRMED",
            name = tostring(payload.name or egg.Name),
            returned = returned,
        })
        return
    end

    sendFailure(player, "Unknown action: " .. tostring(action))
end)

Players.PlayerRemoving:Connect(function(player)
    lastRequest[player] = nil
    startCFrames[player] = nil
end)
