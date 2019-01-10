require("survival_in_pollution/config")

-- oarc_utils.lua
-- Nov 2016
--
-- My general purpose utility functions for factorio
-- Also contains some constants and gui styles


--------------------------------------------------------------------------------
-- Useful constants
--------------------------------------------------------------------------------

local CHUNK_SIZE = 32
local MAX_FORCES = 64
local TICKS_PER_SECOND = 60
local TICKS_PER_MINUTE = TICKS_PER_SECOND * 60
local TICKS_PER_HOUR = TICKS_PER_MINUTE * 60

--------------------------------------------------------------------------------

local GAME_SURFACE_NAME=SURVIVAL_IN_POLLUTION

--------------------------------------------------------------------------------
-- General Helper Functions
--------------------------------------------------------------------------------

-- Print debug only to me while testing.
local function DebugPrint(msg)
    if ((game.players["Oarc"] ~= nil) and (global.oarcDebugEnabled)) then
        game.players["Oarc"].print("DEBUG: " .. msg)
    end
end

-- Broadcast messages to all connected players
local function SendBroadcastMsg(msg)
    for name,player in pairs(game.connected_players) do
        player.print(msg)
    end
end





-- regrowth_map.lua
-- July 2017
--
-- Code tracks all chunks generated and allows for deleting inactive chunks
-- Relies on some changes to RSO to provide random resource locations the next
-- time the land is regenerated. -- (THIS IS CURRENTLY NOT WORKING IN 0.16,
-- resources always how up in the same spot!)
-- 
-- Basic rules of regrowth:
-- 1. Area around player is safe for quite a large distance.
-- 2. Rocket silo won't be deleted. - PERMANENT
-- 3. Chunks with pollution won't be deleted.
-- 4. Chunks with railways won't be deleted.
-- 5. Anything within radar range won't be deleted, but radar MUST be active.
--      -- This works by refreshing all chunk timers within radar range using
--      the on_sector_scanned event.
-- 6. Chunks timeout after 1 hour-ish, configurable
-- 7. For now, oarc spawns are deletion safe as well, but only immediate area.

-- Generic Utility Includes


-- Default timeout of generated chunks
local REGROWTH_TIMEOUT_TICKS = TICKS_PER_HOUR
--local REGROWTH_TIMEOUT_TICKS = TICKS_PER_MINUTE -- for debug

-- We can't delete chunks regularly without causing lag.
-- So we should save them up to delete them.
local REGROWTH_CLEANING_INTERVAL_TICKS = REGROWTH_TIMEOUT_TICKS

-- Not used right now.
-- It takes a radar 7 hours and 20 minutes to scan it's whole area completely
-- So I will bump the refresh time of blocks up by 8 hours
-- RADAR_COMPLETE_SCAN_TICKS = TICKS_PER_HOUR*8
-- Additional bonus time for certain things:
-- REFRESH_BONUS_RADAR = RADAR_COMPLETE_SCAN_TICKS

-- declear before reference
local OarcRegrowthForceRefreshChunk, OarcRegrowthOffLimits

-- Init globals and set player join area to be off limits.
local function OarcRegrowthInit()
    global.chunk_regrow = {}
    global.chunk_regrow.map = {}
    global.chunk_regrow.removal_list = {}
    global.chunk_regrow.rso_region_roll_counter = 0
    global.chunk_regrow.player_refresh_index = 1
    global.chunk_regrow.min_x = 0
    global.chunk_regrow.max_x = 0
    global.chunk_regrow.x_index = 0
    global.chunk_regrow.min_y = 0
    global.chunk_regrow.max_y = 0
    global.chunk_regrow.y_index = 0
    global.chunk_regrow.force_removal_flag = -1000

    OarcRegrowthOffLimits({ x = 0, y = 0 }, 10)
end

local function GetChunkTopLeft(pos)
    return { x = pos.x - (pos.x % 32), y = pos.y - (pos.y % 32) }
end

local function GetChunkCoordsFromPos(pos)
    return { x = math.floor(pos.x / 32), y = math.floor(pos.y / 32) }
end

