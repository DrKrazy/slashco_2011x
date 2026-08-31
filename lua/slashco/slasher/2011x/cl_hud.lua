if not CLIENT then return end

-- Hud function, this is where you do cool UI shit
local lmbTable = {
	default = Material("slashco/ui/icons/slasher/2011x/LMB"),
	["d/"] = Material("slashco/ui/icons/slasher/2011x/LMB_d")
}

local rmbTable = {
	default = Material("slashco/ui/icons/slasher/2011x/fakeitem"),
	["d/"] = Material("slashco/ui/icons/slasher/2011x/fakeitem_d")
}

local mwTable = {
	default = Material("slashco/ui/icons/slasher/2011x/"),
	["d/"] = Material("slashco/ui/icons/slasher/2011x/_d"),
	["detonate"] = Material("slashco/ui/icons/slasher/2011x/detonate"),
	["d/detonate"] = Material("slashco/ui/icons/slasher/2011x/detonate_d")
}

local fTable = {
	default = Material("slashco/ui/icons/slasher/2011x/tptoclone"),
	["d/"] = Material("slashco/ui/icons/slasher/2011x/tptoclone_d")
}

local rTable = {
	default = Material("slashco/ui/icons/slasher/2011x/charge"),
	["d/"] = Material("slashco/ui/icons/slasher/2011x/charge_d")
}

function SLASHER.InitHud(_, hud)
	hud:SetAvatar(Material("slashco/ui/icons/slasher/2011x/avatar"))
	hud:SetTitle(SLASHER.Name)
	hud:SetCrosshairEnabled(true)
	hud:SetCrosshairAlpha(255)
	hud:SetCrosshairSpin(0)
	hud:SetCrosshairTighten(5)
	hud:SetCrosshairProngs(4)

	hud:TieCrosshair({
		"2011xCanTpToClone",
		"2011xLookingAtFakeItem",
		InvertOutput = true,
		IsOr = true
	}, {
		TightenOn = 20,
		TightenOff = 0
	})

	-- Control Stuff
	-- This was made to make creating the controls and editing them easier for the cooldown system
	-- Do NOT make this a hash table, otherwise you won't be able to control the order in the hud
	handleCooldowns = {
		{
			key = "R",
			controlName = "X_charge",
			netVarCD = "2011xChargeCooldown",
			netVarTie = "2011xCanCharge",
			icon = rTable,
			preventOverwrite = false,
		},
		{
			key = "F",
			controlName = "X_teleport",
			netVarCD = "2011xTpToCloneCooldown",
			netVarTie = "2011xCanTpToClone",
			icon = fTable,
			preventOverwrite = false,
		},
		{
			key = "MOUSEWHEEL",
			controlName = "X_detonate",
			netVarCD = "2011xDetonateCooldown",
			netVarTie = "2011xCanDetonate",
			icon = mwTable,
			preventOverwrite = true,
		},
		{
			key = "RMB",
			controlName = "X_fakeItem",
			netVarCD = "2011xFakeItemCooldown",
			netVarTie = "2011xCanFakeItem",
			icon = rmbTable,
			preventOverwrite = false,
		},
		{
			key = "LMB",
			controlName = "kill survivor",
			netVarCD = "2011xLMBCooldown",
			netVarTie = "2011xCanLMB",
			icon = lmbTable,
			preventOverwrite = false,
		},
	}

	for _, control in pairs(handleCooldowns) do
		hud:AddControl(control.key, "", control.icon)
		hud:TieControl(control.key, control.netVarTie, false, true, nil)
	end

	local slasher = GameData.LocalPlayer

	-- This is mainly used to update the hud for the cooldowns

	function hud.AlsoThink()
		local detonateText = "X_detonate"
		local globalCooldown = slasher:GetNWFloat("2011xGlobalCooldown", 0)
		local fakeItemSelection = slasher:GetNWInt("2011xCurFakeItemSelection", 1)

		if not slasher:GetNWBool("2011xLookingAtFakeItem") then
			detonateText = tostring(SLASHER.XSettings.FakeItem.spawnList[fakeItemSelection].pingtype)
		end

		for _, control in ipairs(handleCooldowns) do
			local cooldown = math.max(slasher:GetNWFloat(control.netVarCD, 0), globalCooldown)

			local controlName = control.controlName
			if control.preventOverwrite then controlName = detonateText end

			local text = SlashCo.LangTable[controlName]
			if cooldown > 0 then text = string.format( "[ %.1f ] %s", cooldown, text ) end

			hud:SetControlText(control.key, text)
		end

		if DEBUG then
			local debugTable = {
				{ seperator = " :", debugString = "", value = "Cooldowns"},
				{ seperator = " : ", debugString = "2011xLMBCooldown", value = math.Clamp(slasher:GetNWFloat("2011xLMBCooldown", 0), 0, math.huge)},
				{ seperator = " : ", debugString = "2011xFakeItemCooldown", value = math.Clamp(slasher:GetNWFloat("2011xFakeItemCooldown", 0), 0, math.huge)},
				{ seperator = " : ", debugString = "2011xChargeCooldown", value = math.Clamp(slasher:GetNWFloat("2011xChargeCooldown", 0), 0, math.huge)},
				{ seperator = " : ", debugString = "2011xTpToCloneCooldown", value = math.Clamp(slasher:GetNWFloat("2011xTpToCloneCooldown", 0), 0, math.huge)},
				{ seperator = " : ", debugString = "2011xDetonateCooldown", value = math.Clamp(slasher:GetNWFloat("2011xDetonateCooldown", 0), 0, math.huge)},
				{ seperator = " : ", debugString = "2011xGlobalCooldown", value = math.Clamp(slasher:GetNWFloat("2011xGlobalCooldown", 0), 0, math.huge)},

				{ seperator = "", debugString = "", value = ""},
				{ seperator = " :", debugString = "", value = "Abilities"},
				{ seperator = " : ", debugString = "2011xCanFakeItem", value = slasher:GetNWBool("2011xCanFakeItem", false)},
				{ seperator = " : ", debugString = "2011xCanCharge", value = slasher:GetNWBool("2011xCanCharge", false)},
				{ seperator = " : ", debugString = "2011xCanTpToClone", value = slasher:GetNWBool("2011xCanTpToClone", false)},
				{ seperator = " : ", debugString = "2011xCanDetonate", value = slasher:GetNWBool("2011xCanDetonate", false)},
				{ seperator = " : ", debugString = "2011xLookingAtFakeItem", value = slasher:GetNWBool("2011xLookingAtFakeItem", false)},

				{ seperator = "", debugString = "", value = ""},
				{ seperator = " :", debugString = "", value = "Player"},
				{ seperator = " : ", debugString = "Velocity", value = math.Round(slasher:GetVelocity():Length())},
			}
			for i, debugText in ipairs(debugTable) do
				DebugInfo(i, tostring(debugText.value) .. debugText.seperator .. debugText.debugString)
			end
		end
	end
end