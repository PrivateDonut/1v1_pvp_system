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
    ARENA_PLAYER1_X = -13173.569,                  -- Player 1 X coordinate
    ARENA_PLAYER1_Y = 249.4476,                     -- Player 1 Y coordinate
    ARENA_PLAYER1_Z = 21.857931,                      -- Player 1 Z coordinate (estimated)
    ARENA_PLAYER1_O = 2.6241155,                       -- Player 1 orientation (facing north)

    ARENA_PLAYER2_X = -13241.986,                  -- Player 2 X coordinate
    ARENA_PLAYER2_Y = 287.11407,                     -- Player 2 Y coordinate
    ARENA_PLAYER2_Z = 21.857931,                      -- Player 2 Z coordinate (estimated)
    ARENA_PLAYER2_O = 5.789287,                    -- Player 2 orientation (facing south)
    
    -- Matchmaking Settings
    MATCHMAKING_INTERVAL = 5000,               -- Check for matches every 5 seconds (in milliseconds)
    
    -- Countdown Settings
    COUNTDOWN_DURATION = 5,                    -- Countdown duration in seconds
    ROOT_AURA_ID = 45524,                      -- Chains of Ice effect (root aura)
    MSG_COUNTDOWN_PREFIX = "Match starts in: ",
    MSG_FIGHT = "|cFFFFFF00FIGHT!|r",         -- Yellow colored FIGHT message
    
    -- Round End Messages
    MSG_ROUND_WINNER = "|cFF00FF00%s wins the round!|r",  -- Green colored winner message
    
    -- Match Settings
    WINNING_SCORE = 2,                         -- Number of rounds needed to win a match (best of 3)
    
    -- Match End Messages
    MSG_MATCH_WINNER = "|cFFFFD700%s has won the match %d-%d!|r",  -- Golden colored final winner message
    MSG_NEXT_ROUND = "|cFF00FFFF Round %d starting soon...|r",      -- Cyan colored next round message
    MSG_CURRENT_SCORE = "|cFFFFFFFF Score: %s [%d] - [%d] %s|r",   -- White colored score update
    
    -- Round Transition Settings
    ROUND_TRANSITION_DELAY = 2000,              -- Delay before starting next round (in milliseconds)
    
    -- Logout/Disconnect Messages
    MSG_REMOVED_FROM_QUEUE = "You have been removed from the 1v1 queue due to logout.",
    MSG_OPPONENT_FORFEITED = "|cFFFFD700Your opponent has disconnected. You win by forfeit!|r",
    MSG_FORFEIT_LOSS = "|cFFFF0000You forfeited the match by disconnecting.|r",
    
    -- Status Command Messages
    MSG_STATUS_IN_QUEUE = "You are in the 1v1 queue. Position: %d of %d",
    MSG_STATUS_IN_MATCH = "You are currently in a 1v1 match. Score: %s [%d] - [%d] %s",
    MSG_STATUS_NOT_IN_SYSTEM = "You are not in the queue or any active match.",
    MSG_COMMAND_USAGE = "Usage: .1v1 status - Check your queue position or match status",
    
    -- Arena Area Settings
    ARENA_AREA_ID = 2177,                      -- Gurubashi Arena area ID
    MSG_LEFT_ARENA_FORFEIT = "|cFFFF0000%s has left the arena and forfeited the match!|r",
    MSG_LEFT_ARENA_WARNING = "|cFFFF8800You have left the arena! You forfeit!|r"
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
    if not player then
        return
    end
    
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

local function getQueuePosition(playerGuid)
    for i = 1, #pvpQueue do
        if pvpQueue[i] == playerGuid then
            return i
        end
    end
    return nil
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
    
    player:AddAura(CONFIG.ROOT_AURA_ID, player)
end

local function startCountdown(player1Guid, player2Guid, secondsLeft)
    local player1 = GetPlayerByGUID(player1Guid)
    local player2 = GetPlayerByGUID(player2Guid)
    
    if not player1 or not player2 then
        return
    end
    
    if secondsLeft > 0 then
        local message = CONFIG.MSG_COUNTDOWN_PREFIX .. secondsLeft .. "..."
        sendMessage(player1, message)
        sendMessage(player2, message)
        
        CreateLuaEvent(function()
            startCountdown(player1Guid, player2Guid, secondsLeft - 1)
        end, 1000, 1)
    else
        sendMessage(player1, CONFIG.MSG_FIGHT)
        sendMessage(player2, CONFIG.MSG_FIGHT)
        
        player1:RemoveAura(CONFIG.ROOT_AURA_ID)
        player2:RemoveAura(CONFIG.ROOT_AURA_ID)
    end
