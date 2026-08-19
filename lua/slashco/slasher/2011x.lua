local SLASHER = {}
local SlashCoItems = SlashCoItems or {}

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
	chaseColor = Color(0, 50, 255),

	-- Uses pingInfo.Type and a Slasher's name (both in lowercase) and associates it to a voiceline for 2011x
	specialInteractions = {
		["survivor"] = { "pieceofshit", "fuckyou" },
		["generator"] = "pieceofshit",
		["item"] = "fuckyou",
		["sid"] = "pieceofshit",
		["postal dude"] = "fuckyou",
	},

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
	-- Every ability has a shared globalCooldown variable.

	-- Left Click (normal attack)
	LMB = {
		cooldown = 1,
		globalCooldown = 1,
		knockback = 9999,
		hitboxSize = 120,

		damage = 30,
		windup = 0.5,
	},

	-- Right Click (spawns an explosive item that explodes on use or if pinged by 2011x)
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

		-- Sub ability of fake items, used when they're detonated via ping
		Detonate = {
			cooldown = 6,
			globalCooldown = 0
		},

		-- List of items that X can spawns with FakeItem
		-- Ping type can't be retrieved from mimic entity, so we have to set it manually
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
		duration = 3,					-- Total duration of charge
		speed = 30,						-- Base speed
		friction = 0.15,				-- Acceleration overtime that depends on speed
		baseDamage = 40,				-- Base damage
		damageBasedOnDuration = true,	-- Should the damage of the charge depends on it's current length

		crashLogic = true, 			-- Activate the crash logic (prevents people from pinballing around the map and getting auranteed hits)
		crashActivateThreshold = 600,	-- At what velocity threshold the slasher CAN crash
		crashThreshold = 400,			-- At what velocity ACTUALLY crashes if it goes below

	},

	-- When looking at a clone from anywhere i nthe map you can swap positions with it, usefull for ambushes
	TpToClone = {
		globalCooldown = 1,				-- Global cooldown on all abilities when used (prevents being able to instantly do stuff after manifesting)
		cooldown = 2,					-- Cooldown between this ability's uses

		tpRange = 2048					-- Maximum range of the teleport (clones farther can't be teleport to)
	},
}

-- We do be precachin
hook.Add("SlashCo:Precache", "SlashCo:PrecacheBeacon", function()
	for slasher, voiceline in pairs(table) do
		SlashCo.PrecacheSound("slashco/slasher/2011x/specialinteraction_" .. tostring(voiceline) .. ".mp3")
	end
end)

-- Functions used for abilities

-- Logic to make either survivor or 2011x say a voice line (might be refined later)
function sayPrompt(ply, input)
	if ply:Team() == TEAM_SURVIVOR then
		ply:EmitSound("slashco/survivor/voice/prompt_" .. input .. math.random(1,3) .. ".mp3")
	elseif ply:Team() == TEAM_SLASHER and ply:GetNWString("Slasher") == "2011x" then
		ply:EmitSound("slashco/slasher/2011x/specialinteraction_" .. input .. ".mp3")
	end
end

-- Getting the voiceline suffix by ping type for fake items, used for survivors mainly
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

	if (doStun) then SLASHER.OnHitByPocketSand(slasher, nil, stunTime) end
end