-- This complicated function checks that if a chunk
local function CheckChunkEmpty(pos)
    local chunkPos = GetChunkCoordsFromPos(pos)
    local search_top_left = { x = chunkPos.x * 32, y = chunkPos.y * 32 }
    local search_area = { search_top_left, { x = search_top_left.x + 32, y = search_top_left.y + 32 } }
    local total = 0
    for f, _ in pairs(game.forces) do
        if f ~= "neutral" and f ~= "enemy" then
            local entities = game.surfaces[GAME_SURFACE_NAME].find_entities_filtered({ area = search_area, force = f })
            total = total + #entities
            if (#entities > 0) then

                for _, e in pairs(entities) do
                    if ((e.type == "player") or
                            (e.type == "car") or
                            (e.type == "logistic-robot") or
                            (e.type == "construction-robot")) then
                        total = total - 1
                    end
                end
            end
        end
    end

    -- A destroyed entity is still found during the event check.
    return (total == 1)
end

-- game.surfaces[GAME_SURFACE_NAME].find_entities_filtered{area = {game.player.position, {game.player.position.x+32, game.player.position-`32}}, type= "resource"}

-- If an entity is mined or destroyed, then check if the chunk
-- is empty. If it's empty, reset the refresh timer.
local function OarcRegrowthCheckChunkEmpty(event)
    if ((event.entity.force ~= nil) and (event.entity.force ~= "neutral") and (event.entity.force ~= "enemy")) then
        if CheckChunkEmpty(event.entity.position) then
            DebugPrint("Resetting chunk timer." .. event.entity.position.x .. " " .. event.entity.position.y)
            OarcRegrowthForceRefreshChunk(event.entity.position, 0)
        end
    end
end

-- Adds new chunks to the global table to track them.
-- This should always be called first in the chunk generate sequence
-- (Compared to other RSO & Oarc related functions...)
local function OarcRegrowthChunkGenerate(pos)

    local c_pos = GetChunkCoordsFromPos(pos)

    -- If this is the first chunk in that row:
    if (global.chunk_regrow.map[c_pos.x] == nil) then
        global.chunk_regrow.map[c_pos.x] = {}
    end

    -- Confirm the chunk doesn't already have a value set:
    if (global.chunk_regrow.map[c_pos.x][c_pos.y] == nil) then
        global.chunk_regrow.map[c_pos.x][c_pos.y] = game.tick
    end

    -- Store min/max values for x/y dimensions:
    if (c_pos.x < global.chunk_regrow.min_x) then
        global.chunk_regrow.min_x = c_pos.x
    end
    if (c_pos.x > global.chunk_regrow.max_x) then
        global.chunk_regrow.max_x = c_pos.x
    end
    if (c_pos.y < global.chunk_regrow.min_y) then
        global.chunk_regrow.min_y = c_pos.y
    end
    if (c_pos.y > global.chunk_regrow.max_y) then
        global.chunk_regrow.max_y = c_pos.y
    end
end

-- Mark an area for immediate forced removal
local function OarcRegrowthMarkForRemoval(pos, chunk_radius)
    local c_pos = GetChunkCoordsFromPos(pos)
    for i = -chunk_radius, chunk_radius do
        for k = -chunk_radius, chunk_radius do
            local x = c_pos.x + i
            local y = c_pos.y + k

            if (global.chunk_regrow.map[x] == nil) then
                global.chunk_regrow.map[x] = {}
            end
            global.chunk_regrow.map[x][y] = nil
            table.insert(global.chunk_regrow.removal_list, { x = x, y = y })
        end
    end
end

-- Marks a chunk a position that won't ever be deleted.
local function OarcRegrowthOffLimitsChunk(pos)
    local c_pos = GetChunkCoordsFromPos(pos)

    if (global.chunk_regrow.map[c_pos.x] == nil) then
        global.chunk_regrow.map[c_pos.y] = {}
    end
    global.chunk_regrow.map[c_pos.x][c_pos.y] = -1
end


-- Marks a safe area around a position that won't ever be deleted.
--local function OarcRegrowthOffLimits(pos, chunk_radius)
OarcRegrowthOffLimits = function(pos, chunk_radius)
    local c_pos = GetChunkCoordsFromPos(pos)
    for i = -chunk_radius, chunk_radius do
        for k = -chunk_radius, chunk_radius do
            local x = c_pos.x + i
            local y = c_pos.y + k

            if (global.chunk_regrow.map[x] == nil) then
                global.chunk_regrow.map[x] = {}
            end
            global.chunk_regrow.map[x][y] = -1
        end
    end
end

-- Refreshes timers on a chunk containing position
local function OarcRegrowthRefreshChunk(pos, bonus_time)
    local c_pos = GetChunkCoordsFromPos(pos)

    if (global.chunk_regrow.map[c_pos.x] == nil) then
        global.chunk_regrow.map[c_pos.y] = {}
    end
    if (global.chunk_regrow.map[c_pos.x][c_pos.y] ~= -1) then
        global.chunk_regrow.map[c_pos.x][c_pos.y] = game.tick + bonus_time
    end
end

-- Forcefully refreshes timers on a chunk containing position
-- Will overwrite -1 flag.
--local function OarcRegrowthForceRefreshChunk(pos, bonus_time)
OarcRegrowthForceRefreshChunk = function(pos, bonus_time)
    local c_pos = GetChunkCoordsFromPos(pos)

    if (global.chunk_regrow.map[c_pos.x] == nil) then
        global.chunk_regrow.map[c_pos.y] = {}
    end
    global.chunk_regrow.map[c_pos.x][c_pos.y] = game.tick + bonus_time
end

-- Refreshes timers on all chunks around a certain area
local function OarcRegrowthRefreshArea(pos, chunk_radius, bonus_time)
    local c_pos = GetChunkCoordsFromPos(pos)

    for i = -chunk_radius, chunk_radius do
        for k = -chunk_radius, chunk_radius do
            local x = c_pos.x + i
            local y = c_pos.y + k

            if (global.chunk_regrow.map[x] == nil) then
                global.chunk_regrow.map[x] = {}
            end
            if (global.chunk_regrow.map[x][y] ~= -1) then
                global.chunk_regrow.map[x][y] = game.tick + bonus_time
            end
        end
    end
end

-- Refreshes timers on all chunks near an ACTIVE radar
local function OarcRegrowthSectorScan(event)
    OarcRegrowthRefreshArea(event.radar.position, 14, 0)
    OarcRegrowthRefreshChunk(event.chunk_position, 0)
end

-- Refresh all chunks near a single player. Cyles through all connected players.
local function OarcRegrowthRefreshPlayerArea()
    global.chunk_regrow.player_refresh_index = global.chunk_regrow.player_refresh_index + 1
    if (global.chunk_regrow.player_refresh_index > #game.connected_players) then
        global.chunk_regrow.player_refresh_index = 1
    end
    if (game.connected_players[global.chunk_regrow.player_refresh_index]) then
        OarcRegrowthRefreshArea(game.connected_players[global.chunk_regrow.player_refresh_index].position, 4, 0)
    end
end

-- Check each chunk in the 2d array for a timeout value
local function OarcRegrowthCheckArray()

    -- Increment X
    if (global.chunk_regrow.x_index > global.chunk_regrow.max_x) then
        global.chunk_regrow.x_index = global.chunk_regrow.min_x

        -- Increment Y
        if (global.chunk_regrow.y_index > global.chunk_regrow.max_y) then
            global.chunk_regrow.y_index = global.chunk_regrow.min_y
            DebugPrint("Finished checking regrowth array." .. global.chunk_regrow.min_x .. " " .. global.chunk_regrow.max_x .. " " .. global.chunk_regrow.min_y .. " " .. global.chunk_regrow.max_y)
        else
            global.chunk_regrow.y_index = global.chunk_regrow.y_index + 1
        end
    else
        global.chunk_regrow.x_index = global.chunk_regrow.x_index + 1
    end

    -- Check row exists, otherwise make one.
    if (global.chunk_regrow.map[global.chunk_regrow.x_index] == nil) then
        global.chunk_regrow.map[global.chunk_regrow.x_index] = {}
    end

    -- If the chunk has timed out, add it to the removal list
    local c_timer = global.chunk_regrow.map[global.chunk_regrow.x_index][global.chunk_regrow.y_index]
    if ((c_timer ~= nil) and (c_timer ~= -1) and ((c_timer + REGROWTH_TIMEOUT_TICKS) < game.tick)) then

        -- Check chunk actually exists
        if (game.surfaces[GAME_SURFACE_NAME].is_chunk_generated({ x = (global.chunk_regrow.x_index),
                                                                  y = (global.chunk_regrow.y_index) })) then
            table.insert(global.chunk_regrow.removal_list, { x = global.chunk_regrow.x_index,
                                                             y = global.chunk_regrow.y_index })
            global.chunk_regrow.map[global.chunk_regrow.x_index][global.chunk_regrow.y_index] = nil
        end
    end
end

-- Remove all chunks at same time to reduce impact to FPS/UPS
local function OarcRegrowthRemoveAllChunks()
    while (#global.chunk_regrow.removal_list > 0) do
        local c_pos = table.remove(global.chunk_regrow.removal_list)
        local c_timer = global.chunk_regrow.map[c_pos.x][c_pos.y]

        -- Confirm chunk is still expired
        if (c_timer == nil) then

            -- Check for pollution
            if (game.surfaces[GAME_SURFACE_NAME].get_pollution({ c_pos.x * 32, c_pos.y * 32 }) > 0) then
                global.chunk_regrow.map[c_pos.x][c_pos.y] = game.tick

                -- Else delete the chunk
            else
                game.surfaces[GAME_SURFACE_NAME].delete_chunk(c_pos)
                global.chunk_regrow.map[c_pos.x][c_pos.y] = nil
            end
        else

            -- DebugPrint("Chunk no longer expired?")
        end
    end
end

-- This is the main work function, it checks a single chunk in the list
-- per tick. It works according to the rules listed in the header of this
-- file.
local function OarcRegrowthOnTick()

    -- Every half a second, refresh all chunks near a single player
    -- Cyles through all players. Tick is offset by 2
    if ((game.tick % (30)) == 2) then
        OarcRegrowthRefreshPlayerArea()
    end

    -- Every tick, check a few points in the 2d array
    -- According to /measured-command this shouldn't take more
    -- than 0.1ms on average
    for i = 1, 20 do
        OarcRegrowthCheckArray()
    end

    -- Send a broadcast warning before it happens.
    if ((game.tick % REGROWTH_CLEANING_INTERVAL_TICKS) == REGROWTH_CLEANING_INTERVAL_TICKS - 601) then
        if (#global.chunk_regrow.removal_list > 100) then
            SendBroadcastMsg("Map cleanup in 10 seconds, if you don't want to lose what you found drop a powered radar on it!")
        end
    end

    -- Delete all listed chunks
    if ((game.tick % REGROWTH_CLEANING_INTERVAL_TICKS) == REGROWTH_CLEANING_INTERVAL_TICKS - 1) then
        if (#global.chunk_regrow.removal_list > 100) then
            OarcRegrowthRemoveAllChunks()
            SendBroadcastMsg("Map cleanup done, sorry for your loss.")
        end
    end
end

-- This function removes any chunks flagged but on demand.
-- Controlled by the global.chunk_regrow.force_removal_flag
-- This function may be used outside of the normal regrowth modse.
local function OarcRegrowthForceRemovalOnTick()
    -- Catch force remove flag
    if (game.tick == global.chunk_regrow.force_removal_flag + 60) then
        SendBroadcastMsg("Map cleanup in 10 seconds, if you don't want to lose what you found drop a powered radar on it!")
    end
    if (game.tick == global.chunk_regrow.force_removal_flag + 660) then
        OarcRegrowthRemoveAllChunks()
        SendBroadcastMsg("Map cleanup done, sorry for your loss.")
    end
end

require 'stdlib/event/event'
Event.register(Event.core_events.init, OarcRegrowthInit)
Event.register(defines.events.on_chunk_generated, function(event)
    OarcRegrowthChunkGenerate(event.area.left_top)
end)
Event.register(defines.events.on_built_entity, function(event)
    OarcRegrowthOffLimitsChunk(event.created_entity.position)
end)
Event.register(defines.events.on_tick, OarcRegrowthOnTick)
Event.register(defines.events.on_sector_scanned, OarcRegrowthSectorScan)
Event.register(defines.events.on_robot_built_entity, function(event)
    OarcRegrowthOffLimitsChunk(event.created_entity.position)
end)
Event.register(defines.events.on_player_mined_entity, OarcRegrowthCheckChunkEmpty)
Event.register(defines.events.on_robot_mined_entity, OarcRegrowthCheckChunkEmpty)