end

local function findActiveMatchByPlayer(playerGuid)
    for i, match in ipairs(activeMatches) do
        if match.player1.guid == playerGuid or match.player2.guid == playerGuid then
            return match, i
        end
    end
    return nil
end

local function forfeitMatch(match, matchIndex, forfeitingPlayerGuid, reason)
    local player1 = GetPlayerByGUID(match.player1.guid)
    local player2 = GetPlayerByGUID(match.player2.guid)
    
    local winner, loser, winnerLocation, loserLocation
    
    -- Determine winner and loser based on who forfeited
    if match.player1.guid == forfeitingPlayerGuid then
        winner = player2
        loser = player1
        winnerLocation = match.player2.originalLocation
        loserLocation = match.player1.originalLocation
    else
        winner = player1
        loser = player2
        winnerLocation = match.player1.originalLocation
        loserLocation = match.player2.originalLocation
    end
    
    -- Send appropriate message to the winner based on reason
    if winner then
        local message
        if reason == "left_arena" then
            -- Player left the arena - use the arena-specific message
            local loserName = loser and loser:GetName() or "Your opponent"
            message = string.format(CONFIG.MSG_LEFT_ARENA_FORFEIT, loserName)
        else
            -- Default to disconnect message
            message = CONFIG.MSG_OPPONENT_FORFEITED
        end
        sendMessage(winner, message)
        
        if winner:IsDead() then
            winner:ResurrectPlayer(1.0)
        end
        winner:SetHealth(winner:GetMaxHealth())
        winner:SetPower(winner:GetMaxPower(0), 0)
        winner:RemoveAura(CONFIG.ROOT_AURA_ID)
        
        -- Teleport winner back
        winner:Teleport(winnerLocation.mapId, winnerLocation.x, winnerLocation.y, winnerLocation.z, winnerLocation.o)
    end
    table.remove(activeMatches, matchIndex)
end

local function endMatch(match, matchIndex)
    local player1 = GetPlayerByGUID(match.player1.guid)
    local player2 = GetPlayerByGUID(match.player2.guid)
    
    -- Determine winner and final score
    local winner, loser, winnerScore, loserScore
    if match.player1.score >= CONFIG.WINNING_SCORE then
        winner = player1
        loser = player2
        winnerScore = match.player1.score
        loserScore = match.player2.score
    else
        winner = player2
        loser = player1
        winnerScore = match.player2.score
        loserScore = match.player1.score
    end
    
    -- Announce match winner
    if winner and loser then
        local winnerName = winner:GetName()
        local message = string.format(CONFIG.MSG_MATCH_WINNER, winnerName, winnerScore, loserScore)
        sendMessage(winner, message)
        sendMessage(loser, message)
        
        if winner:IsDead() then
            winner:ResurrectPlayer(1.0)
        end
        if loser:IsDead() then
            loser:ResurrectPlayer(1.0)
        end
        
        winner:SetHealth(winner:GetMaxHealth())
        winner:SetPower(winner:GetMaxPower(0), 0)
        loser:SetHealth(loser:GetMaxHealth())
        loser:SetPower(loser:GetMaxPower(0), 0)
        
        winner:RemoveAura(CONFIG.ROOT_AURA_ID)
        loser:RemoveAura(CONFIG.ROOT_AURA_ID)
        
        -- Teleport players back to their original locations
        local loc1 = match.player1.originalLocation
        local loc2 = match.player2.originalLocation
        
        if player1 then
            player1:Teleport(loc1.mapId, loc1.x, loc1.y, loc1.z, loc1.o)
        end
        if player2 then
            player2:Teleport(loc2.mapId, loc2.x, loc2.y, loc2.z, loc2.o)
        end
    end
    table.remove(activeMatches, matchIndex)
end

