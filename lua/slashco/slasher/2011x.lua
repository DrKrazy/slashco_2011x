--[[
2011x INFO:

CREDITS:
- Model: DarksArtworks (link: https://darksartworks.itch.io/)
- Kit: Krazy (dc: doctorkrazy), NotFun (dc: loadsoffun)
- Animations: Krazy (dc: doctorkrazy)
- Coding: Krazy (dc: doctorkrazy)

This is my first every project on SlashCo or even Gmod as a whole.
Any tips are greatly appreciated on this project as a whole.

]]
-- Enable to see a bunch of debug information that was used during this slasher's development
DEBUG = true

local SLASHER = {}

-- Stock SlashCo parameters
SLASHER.Name = "X_name"
SLASHER.Aliases = {
	"GOD",
	"X",
	"THE FIRST",
}

SLASHER.Class = SlashCo.SlasherClass.Unknown
SLASHER.DangerLevel = SlashCo.DangerLevel.Unknown
SLASHER.IsSelectable = true
SLASHER.Model = "models/slashco/slashers/2011x/2011x.mdl"
SLASHER.GasCanMod = 0
SLASHER.KillDelay = 2
SLASHER.ProwlSpeed = 290
SLASHER.ChaseSpeed = SLASHER.ProwlSpeed
SLASHER.Perception = 1.0
SLASHER.Eyesight = 3
SLASHER.KillDistance = 70

SLASHER.JumpscareDuration = 1
SLASHER.ChaseMusic = "slashco/slasher/2011x/2011x_tempChase.mp3"
SLASHER.ChaseRange = 300
SLASHER.ChaseRange = 300
SLASHER.ChaseFOV = 90
SLASHER.ChaseRadius = math.cos(math.rad(SLASHER.ChaseFOV))	-- That shit is weird, like why

SLASHER.Description = "X_desc"
SLASHER.ProTip = "X_tip"
SLASHER.SpeedRating = "★★★★★"
SLASHER.EyeRating = "★★★★★"
SLASHER.DiffRating = "★★★☆☆"
SLASHER.StunTime = 1

-- 2011x ability specific parameters
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

		detectionRange = 500,			-- Clone's detection range (used for outlining range for the survivor)
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
		windUp = 0.5,
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

		-- Slowness effect applied dynamically when a survivor detonates a fake item
		-- Duration is dependent on the distance form the survivor to the slasher
		Slowness = {
			active = true,
			minDuration = 1,
			maxDuration = 8,

			minDistance = 0,
			maxDistance = 800
		},

		-- Sub ability of fake items, used when they're detonated via ping
		Detonate = {
			cooldown = 4,				-- Cooldown between this ability's uses
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
		cooldown = 2,					-- Cooldown between this ability's uses

		tpRange = 2048					-- Maximum range of the teleport (clones farther can't be teleport to)
	},
}

--[[ 
	A bunch of helper functions used here and there, will remove some that are only used once in the future.
]]

-- Replaces the player's ragdoll and adds velocity to it, it's just usefull
function replaceRagdoll(player, model, velocity, velocity_origin)
	local ragdoll = player.DeadBody
	if IsValid(ragdoll) then
		ragdoll:Remove()
	end

	local burntRagdoll = ents.Create("prop_ragdoll")
	burntRagdoll:SetModel(model)
	burntRagdoll:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)
	burntRagdoll.PingType = "DEAD BODY"
	burntRagdoll.SurvivorSteamID = player:SteamID64()

	player.DeadBody = burntRagdoll

	burntRagdoll:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
	burntRagdoll:SetPos(player:GetPos())
	burntRagdoll:SetNoDraw(false)
	burntRagdoll:Spawn()
	burntRagdoll:Activate()

	if not IsValid(burntRagdoll) then return end

	for i = 0, burntRagdoll:GetPhysicsObjectCount() do
		local phys = burntRagdoll:GetPhysicsObjectNum(i)

		if IsValid(phys) then
			phys:AddVelocity(-(velocity_origin - burntRagdoll:GetPos()) * velocity)
		end
	end

	return burntRagdoll
end

