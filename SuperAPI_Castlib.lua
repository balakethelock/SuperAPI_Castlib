SUPERAPI_SpellEvents = {}

-- catch all nameplates
local frames
local initialized = 0
local parentcount = 0

function SuperAPI_Castlib_Load()
	-- if client was not launched with the mod, shutdown
	if not SetAutoloot then
		this:SetScript("OnUpdate", nil)
		return
	end

	this:RegisterEvent("UNIT_CASTEVENT")
	this:SetScript("OnEvent", SuperAPI_Castlib_OnEvent)
end

function SuperAPI_Castlib_Update(elapsed)
	SuperAPI_SpellCastsUpdate(elapsed)
	SuperAPI_NameplateUpdateAll(elapsed)
end

function SuperAPI_Castlib_OnEvent()
	if (event == "UNIT_CASTEVENT") then
		--		if UnitIsUnit(arg1, "player") then return end
		if arg3 == "MAINHAND" or arg3 == "OFFHAND" then
			return
		end
		if arg3 == "CAST" then
			local currentCastInfo = SUPERAPI_SpellEvents[arg1]
			if not currentCastInfo or arg4 ~= currentCastInfo.spell then
				return
			end
		end
		arg5 = arg5 / 1000
		SUPERAPI_SpellEvents[arg1] = nil
		SUPERAPI_SpellEvents[arg1] = { target = arg2, spell = arg4, event = arg3, timer = arg5, start = GetTime() }

		if not SuperAPI_nameplatebars then
			SuperAPI_nameplatebars = true
		end
		-- If you want to disable this module's nameplate castbars, type in chat
		-- "   /run SuperAPI_nameplatebars = false  "
	end
end

function SuperAPI_SpellCastsUpdate(elapsed)
	for unit, castinfo in pairs(SUPERAPI_SpellEvents) do
		if castinfo.start + castinfo.timer + 1.5 < GetTime() then
			SUPERAPI_SpellEvents[unit] = nil
		elseif (castinfo.event == "CAST" or castinfo.event == "FAIL") and castinfo.start + castinfo.timer + 1 < GetTime() then
			SUPERAPI_SpellEvents[unit] = nil
		end
	end
end

function SuperAPI_NameplateCastbarInitialize(plate)
	plate.castbar = CreateFrame("StatusBar", "castbar", plate)
	plate.castbar:SetWidth(110)
	plate.castbar:SetHeight(8)
	plate.castbar:SetPoint("TOPLEFT", plate, "BOTTOMLEFT", 12, 0)
	plate.castbar:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	                            insets = { left = -1, right = -1, top = -1, bottom = -1 } })
	plate.castbar:SetBackdropColor(0, 0, 0, 1)
	plate.castbar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

	if plate.castbar.spark == nil then
		plate.castbar.spark = plate.castbar:CreateTexture(nil, "OVERLAY")
		plate.castbar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
		plate.castbar.spark:SetWidth(32)
		plate.castbar.spark:SetHeight(10)
		plate.castbar.spark:SetBlendMode("ADD")
	end

	if plate.castbar.text == nil then
		plate.castbar.text = plate.castbar:CreateFontString(nil, "HIGH", "GameFontWhite")
		plate.castbar.text:SetPoint("CENTER", plate.castbar, "CENTER", 0, 0)
		local font, size, opts = plate.castbar.text:GetFont()
		plate.castbar.text:SetFont(font, size - 4, "THINOUTLINE")
	end

	if plate.castbar.icon == nil then
		plate.castbar.icon = plate.castbar:CreateTexture(nil, "BORDER")
		plate.castbar.icon:ClearAllPoints()
		plate.castbar.icon:SetPoint("TOPRIGHT", plate.castbar, "TOPLEFT")
		plate.castbar.icon:SetWidth(12)
		plate.castbar.icon:SetHeight(12)
		plate.castbar.icon:Show()
	end
end

function SuperAPI_NameplateUpdateFrames()
	parentcount = WorldFrame:GetNumChildren()
	if initialized < parentcount then
		frames = { WorldFrame:GetChildren() }
		initialized = parentcount
	end
end

