lycan_e = class({})

LinkLuaModifier("modifier_lycan_e", "abilities/lycan/modifier_lycan_e", LUA_MODIFIER_MOTION_NONE)

function lycan_e:OnSpellStart()
    local hero = self:GetCaster().hero

    hero:AreaEffect({
        ability = self,
        filter = Filters.Area(hero:GetPos(), 350),
        onlyHeroes = true,
        action = function(target)
            target:AddNewModifier(hero, self, "modifier_lycan_e", { duration = 2.0 }):Update()
            if instanceof(target, Hero) then
                target:AddKnockbackSource(hero, 2.0)
            end
        end
    })

    FX("particles/units/heroes/hero_lycan/lycan_howl_cast.vpcf", PATTACH_ABSORIGIN, hero, {
        cp0 = hero:GetPos(),
        cp1 = hero:GetPos() + hero:GetFacing()
    })
    hero:EmitSound("Arena.Lycan.CastE")
end

function lycan_e:GetCastAnimation()
    return ACT_DOTA_CAST_ABILITY_2
end

function lycan_e:GetPlaybackRateOverride()
    return 2.0
end

if IsClient() then
    require("wrappers")
end

Wrappers.NormalAbility(lycan_e)