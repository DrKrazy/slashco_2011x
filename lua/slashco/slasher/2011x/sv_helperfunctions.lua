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

-- Getting the voiceline suffix by ping type for fake items, used for survivors mainly
function GetVoiceByPingType(pingtype)
	for _, item in ipairs(SLASHER.XSettings.FakeItem.spawnList) do
		if item.pingtype == pingtype then
			return item.vlInput
		end
	end
	return nil
end

-- Used to end the charge properly
function endCharge(slasher, doStun, stunTime)
	slasher:SetFriction(1)
	slasher:SetNWBool("2011xCharging", false)

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
	fakeItem:SetVar("expKnockback", SLASHER.XSettings.FakeItem.expKnockback)
	fakeItem:SetVar("maxNear", SLASHER.XSettings.FakeItem.maxNear)
	fakeItem:SetVar("slowActive", SLASHER.XSettings.FakeItem.Slowness.active)
	fakeItem:SetVar("slowMinDuration", SLASHER.XSettings.FakeItem.Slowness.minDuration)
	fakeItem:SetVar("slowMaxDuration", SLASHER.XSettings.FakeItem.Slowness.maxDuration)
	fakeItem:SetVar("slowMinDistance", SLASHER.XSettings.FakeItem.Slowness.minDistance)
	fakeItem:SetVar("slowMaxDistance", SLASHER.XSettings.FakeItem.Slowness.maxDistance)

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

function damagePlayer(slasher, victim, damage, damageForce)
	if victim:IsValid() and victim:IsPlayer() then
		-- If the victim is one hit, we jumpscare them instead (need to add jumps)
		-- Have to make my own jumpscare logic cause stock one wouldn't work
		if victim:Health() <= SLASHER.XSettings.LMB.damage then
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
		victim:SetVelocity(slasher:GetAimVector() * damageForce)

		effect:SetOrigin(victim:GetPos() + Vector(0,0,40))
		util.Effect("BloodImpact", effect)
		return true
	end
	return false
end