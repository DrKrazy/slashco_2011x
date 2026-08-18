AddCSLuaFile()

-- Shared stuff
local SlashCo = SlashCo
ENT.Base = "base_nextbot"
ENT.Type = "nextbot"
ENT.PrintName = "2011x"
ENT.PingType = "SLASHER"

-- Server only stuff
local model = "models/slashco/slashers/2011x/2011x.mdl"

hook.Add("SlashCo:Precache", "SlashCo:Precache_XTpClone", function()
	SlashCo.PrecacheModel(model)
end)


-- Server only stuff
if SERVER then
	function ENT:Initialize()
		self:SetModel(model)
		self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)

		self.flTicks = self:GetVar("flTicks", 0)
		self.clDuration = self:GetVar("clDuration", nil)
		self.flRange = self:GetVar("flRange", 10)
	end

	function ENT:Think()

		-- If the flashlight counter or duration reaches below 1, we kill it (this is cause doing below or equal 0 gives it an extra second and it was angering me)
		-- the "or 2" for the duration is here for if its nil ( its for infinite duration, dw about it :D )

		if (self.flTicks < 1 or (self.clDuration or 2) < 1) then
			local effect = EffectData()
			effect:SetOrigin(self:GetPos() + Vector(0,0,40))
			effect:SetScale(600)
			util.Effect("BloodImpact", effect)
			self:Remove()
		end

		-- I have no idea how to not make this suck absolute balls, sorry to whoever wants to make this better
		for _, ply in ipairs(team.GetPlayers(TEAM_SURVIVOR)) do
			if ply:GetEyeTrace().Entity ~= self then return end
			if not IsValid(ply) or not ply:Alive() then return end
			if ply:GetPos():DistToSqr(self:GetPos()) > self.flRange * self.flRange then return end
			if not ply:GetNW2Bool("DynamicFlashlight") then return end

			self.flTicks = self.flTicks - FrameTime()
		end

		-- As long as the clDuration isnt nil, we count it down
		if (self.clDuration ~= nil) then
			self.clDuration = self.clDuration - FrameTime()
		end
		return true
	end

	-- This is done to prevent warnings and shit in the console due to this entity being anext bot
	-- Will be used in the future tho 
	function ENT:BehaveStart()
	end
end

-- Client only stuff
if CLIENT then
	function ENT:Think()
		local client = LocalPlayer()

		if not IsValid(client) or not IsValid(self) then return end
		if (client:Team() ~= TEAM_SURVIVOR) then return end

		local direction = self:WorldToLocal(client:GetPos())

		local ang = direction:Angle()

		self:SetPoseParameter("body_pitch", -ang.p)
		self:SetPoseParameter("body_yaw", -ang.y)
	end

	function ENT:Draw()
		self:DrawModel()
	end
end

