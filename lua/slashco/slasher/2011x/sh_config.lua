-- 2011X Specific Parameters (sorry to whoever wants to balance this fucking slasher lmfao)
SLASHER.Config = {
	-- Normal settings
	chaseColor = Color(38, 0, 255),

	-- Uses the entity class or a Slasher's name (both in lowercase) and associates it to a voiceline for 2011x
	-- You can use a table for randomized lines or just a string if you only want one played
	specialInteractions = {
		["sc_generator"] = "pieceofshit",
		["sc_battery"] = "fuckyou",
		["sc_x_fakeitem"] = "fuckyou",
		["sc_x_clone"] = "fuckyou",
		["prop_ragdoll"] = "pieceofshit",

		["survivor"] = { "pieceofshit", "fuckyou" },
		["2011x"] = "pieceofshit",
		["postal dude"] = "fuckyou",
	},

	-- Passives
	Clones = {
		spawnTimer = 0,					-- Time between each spawn
		maxAmount = 10,					-- Amount of Clones that can spawn
		duration = nil,					-- Duration of a clone until it dissapears (nil for infinite)

		detectionRange = 200,			-- Clone's detection range (used for outlining and apperance range for the survivor)
		flRange = 200,					-- Range for the flishlight to work against the clones
		flTicks = 2						-- How much time (in seconds) you need to keep your flashlight on the clone for it to dissapear
	},

	-- Abilities
	-- Every ability has a shared globalCooldown variable.

	-- Left Click (normal attack)
	LMB = {
		cooldown = 1,
		globalCooldown = 1,
		knockback = 150,
		hitboxSize = 120,

		damage = 35,
		windup = 0.5,
	},

	-- Right Click (spawns an explosive item that explodes on use or if pinged by 2011x)
	FakeItem = {
		cooldown = 0,						-- Cooldown between this ability's uses
		spawnLimit = 4,						-- Max amount of fake items you can spawn
		maxNear = nil,						-- Amount that can be in range of eachother before they start to detonate (nil for infinite)

		triggeredColor = Color(255,0,0),  -- Color of the fake item when it is triggered
		expDelay = 0.2,						-- The delay after use before the explosion happens
		expRange = 100,						-- Range of explosion
		expDamage = 5,						-- Amount of damage it does when it explodes
		expKnockback = 25,						-- Force of the explosion (used to apply velocity to players)

		Slowness = {
			active = true,
			minDuration = 1,
			maxDuration = 8,

			minDistance = 0,
			maxDistance = 800
		},

		-- Sub ability of fake items, used when they're detonated via ping
		Detonate = {
			cooldown = 0,				-- Cooldown between this ability's uses
			globalCooldown = 0,			-- Global cooldown on all abilities when used

			expDamageOverride = 999		-- The damage the fake item explosion will do if detonated by the 2011x
		},

		-- List of items that X can spawns with FakeItem
		-- Ping type can't be retrieved from mimic entity, so we have to set it manually
		-- vlInput is the suffix for the voiceline, mainly used for fake items to play the right voicelines when survivors ping em
		spawnList = {
			{ entity = "sc_gascan" , 	pingtype = "GasCan",	vlInput = "gascan"},
			{ entity = "sc_battery" , 	pingtype = "Battery",	vlInput = "battery"},
			{ entity = "sc_brick" , 	pingtype = "Brick",		vlInput = "brick"},
			{ entity = "sc_beacon" , 	pingtype = "Beacon",	vlInput = "beacon"},
		},
	},

	-- Charge ability, used for closing distance really fast or getting a kill if a survivor is out in the open
	Charge = {
		cooldown = 2,					-- Cooldown between this ability's uses
		duration = 8,					-- Total duration of charge
		speed = 30,						-- Base speed
		friction = 0.15,				-- Acceleration overtime that depends on speed
		baseDamage = 40,				-- Base damage
		damageBasedOnDuration = false,	-- Should the damage of the charge depends on it's current length

		crashLogic = false, 			-- Activate the crash logic (prevents people from pinballing around the map and getting auranteed hits)
		crashActivateThreshold = 600,	-- At what velocity threshold the slasher CAN crash
		crashThreshold = 400,			-- At what velocity ACTUALLY crashes if it goes below

	},

	-- When looking at a clone from anywhere i nthe map you can swap positions with it, usefull for ambushes
	TpToClone = {
		globalCooldown = 0,				-- Global cooldown on all abilities when used (prevents being able to instantly do stuff after manifesting)
		cooldown = 0,					-- Cooldown between this ability's uses

		tpRange = 2048					-- Maximum range of the teleport (clones farther can't be teleport to)
	},
}