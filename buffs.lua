local L = LibStub("AceLocale-3.0"):GetLocale("FascistGnome")

local flaskIds = {
	-- Cataclysm
	92679, 94160, 79469, 79470, 79471, 79472,
	-- WotLK
	53760, 54212, 53758, 53755, 62380, 53752,
	-- TBC
	28521, 28518, 28519, 28540, 28520, 17629, 17627, 17628, 17626,
}
local flasks = nil
local function generateFlaskMap()
	flasks = {}
	for i, id in next, flaskIds do
		local n = GetSpellInfo(id)
		if n then flasks[n] = true end
	end
	flaskIds = nil
	generateFlaskMap = nil
end

local foods = {
	[(GetSpellInfo(44100))] = true,
	[(GetSpellInfo(19706))] = true,
}

local texture = nil

local hexColors = {}
for k, v in pairs(RAID_CLASS_COLORS) do
	hexColors[k] = "|cff" .. string.format("%02x%02x%02x", v.r * 255, v.g * 255, v.b * 255)
end
local coloredNames = setmetatable({}, {__index = function(self, key)
	local class = select(2, UnitClass(key))
	if not key or not hexColors[class] then return "|cffcccccc" .. tostring(key) .. "|r" end
	self[key] = hexColors[class]  .. key .. "|r"
	return self[key]
end})

local f = CreateFrame("Frame")

function f:ADDON_LOADED(msg)
	if msg:lower() ~= "fascistgnome" then return end
	_G.FascistGnomeDB = _G.FascistGnomeDB or {}
	self.db = _G.FascistGnomeDB
	for k, v in pairs({
		flaskTell = L["FascistGnome: Flask reminder!"],
		foodTell = L["FascistGnome: Well Fed reminder!"],
		expireTell = L["FascistGnome: Food/flask expires soon!"],
		whisperAtReadyCheck = true,
		whisperIfOfficer = true,
		whisperIfLeader = true,
		statusPrintAtReady = true,
		partyWithTheGnome = true,
	}) do
		if type(self.db[k]) == "nil" then
			self.db[k] = v
		end
	end

	local t = UIParent:CreateTexture("FascistGnomeSalute", "OVERLAY")
	t:SetTexture("Interface\\AddOns\\FascistGnome\\nazignome")
	t:SetHeight(256)
	t:SetWidth(256)
	t:SetPoint("CENTER", UIParent)
	t:SetAlpha(0)
	t:Hide()
	texture = t
	
	self:UnregisterEvent("ADDON_LOADED")
end

local function remind(player, tell)
	if ChatThrottleLib then
		ChatThrottleLib:SendChatMessage("BULK", "Nazi", tell, "WHISPER", nil, player, "FascistGnome")
	else
		SendChatMessage(tell, "WHISPER", nil, player)
	end
end

local nofood, noflask, recheck = {}, {}, {}
local function inspectUnit(unit, time)
	if not flasks then generateFlaskMap() end
	local flask, food = nil, nil
	for j = 1, 40 do
		local name, _, _, _, _, _, exp = UnitBuff(unit, j)
		if not name then break end
		local timeLeft = -1 * (time - exp) / 60
		if foods[name] then food = timeLeft end
		if flasks[name] then flask = timeLeft end
		if food and flask then break end
	end
	return flask, food
end
local function inspectRaid()
	local time = GetTime()
	for i = 1, GetNumRaidMembers() do
		local n = GetRaidRosterInfo(i)
		if n then
			local flask, food = inspectUnit(n, time)
			if not food then nofood[#nofood+1] = n end
			if not flask then noflask[#noflask+1] = n end
			if not food or not flask then recheck[#recheck+1] = n end
			if (food and food < 5) or (flask and flask < 5) then
				remind(n, f.db.expireTell)
			end
		end
	end
end

local function printStatusReport()
	if #nofood > 0 then
		print(L["Missing food: %s."]:format(table.concat(nofood, ", ")))
	end
	if #noflask > 0 then
		print(L["Missing flask: %s."]:format(table.concat(noflask, ", ")))
	end
end

function f:READY_CHECK_FINISHED()
	self:Hide()
	-- Because these can get spammed when you leave raid/group (and because we can call this function due to timeout)
	self:UnregisterEvent("READY_CHECK_FINISHED")

	if not self.db.statusPrintAtReady then return end
	wipe(nofood); wipe(noflask)
	local t = GetTime()
	for i, player in next, recheck do
		local flask, food = inspectUnit(player, t)
		if not food then nofood[#nofood+1] = coloredNames[player] end
		if not flask then noflask[#noflask+1] = coloredNames[player] end
	end
	wipe(recheck)
	printStatusReport()
end

local rcTimeout = 0
function f:READY_CHECK(sender, timeout)
	-- Track timeout locally because officers sometimes don't get the _FINISHED like they should. Yay.
	-- +1 because half the time we get given 29 instead of 30. Blizzard strikes again.
	rcTimeout = GetTime() + tonumber(timeout) + 1

	self:Show()

	self:RegisterEvent("READY_CHECK_FINISHED")

	wipe(nofood); wipe(noflask); wipe(recheck)
	inspectRaid()

	if self.db.whisperAtReadyCheck then
		if (self.db.whisperIfLeader and IsRaidLeader()) or
		   (self.db.whisperIfOfficer and UnitIsRaidOfficer("player")) or
		   (not self.db.whisperIfLeader and not self.db.whisperIfOfficer) then
			for i, player in next, noflask do
				remind(player, self.db.flaskTell)
			end
			for i, player in next, nofood do
				remind(player, self.db.foodTell)
			end
		end
	end
end

local total = 0
f:Hide()
f:SetScript("OnHide", function() UIFrameFlashStop(texture) end)
f:SetScript("OnUpdate", function(self, elapsed)
	if GetTime() > rcTimeout then
		self:READY_CHECK_FINISHED()
	end

	if total <= 0 and self.db.partyWithTheGnome then
		local rx = math.random(128, WorldFrame:GetWidth() - 128)
		local ry = math.random(128, WorldFrame:GetHeight() - 128)
		texture:SetPoint("CENTER", UIParent, "TOPLEFT", rx, -ry)
		UIFrameFlash(texture, 0.5, 0.5, 1.6, false, 0.2, 0.4)
		total = 1.7
	end
	total = total - elapsed
end)
f:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
f:RegisterEvent("READY_CHECK")
f:RegisterEvent("ADDON_LOADED")

local function filter(self, event, msg)
	if msg == f.db.foodTell or msg == f.db.flaskTell or msg == f.db.expireTell then return true end
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", filter)

_G.FascistGnome = f

