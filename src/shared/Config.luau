-- Brainrot Bazaar: every tuning number for the game in one place.
-- The server and the client both read this, so a balance change is one edit.

local Config = {}

-- Money
Config.START_CASH = 100
Config.TICK_SECONDS = 1

-- Bases
Config.BASE_COUNT = 8
Config.BASE_SIZE = 16
Config.SLOTS_START = 4
Config.SLOTS_MAX = 8
Config.SLOT_COST_BASE = 1500 -- extra slot n costs SLOT_COST_BASE * (slots - 3)

-- Speed boots upgrade
Config.SPEED_LEVEL_MAX = 3
Config.SPEED_COST_BASE = 1500 -- level n costs SPEED_COST_BASE * n
Config.SPEED_PER_LEVEL = 4
Config.WALK_SPEED_BASE = 16

-- Base lock (anti-steal shield)
Config.LOCK_SECONDS = 30
Config.LOCK_COOLDOWN = 90

-- Steal
Config.STEAL_SLOW_SECONDS = 6
Config.STEAL_SLOW_SPEED = 8
Config.STEAL_COOLDOWN = 10 -- seconds before the same brainrot can be stolen again

-- Conveyor belt the brainrots walk along
Config.BELT_START_X = -52
Config.BELT_END_X = 52
Config.BELT_Z = -35
Config.BELT_SPEED = 4
Config.BELT_SPEED_RUSH = 6.5
Config.SPAWN_INTERVAL = 5
Config.SPAWN_INTERVAL_RUSH = 2.5
Config.BELT_MAX_NPCS = 10

-- Events
Config.RUSH_EVERY_MIN = 90
Config.RUSH_EVERY_MAX = 150
Config.RUSH_DURATION = 60
Config.WAVE_EVERY_MIN = 150
Config.WAVE_EVERY_MAX = 210
Config.WAVE_WARNING = 10 -- seconds of warning before the wave arrives
Config.WAVE_CASH_LOSS = 0.10 -- 10 percent of cash lost when the wave catches you

-- Rebirth: cost grows with each rebirth, income multiplier grows with it
Config.REBIRTH_BASE_COST = 25000
Config.REBIRTH_MULT_PER = 0.25

return Config