local function prepareNextRound(match)
    local player1 = GetPlayerByGUID(match.player1.guid)
    local player2 = GetPlayerByGUID(match.player2.guid)
    
    if not player1 or not player2 then
        return
    end
    
    match.currentRound = match.currentRound + 1
    
    -- Announce current score
    local player1Name = player1:GetName()
    local player2Name = player2:GetName()
    local scoreMessage = string.format(CONFIG.MSG_CURRENT_SCORE, 
        player1Name, match.player1.score, match.player2.score, player2Name)
    sendMessage(player1, scoreMessage)
    sendMessage(player2, scoreMessage)
    
    local roundMessage = string.format(CONFIG.MSG_NEXT_ROUND, match.currentRound)
    sendMessage(player1, roundMessage)
    sendMessage(player2, roundMessage)
    
    if player1:IsDead() then
        player1:ResurrectPlayer(1.0)
    end
    if player2:IsDead() then
        player2:ResurrectPlayer(1.0)
    end

    player1:SetHealth(player1:GetMaxHealth())
    player1:SetPower(player1:GetMaxPower(0), 0)
    player2:SetHealth(player2:GetMaxHealth())
    player2:SetPower(player2:GetMaxPower(0), 0)
    
    player1:ResetAllCooldowns()
    player2:ResetAllCooldowns()
    
    player1:Teleport(CONFIG.ARENA_MAP_ID, CONFIG.ARENA_PLAYER1_X, CONFIG.ARENA_PLAYER1_Y, CONFIG.ARENA_PLAYER1_Z, CONFIG.ARENA_PLAYER1_O)
    player2:Teleport(CONFIG.ARENA_MAP_ID, CONFIG.ARENA_PLAYER2_X, CONFIG.ARENA_PLAYER2_Y, CONFIG.ARENA_PLAYER2_Z, CONFIG.ARENA_PLAYER2_O)
    
    -- Apply root and start countdown after a delay
    CreateLuaEvent(function()
        local p1 = GetPlayerByGUID(match.player1.guid)
        local p2 = GetPlayerByGUID(match.player2.guid)
        if p1 and p2 then
            p1:AddAura(CONFIG.ROOT_AURA_ID, p1)
            p2:AddAura(CONFIG.ROOT_AURA_ID, p2)
            startCountdown(match.player1.guid, match.player2.guid, CONFIG.COUNTDOWN_DURATION)
        end
    end, CONFIG.ROUND_TRANSITION_DELAY, 1)
end

local function handleRoundEnd(winnerGuid, loserGuid, match, matchIndex)
    local winner = GetPlayerByGUID(winnerGuid)
    local loser = GetPlayerByGUID(loserGuid)
    
    if not winner or not loser then
        return
    end
    
    if match.player1.guid == winnerGuid then
        match.player1.score = match.player1.score + 1
    else
        match.player2.score = match.player2.score + 1
    end
    
    local winnerName = winner:GetName()
    local message = string.format(CONFIG.MSG_ROUND_WINNER, winnerName)
    sendMessage(winner, message)
    sendMessage(loser, message)
    
    -- Resurrect the loser with a small delay to ensure death state is processed
    CreateLuaEvent(function()
        local loserPlayer = GetPlayerByGUID(loserGuid)
        if loserPlayer and loserPlayer:IsDead() then
            loserPlayer:ResurrectPlayer(100, false)
        end
    end, 500, 1)
    
    -- Check if someone has won the match
    if match.player1.score >= CONFIG.WINNING_SCORE or match.player2.score >= CONFIG.WINNING_SCORE then
        endMatch(match, matchIndex)
    else
        prepareNextRound(match)
    end
end

