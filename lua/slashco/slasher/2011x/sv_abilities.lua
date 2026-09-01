--[[ 
    Seperated the abilities themselves into their own file cause why not.
]]

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
		SLASHER.damagePlayer(slasher, target, SLASHER.Config.LMB.damage, SLASHER.Config.LMB.knockback)
	end
end

-- Right click
function SLASHER.OnSecondaryFire(slasher)
	if not slasher:GetNWBool("2011xCanFakeItem") then return end
	slasher:SetNWFloat("2011xFakeItemCooldown", SLASHER.Config.FakeItem.cooldown)
	slasher:SetNWFloat("2011xGlobalCooldown", SLASHER.Config.FakeItem.globalCooldown or 0)
	SLASHER.spawnFakeItem(slasher)
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
		SLASHER.endCharge(slasher, false)
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