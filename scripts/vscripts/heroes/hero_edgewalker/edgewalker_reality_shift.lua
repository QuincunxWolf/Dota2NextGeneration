--------------------------------------------------------------------------------------------------------
--	edgewalker_reality_shift
--------------------------------------------------------------------------------------------------------
if edgewalker_reality_shift == nil then edgewalker_reality_shift = class({}) end

function edgewalker_reality_shift:GetCastAnimation() return ACT_DOTA_CAST_ABILITY_4 end

function edgewalker_reality_shift:OnSpellStart()
	local hCaster = self:GetCaster()
	local fWardLifetime = self:GetSpecialValueFor("ward_duration")
	local nWardCount = 1

	if hCaster:HasModifier("modifier_item_ultimate_scepter") then
		nWardCount = 2
	end

	for i=1, nWardCount do
		local hWard = CreateUnitByName("npc_reality_shift_ward", self:GetCursorPosition(), false, nil, hCaster, hCaster:GetTeamNumber())
		hWard:SetControllableByPlayer(hCaster:GetPlayerID(), false)
		hWard:AddNewModifier(hCaster, self, "modifier_reality_shift_ward_aura", { duration = fWardLifetime })
	end
end

--------------------------------------------------------------------------------------------------------
--	modifier_reality_shift_ward_aura
--------------------------------------------------------------------------------------------------------
if modifier_reality_shift_ward_aura == nil then modifier_reality_shift_ward_aura = ({}) end

function modifier_reality_shift_ward_aura:CheckState() return { [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true } end

function modifier_reality_shift_ward_aura:IsAura() return true end

function modifier_reality_shift_ward_aura:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("aura_range") end

function modifier_reality_shift_ward_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_BOTH end

function modifier_reality_shift_ward_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end

function modifier_reality_shift_ward_aura:GetAuraEntityReject(hEntity)
	if IsServer() then
		if hEntity:GetUnitName() == "npc_reality_shift_ward" then return true end
	end
	return false
end

function modifier_reality_shift_ward_aura:GetModifierAura() return "modifier_reality_shift_ward_effect" end

function modifier_reality_shift_ward_aura:OnCreated()
	if IsServer() then
		-- gravity well
		local hCaster = self:GetCaster()
		local hEdgeWalkerAbility = hCaster:FindAbilityByName("edgewalker_gravity_well")
		if hEdgeWalkerAbility and hEdgeWalkerAbility:GetLevel() > 0 then
			CreateModifierThinker(hCaster, hEdgeWalkerAbility, "modifier_gravity_well_pull", { location = self:GetParent():GetOrigin() }, self:GetParent():GetOrigin(), hCaster:GetTeamNumber(), false )
		end
		-- portal
		self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_cascade_event_portal", {})
		-- particle
		local fAuraRadius = self:GetAbility():GetSpecialValueFor("aura_range")
		self.nAuraFX = ParticleManager:CreateParticle("particles/heroes/hero_edgewalker/reality_shift_aura.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControl(self.nAuraFX, 1, Vector(fAuraRadius,0,0))
	end
end

function modifier_reality_shift_ward_aura:OnDestroy()
	if IsServer() then
		-- particle destroy
		ParticleManager:DestroyParticle(self.nAuraFX, false)
		ParticleManager:ReleaseParticleIndex(self.nAuraFX)

		self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_reality_shift_ward_explosion", {})

		-- gravity well
		local hCaster = self:GetCaster()
		local hEdgeWalkerAbility = hCaster:FindAbilityByName("edgewalker_gravity_well")
		if hEdgeWalkerAbility and hEdgeWalkerAbility:GetLevel() > 0 then
			CreateModifierThinker(hCaster, hEdgeWalkerAbility, "modifier_gravity_well_pull", { location = self:GetParent():GetOrigin() }, self:GetParent():GetOrigin(), hCaster:GetTeamNumber(), false )
		end
		self:GetParent():ForceKill(false)
	end
end

--------------------------------------------------------------------------------------------------------
--	modifier_reality_shift_ward_effect
--------------------------------------------------------------------------------------------------------
if modifier_reality_shift_ward_effect == nil then modifier_reality_shift_ward_effect = ({}) end

function modifier_reality_shift_ward_effect:GetStatusEffectName()
	return "particles/status_fx/status_effect_wraithking_ghosts.vpcf"
end

function modifier_reality_shift_ward_effect:OnCreated()
	if IsServer() then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("stickiness"), true)
	end
end

function modifier_reality_shift_ward_effect:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DECREPIFY_UNIQUE } end

