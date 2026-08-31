if not CLIENT then return end

hook.Add("Think", "FakeChaseLight", function()
    for _, slasher in ipairs(team.GetPlayers(TEAM_SLASHER)) do
        if not slasher:GetNWBool("InSlasherChaseMode") then return end
        local dlight = DynamicLight(slasher:UserID())

        if dlight then
            dlight.pos = slasher:LocalToWorld(Vector(0,0,40))
            dlight.r = SLASHER.XSettings.chaseColor.r
            dlight.g = SLASHER.XSettings.chaseColor.g
            dlight.b = SLASHER.XSettings.chaseColor.b
            dlight.brightness = 6

            dlight.Decay = 1000
            dlight.Size = 300
            dlight.DieTime = CurTime() + 1
        end
    end
end)