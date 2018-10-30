LycanWolf = LycanWolf or class({}, nil, UnitEntity)

function LycanWolf:constructor(round, owner, target, offsetModifier, ability)
    local direction = (target - owner:GetPos()):Normalized()
    direction = Vector(direction.y, -direction.x, 0)
    local pos = owner:GetPos() + direction * 200 * offsetModifier

    getbase(LycanWolf).constructor(self, round, "lycan_wolf", pos, owner.unit:GetTeamNumber(), true)

    self.owner = owner.owner
    self.hero = owner
    self.size = 128
    self.start = owner:GetPos()
    self.target = target
    self.offsetModifier = offsetModifier
    self.removeOnDeath = false
    self.attacking = nil
    self.collisionType = COLLISION_TYPE_INFLICTOR
    self.startTime = GameRules:GetGameTime()
    self.ability = ability

    self:SetFacing(target - self.start)

    self:AddComponent(HealthComponent())
    self:AddNewModifier(self.hero, nil, "modifier_lycan_q", { duration = 3 })
    self:SetCustomHealth(2)
    self:EnableHealthBar()

    self.fearIsUsed = false

    if owner:IsAwardEnabled() then
        local awardModel = "models/items/lycan/wolves/hunter_kings_wolves/hunter_kings_wolves.vmdl"
        
        self:GetUnit():SetModel(awardModel)
        self:GetUnit():SetOriginalModel(awardModel)
    end

    ImmediateEffect("particles/units/heroes/hero_lycan/lycan_summon_wolves_spawn.vpcf", PATTACH_ABSORIGIN, self.unit)
end

function LycanWolf:GetPos()
    return self:GetUnit():GetAbsOrigin()
end

function LycanWolf:CollidesWith(target)
    return self.owner.team ~= target.owner.team
end

function LycanWolf:CollideWith(target)
    local unit = self:GetUnit()

    if not instanceof(target, Projectile) and not instanceof(target, Obstacle) and not unit:IsStunned() and not unit:IsRooted() and not self.attacking and not target:IsAirborne() and self.fearIsUsed == false then
        local direction = (target:GetPos() - self:GetPos())
        local distance = direction:Length2D()

        ExecuteOrderFromTable({ UnitIndex = unit:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_STOP })

        self:FindModifier("modifier_lycan_q"):SetDuration(0.25, false)
        self:SetFacing(direction:Normalized())
        self.attacking = target
        self.collisionType = COLLISION_TYPE_RECEIVER
        self:EmitSound("Arena.Lycan.HitQ")

        StartAnimation(unit, { duration = 0.25, activity = ACT_DOTA_ATTACK, rate = 2.0 })
    end
end

function LycanWolf:Update()
    getbase(LycanWolf).Update(self)

    if self.falling then
        return
    end

    if self.fearIsUsed then
        TimedEntity(0.75, function()
            self:Destroy()
        end):Activate()
    end

    if self:FindModifier("modifier_lycan_q"):GetRemainingTime() <= 0 then
        local blocked = self.attacking and self.attacking:AllowAbilityEffect(self, self.ability) == false

        if not blocked and self.attacking and self.attacking:Alive() and not self.fearIsUsed then
            local distance = (self.attacking:GetPos() - self:GetPos()):Length2D()

            --if distance <= 250 then
                self.attacking:Damage(self, self.ability:GetDamage())
                self:EmitSound("Arena.Lycan.HitQ2")
                LycanUtil.MakeBleed(self.hero, self.attacking)
            --end
        end

        self:Destroy()
        return
    end

    if self.attacking then
        if self:GetUnit():IsStunned() or self:GetUnit():IsRooted() then
            self.collisionType = COLLISION_TYPE_INFLICTOR
            self.attacking = false
        end

        return
    end

    local direction = self.target - self.start
    local normal = direction:Normalized()
    local currentPosition = self:GetPos() - self.start
    local projected = (currentPosition:Length2D() + 300) * normal

    local progress = projected:Length2D() / direction:Length2D() -- graph shifting
    local y = (progress * progress) * 100
    local offset = Vector(normal.y, -normal.x) * y * self.offsetModifier
    local result = self.target + projected + offset

    self.i = (self.i or 0) + 1

    if self.i % 5 == 0 and self.fearIsUsed == false then
        ExecuteOrderFromTable({ UnitIndex = self:GetUnit():GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, Position = result })
    end
end

function LycanWolf:FearBark()
    self.fearIsUsed = true
    local unit = self:GetUnit()

    ExecuteOrderFromTable({ UnitIndex = unit:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_STOP })
    StartAnimation(unit, { duration = 0.75, activity = ACT_DOTA_OVERRIDE_ABILITY_1, rate = 1.5 })
    FX("particles/units/heroes/hero_lycan/lycan_howl_cast.vpcf", PATTACH_ABSORIGIN, self, {
        cp0 = self:GetPos(),
        cp1 = self:GetPos() + self:GetFacing()
    })

    self.hero:AreaEffect({
        ability = self.ability,
        filter = Filters.Area(self:GetPos(), 350),
        onlyHeroes = true,
        modifier = { name = "modifier_lycan_e", ability = self.hero:FindAbility("lycan_e"), duration = 1.0 },
        action = function(target)
            if instanceof(target, Hero) then
                target:AddKnockbackSource(hero, 2.0)
            end
        end
    })
end