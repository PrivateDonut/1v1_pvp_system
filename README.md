# 1v1 PvP Queue System

A simple automated 1v1 arena system for AzerothCore with Eluna. Players can queue up and get matched for fair 1v1 duels automatically!

## What This Does

This script creates an NPC that lets players:
- Join a queue for 1v1 fights
- Get matched with another player automatically
- Fight in Gurubashi Arena (best of 3 rounds)
- Get teleported back when the match ends

## Quick Setup Guide

### Step 1: Create the NPC
Add this NPC to your database:
```sql
INSERT INTO creature_template (entry, name, subname, minlevel, maxlevel, faction, npcflag, scale) 
VALUES (1000000, 'Arena Master', '1v1 Queue', 80, 80, 35, 1, 1);
INSERT INTO creature_template_model(CreatureID, CreatureDisplayID, DisplayScale) VALUES(1000000, 987, 1);
```

### Step 2: Place the NPC in Your World
Spawn the NPC where players can find it easily (like in a major city):
```
.npc add 1000000
```

### Step 3: Install the Script
1. Put the `1v1_core.lua` file in your server's lua_scripts folder
2. Restart your server or reload Eluna

That's it! Players can now use the NPC to queue for 1v1 matches.

## Simple Configuration

Open `1v1_core.lua` and look at the top section. You can easily change:

### NPC Settings
- `NPC_ID` - Change this if you use a different NPC ID (default: 1000000)

### Messages Players See
- `MSG_JOINED` - Message when joining queue
- `MSG_LEFT` - Message when leaving queue  
- `MSG_MATCH_FOUND` - Message when match starts
- `COLOR_CODE` - Change the color of messages

### Match Settings
- `WINNING_SCORE` - How many rounds to win (default: 2 for best of 3)
- `COUNTDOWN_DURATION` - Seconds before fight starts (default: 5)

### Arena Location
The script uses Gurubashi Arena by default. If you want to use a different arena:
1. Go to your arena location in-game
2. Type `.gps` to get coordinates
3. Replace the ARENA coordinates in the config

## How Players Use It

1. Talk to the Arena Master NPC
2. Click "Join 1v1 Queue"
3. Wait for another player to queue
4. Get teleported to arena when matched
5. Fight! (Best of 3 rounds)
6. Get sent back after the match

Players can leave the queue anytime by talking to the NPC again.

## Common Issues & Fixes

**NPC won't appear:**
- Check the NPC ID matches in both the database and script
- Make sure Eluna is installed and working

**Players stuck in arena:**
- The script should teleport them back automatically
- If not, they can use hearthstone

**Match not starting:**
- Need at least 2 players in queue
- Check both players are online and not in combat

**Want to change the arena:**
- Use `.gps` at your desired location
- Update the ARENA coordinates in the config section
- Restart the server

## Notes for Server Owners

- This is a fair fight system - both players get full health/mana between rounds
- Players can't interfere with other matches
- The queue is first-come, first-served
- No rewards are given by default (TBA)
- Works with any level players (they keep their gear/stats)

## Support

Created by PrivateDonut for the AzerothCore community.
Having issues? [Create An Issue on Github](https://github.com/PrivateDonut/1v1_pvp_system/issues)