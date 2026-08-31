if not SERVER then return end

hook.Add( "StartCommand", "MouseWheel", function( ply, cmd )
    if ply:Team() ~= TEAM_SLASHER or ply:GetNWString("Slasher") ~= "2011x" then return end
    if ( cmd:GetMouseWheel() ~= 0) then

        ply:SetNWInt("2011xCurFakeItemSelection", math.Clamp(ply:GetNWInt("2011xCurFakeItemSelection") + -cmd:GetMouseWheel(), 1, #SLASHER.XSettings.FakeItem.spawnList))
    end

    if (ply:GetNWBool("2011xCharging")) then
        cmd:ClearMovement()
    end
end)

hook.Add("SlashCo:OnPing", "2011xPingStuff", function(pingInfo)
    if not istable(pingInfo) then return end -- Should always be a table but just in case

    local pingingPlayer = pingInfo.Player
    if isnumber(pingingPlayer) then pingingPlayer = Entity(pingingPlayer) end
    if not IsValid(pingingPlayer) or not pingingPlayer:IsPlayer() then return end

    local entity = pingInfo.Entity
    if isnumber(entity) then entity = Entity(entity) end

    -- This section of code is to properly detect when you ping a slasher, as for some fucking reason it wouldn't put the entity in pinginfo.Entity
    local traced = pingingPlayer:GetEyeTrace().Entity

    -- Had to do this cause if you ping a player it wouldn't return the entity, and so I couldn't get a slasher's name
    if traced:IsPlayer() and pingingPlayer:Team() == TEAM_SLASHER and traced:Team() == TEAM_SLASHER then
        pingInfo.Type = traced:GetNWString("Slasher", "")
    end

    -- Fake item stuff
    if IsValid(entity) and entity:GetClass() == "sc_x_fakeitem" then
        -- If a survivor pings the fake item, we make them say the line and return
        if pingInfo.Team == TEAM_SURVIVOR then
            local voiceLine = GetVoiceByPingType(pingInfo.Type)

            if voiceLine then
                sayPrompt(pingingPlayer, voiceLine)
            end
            return true
        end

        -- If 2011x pings a fake item and it can blow up, we blow it up (we don't care if its another 20xx's fake item, they're shared)
        if pingInfo.Team == TEAM_SLASHER and pingingPlayer:GetNWBool("2011xCanDetonate", false) then
            entity:SetVar("expDamage", SLASHER.XSettings.FakeItem.Detonate.expDamageOverride)
            entity:SetVar("slowActive", false)
            entity:Explode()

            pingingPlayer:SetNWFloat("2011xDetonateCooldown", SLASHER.XSettings.FakeItem.Detonate.cooldown)
            pingingPlayer:SetNWFloat("2011xGlobalCooldown", SLASHER.XSettings.FakeItem.Detonate.globalCooldown)
        end
    end

    -- Used for 2011x special interactions
    local returnTarget = pingInfo.Type
    if IsValid(entity) then returnTarget = entity:GetClass() end

    if DEBUG then
        print("Pinged: " .. returnTarget)
    end

    local pingVoiceLine = SLASHER.XSettings.specialInteractions[string.lower(returnTarget)]
    if not pingVoiceLine then return end	-- If there's no voiceline at all then we return

    if istable(pingVoiceLine) then
        pingVoiceLine = pingVoiceLine[math.random(#pingVoiceLine)]
    end
    sayPrompt(pingingPlayer, pingVoiceLine)

    return false
end)