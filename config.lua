local frame = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
frame.name = "FascistGnome"
frame:Hide()

local L = LibStub("AceLocale-3.0"):GetLocale("FascistGnome")

local hint = nil
local addon = _G.FascistGnome
local function checkFunc(key, setting) addon.db[key] = setting == "1" and true or false end

local function newCheckbox(label, key, small)
	local check = CreateFrame("CheckButton", "FascistGnomeCheck" .. label, frame, small and "InterfaceOptionsSmallCheckButtonTemplate" or "InterfaceOptionsCheckButtonTemplate")
	check:SetChecked(addon.db[key])
	check.key = key
	check.setFunc = function(setting) checkFunc(check.key, setting) end
	_G[check:GetName() .. "Text"]:SetText(label)
	return check
end

local function unsaved(self)
	if self:GetText() == addon.db[self.key] then
		self:SetTextColor(1, 1, 1, 1)
		hint:Hide()
	else
		self:SetTextColor(1, 0, 0, 1)
		hint:Show()
	end
end
local function reset(self)
	self:SetText(addon.db[self.key])
	self:SetTextColor(1, 1, 1, 1)
	self:ClearFocus()
	hint:Hide()
end
local function save(self)
	self:SetTextColor(1, 1, 1, 1)
	addon.db[self.key] = self:GetText()
	self:HighlightText(0, 0)
	hint:Hide()
	self:ClearFocus()
end
local function newEditbox(label, key)
	local editbox = CreateFrame("EditBox", "FascistGnomeEdit"..label, frame, "InputBoxTemplate")
	editbox.key = key
	editbox:SetAutoFocus(false)
	editbox:ClearFocus()
	editbox:SetText(addon.db[key])
	editbox:SetScript("OnEnterPressed", save)
	editbox:SetScript("OnEditFocusLost", reset)
	editbox:SetScript("OnEscapePressed", reset)
	editbox:SetScript("OnTextChanged", unsaved)
	editbox:SetHeight(20)
	local l = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	l:SetJustifyH("LEFT")
	l:SetHeight(20)
	l:SetWidth(80)
	l:SetText(label)
	editbox:SetPoint("LEFT", l, "RIGHT")
	editbox:SetPoint("RIGHT", frame, "RIGHT", -32, 0)
	return l
end

frame:SetScript("OnShow", function(frame)
	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("FascistGnome")

	local subtitle = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetWidth(frame:GetWidth() - 40)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")
	subtitle:SetText(L["Thanks for believing in the FascistGnome philosophy. Join us in the crusade to purify the worlds population from anyone who thinks using the term 'nazi' in a ironic, light, and fun way is wrong! We shall overthrow them all and build a new empire where people are free to use such terms without fear of persecution."])

	local whisper = newCheckbox(L["Whisper reminders when a ready check is performed"], "whisperAtReadyCheck")
	whisper:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", -2, -12)

	local ifPromoted = newCheckbox(L["If you are promoted"], "whisperIfOfficer", true)
	ifPromoted:SetPoint("TOPLEFT", whisper, "BOTTOMLEFT", 10, 0)

	local ifLeader = newCheckbox(L["If you are the leader"], "whisperIfLeader", true)
	ifLeader:SetPoint("TOPLEFT", ifPromoted, "BOTTOMLEFT", 0, 0)

	whisper.dependentControls = { ifPromoted, ifLeader }

	local statusPrint = newCheckbox(L["Print local status reports"], "statusPrintAtReady")
	statusPrint:SetPoint("TOPLEFT", ifLeader, "BOTTOMLEFT", -10, -8)

	local party = newCheckbox(L["Party with the gnome"], "partyWithTheGnome")
	party:SetPoint("TOPLEFT", statusPrint, "BOTTOMLEFT", 0, -8)

	local flask = newEditbox(L["Flask whisper"], "flaskTell")
	flask:SetPoint("TOPLEFT", party, "BOTTOMLEFT", 4, -12)

	local food = newEditbox(L["Food whisper"], "foodTell")
	food:SetPoint("TOPLEFT", flask, "BOTTOMLEFT", 0, -8)

	local expire = newEditbox(L["Expire warning"], "expireTell")
	expire:SetPoint("TOPLEFT", food, "BOTTOMLEFT", 0, -8)

	hint = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	hint:SetPoint("TOPLEFT", expire, "BOTTOMLEFT", 0, -8)
	hint:SetWidth(frame:GetWidth() - 40)
	hint:SetJustifyH("CENTER")
	hint:SetText(L["|cff44ff44Press Enter to save or Escape to reset.|r"])
	hint:Hide()

	frame:SetScript("OnShow", nil)
end)
InterfaceOptions_AddCategory(frame)

