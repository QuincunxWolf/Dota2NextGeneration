--------------------------------------------------------------------------------------------------------
--		Ability: keen_commander_recon_systems																
--------------------------------------------------------------------------------------------------------
if keen_commander_recon_systems == nil then keen_commander_recon_systems = class({}) end
--------------------------------------------------------------------------------------------------------
function keen_commander_recon_systems:GetCastAnimation() return ACT_DOTA_CAST_ABILITY_1 end
--------------------------------------------------------------------------------------------------------
function keen_commander_recon_systems:OnSpellStart()
	local vCursorPos = self:GetCursorTarget():GetOrigin()
	local fBotDuration = self:GetSpecialValueFor("shock_bot_duration")
	CreateModifierThinker(self:GetCaster(), self, "modifier_recon_systems_bot_aura", { duration = fBotDuration }, vCursorPos, self:GetCaster():GetTeamNumber(), false)
end

--------------------------------------------------------------------------------------------------------
--		Modifier: modifier_recon_systems_bot_aura													
--------------------------------------------------------------------------------------------------------
if modifier_recon_systems_bot_aura == nil then modifier_recon_systems_bot_aura = class({}) end
--------------------------------------------------------------------------------------------------------
function modifier_recon_systems_bot_aura:RemoveOnDeath() return true end
--------------------------------------------------------------------------------------------------------
function modifier_recon_systems_bot_aura:IsAura() return true end
----------------------------------------------------------------------------------------------------------
function modifier_recon_systems_bot_aura:GetModifierAura()	return "modifier_recon_systems_bot_shock" end
----------------------------------------------------------------------------------------------------------
function modifier_recon_systems_bot_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
----------------------------------------------------------------------------------------------------------
function modifier_recon_systems_bot_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
----------------------------------------------------------------------------------------------------------
function modifier_recon_systems_bot_aura:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("shock_range") end
----------------------------------------------------------------------------------------------------------
function modifier_recon_systems_bot_aura:GetAuraEntityReject( hEntity )
	if IsServer() then	
		if hEntity:HasModifier("modifier_recon_systems_shock_nulled") then 
			return true 
		end
	end
	return false
end
----------------------------------------------------------------------------------------------------------
function modifier_recon_systems_bot_aura:OnCreated(kv)
	if IsServer() then	
		local fBotRadius = self:GetAbility():GetSpecialValueFor("shock_range")		
		self:StartIntervalThink(1/30)
	end
end
--------------------------------------------------------------------------------------------------------
function modifier_recon_systems_bot_aura:OnIntervalThink()
	if IsServer() then
		local tTrees = GridNav:GetAllTreesAroundPoint(self:GetParent():GetOrigin(), 10, false)
		if #tTrees < 1 then self:Destroy() end

		local fBotRadius = self:GetAbility():GetSpecialValueFor("shock_range")
		local tEnemyUnits = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetParent():GetOrigin(), nil, fBotRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 2, false)
		
		local vParentOrigin = self:GetParent():GetOrigin()
		vParentOrigin.z = 100
		DebugDrawSphere( vParentOrigin, Vector(0,255,0), 255, 50, true, 1/30)



		DebugDrawCircle(self:GetParent():GetOrigin(), Vector(255,255,0), 1, fBotRadius, false, 1/30)

		if #tEnemyUnits > 0 then
			for i=1, #tEnemyUnits do
				tEnemyUnits[i]:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_recon_systems_heat_signature", {})
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------
--		Modifier: modifier_recon_systems_heat_signature													
--------------------------------------------------------------------------------------------------------
if modifier_recon_systems_heat_signature == nil then modifier_recon_systems_heat_signature = class({}) end
--------------------------------------------------------------------------------------------------------
function modifier_recon_systems_heat_signature:IsHidden() return true end
--------------------------------------------------------------------------------------------------------
function modifier_recon_systems_heat_signature:DeclareFunctions() return { MODIFIER_PROPERTY_PROVIDES_FOW_POSITION, MODIFIER_PROPERTY_FORCE_DRAW_MINIMAP } end
--------------------------------------------------------------------------------------------------------
function modifier_recon_systems_heat_signature:GetModifierProvidesFOWVision() return 1 end
--------------------------------------------------------------------------------------------------------
function modifier_recon_systems_heat_signature:GetForceDrawOnMinimap() return 1 end
--------------------------------------------------------------------------------------------------------
function modifier_recon_systems_heat_signature:OnCreated()
	if IsServer() then
		DebugDrawSphere(self:GetParent():GetOrigin(), Vector(255,255,255), 1, self:GetParent():GetHullRadius(), false, 1/30) 
		self:SetDuration(1/30, false) 
	end
end

--------------------------------------------------------------------------------------------------------
--		Modifier: modifier_recon_systems_shock_nulled													
--------------------------------------------------------------------------------------------------------
if modifier_recon_systems_shock_nulled == nil then modifier_recon_systems_shock_nulled = class({}) end
--------------------------------------------------------------------------------------------------------
function modifier_recon_systems_shock_nulled:GetTexture() return "hero_keen_commander/keen_commander_recon_systems_null" end
--------------------------------------------------------------------------------------------------------
function modifier_recon_systems_shock_nulled:OnCreated()
	if IsServer() then
		local fNullDuration = self:GetAbility():GetSpecialValueFor("shock_null_duration")
		self:SetDuration( fNullDuration, true )
	end
end

--------------------------------------------------------------------------------------------------------
--		Modifier: modifier_recon_systems_bot_shock													
--------------------------------------------------------------------------------------------------------
if modifier_recon_systems_bot_shock == nil then modifier_recon_systems_bot_shock = class({}) end
--------------------------------------------------------------------------------------------------------
function modifier_recon_systems_bot_shock:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
--------------------------------------------------------------------------------------------------------
function modifier_recon_systems_bot_shock:GetModifierMoveSpeedBonus_Percentage() return -(self:GetAbility():GetSpecialValueFor("movespeed_slow_percentage")) end
--------------------------------------------------------------------------------------------------------
function modifier_recon_systems_bot_shock:OnCreated()
	if IsServer() then
		local fShockDamage = self:GetAbility():GetLevelSpecialValueFor("shock_damage", self:GetAbility():GetLevel()-1)
		local fSlowDuration = self:GetAbility():GetLevelSpecialValueFor("slow_duration", self:GetAbility():GetLevel()-1)	
		self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_recon_systems_shock_nulled", {})
		ApplyDamage({
			victim = self:GetParent(),
			attacker = self:GetCaster(),
			damage = self:GetAbility():GetLevelSpecialValueFor("shock_damage", self:GetAbility():GetLevel()-1),
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self:GetAbility()
			})
		self:SetDuration(fSlowDuration, true)
	end
end