-- Spawns the fake item with all its relevant stats
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
	slasher:SetViewOffset(Vector(0,0, 50))

	slasher:SetNWBool("CanChase", false)
	slasher:SetNWBool("DisableChaseLight", true)

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

	slasher.canCrash = false
	-- Please dont touch anything between these two comments

	-- Timer set to happen infinitely, timer.IsPaused isnt available yet so we just do the comparing init
	-- Need a way to pause this time when there is no 2011x, i can't find a function for it though, help
	timer.Create("passiveClones" .. slasher:EntIndex(),SLASHER.XSettings.Clones.spawnTimer, -1, function()
		if not IsValid(slasher) then return end
		if (#ents.FindByClass("sc_x_clone") >= SLASHER.XSettings.Clones.maxAmount) then return end

		spawnTpClone(SlashCo.RandomPosLocator())
	end)
end

-- This happens on every tick, lord have mercy this shit sucks
-- Sorry to whoever wants to take a look into this
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

	-- Used for the MOUSE WHEEL text change to "Detonate" for fake items
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
		)
	)
	slasher:SetNWBool("2011xCanFakeItem", not tobool(slasher:GetNWFloat("2011xFakeItemCooldown") > 0 or slasher:GetNWFloat("2011xGlobalCooldown") > 0 or slasher:GetNWBool("2011xStunned")) )
	slasher:SetNWBool("2011xCanCharge", not tobool(slasher:GetNWFloat("2011xChargeCooldown") > 0 or slasher:GetNWFloat("2011xGlobalCooldown") > 0 or slasher:GetNWBool("2011xStunned")) )
	slasher:SetNWBool("2011xCanTpToClone", not tobool(slasher:GetNWFloat("2011xTpToCloneCooldown") > 0 or slasher:GetNWFloat("2011xGlobalCooldown") > 0 or not (traceClone.Entity:IsValid() and traceClone.Entity:GetClass() == "sc_x_clone") or slasher:GetNWBool("2011xStunned")) )
	slasher:SetNWBool("2011xCanDetonate", tobool(slasher:GetNWFloat("2011xDetonateCooldown") <= 0 and slasher:GetNWFloat("2011xGlobalCooldown") <= 0))

	slasher:SetNWBool("2011xLookingAtFakeItem", tobool(traceMisc.Entity:IsValid() and traceMisc.Entity:GetClass() == "sc_x_fakeitem"))

	-- Logic for the charge, i wanna die this code fucking sucks
	if slasher:GetNWBool("2011xCharging") then
		slasher:SetVelocity(slasher:GetAimVector() * SLASHER.XSettings.Charge.speed)

		-- The charge crash logic, it's ass, this shit needs to be changed asap to depends on normals
		if (SLASHER.XSettings.Charge.crashLogic) then
			local curVel = slasher:GetVelocity():Length()
			if (curVel > SLASHER.XSettings.Charge.crashActivateThreshold) then slasher.canCrash = true end

			if (curVel < SLASHER.XSettings.Charge.crashThreshold and slasher.canCrash) then endCharge(slasher, nil, true) end
		end
	end

	-- :D
	slasher:SetEyeSight(final_eyesight)
	slasher:SetPerception(final_perception)
end