local function createMatch(player1Guid, player2Guid, player1Location, player2Location)
    local matchData = {
        player1 = {
            guid = player1Guid,
            originalLocation = player1Location,
            score = 0
        },
        player2 = {
            guid = player2Guid,
            originalLocation = player2Location,
            score = 0
        },
        currentRound = 1,
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
            
            startCountdown(player1Guid, player2Guid, CONFIG.COUNTDOWN_DURATION)
            
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

local function OnPlayerDeath(event, killer, victim)
    local victimGuid = victim:GetGUID()
    local match, matchIndex = findActiveMatchByPlayer(victimGuid)
    
    if not match then
        -- Player is not in a 1v1 match, ignore this death
        return
    end
    
    -- Determine if this is player1 or player2 who died
    local killerGuid = killer and killer:GetGUID() or nil
    
    -- Verify the killer is the opponent in the match
    local isValidKill = false
    if match.player1.guid == victimGuid and match.player2.guid == killerGuid then
        isValidKill = true
    elseif match.player2.guid == victimGuid and match.player1.guid == killerGuid then
        isValidKill = true
    end
    
    if not isValidKill then
        -- Death was not from the designated opponent (e.g., environmental or other damage)
        return
    end
    
    handleRoundEnd(killerGuid, victimGuid, match, matchIndex)
end

local function OnPlayerLogout(event, player)
    local playerGuid = player:GetGUID()
    
    -- Check if player is in queue
    if removePlayerFromQueue(playerGuid) then

    end
    
    -- Check if player is in an active match
    local match, matchIndex = findActiveMatchByPlayer(playerGuid)
    if match then
        -- Player is in a match - they forfeit due to disconnect
        forfeitMatch(match, matchIndex, playerGuid, "disconnect")
    end
end

local function OnPlayerUpdateArea(event, player, oldArea, newArea)
    local playerGuid = player:GetGUID()
    
    -- Check if player is in an active match
    local match, matchIndex = findActiveMatchByPlayer(playerGuid)
    if not match then
        return  -- Not in a match, ignore area changes
    end
    
    -- Check if player left the arena
    if oldArea == CONFIG.ARENA_AREA_ID and newArea ~= CONFIG.ARENA_AREA_ID then
        -- Player left the arena during a match - they forfeit
        local playerName = player:GetName()
        
        -- Notify both players
        local opponent
        if match.player1.guid == playerGuid then
            opponent = GetPlayerByGUID(match.player2.guid)
        else
            opponent = GetPlayerByGUID(match.player1.guid)
        end
        
        if opponent then
            local forfeitMsg = string.format(CONFIG.MSG_LEFT_ARENA_FORFEIT, playerName)
            sendMessage(opponent, forfeitMsg)
        end
        
        sendMessage(player, CONFIG.MSG_LEFT_ARENA_WARNING)
        
        -- Forfeit the match due to leaving arena
        forfeitMatch(match, matchIndex, playerGuid, "left_arena")
    end
end

local function OnPlayerCommand(event, player, command, chatHandler)
    -- Check if command starts with "1v1"
    if command:find("^1v1") then
        local args = {}
        for word in command:gmatch("%S+") do
            table.insert(args, word:lower())
        end
        
        if args[2] == "status" then
            local playerGuid = player:GetGUID()
            
            -- Check if in queue
            local queuePosition = getQueuePosition(playerGuid)
            if queuePosition then
                local message = string.format(CONFIG.MSG_STATUS_IN_QUEUE, queuePosition, #pvpQueue)
                sendMessage(player, message)
                return false  -- Prevent default command handling
            end
            
            -- Check if in match
            local match = findActiveMatchByPlayer(playerGuid)
            if match then
                local player1 = GetPlayerByGUID(match.player1.guid)
                local player2 = GetPlayerByGUID(match.player2.guid)
                
                if player1 and player2 then
                    local player1Name = player1:GetName()
                    local player2Name = player2:GetName()
                    local message = string.format(CONFIG.MSG_STATUS_IN_MATCH,
                        player1Name, match.player1.score, match.player2.score, player2Name)
                    sendMessage(player, message)
                else
                    sendMessage(player, "You are in a match but opponent information is unavailable.")
                end
                return false 
            end

            sendMessage(player, CONFIG.MSG_STATUS_NOT_IN_SYSTEM)
            return false  -- Prevent default command handling
        else
            -- Show usage for unrecognized 1v1 commands
            sendMessage(player, CONFIG.MSG_COMMAND_USAGE)
            return false 
        end
    end
    return true
end

RegisterCreatureGossipEvent(CONFIG.NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(CONFIG.NPC_ID, 2, OnGossipSelect)

RegisterPlayerEvent(6, OnPlayerDeath)
RegisterPlayerEvent(4, OnPlayerLogout)
RegisterPlayerEvent(42, OnPlayerCommand)
RegisterPlayerEvent(47, OnPlayerUpdateArea)

CreateLuaEvent(processMatchmaking, CONFIG.MATCHMAKING_INTERVAL, 0)