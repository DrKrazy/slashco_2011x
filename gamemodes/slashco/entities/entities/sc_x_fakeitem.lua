AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "sc_baseitem"
ENT.PrintName = "Test Entity"
ENT.Spawnable = true

function ENT:Initialize()
	self:SetNotSolid( true )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:PhysWake()
end

if SERVER then
	function ENT:Explode()
		if self.Exploded then return end
		self.Exploded = true

		local expRange = self:GetVar("expRange")
		local expDamage = self:GetVar("expDamage")
		local expDelay = self:GetVar("expDelay")
		local expForce = self:GetVar("expForce")
		local triggeredColor = self:GetVar("triggeredColor")
		local slasherKnockback = self:GetVar("slasherKnockback")

		-- PrintMessage(HUD_PRINTCENTER,
		-- 	"expRange: " .. tostring(expRange) .. "\n" ..
		-- 	"expDamage: " .. tostring(expDamage) .. "\n" ..
		-- 	"expDelay: " .. tostring(expDelay) .. "\n" ..
		-- 	"expForce: " .. tostring(expForce) .. "\n" ..
		-- 	"triggeredColor: " .. tostring(triggeredColor) .. "\n" ..
		-- 	"self.pos: " .. tostring(self:GetPos())
		-- )

		self:SetColor(triggeredColor)
		timer.Simple(expDelay, function()
			local pos = self:GetPos()

			for _, ent in ipairs(ents.FindInSphere(pos, expRange)) do
				if not IsValid(ent) or ent == self then continue end

				if ent:IsPlayer() and (ent:Team() == TEAM_SURVIVOR or slasherKnockback) then
					ent:TakeDamage(expDamage, self, self)
					ent:SetVelocity(-(pos - ent:GetPos()) * expForce)
				end
				if ent:GetClass() == self:GetClass() then
					ent:Explode()
				end
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
		debugoverlay.Sphere(self:GetPos(), self:GetVar("expRange"), 1)
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