function modifier_reality_shift_ward_effect:CheckState()
	if IsServer then
		if self:GetParent() == self:GetCaster() then return { [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true } end
		return { [MODIFIER_STATE_DISARMED] = true }
	end
end

function modifier_reality_shift_ward_effect:GetModifierMoveSpeedBonus_Percentage(params) 
	if IsServer() then
		if self:GetParent() == self:GetCaster() then
			return self:GetAbility():GetLevelSpecialValueFor("parent_buff_value", self:GetAbility():GetLevel()-1)
		end
	end
	return self:GetAbility():GetSpecialValueFor("debuff_value")
end

function modifier_reality_shift_ward_effect:GetModifierMagicalResistanceDecrepifyUnique(params)
	if IsServer() then
		-- local fParentMagicRes = self:GetParent():GetMagicalArmorValue()
		-- print("fParentMagicRes: ", fParentMagicRes)
		-- local fBonusResPercentage = 0
		-- if self:GetParent() == self:GetCaster() then
		-- 	fBonusResPercentage = self:GetAbility():GetLevelSpecialValueFor("parent_buff_value", self:GetAbility():GetLevel()-1)
		-- else
		-- 	fBonusResPercentage = self:GetAbility():GetSpecialValueFor("debuff_value")			
		-- end
		-- print("fBonusResPercentage: ", fBonusResPercentage)
		-- if fBonusResPercentage ~= 0 then

		-- return fParentMagicRes * fBonusResPercentage/100
		-- end
		if self:GetParent() == self:GetCaster() then
			return self:GetAbility():GetLevelSpecialValueFor("parent_buff_value", self:GetAbility():GetLevel()-1)
		else
			return self:GetAbility():GetSpecialValueFor("debuff_value")			
		end	
	end
	return 0
end

--------------------------------------------------------------------------------------------------------
--	modifier_reality_shift_ward_explosion
--------------------------------------------------------------------------------------------------------
if modifier_reality_shift_ward_explosion == nil then modifier_reality_shift_ward_explosion = ({}) end

function modifier_reality_shift_ward_explosion:OnCreated(kv)
	if IsServer() then
		local hCaster = self:GetCaster()
		local fExplosionRadius = self:GetAbility():GetSpecialValueFor("aura_range")
		local tUnits = FindUnitsInRadius(hCaster:GetTeamNumber(), self:GetParent():GetOrigin(), nil, fExplosionRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
		if #tUnits > 0 then
			for i=1, #tUnits do
				tUnits[i]:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_rooted", { duration = self:GetAbility():GetSpecialValueFor("root_duration")})
				ApplyDamage({
					victim = tUnits[i],
					attacker = self:GetCaster(),
					ability = self:GetAbility(),
					damage_type = DAMAGE_TYPE_MAGICAL,
					damage = self:GetAbility():GetLevelSpecialValueFor("explosion_damage", self:GetAbility():GetLevel()-1)
					})
			end
		end

		--particle explosion
		local nFX = ParticleManager:CreateParticle("particles/heroes/hero_edgewalker/reality_shift_ward_explosion.vpcf", PATTACH_ABSORIGIN, self:GetParent())
		ParticleManager:SetParticleControl(nFX, 1, self:GetParent():GetOrigin())
		ParticleManager:SetParticleControl(nFX, 3, Vector(fExplosionRadius,0,0))
	end
end