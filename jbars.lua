local NAME, _ = ...

local DEFAULTS = {
	desaturate = true,
	hideborder = true,
}

local function setup_options(
	f
)
	f.panel = CreateFrame('Frame')
	f.panel.name = NAME

	local cb = CreateFrame("CheckButton", nil, f.panel, "InterfaceOptionsCheckButtonTemplate")
	cb:SetPoint("TOPLEFT", 20, -20)
	cb.Text:SetText("Desaturate")
	cb:HookScript("OnClick", function(_, btn, down)
		jbarsDB.desaturate = cb:GetChecked()
	end)
	cb:SetChecked(jbarsDB.desaturate)

	local hb = CreateFrame("CheckButton", nil, f.panel, "InterfaceOptionsCheckButtonTemplate")
	hb:SetPoint("TOPLEFT", 20, -60)
	hb.Text:SetText("Hide Border")
	hb:HookScript("OnClick", function(_, btn, down)
		jbarsDB.hideborder = hb:GetChecked()
	end)
	hb:SetChecked(jbarsDB.hideborder)

	local cat = Settings.RegisterCanvasLayoutCategory(f.panel, f.panel.name, f.panel.name);
	cat.ID = f.panel.name
	Settings.RegisterAddOnCategory(cat)
end

local desaturation_curve = C_CurveUtil.CreateCurve()
desaturation_curve:SetType(Enum.LuaCurveType.Step)
desaturation_curve:AddPoint(0, 0)
desaturation_curve:AddPoint(0.001, 1)

local alpha_curve = C_CurveUtil.CreateCurve()
alpha_curve:SetType(Enum.LuaCurveType.Step)
alpha_curve:AddPoint(0, 1)
alpha_curve:AddPoint(0.001, 0.5)

local function on_cooldown_desaturate(
	button
)
	local duration

	local cooldown = C_ActionBar.GetActionCooldown(button.action)
	if cooldown and not cooldown.isOnGCD then
		duration = C_ActionBar.GetActionCooldownDuration(button.action)
	end

	if duration then
		button.icon:SetDesaturation(duration:EvaluateRemainingDuration(desaturation_curve))
		button:SetAlpha(duration:EvaluateRemainingDuration(alpha_curve))
	else
		button.icon:SetDesaturation(0)
		button:SetAlpha(1)
	end
end

local function setup_desaturation(
	button
)
	hooksecurefunc(button, 'UpdateAction', on_cooldown_desaturate)
	button.cooldown:HookScript('OnCooldownDone', GenerateClosure(on_cooldown_desaturate, button))
	EventRegistry:RegisterFrameEventAndCallback('SPELL_UPDATE_COOLDOWN', GenerateClosure(on_cooldown_desaturate, button))
end

local function hide_self(
	self
)
	self:Hide()
end

local function setup_hideborder(
	button
)
	button.cooldown:SetAllPoints(button)
	for _, e in next, {
		button.IconMask,
		button.Border,
		button.HighlightTexture,
		button.CheckedTexture,
		button.SpellHighlightTexture,
		button.NewActionTexture,
		button.PushedTexture,
		button.SlotBackground,
		button.NormalTexture,
		button.SpellCastAnimFrame
	} do
		e:SetAlpha(0)
		e:Hide()
		e:HookScript('OnShow', function(self) self:Hide() end)
	end
end

local function setup_button(
	button,
	desaturate,
	hideborder
)
	if desaturate then
		setup_desaturation(button)
	end
	if hideborder then
		setup_hideborder(button)
	end
end

local function setup_bar(
	bar,
	buttons,
	desaturate,
	hideborder
)
	for i = 1, buttons do
		button = _G[bar .. i]
		if button ~= nil then
			setup_button(button, desaturate, hideborder)
		end
	end
end

local function setup_bars(
	desaturate,
	hideborder
)
	for bar, buttons in next, {
		ActionButton = 12,
  		MultiBarBottomLeftButton = 12,
  		MultiBarBottomRightButton = 12,
  		MultiBarLeftButton = 12,
  		MultiBarRightButton = 12,
  		MultiBar5Button = 12,
  		MultiBar6Button = 12,
  		MultiBar7Button = 12,
	} do
		setup_bar(bar, buttons, desaturate, hideborder)
	end
end

local function on_event(
	frame,
	event,
	name
)
	if name ~= NAME or event ~= 'ADDON_LOADED' then
		return
	end
	jbarsDB = jbarsDB or CopyTable(DEFAULTS)
	setup_options(frame)
	setup_bars(
		jbarsDB.desaturate,
		jbarsDB.hideborder
	)
end

local F = CreateFrame("Frame")
F:RegisterEvent('ADDON_LOADED')
F:SetScript("OnEvent", on_event)
