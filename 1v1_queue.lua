-- 1v1 PvP Queue System for AzerothCore with Eluna
-- Made By: PrivateDonut

-- ==========================================
-- CONFIGURATION SECTION - Edit values below
-- ==========================================

local CONFIG = {
    -- NPC Settings
    NPC_ID = 1000000,                          -- NPC entry ID for the Duel Master
    
    -- Gossip Menu Options
    MENU_JOIN_TEXT = "Join 1v1 Queue",         -- Text shown for joining queue
    MENU_LEAVE_TEXT = "Leave 1v1 Queue",       -- Text shown for leaving queue
    GOSSIP_ICON = 0,                           -- Icon type (0 = chat bubble, 1 = vendor, 2 = taxi, etc.)
    
    -- System Messages
    MSG_JOINED = "You have joined the 1v1 queue.",
    MSG_LEFT = "You have left the 1v1 queue.",
    MSG_ALREADY_IN_QUEUE = "You are already in the 1v1 queue.",
    MSG_NOT_IN_QUEUE = "You are not in the 1v1 queue.",
    MSG_MATCH_FOUND = "Match found! Prepare to fight.",
    
    -- Message Formatting
    MSG_PREFIX = "[1v1 Arena] ",               -- Prefix for all messages
    USE_PREFIX = true,                         -- Enable/disable message prefix
    USE_COLOR = true,                          -- Enable/disable colored messages
    COLOR_CODE = "|cFFFF6060",                 -- Color code (currently light red)
    
    -- Arena Settings (Gurubashi Arena)
    ARENA_MAP_ID = 0,                          -- Eastern Kingdoms map ID
    ARENA_PLAYER1_X = -13224,                  -- Player 1 X coordinate
    ARENA_PLAYER1_Y = 227,                     -- Player 1 Y coordinate
    ARENA_PLAYER1_Z = 33,                      -- Player 1 Z coordinate (estimated)
    ARENA_PLAYER1_O = 0,                       -- Player 1 orientation (facing north)
    ARENA_PLAYER2_X = -13224,                  -- Player 2 X coordinate
    ARENA_PLAYER2_Y = 252,                     -- Player 2 Y coordinate
    ARENA_PLAYER2_Z = 33,                      -- Player 2 Z coordinate (estimated)
    ARENA_PLAYER2_O = 3.14,                    -- Player 2 orientation (facing south)
    
    -- Matchmaking Settings
    MATCHMAKING_INTERVAL = 5000                -- Check for matches every 5 seconds (in milliseconds)
}

-- ==========================================
-- DO NOT EDIT BELOW THIS LINE
-- Core functionality - No changes needed
-- ==========================================

-- Global tables
local pvpQueue = {}
local activeMatches = {}

-- Helper function to format and send messages
local function sendMessage(player, message)
    local formattedMsg = message
    
    if CONFIG.USE_PREFIX then
        formattedMsg = CONFIG.MSG_PREFIX .. formattedMsg
    end
    
    if CONFIG.USE_COLOR then
        formattedMsg = CONFIG.COLOR_CODE .. formattedMsg .. "|r"
    end
    
    player:SendBroadcastMessage(formattedMsg)
end

local function isPlayerInQueue(playerGuid)
    for i = 1, #pvpQueue do
        if pvpQueue[i] == playerGuid then
            return true
        end
    end
    return false
end

local function removePlayerFromQueue(playerGuid)
    for i = #pvpQueue, 1, -1 do
        if pvpQueue[i] == playerGuid then
            table.remove(pvpQueue, i)
            return true
        end
    end
    return false
end

local function savePlayerLocation(player)
    local x, y, z, o = player:GetLocation()
    local mapId = player:GetMapId()
    return {
        mapId = mapId,
        x = x,
        y = y,
        z = z,
        o = o
    }
end

local function teleportToArena(player, spawnPoint)
    if spawnPoint == 1 then
        player:Teleport(CONFIG.ARENA_MAP_ID, CONFIG.ARENA_PLAYER1_X, CONFIG.ARENA_PLAYER1_Y, CONFIG.ARENA_PLAYER1_Z, CONFIG.ARENA_PLAYER1_O)
    else
        player:Teleport(CONFIG.ARENA_MAP_ID, CONFIG.ARENA_PLAYER2_X, CONFIG.ARENA_PLAYER2_Y, CONFIG.ARENA_PLAYER2_Z, CONFIG.ARENA_PLAYER2_O)
    end
end

local function createMatch(player1Guid, player2Guid, player1Location, player2Location)
    local matchData = {
        player1 = {
            guid = player1Guid,
            originalLocation = player1Location
        },
        player2 = {
            guid = player2Guid,
            originalLocation = player2Location
        },
        startTime = os.time()
    }
    table.insert(activeMatches, matchData)
    return matchData
end

local function processMatchmaking()
    if #pvpQueue >= 2 then
        local player1Guid = pvpQueue[1]
        local player2Guid = pvpQueue[2]
        
        local player1 = GetPlayerByGUID(player1Guid)
        local player2 = GetPlayerByGUID(player2Guid)
        
        if player1 and player2 then
            local player1Location = savePlayerLocation(player1)
            local player2Location = savePlayerLocation(player2)
            
            createMatch(player1Guid, player2Guid, player1Location, player2Location)
            
            teleportToArena(player1, 1)
            teleportToArena(player2, 2)
            
            sendMessage(player1, CONFIG.MSG_MATCH_FOUND)
            sendMessage(player2, CONFIG.MSG_MATCH_FOUND)
            
            table.remove(pvpQueue, 1)
            table.remove(pvpQueue, 1)
        else
            if not player1 then
                table.remove(pvpQueue, 1)
            end
            if not player2 and #pvpQueue > 0 then
                if pvpQueue[1] == player2Guid then
                    table.remove(pvpQueue, 1)
                end
            end
        end
    end
end

local function OnGossipHello(event, player, creature)
    player:GossipMenuAddItem(CONFIG.GOSSIP_ICON, CONFIG.MENU_JOIN_TEXT, 0, 1)
    player:GossipMenuAddItem(CONFIG.GOSSIP_ICON, CONFIG.MENU_LEAVE_TEXT, 0, 2)
    player:GossipSendMenu(1, creature)
end

local function OnGossipSelect(event, player, creature, sender, intid, code)
    local playerGuid = player:GetGUID()
    
    if intid == 1 then
        if isPlayerInQueue(playerGuid) then
            sendMessage(player, CONFIG.MSG_ALREADY_IN_QUEUE)
        else
            table.insert(pvpQueue, playerGuid)
            sendMessage(player, CONFIG.MSG_JOINED)
        end
    elseif intid == 2 then
        if removePlayerFromQueue(playerGuid) then
            sendMessage(player, CONFIG.MSG_LEFT)
        else
            sendMessage(player, CONFIG.MSG_NOT_IN_QUEUE)
        end
    end
    
    player:GossipComplete()
end

RegisterCreatureGossipEvent(CONFIG.NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(CONFIG.NPC_ID, 2, OnGossipSelect)

CreateLuaEvent(processMatchmaking, CONFIG.MATCHMAKING_INTERVAL, 0)