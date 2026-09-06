AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "sc_baseitem"
ENT.PrintName = "Test Entity"
ENT.Spawnable = true

function ENT:Initialize()
	self:SetNotSolid( true )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
	self:PhysWake()
end

if SERVER then
	function ENT:Explode()
		if self.Exploded then return end
		self.Exploded = true

		local expRange = self:GetVar("expRange")
		local expDamage = self:GetVar("expDamage")
		local expDelay = self:GetVar("expDelay")
		local velocity = self:GetVar("velocity")
		local triggeredColor = self:GetVar("triggeredColor")
		local slowActive = self:GetVar("slowActive")
		local slowMinDuration = self:GetVar("slowMinDuration")
		local slowMaxDuration = self:GetVar("slowMaxDuration")
		local slowMinDistance = self:GetVar("slowMinDistance")
		local slowMaxDistance = self:GetVar("slowMaxDistance")

		self:SetColor(triggeredColor)
		timer.Simple(expDelay, function()
			local pos = self:GetPos()

			for _, ent in ipairs(ents.FindInSphere(pos, expRange)) do
				if not IsValid(ent) or ent == self then continue end

				-- If its of the same class (so a fake item), we explode it and continue
				if ent:GetClass() == self:GetClass() then
					ent:Explode()
					continue
				end

				-- If the entity isnt a player, we continue
				-- If the player isn't a survivor and slasherknockback is false, we continue
				if not ent:IsPlayer() or ent:Team() ~= TEAM_SURVIVOR then continue end

				if (ent:Health() < expDamage) then
					ent:Kill()

					local newragdoll = replaceRagdoll(ent, "models/Humans/Charple01.mdl", velocity, self:GetPos())
					newragdoll:Fire("Ignite", 0)
				end
				ent:TakeDamage(expDamage, self, self)
				ent:SetVelocity(-(pos - ent:GetPos()) * velocity)

				if slowActive then
					ent:AddEffect("Slowness",
					math.Remap(
						self:GetPos():Distance(self:GetOwner():GetPos()),
						slowMinDistance,
						slowMaxDistance,
						slowMinDuration,
						slowMaxDuration)
					)
				end

				--print(ent:Nick() .. " slashco_tyler_disable_shake: " .. ent:GetInfo("slashco_tyler_disable_shake") or "nothing")
				ent:AddEffect("Dazed", math.Remap(
						self:GetPos():Distance(self:GetOwner():GetPos()),
						slowMinDistance,
						slowMaxDistance,
						slowMinDuration,
						slowMaxDuration)
					)
			end

			local effect = EffectData()
			effect:SetOrigin(pos)

			util.Effect("Explosion", effect)
			self:Remove()
		end)
	end
	function ENT:Use(activator)
		if activator:Team() ~= TEAM_SURVIVOR or self.Exploded == true then
			return
		end
		self:Explode()
	end

	function ENT:Think()
		if self:GetVar("maxNear") == nil then return end

		-- We check it every second, there's no need for it to be any faster
		self:NextThink(CurTime() + 1)

		local pos = self:GetPos()

		local counter = 0
		for _, ent in ipairs(ents.FindInSphere(pos, self:GetVar("expRange"))) do
			if not IsValid(ent) or ent == self then continue end
			if ent:GetClass() == self:GetClass() then
				counter = counter + 1
			end
		end

		if counter >= self:GetVar("maxNear") then
			self:Explode()
		end

		return true
	end
end

if not CLIENT then return end

function ENT:Draw()
	self:DrawModel()
end