-- Logic to make either survivor or 2011x say a voice line (might be refined later)
function sayPrompt(ply, input)
	if ply:Team() == TEAM_SURVIVOR then
		ply:EmitSound("slashco/survivor/voice/prompt_" .. input .. math.random(1,3) .. ".mp3")
	elseif ply:Team() == TEAM_SLASHER and ply:GetNWString("Slasher") == "2011x" then
		SlashCo.AudioSystem.PlaySound({
			soundPath = "slashco/slasher/2011x/specialinteraction_" .. input .. ".mp3",
			identifier = "2011xInteraction" .. ply:EntIndex(),
			minDistance = 500,
			maxDistance = 750,
			entity = ply,
			volume = 1,
			fadeIn = 0,
		})
	end
end

-- Getting the voiceline suffix by ping type for fake items, used for survivors
function GetVoiceByPingType(pingtype)
	for _, item in ipairs(SLASHER.Config.FakeItem.spawnList) do
		if item.pingtype == pingtype then
			return item.vlInput
		end
	end
	return nil
end

-- Used to end the charge properly
function SLASHER.endCharge(slasher, doStun, stunTime)
	slasher:SetFriction(1)
	slasher:SetNWBool("2011xCharging", false)

	if (doStun) then SLASHER.OnHitByPocketSand(slasher, nil, stunTime) end
end

-- Spawns the fake item with all its relevant stats
function SLASHER.spawnFakeItem(slasher)
	local selectedFakeItem = SLASHER.Config.FakeItem.spawnList[slasher:GetNWInt("2011xCurFakeItemSelection")]

	local mimicItem = ents.Create(selectedFakeItem.entity)
	mimicItem:Spawn()

	local fakeItem = ents.Create("sc_x_fakeitem")
	fakeItem:SetModel(mimicItem:GetModel())
	fakeItem:SetPos(slasher:EyePos())
	fakeItem:SetOwner(slasher)
	fakeItem.PingType = selectedFakeItem.pingtype
	mimicItem:Remove()

	fakeItem:SetVar("triggeredColor", SLASHER.Config.FakeItem.triggeredColor)
	fakeItem:SetVar("expRange", SLASHER.Config.FakeItem.expRange)
	fakeItem:SetVar("expDamage", SLASHER.Config.FakeItem.expDamage)
	fakeItem:SetVar("expDelay", SLASHER.Config.FakeItem.expDelay)
	fakeItem:SetVar("velocity", SLASHER.Config.FakeItem.expKnockback)
	fakeItem:SetVar("maxNear", SLASHER.Config.FakeItem.maxNear)
	fakeItem:SetVar("slowActive", SLASHER.Config.FakeItem.Slowness.active)
	fakeItem:SetVar("slowMinDuration", SLASHER.Config.FakeItem.Slowness.minDuration)
	fakeItem:SetVar("slowMaxDuration", SLASHER.Config.FakeItem.Slowness.maxDuration)
	fakeItem:SetVar("slowMinDistance", SLASHER.Config.FakeItem.Slowness.minDistance)
	fakeItem:SetVar("slowMaxDistance", SLASHER.Config.FakeItem.Slowness.maxDistance)

	fakeItem:Spawn()
	fakeItem:Activate()

	local phys = fakeItem:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetVelocity(slasher:GetAimVector() * 200 )
	end
end

-- Spawn the clones used to teleport (need to add Stage5 Behavior)
function SLASHER.spawnTpClone(pos, ang)
	local clone = ents.Create("sc_x_clone")

	clone:SetPos(pos)

	-- Wish i knew more cause creating an entire Angle just for this seems wasatful
	clone:SetAngles(ang or Angle(0,math.random(360),0))

	clone:Spawn()
	clone:Activate()

	clone:SetVar("flTicks", SLASHER.Config.Clones.flTicks)
	clone:SetVar("flRange", SLASHER.Config.Clones.flRange)
	clone:SetVar("clDuration", SLASHER.Config.Clones.duration)
end

