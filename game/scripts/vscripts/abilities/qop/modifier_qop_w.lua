modifier_qop_w = class({})
self = modifier_qop_w
self.itsTimeToStop = 0

if IsServer() then
    function modifier_qop_w:OnCreated()
        self:GetParent():Interrupt()
        self:StartIntervalThink(0.1)
        self:OnIntervalThink()
    end

    function modifier_qop_w:OnIntervalThink()
        if self.itsTimeToStop >= 3 then
            self:Destroy()
        end
        self:GetParent():MoveToNPC(self:GetCaster())
    end

    function modifier_qop_w:OnDestroy()
        self:GetParent():Interrupt()
    end
end

function modifier_qop_w:OnDamageReceived(source, hero, amount)
    self.itsTimeToStop = self.itsTimeToStop + amount
    return amount
end

function modifier_qop_w:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end

function modifier_qop_w:GetEffectName()
    return "particles/qop_w/qop_w_overhead.vpcf"
end
 
function modifier_qop_w:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end
 
function modifier_qop_w:CheckState()
    local state = {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    }
 
    return state
end

function modifier_qop_w:GetModifierMoveSpeedBonus_Percentage(params)
    return -20
end