-- Left click
function SLASHER.OnPrimaryFire(slasher)
	if not IsValid(slasher) then return end
	if not slasher:GetNWBool("2011xCanLMB") then return end
	slasher:SetNWFloat("2011xLMBCooldown", SLASHER.XSettings.LMB.cooldown)
	slasher:SetNWFloat("2011xGlobalCooldown", SLASHER.XSettings.LMB.globalCooldown or 0)

	slasher:LagCompensation(true)

	local startpos = slasher:GetPos()
	local dir = slasher:GetUp()

	local maxs = Vector(SLASHER.XSettings.LMB.hitboxSize / 2, SLASHER.XSettings.LMB.hitboxSize / 2, SLASHER.XSettings.LMB.hitboxSize / 2)
	local mins = Vector(-SLASHER.XSettings.LMB.hitboxSize / 2, -SLASHER.XSettings.LMB.hitboxSize / 2, -SLASHER.XSettings.LMB.hitboxSize / 2)

	local tr = util.TraceHull({
		start = startpos,
		endpos = startpos + dir * SLASHER.XSettings.LMB.hitboxSize,
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
		if target:Health() <= SLASHER.XSettings.LMB.damage then
			SlashCo.Jumpscare(slasher, target)
			slasher:Freeze(true)

			timer.Simple(SLASHER.JumpscareDuration / 2, function()
				slasher:Freeze(false)
				target:Kill()
			end)

			return
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

-- Right click
function SLASHER.OnSecondaryFire(slasher)
	if not slasher:GetNWBool("2011xCanFakeItem") then return end
	slasher:SetNWFloat("2011xFakeItemCooldown", SLASHER.XSettings.FakeItem.cooldown)
	slasher:SetNWFloat("2011xGlobalCooldown", SLASHER.XSettings.FakeItem.globalCooldown or 0)
	spawnFakeItem(slasher)
end

-- R
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

-- F
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

	-- We swap em
	if (trace.Hit and trace.Entity:IsValid()) then
		local tempPos, tempAngle = slasher:GetPos(), slasher:GetAngles()

		slasher:SetPos(trace.Entity:GetPos())
		slasher:SetEyeAngles(trace.Entity:GetAngles())

		trace.Entity:SetPos(tempPos)
		trace.Entity:SetAngles(tempAngle)
	end

end

-- Function used for when the slasher should be in third person (the return is the state, so if you return true they're in thirdperson)
function SLASHER.Thirdperson(ply)
	return ply:GetNWBool("2011xStunned") or ply:GetNWBool("2011xCharging")
end

-- Animator function, will be finished when animations are done
function SLASHER.Animator(ply)
	ply.CalcIdeal = ACT_MP_STAND_IDLE
	ply.CalcSeqOverride = -1

	ply:SetPoseParameter("body_pitch", -ply:EyeAngles().pitch)

	-- This fucking bullshit took me way too long to figure out, i fucking HATE math, please use it
	ply:SetPoseParameter("body_yaw", -(math.AngleDifference(ply:EyeAngles().y, select(2, ply:GetBonePosition(0)).y) + 90))

	return ply.CalcIdeal, ply.CalcSeqOverride
end

-- The footsteps, will be finished eventually lmfao
function SLASHER.Footstep(ply)
	return true
end

-- The stun function basically, added stuntime variable
function SLASHER.OnHitByPocketSand(slasher, ply, stunTime)
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

-- Hud function, this is where you do cool UI shit
function SLASHER.InitHud(_, hud)
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

	-- Control Stuff
	-- This was made to make creating the controls and editing them easier for the cooldown system
	-- Do NOT make this a hash table, otherwise you won't be able to control the order in the hud
	handleCooldowns = {
		{ key = "R", 	 		controlName = "X_charge", 		netVarCD = "2011xChargeCooldown", 		netVarTie = "2011xCanCharge", 		preventOverwrite = false},
		{ key = "F", 	 		controlName = "X_teleport",	netVarCD = "2011xTpToCloneCooldown", 	netVarTie = "2011xCanTpToClone", 	preventOverwrite = false},
		{ key = "MOUSEWHEEL", 	controlName = "X_detonate", 	netVarCD = "2011xDetonateCooldown", 	netVarTie = "2011xCanDetonate", 	preventOverwrite = true},
		{ key = "RMB", 	 		controlName = "X_fakeItem", 	netVarCD = "2011xFakeItemCooldown", 	netVarTie = "2011xCanFakeItem", 	preventOverwrite = false},
		{ key = "LMB", 	 		controlName = "kill survivor", netVarCD = "2011xLMBCooldown", 			netVarTie = "2011xCanLMB", 			preventOverwrite = false},
	}

	for _, control in pairs(handleCooldowns) do
		hud:AddControl(control.key, "")
		hud:TieControl(control.key, control.netVarTie, false, true, nil)
	end

	local slasher = GameData.LocalPlayer

	-- This is mainly used to update the hude for the cooldowns
	function hud.AlsoThink()
		local globalCooldown = slasher:GetNWFloat("2011xGlobalCooldown", 0)

		local curFakeItemSelection = slasher:GetNWInt("2011xCurFakeItemSelection", 1)
		if (slasher:GetNWBool("2011xLookingAtFakeItem")) then
			hud:SetControlText("MOUSEWHEEL", "detonate", true)
		else
			hud:SetControlText("MOUSEWHEEL", tostring(SLASHER.XSettings.FakeItem.spawnList[curFakeItemSelection].pingtype), true)
		end

		for _, control in pairs(handleCooldowns) do
			-- If it has a cooldown, we show it
			local highestCooldown = math.max(slasher:GetNWFloat(control.netVarCD, 0), globalCooldown)
			if highestCooldown > 0 then
				hud:SetControlText(
					control.key,
					string.format("[ %s ] %s", math.Round(highestCooldown, 1), SlashCo.LangTable[control.controlName])
				)
			elseif (not control.preventOverwrite) then
				hud:SetControlText(
					control.key,
					control.controlName
				)
			end
		end

	end
end

-- Draws halos around the specific items, its cool
function SLASHER.PreDrawHalos()
	SlashCo.DrawHalo(ents.FindByClass("sc_x_clone"), Color(0,255,170), nil, true)
	SlashCo.DrawHalo(ents.FindByClass("sc_x_fakeitem"), color_red, nil, true)
end

-- For client hooks

if CLIENT then
	hook.Add("Think", "FakeChaseLight", function()
		for _, slasher in ipairs(team.GetPlayers(TEAM_SLASHER)) do
			if not slasher:GetNWBool("InSlasherChaseMode") then return end
			local dlight = DynamicLight(slasher:UserID())

			if dlight then
				dlight.pos = slasher:LocalToWorld(Vector(0,0,40))
				dlight.r = SLASHER.XSettings.chaseColor.r
				dlight.g = SLASHER.XSettings.chaseColor.g
				dlight.b = SLASHER.XSettings.chaseColor.b
				dlight.brightness = 4

				local size = 250
				dlight.Decay = size * 8
				dlight.Size = size
				dlight.DieTime = CurTime() + 1
			end
		end
	end)
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
	hook.Remove("SlashCo:OnPing", "2011xPingStuff")
	hook.Add("SlashCo:OnPing", "2011xPingStuff", function(pingInfo)
		if not pingInfo.Player then return end -- it can be nil!

		local ply = pingInfo.Player
		if isnumber(ply) then ply = Entity(ply) end

		local entity = pingInfo.Entity
		if isnumber(entity) then entity = Entity(entity) end

		-- This section of code is to properly detect when you ping a slasher, as for some fucking reason it wouldn't put the entity in pinginfo.Entity
		local traced = ply:GetEyeTrace().Entity

		-- Had to do this cause if you ping a player it wouldn't return the entity, and so I couldn't get a slasher's name
		if traced.IsPlayer() and ply:Team() == TEAM_SLASHER and traced:Team() == TEAM_SLASHER then
			pingInfo.Type = traced:GetNWString("Slasher")
		end

		-- This section of code is to properly detect when you ping a slasher, as for some fucking reason it wouldn't put the entity in pinginfo.Entity

		-- Normal Ping stuff
		if not IsValid(ply) then return end

		if IsValid(entity) and entity:GetClass() == "sc_x_fakeitem" then
			-- If a survivor pings the fake item, we make them say the line and return
			if pingInfo.Team == TEAM_SURVIVOR then
				sayPrompt(ply, GetVoiceByPingType(pingInfo.Type))
				return true

			-- If 2011x pings a fake item and it can blow up, we blow it up (we don't care if its another 20xx's fake item, they're shared)
			elseif pingInfo.Team == TEAM_SLASHER and ply:GetNWBool("2011xCanDetonate") then
				entity:Explode()
				ply:SetNWFloat("2011xDetonateCooldown", SLASHER.XSettings.FakeItem.Detonate.cooldown)
				ply:SetNWFloat("2011xGlobalCooldown", SLASHER.XSettings.FakeItem.Detonate.globalCooldown)
			end
		end

		-- Used at the end just in case
		local pingVoiceLine = SLASHER.XSettings.specialInteractions[string.lower(pingInfo.Type)]
		if pingVoiceLine then
			if type(pingVoiceLine) == "table" then
				pingVoiceLine = pingVoiceLine[math.random(1, #pingVoiceLine)]
			end
			sayPrompt(ply, pingVoiceLine)
		end

		return false
	end)
end

SlashCo.RegisterSlasher(SLASHER, "2011x")