SLASHER = {}
DEBUG = true

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
SLASHER.ProwlSpeed = 290
SLASHER.ChaseSpeed = SLASHER.ProwlSpeed
SLASHER.Perception = 1.0
SLASHER.Eyesight = 3
SLASHER.KillDistance = 70

SLASHER.JumpscareDuration = 1
SLASHER.ChaseMusic = "slashco/slasher/2011x/2011x_tempChase.mp3"
SLASHER.ChaseRange = 300
SLASHER.ChaseRadius = 0.1

SLASHER.Description = "X_desc"
SLASHER.ProTip = "X_tip"
SLASHER.SpeedRating = "★★★★★"
SLASHER.EyeRating = "★★★★★"
SLASHER.DiffRating = "★★★☆☆"
SLASHER.StunTime = 1

-- Stock SlashCo Functions
-- When the slasher first spawns in

function SLASHER.OnSpawn(slasher)
	slasher:SetViewOffset(Vector(0, 0, 50))

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
	timer.Create("passiveClones" .. slasher:EntIndex(),SLASHER.Config.Clones.spawnTimer, -1, function()
		if not IsValid(slasher) then return end
		if (#ents.FindByClass("sc_x_clone") >= SLASHER.Config.Clones.maxAmount) then return end

		spawnTpClone(SlashCo.RandomPosLocator())
	end)
end

-- This happens on every tick, lord have mercy this shit sucks
-- Sorry to whoever wants to take a look into this
function SLASHER.OnTickBehaviour(slasher)
	local final_eyesight = SLASHER.Eyesight
	local final_perception = SLASHER.Perception

	-- This is used to detect when the slasher is looking at a clone to teleport to it
	local traceClone = util.TraceLine(
		{
			start = slasher:EyePos(),
			endpos = slasher:EyePos() + slasher:GetAimVector() * SLASHER.Config.TpToClone.tpRange,
			ignoreworld = true,
			filter = { "sc_x_clone" },
			whitelist = true
		}
	)

	-- Used for the MOUSE WHEEL text change to "Detonate" for fake items
	local traceMisc = slasher:GetEyeTrace()

	-- If 2011x is looking at a fake item (used for detonate)
	slasher:SetNWBool("2011xLookingAtFakeItem",
		traceMisc.Entity:IsValid()
		and traceMisc.Entity:GetClass() == "sc_x_fakeitem"
	)

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

	slasher:SetNWBool("2011xCanTpToClone",
		slasher:GetNWFloat("2011xTpToCloneCooldown") <= 0
		and not globalCooldown
		and not stunned
		and traceClone.Entity:IsValid()
		and traceClone.Entity:GetClass() == "sc_x_clone"
	)

	slasher:SetNWBool("2011xCanDetonate",
		slasher:GetNWFloat("2011xDetonateCooldown") <= 0
		and not globalCooldown
		and not stunned
	)

	-- Logic for the charge, i wanna die this code fucking sucks
	if slasher:GetNWBool("2011xCharging") then
		slasher:SetVelocity(slasher:GetAimVector() * SLASHER.Config.Charge.speed)

		-- Hit detection, it's ass but it'll do, might switch to find players in sphere later
		local entities = ents.FindInSphere(slasher:GetPos() + slasher:GetUp() * 20, 50)
		for _, ent in pairs(entities) do
			if IsValid(ent) and ent:IsPlayer() and ent:Team() == TEAM_SURVIVOR then
				endCharge(slasher, false, nil)

				local finalDamage = SLASHER.Config.Charge.baseDamage

				if SLASHER.Config.Charge.damageBasedOnDuration then
					finalDamage = finalDamage * ((SLASHER.Config.Charge.duration - timer.TimeLeft("2011xCharge_" .. slasher:EntIndex())) / SLASHER.Config.Charge.duration)
				end

				if DEBUG then
					print("Charge damage: " .. finalDamage)
				end
				timer.Stop("2011xCharge_" .. slasher:EntIndex())
				damagePlayer(slasher, ent, finalDamage, 200)
			end
		end

		-- The charge crash logic, it's ass, this shit needs to be changed asap to depends on normals
		if (SLASHER.Config.Charge.crashLogic) then
			local curVel = slasher:GetVelocity():Length()
			if (curVel > SLASHER.Config.Charge.crashActivateThreshold) then slasher.canCrash = true end

			if (curVel < SLASHER.Config.Charge.crashThreshold and slasher.canCrash) then endCharge(slasher, true) end
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
	slasher:SetNWFloat("2011xLMBCooldown", SLASHER.Config.LMB.cooldown)
	slasher:SetNWFloat("2011xGlobalCooldown", SLASHER.Config.LMB.globalCooldown or 0)

	slasher:LagCompensation(true)

	local startpos = slasher:GetPos()
	local dir = slasher:GetUp()

	local maxs = Vector(SLASHER.Config.LMB.hitboxSize / 2, SLASHER.Config.LMB.hitboxSize / 2, SLASHER.Config.LMB.hitboxSize / 2)
	local mins = Vector(-SLASHER.Config.LMB.hitboxSize / 2, -SLASHER.Config.LMB.hitboxSize / 2, -SLASHER.Config.LMB.hitboxSize / 2)

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
		damagePlayer(slasher, target, SLASHER.Config.LMB.damage, SLASHER.Config.LMB.knockback)
	end
end

-- Right click
function SLASHER.OnSecondaryFire(slasher)
	if not slasher:GetNWBool("2011xCanFakeItem") then return end
	slasher:SetNWFloat("2011xFakeItemCooldown", SLASHER.Config.FakeItem.cooldown)
	slasher:SetNWFloat("2011xGlobalCooldown", SLASHER.Config.FakeItem.globalCooldown or 0)
	spawnFakeItem(slasher)
end

-- R
function SLASHER.OnMainAbilityFire(slasher)
	if not slasher:GetNWBool("2011xCanCharge") then return end
	slasher:SetNWFloat("2011xChargeCooldown", SLASHER.Config.Charge.cooldown + SLASHER.Config.Charge.cooldown)

	-- We do +1 here to prevent just being able to use an ability right after
	slasher:SetNWFloat("2011xGlobalCooldown", SLASHER.Config.Charge.duration + (SLASHER.Config.Charge.globalCooldown or 0) + 1)

	slasher.canCrash = false
	slasher:SetFriction(SLASHER.Config.Charge.friction)
	slasher:SetNWBool("2011xCharging", true)
	slasher:SetVelocity(-(slasher:GetVelocity()))

	timer.Create("2011xCharge_" .. slasher:EntIndex(), SLASHER.Config.Charge.duration, 1, function()
		endCharge(slasher, false)
	end)
end

-- F
function SLASHER.OnSpecialAbilityFire(slasher)
	if not slasher:GetNWBool("2011xCanTpToClone") then return end
	slasher:SetNWFloat("2011xTpToCloneCooldown", SLASHER.Config.TpToClone.cooldown)
	slasher:SetNWFloat("2011xGlobalCooldown", SLASHER.Config.TpToClone.globalCooldown or 0)

	local trace = util.TraceLine(
		{
			start = slasher:EyePos(),
			endpos = slasher:EyePos() + slasher:GetAimVector() * SLASHER.Config.TpToClone.tpRange,
			ignoreworld = true,
			filter = { "sc_x_clone" },
			whitelist = true
		}
	)

	-- We swap em
	if (trace.Hit and trace.Entity:IsValid()) then
		local tempPos, tempAngle = slasher:GetPos(), slasher:GetAngles()
		local entity = trace.Entity

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
	end
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
			ply.CalcSeqOverride = ply:LookupSequence("charge_run")
		else
			ply.CalcIdeal = ACT_HL2MP_WALK
			ply.CalcSeqOverride = ply:LookupSequence("run")
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

-- Function used for when the slasher should be in third person (the return is the state, so if you return true they're in thirdperson)
function SLASHER.Thirdperson(ply)
	return ply:GetNWBool("2011xStunned") or ply:GetNWBool("2011xCharging")
end

-- The footsteps, will be finished eventually lmfao
function SLASHER.Footstep(ply)
	return true
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


-- This will be used to highlight players close enough to a clone, thank you very much Xerk
function SLASHER.PreDrawHalos(slasher)
	local plyMarked = {}

	for _, clone in pairs(ents.FindByClass("sc_x_clone")) do
		for _, survivor in ipairs(ents.FindInSphere(clone:GetPos(), SLASHER.Config.Clones.detectionRange)) do
			if not IsValid(survivor) or not survivor:IsPlayer() or survivor:Team() ~= TEAM_SURVIVOR then continue end
			table.insert(plyMarked, survivor)
		end
	end

	SlashCo.DrawHalo(plyMarked, "blue", 2, true)
	SlashCo.DrawHalo(ents.FindByClass("sc_x_*"), Color(255,0,255), nil, true)
end

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


--[[
BADLOADER by krazy, feel free to use and/or change stuff as needed.

The start of the 'slasherPath' is from the 'lua' folder
]]

local slasherPath = "slashco/slasher/2011x"

for _, filename in pairs(file.Find(slasherPath .. "/*.lua", "LUA")) do
	local filepath = string.format("%s/%s", slasherPath, filename)

	if string.StartsWith(filename, "cl_") then
		if SERVER then
			AddCSLuaFile(filepath)
			print(string.format("SERVER: Loaded: %s", filepath))
		else
			include(filepath)
			print(string.format("CLIENT: Loaded: %s", filepath))
		end
	elseif string.StartsWith(filename, "sv_") then
		if SERVER then
			include(filepath)
			print(string.format("SERVER: Loaded: %s", filepath))
		end
	elseif string.StartsWith(filename, "sh_") then
		if SERVER then
			AddCSLuaFile(filepath)
		end
		include(filepath)
		print(string.format("%s: Loaded: %s", SERVER and "SERVER" or "CLIENT", filepath))
	end
end

SlashCo.RegisterSlasher(SLASHER, "2011x")