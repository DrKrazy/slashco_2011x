local SLASHER = {}
local SlashCoItems = SlashCoItems or {}

-- Manual precache for some stuff
-- hook.Add("SlashCo:Precache", "SlashCo:PrecacheBeacon", function()
-- 	SlashCo.PrecacheSound("slashco/slasher/2011x/2011x_tempChase.ogg")
-- end)

--[[
2011x INFO:

CREDITS: 
- Crusty (dc: loadsoffun): Original kit and project
- Krazy (dc: doctorkrazy): Model porter, kit continuation, lead and project hijacker (oops)
- DarksArtworks (link: https://darksartworks.itch.io/): Original creator of the 2011x model

This is my first every project on SlashCo or even Gmod as a whole, any tips are greatly appreciated on this project as a whole.
]]

-- Generic Slasher Parameters

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
SLASHER.ProwlSpeed = 310
SLASHER.ChaseSpeed = 310
SLASHER.Perception = 1.0
SLASHER.Eyesight = 6
SLASHER.KillDistance = 70

SLASHER.JumpscareDuration = 2
SLASHER.ChaseMusic = "slashco/slasher/2011x/2011x_tempChase.ogg"
SLASHER.ChaseRange = 300
SLASHER.ChaseRadius = 0.1
SLASHER.KillSound = ""

SLASHER.Description = "X_desc"
SLASHER.ProTip = "X_tip"
SLASHER.SpeedRating = "★★★★★"
SLASHER.EyeRating = "★★★★★"
SLASHER.DiffRating = "★★★☆☆"
SLASHER.StunTime = 8

-- 2011X Specific Parameters (sorry to whoever wants to balance this fucking slasher lmfao)
SLASHER.XSettings = {

	-- Passives
	Clones = {
		spawnTimer = 1,					-- Time between each spawn
		maxAmount = 4,					-- Amount of Clones that can spawn
		duration = nil,					-- Duration of a clone until it dissapears (nil for infinite)

		detectionRange = 200,			-- Clone's detection range (used for outlining and apperance range for the survivor)
		flRange = 200,					-- Range for the flishlight to work against the clones
		flTicks = 2						-- How much time (in seconds) you need to keep your flashlight on the clone for it to dissapear
	},
	-- Abilities
	LMB = {
		cooldown = 1,
		globalCooldown = 1,
		knockback = 9999,
		hitboxSize = 120,

		damage = 30,
		windup = 0.5,
	},

	FakeItem = {
		cooldown = 1,						-- Cooldown between this ability's uses
		spawnLimit = 4,						-- Max amount of fake items you can spawn
		maxNear = nil,						-- Amount that can be in range of eachother before they start to detonate (nil for infinite)

		triggeredColor = Color(255,0,0),  -- Color of the fake item when it is triggered
		expDelay = 0.2,						-- The delay after use before the explosion happens
		expRange = 200,						-- Range of explosion
		expDamage = 25,						-- Amount of damage it does when it explodes
		expForce = 25,						-- Force of the explosion (used to apply velocity to players)

		slasherKnockback = false, 			-- Force of the explosion will also apply to the slasher (rocket jumping)

		-- List of items that X can spawns with FakeItem
		-- Ping type can't be retrieved from mimic entity, so we have to set it manually
		spawnList = {
			{ entity = "sc_gascan" , 	pingtype = "GasCan",	vlInput = "gascan"},
			{ entity = "sc_battery" , 	pingtype = "Battery",	vlInput = "battery"},
			{ entity = "sc_brick" , 	pingtype = "Brick",		vlInput = "brick"},
			{ entity = "sc_beacon" , 	pingtype = "Beacon",	vlInput = "beacon"},
		},
	},

	Detonate = {
		cooldown = 6,
		globalCooldown = 0
	},

	Charge = {
		cooldown = 2,					-- Cooldown between this ability's uses
		duration = 3,					-- Total duration of charge
		speed = 30,						-- Base speed
		friction = 0.15,				-- Acceleration overtime that depends on speed
		baseDamage = 40,				-- Base damage
		damageBasedOnDuration = true,	-- Should the damage of the charge depends on it's current length

		crashLogic = true, 			-- Activate the crash logic (prevents people from pinballing around the map and getting auranteed hits)
		crashActivateThreshold = 600,	-- At what velocity threshold the slasher CAN crash
		crashThreshold = 400,			-- At what velocity ACTUALLY crashes if it goes below

	},

	TpToClone = {
		globalCooldown = 1,				-- Global cooldown on all abilities when used (prevents being able to instantly do stuff after manifesting)
		cooldown = 2,					-- Cooldown between this ability's uses

		tpRange = 2048					-- Maximum range of the teleport (clones farther can't be teleport to)
	},
}

-- Functions used for abilities

-- Copied sayprompt logic sofake item do the proper voicelines
function sayPrompt(ply, input)
	ply:EmitSound("slashco/survivor/voice/prompt_" .. input .. math.random(1,3) .. ".mp3")
end

-- Getting the voiceline suffix by ping type, it's way nice for the configuring
local function GetVoiceByPingType(pingtype)
	for _, item in ipairs(SLASHER.XSettings.FakeItem.spawnList) do
		if item.pingtype == pingtype then
			return item.vlInput
		end
	end
	return nil
end

-- Used to end the charge properly
function endCharge(slasher, victim, doStun, stunTime)
	slasher:SetFriction(1)
	slasher:SetNWBool("2011xCharging", false)

	if (victim ~= nil and IsValid(victim)) then
		local dmg = DamageInfo()
		dmg:SetDamageType(DMG_SLASH)
		dmg:SetAttacker(slasher)
		dmg:SetInflictor(slasher)
		dmg:SetDamage(SLASHER.XSettings.Charge.baseDamage)
		dmg:SetDamageForce(Vector(50,50,50))
		dmg:SetDamagePosition(slasher:GetPos())
		victim:TakeDamageInfo(dmg)
	end

	if (doStun) then SLASHER.OnHitByPocketSand(slasher, nil, nil, stunTime) end
end

-- Spawns the fake itemwith all its relevant stats
function spawnFakeItem(slasher)
	local selectedFakeItem = SLASHER.XSettings.FakeItem.spawnList[slasher:GetNWInt("2011xCurFakeItemSelection")]

	local mimicItem = ents.Create(selectedFakeItem.entity)
	mimicItem:Spawn()

	local fakeItem = ents.Create("sc_x_fakeitem")
	fakeItem:SetModel(mimicItem:GetModel())
	fakeItem:SetPos(slasher:EyePos())
	fakeItem:SetOwner(slasher)
	fakeItem.PingType = selectedFakeItem.pingtype
	mimicItem:Remove()

	fakeItem:SetVar("triggeredColor", SLASHER.XSettings.FakeItem.triggeredColor)
	fakeItem:SetVar("expRange", SLASHER.XSettings.FakeItem.expRange)
	fakeItem:SetVar("expDamage", SLASHER.XSettings.FakeItem.expDamage)
	fakeItem:SetVar("expDelay", SLASHER.XSettings.FakeItem.expDelay)
	fakeItem:SetVar("expForce", SLASHER.XSettings.FakeItem.expForce)
	fakeItem:SetVar("maxNear", SLASHER.XSettings.FakeItem.maxNear)
	fakeItem:SetVar("slasherKnockback", SLASHER.XSettings.FakeItem.slasherKnockback)

	fakeItem:Spawn()
	fakeItem:Activate()

	local phys = fakeItem:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetVelocity(slasher:GetAimVector() * 200 )
	end
end

-- Spawn the clones used to teleport (need to add Stage5 Behavior)
function spawnTpClone(pos, ang)
	local clone = ents.Create("sc_x_clone")

	clone:SetPos(pos)

	-- Wish i knew more cause creating an entire Angle just for this seems wasatful
	clone:SetAngles(ang or Angle(0,math.random(360),0))

	clone:Spawn()
	clone:Activate()

	clone:SetVar("flTicks", SLASHER.XSettings.Clones.flTicks)
	clone:SetVar("flRange", SLASHER.XSettings.Clones.flRange)
	clone:SetVar("clDuration", SLASHER.XSettings.Clones.duration)
end


-- Stock SlashCo Functions

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

-- When the slasher first spawns in
function SLASHER.OnSpawn(slasher)
	slasher:SetNWBool("CanChase", false)

	-- Please dont touch anything between these two comments
	slasher:SetNWBool("2011xStunned", false)


	slasher:SetNWFloat("2011xLMBCooldown", 0)
	slasher:SetNWFloat("2011xFakeItemCooldown", 0)
	slasher:SetNWFloat("2011xChargeCooldown")
	slasher:SetNWFloat("2011xTpToCloneCooldown", 0)
	slasher:SetNWFloat("2011xDetonateCooldown", 0)
	slasher:SetNWFloat("2011xGlobalCooldown", 0)


	slasher:SetNWBool("2011xCharging", false )
	slasher:GetNWBool("2011xCanDetonate", false)
	slasher:SetNWInt("2011xCurFakeItemSelection", 1)
	slasher:SetCustomCollisionCheck(true)

	slasher.canCrash = false
	-- Please dont touch anything between these two comments

	-- Timer set to happen infinitely, timer.IsPaused isnt available yet so we just do the comparing init
	timer.Create("passiveClones" .. slasher:EntIndex(),SLASHER.XSettings.Clones.spawnTimer, -1, function()
		if not IsValid(slasher) then return end
		if (#ents.FindByClass("sc_x_clone") >= SLASHER.XSettings.Clones.maxAmount) then return end

		spawnTpClone(SlashCo.RandomPosLocator())
	end)
end

-- This happens on every tick, try to not spam too much in there as it could slow down the server a bit
function SLASHER.OnTickBehaviour(slasher)
	local final_eyesight = SLASHER.Eyesight
	local final_perception = SLASHER.Perception
	slasher:LagCompensation(true)
	-- This is used to detect when the slasher is looking at a clone to teleport to it
	local traceClone = util.TraceLine(
		{
			start = slasher:EyePos(),
			endpos = slasher:EyePos() + slasher:GetAimVector() * SLASHER.XSettings.TpToClone.tpRange,
			ignoreworld = true,
			filter = { "sc_x_clone" },
			whitelist = true
		}
	)

	-- Used for both the LMB check and the MOUSE WHEEL change to "Detonate" for fake items
	local traceMisc = slasher:GetEyeTrace()
	slasher:LagCompensation(false)

	-- Custom start chase logic
	-- Unironically very ass, will improve later
	if (IsValid(traceMisc.Entity) and
		traceMisc.Entity:GetClass() == "player" and
		traceMisc.Entity:Team() == TEAM_SURVIVOR and
		((traceMisc.HitPos - traceMisc.StartPos):Length()) < SLASHER.ChaseRange) and
		not slasher:GetNWBool("InSlasherChaseMode")
	then
		SlashCo.StartChaseMode(slasher, true)
	end

	-- Cooldown Ability logic, this shit fucking sucks
	if (slasher:GetNWFloat("2011xLMBCooldown") > 0) then slasher:SetNWFloat("2011xLMBCooldown", slasher:GetNWFloat("2011xLMBCooldown") - FrameTime()) end
	if (slasher:GetNWFloat("2011xFakeItemCooldown") > 0) then slasher:SetNWFloat("2011xFakeItemCooldown", slasher:GetNWFloat("2011xFakeItemCooldown") - FrameTime()) end
	if (slasher:GetNWFloat("2011xChargeCooldown") > 0) then slasher:SetNWFloat("2011xChargeCooldown", slasher:GetNWFloat("2011xChargeCooldown") - FrameTime()) end
	if (slasher:GetNWFloat("2011xTpToCloneCooldown") > 0) then slasher:SetNWFloat("2011xTpToCloneCooldown", slasher:GetNWFloat("2011xTpToCloneCooldown") - FrameTime()) end
	if (slasher:GetNWFloat("2011xDetonateCooldown") > 0) then slasher:SetNWFloat("2011xDetonateCooldown", slasher:GetNWFloat("2011xDetonateCooldown") - FrameTime()) end
	if (slasher:GetNWFloat("2011xGlobalCooldown") > 0) then slasher:SetNWFloat("2011xGlobalCooldown", slasher:GetNWFloat("2011xGlobalCooldown") - FrameTime()) end


	-- Used to debug stuff if needed, can be removed
--[[ 	slasher:PrintMessage(HUD_PRINTCENTER,
		"2011xLMBCooldown: " .. tostring(slasher:GetNWFloat("2011xLMBCooldown")) .. "\n" ..
		"2011xFakeItemCooldown: " .. tostring(slasher:GetNWFloat("2011xFakeItemCooldown")) .. "\n" ..
		"2011xChargeCooldown: " .. tostring(slasher:GetNWFloat("2011xChargeCooldown")) .. "\n" ..
		"2011xTpToCloneCooldown: " .. tostring(slasher:GetNWFloat("2011xTpToCloneCooldown")) .. "\n" ..
		"2011xDetonateCooldown: " .. tostring(slasher:GetNWFloat("2011xDetonateCooldown")) .. "\n" ..
		"2011xGlobalCooldown: " .. tostring(slasher:GetNWFloat("2011xGlobalCooldown"))
	) ]]

	-- Global conditional for if you can use each ability or not, 
	-- this is a fuck fest and i have no clue how to potentially optimize this while keeping how it looks

	-- This conditional is giving me aids, im so sorry
	slasher:SetNWBool("2011xCanLMB", not tobool(
			slasher:GetNWFloat("2011xLMBCooldown") > 0
			or slasher:GetNWFloat("2011xGlobalCooldown") > 0
			or slasher:GetNWBool("2011xStunned")
			or not (IsValid(traceMisc.Entity) and traceMisc.Entity:GetClass() == "player" and ((traceMisc.HitPos - traceMisc.StartPos):Length()) < SLASHER.KillDistance)
		)
	)
	slasher:SetNWBool("2011xCanFakeItem", not tobool(slasher:GetNWFloat("2011xFakeItemCooldown") > 0 or slasher:GetNWFloat("2011xGlobalCooldown") > 0 or slasher:GetNWBool("2011xStunned")) )
	slasher:SetNWBool("2011xCanCharge", not tobool(slasher:GetNWFloat("2011xChargeCooldown") > 0 or slasher:GetNWFloat("2011xGlobalCooldown") > 0 or slasher:GetNWBool("2011xStunned")) )
	slasher:SetNWBool("2011xCanTpToClone", not tobool(slasher:GetNWFloat("2011xTpToCloneCooldown") > 0 or slasher:GetNWFloat("2011xGlobalCooldown") > 0 or not (traceClone.Entity:IsValid() and traceClone.Entity:GetClass() == "sc_x_clone") or slasher:GetNWBool("2011xStunned")) )
	slasher:SetNWBool("2011xCanDetonate", tobool(traceMisc.Entity:IsValid() and traceMisc.Entity:GetClass() == "sc_x_fakeitem") and slasher:GetNWFloat("2011xDetonateCooldown") <= 0 and slasher:GetNWFloat("2011xGlobalCooldown") <= 0)

	-- Logic for the charge, i wanna die this code fucking sucks
	if slasher:GetNWBool("2011xCharging") then
		local curVel = slasher:GetVelocity():Length()
		slasher:SetVelocity(slasher:GetAimVector() * SLASHER.XSettings.Charge.speed)

		-- The charge crash logic, it's ass
		if (SLASHER.XSettings.Charge.crashLogic) then
			if (curVel > SLASHER.XSettings.Charge.crashActivateThreshold) then slasher.canCrash = true end

			if (curVel < SLASHER.XSettings.Charge.crashThreshold and slasher.canCrash) then endCharge(slasher, nil, true) end
		end
	end

	-- :D
	slasher:SetEyeSight(final_eyesight)
	slasher:SetPerception(final_perception)
end

-- Left click
-- 
function SLASHER.OnPrimaryFire(slasher)
	if not slasher:GetNWBool("2011xCanLMB") then return end
	slasher:SetNWFloat("2011xLMBCooldown", SLASHER.XSettings.LMB.cooldown)
	slasher:SetNWFloat("2011xGlobalCooldown", SLASHER.XSettings.LMB.globalCooldown or 0)

	if not IsValid(slasher) then return end

	slasher:LagCompensation(true)
	local tr = util.TraceHull({
		start = slasher:EyePos(),
		endpos = slasher:GetPos(Vector(55, 0, 0)),
		maxs = Vector(SLASHER.XSettings.LMB.hitboxSize / 2, SLASHER.XSettings.LMB.hitboxSize / 2, SLASHER.XSettings.LMB.hitboxSize / 2),
		mins = Vector(-SLASHER.XSettings.LMB.hitboxSize / 2, -SLASHER.XSettings.LMB.hitboxSize / 2, -SLASHER.XSettings.LMB.hitboxSize / 2),

		-- I do this cause player could use fake items to eat the trace, preventing damage
		-- Im sorry but this is dead ass the only way i can think of to properly filter player but not self
		filter = function(ent)
			return ent:IsPlayer() and ent ~= slasher
		end,

		ignoreworld = true,
	})
	slasher:LagCompensation(false)

	local target = tr.Entity

	if target:IsValid() and target:Team() == TEAM_SURVIVOR then
		if target:Health() <= SLASHER.XSettings.LMB.damage then
			SlashCo.Jumpscare(slasher, target)
			slasher:Freeze(true)
			timer.Simple(SLASHER.JumpscareDuration / 2, function()
				slasher:Freeze(false)
			end)
		end

		local effect = EffectData()
		local dmg = DamageInfo()

		dmg:SetDamageType(DMG_SLASH)
		dmg:SetAttacker(slasher)
		dmg:SetInflictor(slasher)
		dmg:SetDamage(SLASHER.XSettings.LMB.damage)
		target:TakeDamageInfo(dmg)

		-- We do this cause set damage force doesn't work for some reason
		target:SetVelocity(slasher:GetAimVector() * 200)

		effect:SetOrigin(target:GetPos() + Vector(0,0,40))
		util.Effect("BloodImpact", effect)
	end
end

-- The right click
function SLASHER.OnSecondaryFire(slasher)
	if not slasher:GetNWBool("2011xCanFakeItem") then return end
	slasher:SetNWFloat("2011xFakeItemCooldown", SLASHER.XSettings.FakeItem.cooldown)
	slasher:SetNWFloat("2011xGlobalCooldown", SLASHER.XSettings.FakeItem.globalCooldown or 0)
	spawnFakeItem(slasher)
end

-- This is R
function SLASHER.OnMainAbilityFire(slasher)
	if not slasher:GetNWBool("2011xCanCharge") then return end
	slasher:SetNWFloat("2011xChargeCooldown", SLASHER.XSettings.Charge.cooldown + SLASHER.XSettings.Charge.cooldown)

	-- We do +1 here to prevent just being able to use an ability right after
	slasher:SetNWFloat("2011xGlobalCooldown", SLASHER.XSettings.Charge.duration + (SLASHER.XSettings.Charge.globalCooldown or 0) + 1)

	slasher.canCrash = false
	slasher:SetFriction(SLASHER.XSettings.Charge.friction)
	slasher:SetNWBool("2011xCharging", true)
	slasher:SetVelocity(-(slasher:GetVelocity()))

	timer.Simple(SLASHER.XSettings.Charge.duration, function()
		endCharge(slasher, nil, false)
	end)
end

-- This is F
function SLASHER.OnSpecialAbilityFire(slasher)
	if not slasher:GetNWBool("2011xCanTpToClone") then return end
	slasher:SetNWFloat("2011xTpToCloneCooldown", SLASHER.XSettings.TpToClone.cooldown)
	slasher:SetNWFloat("2011xGlobalCooldown", SLASHER.XSettings.TpToClone.globalCooldown or 0)

	local trace = util.TraceLine(
		{
			start = slasher:EyePos(),
			endpos = slasher:EyePos() + slasher:GetAimVector() * SLASHER.XSettings.TpToClone.tpRange,
			ignoreworld = true,
			filter = {"sc_x_clone"},
			whitelist = true
		}
	)

	if (trace.Hit and trace.Entity:IsValid()) then
		spawnTpClone(slasher:GetPos(), slasher:GetAngles())
		slasher:SetPos(trace.Entity:GetPos())
		slasher:SetEyeAngles(trace.Entity:GetAngles())
		trace.Entity:Remove()
	end

end

function SLASHER.Thirdperson(ply)
	return ply:GetNWBool("2011xStunned") or ply:GetNWBool("2011xCharging")
end

function SLASHER.Animator(ply)
	ply.CalcIdeal = ACT_MP_STAND_IDLE
	ply.CalcSeqOverride = -1

	ply:SetPoseParameter("body_pitch", -ply:EyeAngles().pitch)

	-- This fucking bullshit took me way too long to figure out, i fucking HATE math, please use it
	ply:SetPoseParameter("body_yaw", -(math.AngleDifference(ply:EyeAngles().y, select(2, ply:GetBonePosition(0)).y) + 90))

	return ply.CalcIdeal, ply.CalcSeqOverride
end

function SLASHER.Footstep(ply)
	return true
end

function SLASHER.OnHitByPocketSand(slasher, ply, rage, stunTime)
	slasher:SetNWBool("2011xStunned", true)
	slasher:Freeze(true)

	local stun = stunTime or SLASHER.StunTime

	slasher:SetNWFloat("2011xGlobalCooldown", stun)

	timer.Simple(stun, function()
		if not IsValid(slasher) then return end

		slasher:SetNWBool("2011xStunned", false)
		slasher:Freeze(false)
	end)
end

SLASHER.OnHitByBeerKeg = function(slasher) SLASHER.OnHitByPocketSand(slasher, nil) end
SLASHER.OnHitByTeslaCoil = function(slasher) SLASHER.OnHitByPocketSand(slasher, nil) end

function SLASHER.InitHud(_, hud)

	handleCooldowns = {
		{ controlKey = "R", 			controlName = "X_charge", 		netVarCD = "2011xChargeCooldown", 		netVarTie = "2011xCanCharge"},
		{ controlKey = "F", 			controlName = "X_teleport",		netVarCD = "2011xTpToCloneCooldown", 	netVarTie = "2011xCanTpToClone"},
		{ controlKey = "MOUSE WHEEL", 	controlName = "X_detonate", 	netVarCD = "2011xDetonateCooldown", 	netVarTie = "2011xCanDetonate"},
		{ controlKey = "RMB", 			controlName = "X_fakeItem", 	netVarCD = "2011xFakeItemCooldown", 	netVarTie = "2011xCanFakeItem"},
		{ controlKey = "LMB",			controlName = "kill survivor", 	netVarCD = "2011xLMBCooldown", 			netVarTie = "2011xCanLMB"},
	}

	hud:SetTitle(SLASHER.Name)
	hud:SetCrosshairEnabled(true)
	hud:SetCrosshairAlpha(255)
	hud:SetCrosshairSpin(0)
	hud:SetCrosshairTighten(5)
	hud:SetCrosshairProngs(4)

	hud:TieCrosshair({
		"2011xCanTpToClone",
		"2011xCanDetonate",
		InvertOutput = true,
		IsOr = true
	}, {
		TightenOn = 20,
		TightenOff = 5
	})

	for _, curControl in pairs(handleCooldowns) do
		hud:AddControl(curControl.controlKey, "")
		hud:TieControl(curControl.controlKey, curControl.netVarTie, false, true, nil)
	end

	local slasher = GameData.LocalPlayer
	function hud.AlsoThink()
		local globalCooldown = slasher:GetNWFloat("2011xGlobalCooldown", 0)

		local curFakeItemSelection = slasher:GetNWInt("2011xCurFakeItemSelection", 1)
		if (slasher:GetNWBool("2011xCanDetonate")) then
			hud:SetControlText("MOUSE WHEEL", "detonate", true)
		else
			hud:SetControlText("MOUSE WHEEL", tostring(SLASHER.XSettings.FakeItem.spawnList[curFakeItemSelection].pingtype), true)
		end

		for _, curControl in pairs(handleCooldowns) do
			-- If it has a cooldown, we show it
			local highestCooldown = math.max(slasher:GetNWFloat(curControl.netVarCD, 0), globalCooldown)
			if highestCooldown > 0 then
				hud:SetControlText(
					curControl.controlKey,
					string.format("[%s] %s", math.Round(highestCooldown, 1), SlashCo.LangTable[curControl.controlName])
				)
			elseif (curControl.controlKey ~= "MOUSE WHEEL") then
				hud:SetControlText(
					curControl.controlKey,
					curControl.controlName
				)
			end
		end

	end
end

function SLASHER.PreDrawHalos()
	SlashCo.DrawHalo(ents.FindByClass("sc_x_clone"), color_red, nil, true)
	SlashCo.DrawHalo(ents.FindByClass("sc_x_fakeitem"), color_red, nil, true)
end

-- For server hooks
if SERVER then
	hook.Add( "StartCommand", "MouseWheel", function( ply, cmd )
		if ply:Team() ~= TEAM_SLASHER or ply:GetNWString("Slasher") ~= "2011x" then return end
		if CLIENT then return end
		if ( cmd:GetMouseWheel() ~= 0) then

			ply:SetNWInt("2011xCurFakeItemSelection", math.Clamp(ply:GetNWInt("2011xCurFakeItemSelection") + -cmd:GetMouseWheel(), 1, #SLASHER.XSettings.FakeItem.spawnList))
		end

		if (ply:GetNWBool("2011xCharging")) then
			cmd:ClearMovement()
		end
	end )

	hook.Add("SlashCo:OnPing", "FakeItemPings", function(pingInfo)
		if not pingInfo.Player then return end -- it can be nil!
		if CLIENT then return end

		local ply = pingInfo.Player

		if isnumber(ply) then
			ply = Entity(ply)
		end

		if not IsValid(ply) then return end

		local entity = pingInfo.Entity
		if isnumber(entity) then
			entity = Entity(entity)
		end

		if not IsValid(entity) then return end

		if entity:GetClass() == "sc_x_fakeitem" then
			if pingInfo.Team == TEAM_SURVIVOR then
				sayPrompt(ply, GetVoiceByPingType(pingInfo.Type))
				return false
			elseif pingInfo.Team == TEAM_SLASHER and ply:GetNWBool("2011xCanDetonate") then
				entity:Explode()
				ply:SetNWFloat("2011xDetonateCooldown", SLASHER.XSettings.Detonate.cooldown)
				ply:SetNWFloat("2011xGlobalCooldown", SLASHER.XSettings.Detonate.globalCooldown)
				return true
			end
		end

		return false
	end)
end

SlashCo.RegisterSlasher(SLASHER, "2011x")