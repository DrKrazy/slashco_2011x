--[[ 
    This shit is gigantic, im putting in it's own file
]]

-- This happens on every tick, lord have mercy this shit sucks
-- Sorry to whoever wants to take a look into this
function SLASHER.OnTickBehaviour(slasher)
	local final_eyesight = SLASHER.Eyesight
	local final_perception = SLASHER.Perception

	-- This is used to detect when the slasher is looking at a clone or fakeitem to trigger
	local traceClone = util.TraceLine(
		{
			start = slasher:EyePos(),
			endpos = slasher:EyePos() + slasher:GetAimVector() * SLASHER.Config.TpToClone.tpRange,
			ignoreworld = true,
			filter = { "sc_x_clone", "sc_x_fakeitem"},
			whitelist = true
		}
	)

	-- Custom start chase logic
	-- Unironically very ass, will improve later
	local traceMisc = slasher:GetEyeTrace()
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
		and traceClone.Entity:IsValid()
	)

	-- Logic for the charge, i wanna die this code fucking sucks
	if slasher:GetNWBool("2011xCharging") then
		slasher:SetVelocity(slasher:GetAimVector() * SLASHER.Config.Charge.speed)

		-- Hit detection, it's ass but it'll do, might switch to find players in sphere later
		local entities = ents.FindInSphere(slasher:GetPos() + slasher:GetUp() * 20, 50)
		for _, ent in pairs(entities) do
			if IsValid(ent) and ent:IsPlayer() and ent:Team() == TEAM_SURVIVOR then
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

	-- :D
	slasher:SetEyeSight(final_eyesight)
	slasher:SetPerception(final_perception)
end