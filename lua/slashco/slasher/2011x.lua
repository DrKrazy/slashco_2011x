-- This has to be non local for the loader to properly work
SLASHER = {}

-- Enable to see a bunch of debug information that was used during this slasher's development
DEBUG = true

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
BADLOADER by krazy, feel free to use and/or change stuff as needed.

The start of the 'slasherPath' is from the 'lua' folder
]]

local slasherPath = "slashco/slasher/2011x"

for _, filename in pairs(file.Find(slasherPath .. "/*.lua", "LUA")) do
	local filepath = string.format("%s/%s", slasherPath, filename)

	if string.StartsWith(filename, "cl_") then
		if SERVER then
			AddCSLuaFile(filepath)
		else
			include(filepath)
		end
		print(string.format("[SlashCo 2011x] %s: Loaded: %s", SERVER and "SERVER" or "CLIENT", filepath))
	elseif string.StartsWith(filename, "sv_") then
		if SERVER then
			include(filepath)
			print(string.format("[SlashCo 2011x] SERVER: Loaded: %s", filepath))
		end
	elseif string.StartsWith(filename, "sh_") then
		if SERVER then
			AddCSLuaFile(filepath)
		end
		include(filepath)
		print(string.format("[SlashCo 2011x] %s: Loaded: %s", SERVER and "SERVER" or "CLIENT", filepath))
	end
end

SlashCo.RegisterSlasher(SLASHER, "2011x")
SLASHER = nil