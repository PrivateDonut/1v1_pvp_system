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
    
    -- Message Formatting
    MSG_PREFIX = "[1v1 Arena] ",               -- Prefix for all messages
    USE_PREFIX = true,                         -- Enable/disable message prefix
    USE_COLOR = true,                          -- Enable/disable colored messages
    COLOR_CODE = "|cFFFF6060"                  -- Color code (currently light red)
}

-- ==========================================
-- DO NOT EDIT BELOW THIS LINE
-- Core functionality - No changes needed
-- ==========================================

-- Global tables
local pvpQueue = {}

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