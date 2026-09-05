if not SERVER then return end

hook.Add( "StartCommand", "MouseWheel", function( ply, cmd )
    if ply:Team() ~= TEAM_SLASHER or ply:GetNWString("Slasher") ~= "2011x" then return end
    if ( cmd:GetMouseWheel() ~= 0) then

        ply:SetNWInt("2011xCurFakeItemSelection", math.Clamp(ply:GetNWInt("2011xCurFakeItemSelection") + -cmd:GetMouseWheel(), 1, #SLASHER.Config.FakeItem.spawnList))
    end

    if (ply:GetNWBool("2011xCharging")) then
        cmd:ClearMovement()
    end
end)

hook.Add("SlashCo:OnPing", "2011xPingStuff", function(pingInfo)
    if not istable(pingInfo) then return end -- Should always be a table but just in case
    if DEBUG then PrintTable(pingInfo) end

    local pingingPlayer = pingInfo.Player
    local entity = pingInfo.Entity

    if isnumber(pingingPlayer) then pingingPlayer = Entity(pingingPlayer) end
    if isnumber(entity) then entity = Entity(entity) end

    if not IsValid(pingingPlayer) or not pingingPlayer:IsPlayer() then return end

    -- This section of code is to properly detect when you ping a slasher, as for some fucking reason it wouldn't put the entity in pinginfo.Entity
    local traced = pingingPlayer:GetEyeTrace().Entity

    -- Had to do this cause if you ping a player it wouldn't return the entity, and so I couldn't get a slasher's name
    if traced:IsPlayer() and pingingPlayer:Team() == TEAM_SLASHER and traced:Team() == TEAM_SLASHER then
        pingInfo.Type = traced:GetNWString("Slasher", "")
    end

    -- Fake item stuff
    if IsValid(entity) and entity:GetClass() == "sc_x_fakeitem" and pingInfo.Team == TEAM_SURVIVOR then
        local voiceline = GetVoiceByPingType(pingInfo.Type)

        -- If a survivor pings the fake item, we make them say the line and return
        if voiceline then
            sayPrompt(pingingPlayer, voiceline)
        end
        return true
    end

    -- Used for 2011x special interactions
    local returnTarget = IsValid(entity) and entity:GetClass() or pingInfo.Type

    local voiceline = SLASHER.Config.specialInteractions[string.lower(returnTarget or "")]
    if not voiceline then return end	-- If there's no voiceline at all then we return

    if istable(voiceline) then
        voiceline = voiceline[math.random(#voiceline)]
    end
    sayPrompt(pingingPlayer, voiceline)

    return false
end)