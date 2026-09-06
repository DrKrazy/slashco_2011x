if not CLIENT then return end

-- Hooks triggered on the clients, mainly used for the fake chase light

hook.Add("Think", "FakeChaseLight", function()
    for _, slasher in ipairs(team.GetPlayers(TEAM_SLASHER)) do
        if not slasher:GetNWBool("InSlasherChaseMode") then return end
        local dlight = DynamicLight(slasher:UserID())

        if dlight then
            dlight.pos = slasher:LocalToWorld(Vector(0,0,40))
            dlight.r = SLASHER.Config.chaseColor.r
            dlight.g = SLASHER.Config.chaseColor.g
            dlight.b = SLASHER.Config.chaseColor.b
            dlight.brightness = 6

            dlight.Decay = 1000
            dlight.Size = 300
            dlight.DieTime = CurTime() + 1
        end
    end
end)

hook.Add("PreDrawHalos", "CloneHighlight", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:Team() ~= TEAM_SURVIVOR then return end

    local lookingClones = {}

    for _, clone in ipairs(ents.FindByClass("sc_x_clone")) do
        if clone:GetPos():Distance(ply:GetPos()) < 250 then
            table.insert(lookingClones, clone)
        end
    end

    halo.Add(lookingClones, Color(255,0,0), 1, 1, 2, nil, true)
end)