function SuperAPI_NameplateUpdateAll(elapsed)
	SuperAPI_NameplateUpdateFrames()

	for _, plate in ipairs(frames) do
		if plate then
			if plate:IsShown() and plate:IsObjectType("Button") then
				local unitGUID = plate:GetName(1)
				if plate.castbar == nil then
					SuperAPI_NameplateCastbarInitialize(plate)
				end
				local unitCastInfo = SUPERAPI_SpellEvents[unitGUID]
				if not unitCastInfo or not SuperAPI_nameplatebars then
					plate.castbar:Hide()
				else

					plate.castbar:Show()
					plate.castbar:SetMinMaxValues(unitCastInfo.start, unitCastInfo.start + unitCastInfo.timer)

					plate.castbar:SetValue(GetTime())
					local sparkPosition = min(max(plate.castbar:GetWidth() * (GetTime() - unitCastInfo.start) / unitCastInfo.timer, 0), plate.castbar:GetWidth())

					local spellname, _, spellicon = SpellInfo(unitCastInfo.spell)
					if not spellname then
						spellname = "UNKNOWN SPELL"
					end
					if not spellicon then
						spellicon = "Interface\\Icons\\INV_Misc_QuestionMark"
					end

					plate.castbar.text:SetText(spellname)
					plate.castbar.icon:SetTexture(spellicon)
					plate.castbar:SetAlpha(1 - GetTime() + unitCastInfo.start + unitCastInfo.timer)

					if unitCastInfo.event == "START" then
						plate.castbar:SetStatusBarColor(1.0, 0.7, 0.0)
						plate.castbar:SetMinMaxValues(unitCastInfo.start, unitCastInfo.start + unitCastInfo.timer)
					elseif unitCastInfo.event == "CAST" then
						plate.castbar:SetStatusBarColor(0.0, 1.0, 0.0)
						plate.castbar:SetMinMaxValues(unitCastInfo.start - 1, unitCastInfo.start)
					elseif unitCastInfo.event == "FAIL" then
						plate.castbar:SetStatusBarColor(1.0, 0.0, 0.0)
						plate.castbar.text:SetText("INTERRUPTED")
						plate.castbar:SetMinMaxValues(unitCastInfo.start - 1, unitCastInfo.start)
					elseif unitCastInfo.event == "CHANNEL" then
						plate.castbar:SetStatusBarColor(0.5, 0.7, 1.0)
						plate.castbar:SetMinMaxValues(unitCastInfo.start, unitCastInfo.start + unitCastInfo.timer)
						plate.castbar:SetValue(unitCastInfo.start + unitCastInfo.timer - GetTime() + unitCastInfo.start)
						sparkPosition = min(max(plate.castbar:GetWidth() * (unitCastInfo.start + unitCastInfo.timer - GetTime()) / unitCastInfo.timer, 0), plate.castbar:GetWidth())
						plate.castbar:SetAlpha(1 + unitCastInfo.start + unitCastInfo.timer - GetTime())
					end
					plate.castbar.spark:SetPoint("CENTER", plate.castbar, "LEFT", sparkPosition, 0);
				end
			end
		end
	end
end

function NameplateInterruptCast(unitGUID, spellname, spellicon)
	local frames = { WorldFrame:GetChildren() }
	for i, plate in ipairs(frames) do
		if plate then
			if plate:IsShown() and plate:IsObjectType("Button") then
				if plate:GetName(1) == unitGUID then
					if plate.castbar == nil then
						plate.castbar = CreateFrame("StatusBar", "castbar", plate)
						plate.castbar:SetWidth(110)
						plate.castbar:SetHeight(8)
						plate.castbar:SetPoint("TOPLEFT", plate, "BOTTOMLEFT", 12, 0)
						plate.castbar:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
						                            insets = { left = -1, right = -1, top = -1, bottom = -1 } })
						plate.castbar:SetBackdropColor(0, 0, 0, 1)
						plate.castbar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

						if plate.castbar.spark == nil then
							plate.castbar.spark = plate.castbar:CreateTexture(nil, "OVERLAY")
							plate.castbar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
							plate.castbar.spark:SetWidth(32)
							plate.castbar.spark:SetHeight(32)
							plate.castbar.spark:SetBlendMode("ADD")
						end

						if plate.castbar.text == nil then
							plate.castbar.text = plate.castbar:CreateFontString(nil, "HIGH", "GameFontWhite")
							plate.castbar.text:SetPoint("CENTER", plate.castbar, "CENTER", 0, 0)
							local font, size, opts = plate.castbar.text:GetFont()
							plate.castbar.text:SetFont(font, size - 4, "THINOUTLINE")
						end

						if plate.castbar.icon == nil then
							plate.castbar.icon = plate.castbar:CreateTexture(nil, "BORDER")
							plate.castbar.icon:ClearAllPoints()
							plate.castbar.icon:SetPoint("TOPRIGHT", plate.castbar, "TOPLEFT")
							plate.castbar.icon:SetWidth(12)
							plate.castbar.icon:SetHeight(12)
							plate.castbar.icon:Show()
						end
					end
					plate.castbar:Show()
					plate.castbar:SetStatusBarColor(1.0, 0.0, 0.0)
					plate.castbar:SetMinMaxValues(0, 1)
					plate.castbar:SetValue(1)
					plate.castbar:SetValue(GetTime())
					plate.castbar.text:SetText("INTERRUPTED")
					plate.castbar.icon:SetTexture(spellicon)
				end
			end
		end
	end
end

function NameplateCastbarEnd(this)
	this:SetValue(0)
	this:SetMinMaxValues(0, 1)
	this.text:SetText(" ")
	this.icon:SetTexture(nil)
	this:Hide()
end
