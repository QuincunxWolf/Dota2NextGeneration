--------------------------------------------------------------------------------------------------------
--		Ability: keen_commander_mortar_shot																
--------------------------------------------------------------------------------------------------------
if keen_commander_mortar_shot == nil then keen_commander_mortar_shot = class({}) end
--------------------------------------------------------------------------------------------------------
function keen_commander_mortar_shot:OnSpellStart()
	local hCaster = self:GetCaster()
	local vCursorPos = self:GetCursorPosition()
	local fFieldRadius = self:GetSpecialValueFor("field_radius")

	local tThinkers = Entities:FindAllByClassnameWithin("npc_dota_thinker", vCursorPos, fFieldRadius)
	local nReconBotCount = 0
	if #tThinkers > 0 then
		for i=1, #tThinkers do
			if tThinkers[i]:HasModifier("modifier_recon_systems_bot_aura") then
				local hBlazeAreaModifier = tThinkers[i]:FindModifierByNameAndCaster("modifier_recon_systems_bot_aura", self:GetCaster())
				-- table.insert(tReconBots)
				nReconBotCount = nReconBotCount + 1
			end
		end
	end
	local nMortarBurnStacksPerSecond = 1
	if nReconBotCount > 0 then
		nMortarBurnStacksPerSecond = nReconBotCount + 1
	end

	local fBlazeDuration = self:GetLevelSpecialValueFor("blaze_duration", self:GetLevel()-1)
	CreateModifierThinker(hCaster, self, "modifier_mortar_shot_aoe", { duration = fBlazeDuration, nStackAdditive = nMortarBurnStacksPerSecond }, vCursorPos, hCaster:GetTeamNumber(), false)
end

--------------------------------------------------------------------------------------------------------
--		Modifier: modifier_mortar_shot_aoe													
--------------------------------------------------------------------------------------------------------
if modifier_mortar_shot_aoe == nil then modifier_mortar_shot_aoe = class({}) end
----------------------------------------------------------------------------------------------------------
function modifier_mortar_shot_aoe:IsAura() return true end
----------------------------------------------------------------------------------------------------------
function modifier_mortar_shot_aoe:GetModifierAura()	return "modifier_mortar_shot_mortar_burn_field" end
----------------------------------------------------------------------------------------------------------
function modifier_mortar_shot_aoe:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
----------------------------------------------------------------------------------------------------------
function modifier_mortar_shot_aoe:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
----------------------------------------------------------------------------------------------------------
function modifier_mortar_shot_aoe:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("field_radius") end
----------------------------------------------------------------------------------------------------------
function modifier_mortar_shot_aoe:OnCreated(kv)
	if IsServer() then
		-- number of stacks to add if on blaze aoe
		self.nStackAdditive = kv.nStackAdditive		
	end
end

--------------------------------------------------------------------------------------------------------
--		Modifier: modifier_mortar_shot_mortar_burn_field										
--------------------------------------------------------------------------------------------------------
if modifier_mortar_shot_mortar_burn_field == nil then modifier_mortar_shot_mortar_burn_field = class({}) end
--------------------------------------------------------------------------------------------------------
function modifier_mortar_shot_mortar_burn_field:OnCreated(kv)
	if IsServer() then
		print("modifier_mortar_shot_mortar_burn_field:OnCreated")
		self.nStackAdditive = self:GetParent():FindModifierByNameAndCaster("modifier_mortar_shot_mortar_burn", self:GetCaster()).nStackAdditive
		self:StartIntervalThink(1)
	end
end
--------------------------------------------------------------------------------------------------------
function modifier_mortar_shot_mortar_burn_field:OnIntervalThink()
	if IsServer() then
		if not self:GetParent():HasModifier("modifier_mortar_shot_mortar_burn") then
			local fDebuffDuration = self:GetAbility():GetSpecialValueFor("debuff_duration")
			self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_mortar_shot_mortar_burn", { duration = fDebuffDuration })
		else
			local modifier = self:GetParent():FindModifierByNameAndCaster("modifier_mortar_shot_mortar_burn", self:GetCaster())
			modifier:SetStackCount(modifier:GetStackCount() + self.nStackAdditive )
		end
	end
end

--------------------------------------------------------------------------------------------------------
--		Modifier: modifier_mortar_shot_mortar_burn										
--------------------------------------------------------------------------------------------------------
if modifier_mortar_shot_mortar_burn == nil then modifier_mortar_shot_mortar_burn = class({}) end
--------------------------------------------------------------------------------------------------------
function modifier_mortar_shot_mortar_burn:OnCreated()
	if IsServer() then self:StartIntervalThink(1) end
end
--------------------------------------------------------------------------------------------------------
function modifier_mortar_shot_mortar_burn:OnIntervalThink()
	if IsServer() then
		local fBaseDPS = self:GetAbility():GetLevelSpecialValueFor("damage_per_second", self:GetAbility():GetLevel()-1)
		local nCurrentStacks = self:GetStackCount() 
		local fCurrentDPS = nCurrentStacks * fBaseDPS
		local damage_table = {victim = self:GetParent(), attacker = self:GetCaster(), damage_type = DAMAGE_TYPE_PHYSICAL, ability = self:GetAbility()}
		damage_table.damage = fCurrentDPS
		ApplyDamage({damage_table})
	end
end