-- Used for damaging a player
function SLASHER.damagePlayer(slasher, victim, damage, knockback)
	if victim:IsValid() and victim:IsPlayer() then
		-- If the victim is one hit, we jumpscare them instead (need to add jumps)
		-- Have to make my own jumpscare logic cause stock one wouldn't work
		if victim:Health() <= SLASHER.Config.LMB.damage then
			slasher:Freeze(true)

			timer.Simple(SLASHER.JumpscareDuration, function()
				if IsValid(slasher) and slasher:IsPlayer() then
					victim:TakeDamage(victim:Health() * 2, slasher, slasher)
				else
					victim:Kill()
				end
				slasher:Freeze(false)
			end)
			return true
		end

		local effect = EffectData()
		local dmg = DamageInfo()

		dmg:SetDamageType(DMG_SLASH)
		dmg:SetAttacker(slasher)
		dmg:SetInflictor(slasher)
		dmg:SetDamage(damage)
		victim:TakeDamageInfo(dmg)

		-- We do this cause set damage force doesn't work for some reason
		victim:SetVelocity(slasher:GetAimVector() * knockback)

		effect:SetOrigin(victim:GetPos() + Vector(0,0,40))
		util.Effect("BloodImpact", effect)
		return true
	end
	return false
end

--[[ 
	Stock SlashCo functions
]]
-- Happens when the slasher first spawns
function SLASHER.OnSpawn(slasher)
	slasher:SetViewOffset(Vector(0, 0, 50))

	slasher:SetNWBool("CanChase", false)
	slasher:SetNWBool("DisableChaseLight", true)

	-- Please dont touch anything between these two comments
	slasher:SetNWBool("2011xStunned", false)

	slasher:SetNWFloat("2011xLMBCooldown", 0)
	slasher:SetNWFloat("2011xFakeItemCooldown", 0)
	slasher:SetNWFloat("2011xChargeCooldown")
	slasher:SetNWFloat("2011xTriggerAimCooldown", 0)

	slasher:SetNWFloat("2011xGlobalCooldown", 0)

	slasher:SetNWBool("2011xCharging", false )
	slasher:SetNWInt("2011xCurFakeItemSelection", 1)

	slasher:SetEyeSight(SLASHER.Eyesight)
	slasher:SetPerception(SLASHER.Perception)

	slasher.canCrash = false
	-- Please dont touch anything between these two comments

	-- Timer set to happen infinitely, timer.IsPaused isnt available yet so we just do the comparing init
	-- Need a way to pause this time when there is no 2011x, i can't find a function for it though, help
	timer.Create("passiveClones" .. slasher:EntIndex(),SLASHER.Config.Clones.spawnTimer, -1, function()
		if not IsValid(slasher) then return end
		if (#ents.FindByClass("sc_x_clone") >= SLASHER.Config.Clones.maxAmount) then return end

		SLASHER.spawnTpClone(SlashCo.RandomPosLocator())
	end)
end

-- This happens on every tick, lord have mercy this shit sucks
-- Sorry to whoever wants to take a look into this
function SLASHER.OnTickBehaviour(slasher)
	-- This is used to detect when the slasher is looking at a clone or fakeitem
	local traceAim = util.TraceLine(
		{
			start = slasher:EyePos(),
			endpos = slasher:EyePos() + slasher:GetAimVector() * SLASHER.Config.TpToClone.tpRange,
			ignoreworld = true,
			filter = { "sc_x_clone", "sc_x_fakeitem"},
			whitelist = true
		}
	)

	-- Clone detection logic, no lcue how optimized this is but i frankly don't care
	for _, ply in ipairs(team.GetPlayers(TEAM_SURVIVOR)) do
		local distances = {}
		for _, clone in ipairs(ents.FindByClass("sc_x_clone")) do
			table.insert(distances, clone:GetPos():Distance(ply:GetPos()))
		end
		ply:SetNWBool("2011xCloneSeen", math.min(unpack(distances)) <= 250)
	end

	-- Automatic Chase logic
	local foundPlayers = slasher:FindPlayersInView(SLASHER.ChaseRange, SLASHER.ChaseRadius, false)
	for _, chasePlayer in ipairs(foundPlayers) do
		if IsValid(chasePlayer) and chasePlayer:Team() == TEAM_SURVIVOR and not slasher:GetNWBool("InSlasherChaseMode") then
			SlashCo.StartChaseMode(slasher, true)
		end
	end

	-- Logic for the charge, i wanna die this code fucking sucks
	if slasher:GetNWBool("2011xCharging") then
		slasher:AddVelocity(slasher:GetAimVector() * SLASHER.Config.Charge.speed)

		if slasher:GetVelocity():LengthSqr() > 600 * 600 then
			slasher:SetVelocity(slasher:GetVelocity():GetNormalized() * 600 - slasher:GetVelocity())
		end

		-- Hit detection, it's ass but it'll do
		local entities = SlashCo.FindPlayersInRange(slasher:GetPos(), 80, TEAM_SURVIVOR, slasher)
		for _, ent in pairs(entities) do
			if IsValid(ent) and ent:IsPlayer() and slasher:GetVelocity():LengthSqr() >= 350 * 350 then
				SLASHER.endCharge(slasher, false, nil)

				local finalDamage = SLASHER.Config.Charge.baseDamage

				if SLASHER.Config.Charge.damageBasedOnDuration then
					finalDamage = finalDamage * ((SLASHER.Config.Charge.duration - timer.TimeLeft("2011xCharge_" .. slasher:EntIndex())) / SLASHER.Config.Charge.duration)
				end

				if DEBUG then
					print("Charge damage: " .. finalDamage)
				end

				timer.Stop("2011xCharge_" .. slasher:EntIndex())
				SLASHER.damagePlayer(slasher, ent, finalDamage, 200)
			end
		end

		-- The charge crash logic, it's ass, this shit needs to be changed asap to depends on normals
		if (SLASHER.Config.Charge.crashLogic) then
			local curVel = slasher:GetVelocity():Length()
			if (curVel > SLASHER.Config.Charge.crashActivateThreshold) then slasher.canCrash = true end

			if (curVel < SLASHER.Config.Charge.crashThreshold and slasher.canCrash) then SLASHER.endCharge(slasher, true) end
		end
	end

	-- Cooldown Ability logic, this shit fucking sucks
	if (slasher:GetNWFloat("2011xLMBCooldown") > 0) then slasher:SetNWFloat("2011xLMBCooldown", slasher:GetNWFloat("2011xLMBCooldown") - FrameTime()) end
	if (slasher:GetNWFloat("2011xFakeItemCooldown") > 0) then slasher:SetNWFloat("2011xFakeItemCooldown", slasher:GetNWFloat("2011xFakeItemCooldown") - FrameTime()) end
	if (slasher:GetNWFloat("2011xChargeCooldown") > 0) then slasher:SetNWFloat("2011xChargeCooldown", slasher:GetNWFloat("2011xChargeCooldown") - FrameTime()) end
	if (slasher:GetNWFloat("2011xTriggerAimCooldown") > 0) then slasher:SetNWFloat("2011xTriggerAimCooldown", slasher:GetNWFloat("2011xTriggerAimCooldown") - FrameTime()) end
	if (slasher:GetNWFloat("2011xGlobalCooldown") > 0) then slasher:SetNWFloat("2011xGlobalCooldown", slasher:GetNWFloat("2011xGlobalCooldown") - FrameTime()) end


	-- Global conditional for if you can use each ability or not,
	-- this is a fuck fest and i have no clue how to potentially optimize this while keeping how it looks
	local globalCooldown = slasher:GetNWFloat("2011xGlobalCooldown") > 0
	local stunned = slasher:GetNWBool("2011xStunned")

	-- This conditional is giving me aids, im so sorry
	slasher:SetNWBool("2011xCanLMB",
		slasher:GetNWFloat("2011xLMBCooldown") <= 0
		and not globalCooldown
		and not stunned
	)

	slasher:SetNWBool("2011xCanFakeItem",
		slasher:GetNWFloat("2011xFakeItemCooldown") <= 0
		and #ents.FindByClass("sc_x_fakeitem") < SLASHER.Config.FakeItem.spawnLimit
		and not globalCooldown
		and not stunned
	)

	slasher:SetNWBool("2011xCanCharge",
		slasher:GetNWFloat("2011xChargeCooldown") <= 0
		and not globalCooldown
		and not stunned
	)

	slasher:SetNWBool("2011xCanTriggerAim",
		slasher:GetNWFloat("2011xTriggerAimCooldown") <= 0
		and not globalCooldown
		and not stunned
		and traceAim.Entity:IsValid()
	)
end

-- Animator function, will be finished when animations are done
function SLASHER.Animator(ply)
	local stunned = ply:GetNWBool("2011xStunned")
	local charging = ply:GetNWBool("2011xCharging")

	if not stunned then
		ply.anim_antispam = false
	end

	if ply:IsOnGround() then
		if charging then
			ply.CalcIdeal = ACT_HL2MP_RUN
			ply.CalcSeqOverride = ply:LookupSequence("chargeangy_run")
		else
			ply.CalcIdeal = ACT_HL2MP_WALK
			ply.CalcSeqOverride = ply:LookupSequence("run")

			if ply:GetVelocity():LengthSqr() == 0 then
				ply.CalcIdeal = ACT_IDLE
			ply.CalcSeqOverride = ply:LookupSequence("idle")
			end
		end
	else
		ply.CalcSeqOverride = ply:LookupSequence("float")
	end

	if stunned then
		ply.CalcSeqOverride = ply:LookupSequence("stunned")
		if not ply.anim_antispam then
			ply:SetCycle(0)
			ply.anim_antispam = true
		end
	end

	return ply.CalcIdeal, ply.CalcSeqOverride
end

-- The stun function basically, added stuntime variable
function SLASHER.OnHitByPocketSand(slasher, ply, stunTime)
	slasher:SetNWBool("2011xStunned", true)
	slasher:Freeze(true)

	stunTime = stunTime or SLASHER.StunTime

	slasher:SetNWFloat("2011xGlobalCooldown", stun)

	timer.Simple(stun, function()
		if not IsValid(slasher) then return end

		slasher:SetNWBool("2011xStunned", false)
		slasher:Freeze(false)
	end)
end

SLASHER.OnHitByBeerKeg = function(slasher) SLASHER.OnHitByPocketSand(slasher, nil) end
SLASHER.OnHitByTeslaCoil = function(slasher) SLASHER.OnHitByPocketSand(slasher, nil) end

function SLASHER.OnPlayerDeath(slasher, victim)
	timer.Simple(1, function()
		SlashCo.AudioSystem.PlaySound({
			soundPath = "slashco/slasher/2011x/dylan_laugh.mp3",
			identifier = "2011xLaugh" .. slasher:EntIndex(),
			minDistance = 5000,
			maxDistance = 1000,
			entity = slasher,
			volume = 0.5,
			fadeIn = 0,
		})
	end)
end

-- Function used for when the slasher should be in third person (the return is the state, so if you return true they're in thirdperson)
function SLASHER.Thirdperson(ply)
	return ply:GetNWBool("2011xStunned") or ply:GetNWBool("2011xCharging")
end

-- The footsteps, will be finished eventually lmfao
function SLASHER.Footstep(ply)
	return true
end

--[[
Will be done later

function SLASHER.OnBalanceForPlayers(totalSurvivors, additionalSurvivors)
	local SO = SlashCo.CurRound.OfferingData.Singularity

	-- For every 5 additional or missing survivors we increase/decrease by 1 second.
	SLASHER.CooldownReduction = math.max((SO * 4) + (0.2 * additionalSurvivors), 0) -- math.max so we don't go below 0

	if additionalSurvivors > 0 then
		SLASHER.ProwlSpeed = 200 + (3 * additionalSurvivors)
		SLASHER.ChaseSpeed = 325 + (0.5 * additionalSurvivors)
		SLASHER.KillDistance = 150 + (2 * additionalSurvivors)
	end
end
]]

-- This will be used to highlight players close enough to a clone, thank you very much Xerk
function SLASHER.PreDrawHalos(slasher)
	local plyMarked = {}

	for _, survivor in ipairs(team.GetPlayers(TEAM_SURVIVOR)) do
		if not IsValid(survivor) or not survivor:IsPlayer() or not survivor:GetNWBool("2011xCloneSeen", false) then continue end
		table.insert(plyMarked, survivor)
	end

	SlashCo.DrawHalo(plyMarked, "blue", 2, true)
	SlashCo.DrawHalo(ents.FindByClass("sc_x_*"), Color(255,0,255), nil, true)
end

--[[
    Seperated the abilities themselves into their own file cause why not.
]]

-- Left click
function SLASHER.OnPrimaryFire(slasher)
	if not IsValid(slasher) then return end
	if not slasher:GetNWBool("2011xCanLMB") then return end
	slasher:SetNWFloat("2011xLMBCooldown", SLASHER.Config.LMB.cooldown)
	slasher:SetNWFloat("2011xGlobalCooldown", SLASHER.Config.LMB.globalCooldown or 0)

	timer.Simple(SLASHER.Config.LMB.windUp, function ()
		slasher:LagCompensation(true)

		local startpos, dir = slasher:GetPos(), slasher:GetUp()

		local mins, maxs =
			Vector(-SLASHER.Config.LMB.hitboxSize / 2, -SLASHER.Config.LMB.hitboxSize / 2, -SLASHER.Config.LMB.hitboxSize / 2),
			Vector(SLASHER.Config.LMB.hitboxSize / 2, SLASHER.Config.LMB.hitboxSize / 2, SLASHER.Config.LMB.hitboxSize / 2)

		local tr = util.TraceHull({
			start = startpos,
			endpos = startpos + dir * SLASHER.Config.LMB.hitboxSize,
			maxs = maxs,
			mins = mins,

			-- I do this cause player could use fake items to eat the trace, preventing damage
			-- Im sorry but this is dead ass the only way i can think of to properly filter player but not self
			-- I know it looks inverted but i promise it works
			filter = function(ent)
				return ent:IsPlayer() and ent ~= slasher
			end,

			ignoreworld = true,
		})

		slasher:LagCompensation(false)

		local target = tr.Entity
		if target:IsValid() and target:Team() == TEAM_SURVIVOR then
			SLASHER.damagePlayer(slasher, target, SLASHER.Config.LMB.damage, SLASHER.Config.LMB.knockback)
		end
	end)
end

-- Right click
function SLASHER.OnSecondaryFire(slasher)
	if not slasher:GetNWBool("2011xCanFakeItem") then return end
	SLASHER.spawnFakeItem(slasher)

	slasher:SetNWFloat("2011xFakeItemCooldown", SLASHER.Config.FakeItem.cooldown)
	slasher:SetNWFloat("2011xGlobalCooldown", SLASHER.Config.FakeItem.globalCooldown or 0)
end

-- R
function SLASHER.OnMainAbilityFire(slasher)
	if not slasher:GetNWBool("2011xCanCharge") then return end

	slasher.canCrash = false
	slasher:SetFriction(SLASHER.Config.Charge.friction)
	slasher:SetNWBool("2011xCharging", true)
	slasher:SetVelocity(-(slasher:GetVelocity()))

	timer.Create("2011xCharge_" .. slasher:EntIndex(), SLASHER.Config.Charge.duration, 1, function()
		SLASHER.endCharge(slasher, false)
	end)

	slasher:SetNWFloat("2011xChargeCooldown", SLASHER.Config.Charge.cooldown + SLASHER.Config.Charge.cooldown)
	slasher:SetNWFloat("2011xGlobalCooldown", SLASHER.Config.Charge.duration + (SLASHER.Config.Charge.globalCooldown or 0) + 1)
end

-- F
function SLASHER.OnSpecialAbilityFire(slasher)
	if not slasher:GetNWBool("2011xCanTriggerAim") then return end
	local cooldown, gCooldown = 0, 0

	local trace = util.TraceLine(
		{
			start = slasher:EyePos(),
			endpos = slasher:EyePos() + slasher:GetAimVector() * SLASHER.Config.TpToClone.tpRange,
			ignoreworld = true,
			filter = { "sc_x_clone" , "sc_x_fakeitem"},
			whitelist = true
		}
	)

	-- We swap em
	if (trace.Hit and trace.Entity:IsValid()) then

		local entity = trace.Entity

		if entity:GetClass() == "sc_x_clone" then
			local tempPos, tempAngle = slasher:GetPos(), slasher:GetAngles()

			slasher:SetPos(trace.Entity:GetPos())
			slasher:SetEyeAngles(trace.Entity:GetAngles())

			entity:SetPos(tempPos)
			entity:SetAngles(tempAngle)

			SlashCo.AudioSystem.PlaySound({
				soundPath = "slashco/slasher/2011x/teleport.mp3",
				identifier = "2011xTeleport" .. slasher:EntIndex(),
				minDistance = 0,
				maxDistance = 2000,
				entity = slasher,
				volume = 0.5,
				fadeIn = 0,
			})

			cooldown =  SLASHER.Config.TpToClone.cooldown
			gCooldown =  SLASHER.Config.TpToClone.globalCooldown

		elseif entity:GetClass() == "sc_x_fakeitem" then

			entity:SetVar("expDamage", SLASHER.Config.FakeItem.Detonate.expDamageOverride)
			entity:SetVar("slowActive", false)
			entity:Explode()

			cooldown = SLASHER.Config.FakeItem.Detonate.cooldown
			gCooldown = SLASHER.Config.FakeItem.Detonate.globalCooldown
		end

		slasher:SetNWFloat("2011xTriggerAimCooldown", cooldown)
		slasher:SetNWFloat("2011xGlobalCooldown", gCooldown)
	end
end

-- For server stuff
if SERVER then
	hook.Add( "StartCommand", "MouseWheel", function( ply, cmd )
		if ply:Team() ~= TEAM_SLASHER or ply:GetNWString("Slasher") ~= "2011x" then return end
		if ( cmd:GetMouseWheel() ~= 0) then

			ply:SetNWInt("2011xCurFakeItemSelection", math.Clamp(ply:GetNWInt("2011xCurFakeItemSelection") + -cmd:GetMouseWheel(), 1, #SLASHER.Config.FakeItem.spawnList))
		end

		if (ply:GetNWBool("2011xCharging")) then
			cmd:ClearMovement()
		end
	end)

	hook.Add("SlashCo:OnPing", "2011xPingStuff", function(pingInfo)
		if not istable(pingInfo) then return end -- Should always be a table but just in case
		if DEBUG then PrintTable(pingInfo) end

		local pingingPlayer = pingInfo.Player
		local entity = pingInfo.Entity

		if isnumber(pingingPlayer) then pingingPlayer = Entity(pingingPlayer) end
		if isnumber(entity) then entity = Entity(entity) end

		if not IsValid(pingingPlayer) or not pingingPlayer:IsPlayer() then return end

		-- This section of code is to properly detect when you ping a slasher, as for some fucking reason it wouldn't put the entity in pinginfo.Entity
		local traced = pingingPlayer:GetEyeTrace().Entity

		-- Had to do this cause if you ping a player it wouldn't return the entity, and so I couldn't get a slasher's name
		if traced:IsPlayer() and pingingPlayer:Team() == TEAM_SLASHER and traced:Team() == TEAM_SLASHER then
			pingInfo.Type = traced:GetNWString("Slasher", "")
		end

		-- Fake item stuff
		if IsValid(entity) and entity:GetClass() == "sc_x_fakeitem" and pingInfo.Team == TEAM_SURVIVOR then
			local voiceline = GetVoiceByPingType(pingInfo.Type)

			-- If a survivor pings the fake item, we make them say the line and return
			if voiceline then
				sayPrompt(pingingPlayer, voiceline)
			end
			return true
		end

		-- Used for 2011x special interactions
		local returnTarget = IsValid(entity) and entity:GetClass() or pingInfo.Type

		local voiceline = SLASHER.Config.specialInteractions[string.lower(returnTarget or "")]
		if not voiceline then return end	-- If there's no voiceline at all then we return

		if istable(voiceline) then
			voiceline = voiceline[math.random(#voiceline)]
		end
		sayPrompt(pingingPlayer, voiceline)

		return false
	end)

-- For client stuff, this goes on EVERY client, watch out for that, use LocalPlayer() if you wanna check for stuff
elseif CLIENT then
	hook.Add("Think", "FakeChaseLight", function()
		for _, slasher in ipairs(team.GetPlayers(TEAM_SLASHER)) do
			if slasher:GetNWString("slasher") ~= "2011x" or not slasher:GetNWBool("InSlasherChaseMode") then continue end
			local dlight = DynamicLight(slasher:UserID())

			if dlight then
				dlight.pos = slasher:LocalToWorld(Vector(0,0,40))
				dlight.r = SLASHER.Config.chaseColor.r
				dlight.g = SLASHER.Config.chaseColor.g
				dlight.b = SLASHER.Config.chaseColor.b
				dlight.brightness = 6

				dlight.Decay = 1000
				dlight.Size = 300
				dlight.DieTime = CurTime() + 1
			end
		end
	end)

	hook.Add("PreDrawHalos", "CloneHighlight", function()
		local ply = LocalPlayer()
		if not IsValid(ply) or ply:Team() ~= TEAM_SURVIVOR then return end

		local lookingClones = {}

		for _, clone in ipairs(ents.FindByClass("sc_x_clone")) do
			if clone:GetPos():Distance(ply:GetPos()) < SLASHER.Config.Clones.detectionRange then
				table.insert(lookingClones, clone)
			end
		end

		halo.Add(lookingClones, Color(255,0,0), 1, 1, 2, nil, true)
	end)

	local iconTable = {
		lmbTable = {
			default = Material("slashco/ui/icons/slasher/2011x/LMB"),
			["d/"] = Material("slashco/ui/icons/slasher/2011x/LMB_d")
		},
		rmbTable = {
			default = Material("slashco/ui/icons/slasher/2011x/fakeitem"),
			["d/"] = Material("slashco/ui/icons/slasher/2011x/fakeitem_d")
		},
		mwTable = {
			default = Material("slashco/ui/icons/slasher/2011x/"),
			["d/"] = Material("slashco/ui/icons/slasher/2011x/_d")
		},
		fTable = {
			default = Material("slashco/ui/icons/slasher/2011x/tptoclone"),
			["d/"] = Material("slashco/ui/icons/slasher/2011x/tptoclone_d"),
			["detonate"] = Material("slashco/ui/icons/slasher/2011x/detonate"),
			["d/detonate"] = Material("slashco/ui/icons/slasher/2011x/detonate_d")
		},
		rTable = {
			default = Material("slashco/ui/icons/slasher/2011x/charge"),
			["d/"] = Material("slashco/ui/icons/slasher/2011x/charge_d")
		}
	}

	function SLASHER.InitHud(_, hud)
		hud:SetAvatar(Material("slashco/ui/icons/slasher/2011x/avatar"))
		hud:SetTitle(SLASHER.Name)
		hud:SetCrosshairEnabled(true)
		hud:SetCrosshairAlpha(255)
		hud:SetCrosshairSpin(0)
		hud:SetCrosshairTighten(5)
		hud:SetCrosshairProngs(4)

		hud:TieCrosshair({
			"2011xCanTriggerAim",
			InvertOutput = true,
			IsOr = true
		}, {
			TightenOn = 20,
			TightenOff = 0
		})

		-- Control Stuff
		-- This was made to make creating the controls and editing them easier for the cooldown system
		-- Do NOT make this a hash table, otherwise you won't be able to control the order in the hud
		local handleCooldowns = {
			{
				key = "R",
				controlName = "X_charge",
				netVarCD = "2011xChargeCooldown",
				netVarTie = "2011xCanCharge",
				icon = iconTable.rTable,
				preventOverwrite = false,
			},
			{
				key = "F",
				controlName = "X_aimAtBelonging",
				netVarCD = "2011xTriggerAimCooldown",
				netVarTie = "2011xCanTriggerAim",
				icon = iconTable.fTable,
				preventOverwrite = false,
			},
			{
				key = "MOUSEWHEEL",
				controlName = "X_itemSelection",
				netVarCD = "",
				netVarTie = "2011xCanFakeItem",
				icon = iconTable.mwTable,
				preventOverwrite = true,
			},
			{
				key = "RMB",
				controlName = "X_fakeItem",
				netVarCD = "2011xFakeItemCooldown",
				netVarTie = "2011xCanFakeItem",
				icon = iconTable.rmbTable,
				preventOverwrite = false,
			},
			{
				key = "LMB",
				controlName = "kill survivor",
				netVarCD = "2011xLMBCooldown",
				netVarTie = "2011xCanLMB",
				icon = iconTable.lmbTable,
				preventOverwrite = false,
			},
		}

		for _, control in pairs(handleCooldowns) do
			hud:AddControl(control.key, "", control.icon)
			hud:TieControl(control.key, control.netVarTie, false, true, nil)
		end

		local slasher = GameData.LocalPlayer

		-- This is mainly used to update the hud for the cooldowns

		function hud.AlsoThink()
			local globalCooldown = slasher:GetNWFloat("2011xGlobalCooldown", 0)
			local fakeItemSelection = slasher:GetNWInt("2011xCurFakeItemSelection", 1)

			for _, control in ipairs(handleCooldowns) do
				local cooldown = math.max(slasher:GetNWFloat(control.netVarCD, 0), globalCooldown)

				local controlName = control.controlName
				if control.preventOverwrite then controlName = tostring(SLASHER.Config.FakeItem.spawnList[fakeItemSelection].pingtype) end

				local text = SlashCo.LangTable[controlName]
				if cooldown > 0 then text = string.format( "[ %.1f ] %s", cooldown, text ) end

				hud:SetControlText(control.key, text)
			end
		end
	end
end

SlashCo.RegisterSlasher(SLASHER, "2011x")