-- LinkWrangler

-- Author: brykrys
-- Original Author: Fallan/Jenavive
-- Code Credits / Other authors: Legorol, Amavana
-- Suggestions:  DwFMagik, dreamtgm, Crusadebank

-------------------------------------------------------------------------------------------
-- VARIABLES
-------------------------------------------------------------------------------------------

local GetAddOnMetadata = C_AddOns.GetAddOnMetadata
local LWVersion = tonumber(GetAddOnMetadata("LinkWrangler", "Version"))
local LWVersionInfo = GetAddOnMetadata("LinkWrangler", "X-Release") or "Unknown"
local LWSessionMode -- set at load time, then can only be changed by reloadui

-- Control variables
local LWDebugEnable = LWVersionInfo:lower() ~= "release"
local LWMasterEnable = true
local LWIsClassic = WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE
-- Flag for new Tooltip API introduced in WoW 10.0.2 {15/11/22}
local LWIsNewTooltips = (C_TooltipInfo and TooltipUtil and TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall) and true or false
local LWIsGameActive = false

-- Global table for exports
LinkWrangler = {
	Version = LWVersion,
	VersionInfo = LWVersionInfo,
	Startup = {EarlyLoadAddOns = {}}
}

-- Utility function variables
local LWStoredValueTable = {}

-- Variables for ItemRef hook
local LWOriginalSetItemRef, LWOriginalIRTSetHyperlink

-- Internal jump tables
local LWQuickActionJump = {}
local LWSlashJump = {}
local LWButtonClickJump = {}

-- Local references to external data tables
-- Placeholders for local refs to LinkWranglerLocal and subtables
local LWL, LWA, LWM, LWS
-- Placeholders for subtables of LinkWranglerSaved
local LWSConfig, LWSClick, LWSButtons, LWSLayout, LWSAddOns, LWSLinkTypes, LWSSpacing

-- Data tables for status of tooltip and compare windows
local LWTooltipData = {} -- central access for tooltip data
local LWTooltipDataCount = 0 -- current number of tooltip frames
local LWCompareData = {} -- central access for compare tooltip data
local LWCompareDataCount = 0 -- current number of compare frames

-- Table storing details of callback functions from other addons
local LWCallbackData = {
	enable = {},
	enablecomp = {},
	list = {},
	refresh = {},
	}
-- Callback Types are codes to tell the RegisterCallback function what to do
-- As this is still in development, codes may be changed at a later date
local LWCallbackType = {
	refresh = 1, redirect = 1,
	show = 2, hide = 2, showcomp = 2, hidecomp = 2, refreshcomp = 2, maximize = 2, minimize = 2,
	item = 3, spell = 3, enchant = 3, achievement = 3, talent = 3, quest = 3, glyph = 3,
	allocate = 4, allocatecomp = 5,
	destroy = 0, destroycomp = 0, scan = 0,
	gameactive = 10,
	}

-- Timer: variables & constants
local LWTimerFrame
local LWTimerRunning
local LWTimerTimeoutList = {} -- table to hold partially-loaded windows
local LWTimerTimeoutElapsed = 0
local LWTimerResizeList = {} -- frames that need resize on next update
local LWTimerRefreshList = {} -- frames that need refresh event on next update
local LWTimerReloadList = {} -- frames that need to be redrawn; change detected after last refresh
local LWTimerReloadElapsed = 0

-- Whisper button: buffer tables for storing chat lines and names
local LWChatBufferTextList = {}
local LWChatBufferNameList = {}
local LWChatBufferIndex = 1	-- index of next message to be stored
local LWChatBufferStored = 0	-- number of messages actually stored
local LWCHATBUFFERMAX = 32

-- Compare button: inventory hook-flag and data
local LWInventoryHooked = false
local LWInventorySlotTable, LWInventorySlotLocalTable
do -- closed scope for 'g'
	local g = GetInventorySlotInfo
	if LWIsClassic then
		LWInventorySlotTable = {
			INVTYPE_2HWEAPON		= {[1] = g"MAINHANDSLOT", [2] = g"SECONDARYHANDSLOT"},
			INVTYPE_BODY			= {[1] = g"SHIRTSLOT"},
			INVTYPE_CHEST			= {[1] = g"CHESTSLOT"},
			INVTYPE_CLOAK			= {[1] = g"BACKSLOT"},
			INVTYPE_FEET			= {[1] = g"FEETSLOT"},
			INVTYPE_FINGER			= {[1] = g"FINGER0SLOT", [2] = g"FINGER1SLOT"},
			INVTYPE_HAND			= {[1] = g"HANDSSLOT"},
			INVTYPE_HEAD			= {[1] = g"HEADSLOT"},
			INVTYPE_HOLDABLE		= {[1] = g"SECONDARYHANDSLOT"},
			INVTYPE_LEGS			= {[1] = g"LEGSSLOT"},
			INVTYPE_NECK			= {[1] = g"NECKSLOT"},
			INVTYPE_ROBE			= {[1] = g"CHESTSLOT"},
			INVTYPE_SHIELD			= {[1] = g"SECONDARYHANDSLOT"},
			INVTYPE_SHOULDER		= {[1] = g"SHOULDERSLOT"},
			INVTYPE_TABARD			= {[1] = g"TABARDSLOT"},
			INVTYPE_TRINKET			= {[1] = g"TRINKET0SLOT", [2] = g"TRINKET1SLOT"},
			INVTYPE_WAIST			= {[1] = g"WAISTSLOT"},
			INVTYPE_WEAPON			= {[1] = g"MAINHANDSLOT", [2] = g"SECONDARYHANDSLOT"},
			INVTYPE_WEAPONMAINHAND	= {[1] = g"MAINHANDSLOT"},
			INVTYPE_WEAPONOFFHAND	= {[1] = g"SECONDARYHANDSLOT"},
			INVTYPE_WRIST			= {[1] = g"WRISTSLOT"},
			INVTYPE_RANGED			= {[1] = g"RANGEDSLOT"},
			INVTYPE_RANGEDRIGHT		= {[1] = g"RANGEDSLOT"},
			INVTYPE_THROWN			= {[1] = g"RANGEDSLOT"},
			INVTYPE_RELIC			= {[1] = g"RANGEDSLOT"},
			INVTYPE_AMMO			= {[1] = g"AMMOSLOT"},
		}
	else -- Retail
		LWInventorySlotTable = {
			INVTYPE_2HWEAPON		= {[1] = g"MAINHANDSLOT", [2] = g"SECONDARYHANDSLOT"},
			INVTYPE_BODY			= {[1] = g"SHIRTSLOT"},
			INVTYPE_CHEST			= {[1] = g"CHESTSLOT"},
			INVTYPE_CLOAK			= {[1] = g"BACKSLOT"},
			INVTYPE_FEET			= {[1] = g"FEETSLOT"},
			INVTYPE_FINGER			= {[1] = g"FINGER0SLOT", [2] = g"FINGER1SLOT"},
			INVTYPE_HAND			= {[1] = g"HANDSSLOT"},
			INVTYPE_HEAD			= {[1] = g"HEADSLOT"},
			INVTYPE_HOLDABLE		= {[1] = g"SECONDARYHANDSLOT"},
			INVTYPE_LEGS			= {[1] = g"LEGSSLOT"},
			INVTYPE_NECK			= {[1] = g"NECKSLOT"},
			INVTYPE_ROBE			= {[1] = g"CHESTSLOT"},
			INVTYPE_SHIELD			= {[1] = g"SECONDARYHANDSLOT"},
			INVTYPE_SHOULDER		= {[1] = g"SHOULDERSLOT"},
			INVTYPE_TABARD			= {[1] = g"TABARDSLOT"},
			INVTYPE_TRINKET			= {[1] = g"TRINKET0SLOT", [2] = g"TRINKET1SLOT"},
			INVTYPE_WAIST			= {[1] = g"WAISTSLOT"},
			INVTYPE_WEAPON			= {[1] = g"MAINHANDSLOT", [2] = g"SECONDARYHANDSLOT"},
			INVTYPE_WEAPONMAINHAND	= {[1] = g"MAINHANDSLOT"},
			INVTYPE_WEAPONOFFHAND	= {[1] = g"SECONDARYHANDSLOT"},
			INVTYPE_WRIST			= {[1] = g"WRISTSLOT"},
			INVTYPE_RANGED			= {[1] = g"MAINHANDSLOT", [2] = g"SECONDARYHANDSLOT"},
			INVTYPE_RANGEDRIGHT		= {[1] = g"MAINHANDSLOT"},
		}
	end

	-- Build second lookup table for scraping tooltips
	-- Note that not all valid EquipLoc codes exist as Globals
	LWInventorySlotLocalTable = {}
	for k, v in pairs(LWInventorySlotTable) do
		local j = _G[k]
		if j then
			LWInventorySlotLocalTable[j] = v
		end
	end
end

-- Colour values for Print functions
local LWRED, LWGREEN, LWBLUE = 0.8, 0.3, 0.9

-- local references to global functions
local pairs, ipairs, next = pairs, ipairs, next
local wipe = wipe
local floor = floor
local type, tonumber, tostring = type, tonumber, tostring
local bitand, bitor = bit.band, bit.bor
local format, strlower = format, strlower
local strfind, strmatch = strfind, strmatch
local pcall = pcall
local _G = _G

-- functions renamed by various patches
local GetItemInfo = C_Item.GetItemInfo or GetItemInfo
local IsEquippableItem = C_Item.IsEquippableItem or IsEquippableItem
local IsDressableItem = C_Item.IsDressableItemByID or IsDressableItem
local GetItemStatDelta = C_Item.GetItemStatDelta or GetItemStatDelta
local GetSpellLink = C_Spell.GetSpellLink or GetSpellLink

local GetDisplayedItem, GetDisplayedSpell
if TooltipUtil then
	-- These are replacements for tooltip:GetItem and tooltip:GetSpell in 10.0.2
	GetDisplayedItem = TooltipUtil.GetDisplayedItem
	GetDisplayedSpell = TooltipUtil.GetDisplayedSpell
else
	GetDisplayedItem = function(tooltip) return tooltip:GetItem() end
	GetDisplayedSpell = function(tooltip) return tooltip:GetSpell() end
end

-------------------------------------------------------------------------------------------
-- INTERNAL UTILITY FUNCTIONS
-------------------------------------------------------------------------------------------

local function LWPrintDebug(msg)
	if LWDebugEnable then
		DEFAULT_CHAT_FRAME:AddMessage("LWDebug: "..msg, LWRED, LWGREEN, LWBLUE)
	end
end

--[
-- !ilogger support
local ilogger = LibStub and LibStub:GetLibrary("!ilogger", true)
local LWLogDebug
if ilogger then
	LWLogDebug = function(msg)
		if LWDebugEnable then ilogger.NewLine("LW:"..msg) end
	end
else
	LWLogDebug = function() end
end
--]]

local function LWPrint(msg, noHeader, noVerbose)
	if noVerbose and not LWSConfig.verbose then
		return
	end
	if not noHeader then
		msg = "LinkWrangler: "..msg
	end
	DEFAULT_CHAT_FRAME:AddMessage(msg, LWRED, LWGREEN, LWBLUE)
end

local function LWReportError(msg, level)
	if LWDebugEnable then
		if not level then
			level = 2
		elseif level > 0 then
			level = level + 1
		end
		error (msg, level)
	else
		LWPrint("LinkWrangler Error: "..msg, true, true)
	end
	return nil, msg
end

local function LWBoolStr(option)
	return option and LWM.Enabled or LWM.Disabled
end

local function LWGetValueTable()
	wipe(LWStoredValueTable)
	return LWStoredValueTable
end

-------------------------------------------------------------------------------------------
-- SAVED VARIABLE DEFAULTS AND CHECKS
-------------------------------------------------------------------------------------------

local function LWGetDefaultClickTable()
	return {
		action = "open",
		shift = "bypass",
		ctrl = "bypass",
		alt = "bypass",
	}
end

local function LWGetDefaultSaveTable()
	return {
		Version = LWVersion,
		Config = {
			verbose = true,
			savelayout = true,
			scale = 1,
			mode = "advanced",
			comparestats = true,
		},
		Click = {
			LeftButton = LWGetDefaultClickTable(),
			RightButton = LWGetDefaultClickTable(),
			MiddleButton = LWGetDefaultClickTable(),
		},
		Buttons = {
			close = true,
			minimize = true,
			compare = true,
			whisper = true,
			relink = true,
			dressup = true,
			capture = true,
		},
		AddOns = {},
		Layout = {},
		LinkTypes = {
			item = true,
			spell = true,
			enchant = true,
			quest = true,
			achievement = true,
			talent = true,
			glyph = true,
		},
		Spacing = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0,
		},
	}
end

LinkWrangler.SyncLocal = function()
	if LinkWranglerSaved then
		LWSConfig = LinkWranglerSaved.Config
		LWSClick = LinkWranglerSaved.Click
		LWSButtons = LinkWranglerSaved.Buttons
		LWSLayout = LinkWranglerSaved.Layout
		LWSAddOns = LinkWranglerSaved.AddOns
		LWSLinkTypes = LinkWranglerSaved.LinkTypes
		LWSSpacing = LinkWranglerSaved.Spacing
	end
	if LinkWranglerLocal then
		LWL = LinkWranglerLocal
		LWA = LinkWranglerLocal.Alias
		LWM = LinkWranglerLocal.Message
		LWS = LinkWranglerLocal.Slash
	end
end

LinkWrangler.Startup.CheckSavedVariables = function()
	if type(LinkWranglerSaved) ~= "table" then
		-- First time use
		LinkWranglerSaved = LWGetDefaultSaveTable()
		return "SavedVarsDefault"
	elseif LinkWranglerSaved.Version ~= LWVersion then
		-- Generate new saved variables table and copy in valid values from old table
		-- This only happens when the version changes
		local newsaved = LWGetDefaultSaveTable()
		local newtable, oldtable
		-- Config
		oldtable = LinkWranglerSaved.Config
		if type(oldtable) == "table" then
			newtable = newsaved.Config
			for option, value in pairs(newtable) do
				if type(oldtable[option]) == type(value) then
					newtable[option] = oldtable[option]
				end
			end
		end
		-- Click
		oldtable = LinkWranglerSaved.Click
		if type(oldtable) == "table" then
			newtable = newsaved.Click
			for button, newsub in pairs(newtable) do
				local oldsub = oldtable[button]
				if type(oldsub) == "table" then
					for option, value in pairs(newsub) do
						if type(oldsub[option]) == type(value) then
							newsub[option] = oldsub[option]
						end
					end
				end
			end
		end
		-- Buttons
		oldtable = LinkWranglerSaved.Buttons
		if type(oldtable) == "table" then
			newtable = newsaved.Buttons
			for option, value in pairs(newtable) do
				if type(oldtable[option]) == type(value) then
					newtable[option] = oldtable[option]
				end
			end
		end
		-- Layout
		oldtable = LinkWranglerSaved.Layout
		if newsaved.Config.savelayout and type(oldtable) == "table" then
			newtable = newsaved.Layout
			local counter = 1
			repeat
				local savestring = oldtable[counter]
				if type(savestring) == "string" then
					savestring = strmatch(savestring, "%-?%d+,%-?%d+")
					newtable[counter] = savestring -- if nil, changes nothing
				end
				counter = counter + 1
			until not savestring
		end
		-- AddOns
		oldtable = LinkWranglerSaved.AddOns
		if type(oldtable) == "table" then
			newtable = newsaved.AddOns
			for option, value in pairs(oldtable) do
				if type(value) == "number" then
					newtable[option] = value
				end
			end
		end
		-- LinkTypes
		oldtable = LinkWranglerSaved.LinkTypes
		if type(oldtable) == "table" then
			newtable = newsaved.LinkTypes
			for option, value in pairs(newtable) do
				if type(oldtable[option]) == type(value) then
					newtable[option] = oldtable[option]
				end
			end
		end
		-- Spacing
		oldtable = LinkWranglerSaved.Spacing
		if type(oldtable) == "table" then
			newtable = newsaved.Spacing
			for option, value in pairs(newtable) do
				if type(oldtable[option]) == type(value) then
					newtable[option] = oldtable[option]
				end
			end
		end

		-- Conversions
		-- none in this version

		LinkWranglerSaved = newsaved
		return "SavedVarsTest"
	end
end

-------------------------------------------------------------------------------------------
-- SAVED VARIABLE FUNCTIONS
-------------------------------------------------------------------------------------------

local function LWLogoutSaveLayout ()
	local x, y

	if not LWSConfig.savelayout then
		return
	end

	local scale = LWSConfig.scale
	for frame, info in pairs(LWTooltipData) do
		x = floor(frame:GetLeft()*frame:GetScale()+.5)
		y = floor(frame:GetTop()*frame:GetScale()-GetScreenHeight()+.5)
		LWSLayout[info.index] = x..","..y
	end
end

local function LWSetFrameLayout(frame, index)
	local x, y, saved
	local scale = LWSConfig.scale
	-- try to restore saved layout for this frame
	if LWSConfig.savelayout then
		saved = LWSLayout[index]
		if saved then
			x,y = strmatch(saved, "(%-?%d+),(%-?%d+)")
			if x and y then
				x = tonumber(x)
				y = tonumber(y)
				if x and y then
					frame:SetPoint("TOPLEFT",nil,"TOPLEFT",x/scale,y/scale)
					return
				end
			end
			LWReportError("Invalid saved layout string found: "..saved, 1)
		end
	end
	-- use default layout
	local screenx = GetScreenWidth()
	local screeny = GetScreenHeight()
	if index > 10 then
		x = screenx /2 -70
		y = -.7 *screeny
	elseif index > 5 then
		x = (index-6) *screenx /5 +30
		y = -.5 *screeny
	else -- index in range 1-5
		x = (index-1) *screenx /5 +30
		y = -.3 * screeny
	end
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", nil, "TOPLEFT", x/scale, y/scale)
end

local function LWLogoutSaveAddOns ()
	local enable = LWCallbackData.enable
	local enablecomp = LWCallbackData.enablecomp
	local saved

	for count, addon in ipairs(LWCallbackData.list) do
		saved = bitor(enable[addon] and 0 or 1, enablecomp[addon] and 0 or 2)
		if saved == 0 then saved = nil end
		LWSAddOns[addon] = saved
	end
end

local function LWSetAddOnSaved(addon)
	local enable = true
	local enablecomp = true
	if LWSAddOns then
		local saved = LWSAddOns[addon]

		if saved then
			if bitand (saved, 1) ~= 0 then
				enable = false
			end
			if bitand (saved, 2) ~= 0 then
				enablecomp = false
			end
		end
	else
		-- store AddOn to be processed when local variables have been loaded
		LinkWrangler.Startup.EarlyLoadAddOns[addon] = true
	end

	LWCallbackData.enable[addon] = enable
	LWCallbackData.enablecomp[addon] = enablecomp
end

-------------------------------------------------------------------------------------------
-- ADDON/PLUGIN SUPPORT
-------------------------------------------------------------------------------------------

local function LWCallbackRefresh(frame, link, linkType)
	-- refresh gets special handling as it is called most frequently
	local enable = LWCallbackData.enable
	-- refresh callback event
	for addon, func in pairs(LWCallbackData.refresh) do
		if enable[addon] then
			func(frame, link)
		end
	end
	if LWCallbackData[linkType] then
		for addon, func in pairs(LWCallbackData[linkType]) do
			if enable[addon] then
				func(frame, link, linkType)
			end
		end
	end
	frame:Show() -- check frame size and layout
end

local function LWCallbackAction(frame, link, request)
	if LWCallbackData[request] then
		local enable
		if frame.IsCompare then
			enable = LWCallbackData.enablecomp
		else
			enable = LWCallbackData.enable
		end
		for addon, func in pairs(LWCallbackData[request]) do
			if enable[addon] then
				func(frame, link, request)
			end
		end
	end
end

-- Used for Global events that occur only once in a session
-- Supports Plugins that do not have their own EventHandler
local function LWCallbackEvent(event)
	local callbacks = LWCallbackData[event]
	if not callbacks then return end
	for addon, func in pairs(callbacks) do
		func(event)
	end
	LWCallbackData[event] = nil -- only used once per session, delete as no longer needed
end

LinkWrangler.RegisterCallback = function(addonname, callbackfunc, ...)
	local errorstring
	local numparams = select("#",...)
	local redirectlevel = (numparams > 0 and select (1,...) == "redirect") and 3 or 2
	-- error checking
	if type(callbackfunc) == "string" then
		callbackfunc = _G[callbackfunc] or false
		-- the 'false' will generate an appropriate error message later...
	end
	if type(addonname) ~= "string" or #addonname < 1 then
		errorstring = "Addon name must be a valid string"
	elseif type(callbackfunc) ~= "function" and type(callbackfunc) ~= "nil" then
		errorstring = "Callback function parameter must be a valid function, global function name, or nil"
	else
		-- The Work Stuff
		local doSetAddOnSaved = false
		if numparams < 1 then -- Default action when no extra params passed
			LWCallbackData.refresh[addonname] = callbackfunc
			doSetAddOnSaved = true
		end
		for i=1,numparams do
			local param = (select(i,...))
			if type(param) ~= "string" then
				errorstring = "Callback request parameters must be strings, if provided"
				break
			else
				param = strlower (param)
			end
			local requesttype = LWCallbackType[param]
			if not requesttype then
				errorstring = "Unknown callback request parameter: "..param
				break
			end
			if requesttype == 1 then
				LWCallbackData.refresh[addonname] = callbackfunc
				doSetAddOnSaved = true
			elseif requesttype >= 2 and requesttype < 10 then
				local requesttable = LWCallbackData[param]
				if not requesttable then
					requesttable = {}
					LWCallbackData[param] = requesttable
				end
				requesttable[addonname] = callbackfunc
				doSetAddOnSaved = true
			elseif requesttype == 10 then -- "gameactive" event
				if LWIsGameActive then -- event has already occurred
					callbackfunc("gameactive")
				else
					local requesttable = LWCallbackData.gameactive
					if not requesttable then
						requesttable = {}
						LWCallbackData.gameactive = requesttable
					end
					requesttable[addonname] = callbackfunc
				end
			end
			-- special extra handling for certain requesttypes
			if callbackfunc then
				if requesttype == 4 then
					for frame,_ in pairs(LWTooltipData) do
						callbackfunc(frame, nil, param)
					end
				elseif requesttype == 5 then
					for frame, _ in pairs(LWCompareData) do
						callbackfunc(frame, nil, param)
					end
				end
			end
		end
		if doSetAddOnSaved and type(LWCallbackData.enable[addonname]) ~= "boolean" then -- check if AddOn already registered
			LWSetAddOnSaved (addonname)
			tinsert(LWCallbackData.list, addonname)
		end

	end

	if errorstring then
		return LWReportError(errorstring, redirectlevel)
	end
	return true
end

LinkWrangler.CallbackData = function(addonRef, command, extra)
	local addonname
	local enable = LWCallbackData.enable
	local enablecomp = LWCallbackData.enablecomp
	local errorstring

	if type(addonRef) == "string" then
		addonname = addonRef
	elseif type(addonRef) == "number" then
		addonname = LWCallbackData.list[addonRef]
	end

	if command == "test" then -- special handling
		if addonname and enable[addonname] ~= nil then
			return true, enable[addonname], enablecomp[addonname]
		end
		return nil -- do not return any errors for 'test' command
	end

	if not addonname then
		errorstring = "Must provide a valid AddOn name or number"
	elseif enable[addonname] == nil then
		errorstring = "AddOn "..addonname.." is not registered with LinkWrangler"
	elseif type (command) ~= "string" then
		errorstring = "Command parameter must be a string"
	elseif command == "enable" then
		enable[addonname] = true
	elseif command == "disable" then
		enable[addonname] = false
	elseif command == "enablecomp" then
		enablecomp[addonname] = true
	elseif command == "disablecomp" then
		enablecomp[addonname] = false
	else
		errorstring = "Invalid command parameter: "..command
	end

	if errorstring then
		return LWReportError(errorstring, 2)
	end
	return true, enable[addonname], enablecomp[addonname]
end

LinkWrangler.GetLinkInfo = function(data)
	local frame, info
	local datatype = type(data)
	if datatype == "string" then
		for fra, inf in pairs(LWTooltipData) do
			if (inf.link == data or inf.textlink == data) and inf.state > 0 then
				frame = fra
				info = inf
				break
			end
		end
	elseif datatype == "table" then -- assume it's a frame
		frame = data
		info = LWTooltipData[frame]
	end
	if info then
		return frame, info.state, info.link, info.textlink, info.name, info.whisper, info.linkType
	end
end

-------------------------------------------------------------------------------------------
-- TIMER FUNCTIONS
-------------------------------------------------------------------------------------------
--[[
LinkWrangler uses a single OnUpdate handler, attached to the Event frame
It handles the various windows through a set of lists held in tables
All timers are started or stopped by Showing or Hiding the Event frame
--]]

local function LWStopTimer()
	if LWTimerRunning then
		LWTimerRunning = false
		LWTimerFrame:Hide()
		-- clear out lists
		wipe(LWTimerTimeoutList)
		wipe(LWTimerReloadList)
		wipe(LWTimerResizeList)
		wipe(LWTimerRefreshList)
	end
end

--[[ Refresh timer
The refresh callback event is fired from inside the OnUpdate handler using this timer table
This should ensure that the basic tooltip is fully drawn before other AddOns add to it
Important to ensure that lines are always added to the tooltip in the same order, irrespective of how the tooltip was created/opened
--]]
local function LWStartRefreshTimer(frame, info)
	LWTimerRefreshList[frame] = info
	LWTimerResizeList[frame] = info -- always resize when we refresh
	if not LWTimerRunning then
		LWTimerRunning = true
		LWTimerFrame:Show()
	end
end

--[[ Resize timer
Timer to resize the tooltip to ensure it is tall enough to contain all the buttons. Also sizes minimized tooltip
Called indirectly by the OnSizeChanged handler, and explicitly in several functions
i.e. may be called multiple times as the tooltip loads
In addition the button height may change during load
We only want to perform the resize once, after everything else has finished, hence this timer
--]]
local function LWStartResizeTimer(frame, info)
	LWTimerResizeList[frame] = info
	if not LWTimerRunning then
		LWTimerRunning = true
		LWTimerFrame:Show()
	end
end

--[[ Timeout timer
Where the item is not held in the local cache, and cannot be downloaded immediately,
tooltip:SetHyperlink may return before displaying the tooltip.
The tooltip may still load and show after a short delay.
However, if after a few seconds the tooltip has still not opened,
this timer resets the tooltip and marks it as 'closed'.
This is a precaution to avoid leaving the tooltip stuck 'half-closed',
in the event that the item data _never_ gets downloaded.
--]]
local function LWStartTimeoutTimer(frame, info)
	LWTimerTimeoutList[frame] = info
	LWTimerTimeoutElapsed = 0 -- reset elapsed time
	if not LWTimerRunning then
		LWTimerRunning = true
		LWTimerFrame:Show()
	end
end

--[[ Reload timer
Handles cases where some elements of a tooltip are not available at the time the tooltip opens
As the missing elements are downloaded, the OnTooltipSetItem handler gets called for each one
Note: LinkWrangler.TooltipSetItem captures both OnTooltipSetItem and OnTooltipSetSpell events

In particular--
Recipes: TooltipSetItem will always be called (at least) twice for recipes,
once for the recipe itself, and again for the item that the recipe creates
(sometimes it is called additional times for the reagents of the recipe, if they are not cached)
Slotted items: If the info for the Gem(s) is not cached, TooltipSetItem gets called as it downloads
(odd note: sometimes 'empty' gem slots appear to generate TooltipSetItem calls too)

If TooltipSetItem gets called after the last refresh event, then we know that something basic about
the tooltip has changed after the other AddOns have seen/modified it.
Possibly new lines were added after lines from other AddOns - i.e. the tooltip is out of order
Also scanning AddOns may need to scan the new data

The timer waits a fraction of a second (in case further data is due to be downloaded),
then reloads the entire tooltip
--]]
local function LWStartReloadTimer(frame, info)
	LWTimerReloadList[frame] = info
	LWTimerReloadElapsed = 0 -- reset elapsed time
	if not LWTimerRunning then
		LWTimerRunning = true
		LWTimerFrame:Show()
	end
end

-------------------------------------------------------------------------------------------
-- COMPARE TOOLTIP FUNCTIONS
-------------------------------------------------------------------------------------------

local function LWGetAvailableCompare()
	-- check for existing available compare frame
	for fra, inf in pairs(LWCompareData) do
		if inf.state == 0 then
			return fra, inf
		end
	end

	-- no available frame so create new compare frame
	LWCompareDataCount = LWCompareDataCount + 1
	local frameName = "LinkWranglerCompare"..LWCompareDataCount
	local frame = CreateFrame ("GameTooltip", frameName, UIParent, "LinkWranglerCompareTemplate")

	if not frame then
		local errmsg = "Error creating Compare frame number "..LWCompareDataCount
		return LWReportError (errmsg, 1)
	end

	-- create new data subtable
	local info = {
		buttonFrames = {
			close = _G[frameName.."CloseButton"],
			relink = _G[frameName.."RelinkButton"],
			capture = _G[frameName.."CaptureButton"],
		},
		state = 0,
	}
	LWCompareData[frame] = info
	frame.IsCompare = true
	frame:SetScale(LWSConfig.scale)
	frame:RegisterForDrag("LeftButton")
	frame:SetClampRectInsets(-LWSSpacing.left, LWSSpacing.right, LWSSpacing.top, -LWSSpacing.bottom)
	LWCallbackAction(frame, nil, "allocatecomp")

	return frame, info
end

local function AddComparison(frame, equippedLink, info)
	if not LWSConfig.comparestats then
		return
	end
	local newLink = info.link
	if not IsEquippableItem(newLink) then
		-- probably a pattern - won't work with GetItemStatDelta
		return
	end
	local changetable = GetItemStatDelta(newLink, equippedLink)
	if not (changetable and next(changetable)) then
		return
	end
	frame:AddLine(format(LWM.CompStats, info.name), nil, nil, nil, true)
	for stat, delta in pairs(changetable) do
		-- we want 1 decimal place, except when that would be .0
		-- cannot be done directly using 'format', so need some pre-processing
		local deltatext = tostring(floor(delta * 10 + .5) /10)
		if delta < 0 then
			frame:AddLine(format("|cffff0000%s|r |cffffffff%s|r", deltatext, _G[stat] or stat))
		else
			frame:AddLine(format("|cff00ff00+%s|r |cffffffff%s|r", deltatext, _G[stat] or stat))
		end
	end
end

local function LWShowCompareFrame(frame, link, anchor, parent)
	local info = LWCompareData[frame]
	local closeButton = info.buttonFrames.close
	local relinkButton = info.buttonFrames.relink
	local captureButton = info.buttonFrames.capture
	local offset = 0
	local padding = 0
	local height = 12

	-- setup and display frame, record state, do callbacks - if needed
	if link and (not frame:IsShown() or info.link ~= link) then
		frame:SetOwner(UIParent, "ANCHOR_PRESERVE")
		frame:SetHyperlink(link)
		AddComparison(frame, link, parent)
		info.link = link
		info.state = 1
		LWCallbackAction(frame, link, "showcomp")
		LWCallbackAction(frame, link, "refreshcomp")
	end

	-- button layout and padding
	if LWSButtons.close then
		closeButton:Show()
		offset = -20
		height = height + 20
		padding = 16
	else
		closeButton:Hide()
	end
	if LWSButtons.relink then
		relinkButton:SetPoint("TOPRIGHT", closeButton, "TOPRIGHT", 0, offset)
		relinkButton:Show()
		offset = offset - 20
		height = height + 20
		padding = 16
	else
		relinkButton:Hide()
	end
	if LWSButtons.capture then
		captureButton:SetPoint("TOPRIGHT", closeButton, "TOPRIGHT", 0, offset)
		captureButton:Show()
		height = height + 20
		padding = 16
	else
		captureButton:Hide()
	end

	frame:SetPadding(padding, 0)
	if frame:GetHeight() < height then
		frame:SetHeight (height)
	end

	-- set anchor
	if anchor then
		frame:ClearAllPoints()
		frame:SetPoint("BOTTOMLEFT",anchor,"TOPLEFT",0,1)
	end
	frame:Show() -- checks layout and resizes tooltip
	frame:Raise()
end

local function LWHideCompareFrame(compareframe)
	local compareinfo = LWCompareData[compareframe]
	if compareframe:IsShown() then
		LWCallbackAction(compareframe, compareinfo.link, "hidecomp")
	end
	compareframe:Hide()
	-- unlink from main tooltip
	LWTooltipData[compareinfo.parentTooltip].compareFrames[compareinfo.compareIndex] = nil
	-- clear data
	compareinfo.state = 0
	compareinfo.parentTooltip = nil
	compareinfo.compareIndex = nil
	compareinfo.link = nil
end

local function LWCloseAllCompareFrames (tooltipinfo)
	for _,cframe in pairs(tooltipinfo.compareFrames) do
		LWHideCompareFrame(cframe)
	end
	tooltipinfo.compare = 0
end

local function LWCloseOneCompareFrame(compareframe)
	-- Function dealing with the case where only 1 compare tooltip is closed
	-- There may be another compare tooltip which requires adjustment
	local compareinfo = LWCompareData[compareframe]
	local tooltipframe = compareinfo.parentTooltip
	local tooltipinfo = LWTooltipData[tooltipframe]
	local frametable = tooltipinfo.compareFrames
	local otherframe, otheranchor

	tooltipinfo.compare = tooltipinfo.compare - 1
	if tooltipinfo.compare < 0 then
		LWCloseAllCompareFrames(tooltipinfo)
		return LWReportError("compare windows counter is negative", 1)
	end

	-- if the other compare frame is anchored to the frame we just hid,
	-- then we want to anchor it to the parent tooltip frame instead
	-- first run checks to see if this is needed, and save the result for later
	if compareinfo.compareIndex == 1 then
		otherframe = frametable[2]
		if otherframe then
			local _,anchor = otherframe:GetPoint()
			if anchor == compareframe then
				_,anchor = compareframe:GetPoint()
				if anchor == tooltipframe then
					otheranchor = tooltipframe
				end
			end
		end
	end

	LWHideCompareFrame(compareframe) -- this will also remove compareframe from tooltipinfo.compareFrames

	if otherframe then
		LWCompareData[otherframe].compareIndex = 1
		frametable[1]=otherframe -- renumber other tooltip in tooltipinfo.compareFrames table
		frametable[2]=nil
		LWShowCompareFrame (otherframe, nil, otheranchor) -- re-anchor the other compare tooltip
	end

	-- error checking, in case something went wrong...
	if tooltipinfo.compare ~= #(tooltipinfo.compareFrames) then
		LWCloseAllCompareFrames (tooltipinfo)
		return LWReportError ("Compare frame counter doesn't match compareFrames table", 1)
	end
end

local function LWOpenCompareWindow(tframe, tinfo, clink)
	local cframe, cinfo = LWGetAvailableCompare()
	if not cframe then
		return nil, cinfo
	end

	local compareindex = tinfo.compare + 1
	if compareindex > 2 then -- ### todo: is this needed?
		return LWReportError("Attempt to add more than 2 Compare windows to "..tframe:GetName(), 1)
	end
	local anchor = (compareindex > 1) and tinfo.compareFrames[compareindex - 1] or tframe
	tinfo.compareFrames[compareindex] = cframe
	tinfo.compare = compareindex
	cinfo.compareIndex = compareindex
	cinfo.parentTooltip = tframe
	cinfo.link = nil
	LWShowCompareFrame(cframe, clink, anchor, tinfo)
	if cinfo.state ~= 1 then
		LWCloseOneCompareFrame(cframe) -- attempt to recover
		return LWReportError("Opened Compare window has incorrect state", 1)
	end

	return true
end

local function LWCheckCompareButtonStatus(frame, info)
	if info.state == 1 then
		local match = false
		if info.slots then
			LWInventoryHooked = true
			for _,slot in ipairs(info.slots) do
				local test = GetInventoryItemLink("player", slot)
				if test then
					match = true
					break
				end
			end
		end
		if match then
			info.buttonFrames.compare:SetButtonState("NORMAL")
		else
			info.buttonFrames.compare:SetButtonState("DISABLED")
		end
	end
end

local function LWCheckInventory()
	LWInventoryHooked = false
	if not LWMasterEnable or not LWSButtons.compare then
		return
	end
	for frame, info in pairs(LWTooltipData) do
		LWCheckCompareButtonStatus(frame, info)
	end
end

-------------------------------------------------------------------------------------------
-- MAIN TOOLTIP FUNCTIONS
-------------------------------------------------------------------------------------------

local function LWResetTooltipData(info)
	info.state = 0
	info.minimized = false
	info.buttonHeight = 0
	info.compare = 0
	info.externalLink = nil
	info.openMinimize = nil
	info.link = nil
	info.textlink = nil
	info.whisper = nil
	info.name = nil
	info.slots = nil
	info.canDressup = false
	info.countSetLink = 0
	info.refreshStatus = 0
	info.originalLink = nil
	info.linkType = nil
end

local function LWCloseTooltipWindow(frame, inhibit)
	local info = LWTooltipData[frame]

	if info.state > 0 then
		LWCallbackAction(frame, info.link, "hide")
	end

	LWResetTooltipData(info)

	-- ensure frame is not held in timer lists
	LWTimerTimeoutList[frame] = nil
	LWTimerResizeList[frame] = nil
	LWTimerRefreshList[frame] = nil
	LWTimerReloadList[frame] = nil

	-- Hide frame and any child frames
	LWCloseAllCompareFrames(info)
	frame:Hide()

	if not inhibit then -- inhibit when closing all windows or when window not fully open
		LWCheckInventory()
	end
end

local function LWCloseAllAction()
	LWStopTimer()
	for frame, _ in pairs(LWTooltipData) do
		LWCloseTooltipWindow(frame, true)
	end
	LWInventoryHooked = false
end
-- local version for internal use. Export for keybind
LinkWrangler.CloseAllWindows = LWCloseAllAction

local function LWTooltipSetItemWrapper(frame)
	LinkWrangler.TooltipSetItem(frame)
end
local function LWTooltipSetSpellWrapper(frame)
	LinkWrangler.TooltipSetItem(frame, true)
end

local function LWCreateTooltipFrame()
	if LWTooltipDataCount >= 100 then
		-- maximum number of frames reached
		-- no-one should reach this number - it's a cap to prevent/detect runaway frame creation
		LWPrint(LWM.MaxWindows,nil,true)
		return
	end

	LWTooltipDataCount = LWTooltipDataCount + 1
	local frameName = "LinkWranglerTooltip"..LWTooltipDataCount
	local frame = CreateFrame("GameTooltip", frameName, UIParent, "LinkWranglerTooltipTemplate")

	if not frame then
		return LWReportError("Error creating Tooltip frame number "..LWTooltipDataCount, 1)
	end

	tinsert(UISpecialFrames, frameName) -- register for ESC key
	frame:RegisterForDrag("LeftButton")
	frame:SetScale(LWSConfig.scale)
	frame:SetClampRectInsets(-LWSSpacing.left, LWSSpacing.right, LWSSpacing.top, -LWSSpacing.bottom)
	if not LWIsNewTooltips then
		-- scripts only exist in "old" tooltip API
		frame:SetScript("OnTooltipSetItem", LWTooltipSetItemWrapper)
		frame:SetScript("OnTooltipSetSpell", LWTooltipSetSpellWrapper)
	end
	LWSetFrameLayout(frame, LWTooltipDataCount) -- set starting position

	-- start constructing data table for this window
	local info = {
		-- "constant" values
		index = LWTooltipDataCount,
		titleFrame = _G[frameName.."TextLeft1"], -- frame containing Title text
		-- sub-tables
		buttonFrames = {
			close = _G[frameName.."CloseButton"],
			minimize = _G[frameName.."MinButton"],
			compare = _G[frameName.."CompButton"],
			whisper = _G[frameName.."WhisperButton"],
			relink = _G[frameName.."RelinkButton"],
			dressup = _G[frameName.."DressupButton"],
		},
		compareFrames = {},
	}
	-- Initialize all other data fields
	LWResetTooltipData(info)
	-- Add new table to the data array
	LWTooltipData[frame] = info
	-- Notify other AddOns of tooltip creation
	LWCallbackAction(frame, nil, "allocate")

	return frame, info
end

local function LWGetCheckAvailableTooltip(link)
	local frame, info
	local index = LWTooltipDataCount + 1
	-- Scan existing windows
	for fra, inf in pairs(LWTooltipData) do
		if inf.link == link then
			if (inf.state < 0) then -- timer is running for this link
				LWCloseTooltipWindow(fra)
				return fra, inf -- force immediate retry in same fra
			else
				-- close the window
				LWCloseTooltipWindow(fra)
				return nil, nil
			end
		elseif inf.state == 0 and inf.index <= index then
			frame = fra
			info = inf
			index = inf.index
		end
	end

	if not frame then -- Attempt to create new frame
		frame, info = LWCreateTooltipFrame()
	end

	if frame and info then
		return frame, info
	end
	-- any errors have already been handled, just return nil
end

local function LWTooltipButtonLayout(frame, info)
	-- local references to buttons
	local closeButton = info.buttonFrames.close
	local minButton = info.buttonFrames.minimize
	local compareButton = info.buttonFrames.compare
	local whisperButton = info.buttonFrames.whisper
	local relinkButton = info.buttonFrames.relink
	local dressupButton = info.buttonFrames.dressup

	-- counter variables
	local offset = 0
	local height = 12
	local padding = 0

	if LWSButtons.close then
		closeButton:Show()
		offset = -20
		height = height + 20
		padding = 16
	else
		closeButton:Hide()
	end
	if info.minimized then
		if LWSButtons.minimize then
			minButton:SetPoint("TOPRIGHT",closeButton,"TOPRIGHT",offset,0)
			minButton:Show()
		else
			minButton:Hide()
		end
		compareButton:Hide()
		whisperButton:Hide()
		relinkButton:Hide()
		dressupButton:Hide()
	else
		if LWSButtons.minimize then
			minButton:SetPoint("TOPRIGHT",closeButton,"TOPRIGHT",0,offset)
			offset = offset - 20
			height = height + 20
			padding = 16
			minButton:Show()
		else
			minButton:Hide()
		end
		if LWSButtons.compare and info.slots then
			compareButton:SetPoint("TOPRIGHT",closeButton,"TOPRIGHT",0,offset)
			offset = offset - 20
			height = height + 20
			padding = 16
			compareButton:Show()
		else
			compareButton:Hide()
		end
		if LWSButtons.whisper and info.whisper then
			whisperButton:SetPoint("TOPRIGHT",closeButton,"TOPRIGHT",0,offset)
			offset = offset - 20
			height = height + 20
			padding = 16
			whisperButton:Show()
		else
			whisperButton:Hide()
		end
		if LWSButtons.relink and info.textlink then
			relinkButton:SetPoint("TOPRIGHT",closeButton,"TOPRIGHT",0,offset)
			offset = offset - 20
			height = height + 20
			padding = 16
			relinkButton:Show()
		else
			relinkButton:Hide()
		end
		if LWSButtons.dressup and info.canDressup then
			dressupButton:SetPoint("TOPRIGHT",closeButton,"TOPRIGHT",0,offset)
			offset = offset - 20
			height = height + 20
			padding = 16
			dressupButton:Show()
		else
			dressupButton:Hide()
		end

		frame:SetPadding(padding, 0)
		info.buttonHeight = height
	end
end

local function LWReloadTooltip(frame, info)
	local link = info.link
	info.countSetLink = 0
	info.refreshStatus = 0

	frame:ClearLines()
	frame:SetHyperlink(link)
	LWStartRefreshTimer(frame, info)
end

local function LWMinimizeTooltip(frame)
	local info = LWTooltipData[frame]
	local link = info.link

	if info.minimized then -- do maximize
		-- set indicators
		info.minimized = false
		info.state = 1
		LWCallbackAction(frame, link, "maximize")
		-- ensure anchored by top left corner
		local left, top = frame:GetLeft(), frame:GetTop()-GetScreenHeight()/frame:GetScale()
		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT", nil, "TOPLEFT", left, top)
		-- redraw frame
		LWReloadTooltip(frame, info)
		frame:Raise()
	else -- do minimize
		-- set indicators
		info.minimized = true
		info.state = 2
		LWTimerReloadList[frame] = nil
		LWCallbackAction(frame, link, "minimize")
		-- ensure anchored by top left corner
		local left, top = frame:GetLeft(), frame:GetTop()-GetScreenHeight()/frame:GetScale()
		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT", nil, "TOPLEFT", left, top)
		-- clear everything except the title
		frame:SetText(info.titleFrame:GetText(), info.titleFrame:GetTextColor())
		frame:Lower()
		-- close any other associated frames
		LWCloseAllCompareFrames(info)
	end

	LWTooltipButtonLayout(frame, info)
	LWStartResizeTimer(frame, info)
	LWCheckCompareButtonStatus(frame, info)
	frame:Show()
end

LinkWrangler.MinimizeAllWindows = function() -- used for keybinding
	-- scan for open / unminimized tooltips
	local dropout = true
	local maxfound

	--scan to check states of tooltips
	for _, info in pairs(LWTooltipData) do
		if info.state > 0 then
			dropout = false -- found an open window
			if not info.minimized then
				maxfound = true
				break
			end
		end
	end

	if dropout then -- no further action
		return
	end

	if maxfound then -- at least 1 window open and not minimized
		for frame, info in pairs(LWTooltipData) do
			if info.state == 1 then -- only fully open windows
				LWMinimizeTooltip(frame)
			end
		end
	else -- at least 1 window open and all minimized
		for frame,_ in pairs(LWTooltipData) do
			LWMinimizeTooltip(frame)
		end
	end
end

-------------------------------------------------------------------------------------------
-- SLASH HANDLER
-------------------------------------------------------------------------------------------

LinkWrangler.MasterSwitch = function (option, bool)
	if (option == "enable") then
		LWMasterEnable = true
	elseif (option == "disable") then
		LWMasterEnable = false
	elseif (option == "toggle") then
		LWMasterEnable = not LWMasterEnable
	elseif (option == "switch") then
		LWMasterEnable = not (not bool)
	end
	if not LWMasterEnable then
		LWCloseAllAction()
	end
	LWPrint(LWBoolStr(LWMasterEnable))
end
LWSlashJump["enable"]=LinkWrangler.MasterSwitch
LWSlashJump["disable"]=LinkWrangler.MasterSwitch
LWSlashJump["toggle"]=LinkWrangler.MasterSwitch

LWSlashJump["mode"] = function (option, extra)
	extra = LWA[extra] or extra
	if extra == "default" then extra = "advanced" end
	if extra == "simple" or extra == "advanced" then
		LWSConfig.mode = extra
		LWPrint(format(LWS.SettingMode, extra))
		if LWSessionMode ~= LWSConfig.mode then
			LWPrint(LWS.ResetSetting, true)
		end
	elseif extra == "" then
		local modetext = format(LWS.SessionMode, LWSessionMode)
		if LWSessionMode ~= LWSConfig.mode then
			modetext = modetext..format(LWS.ChangedMode, LWSConfig.mode)
		end
		LWPrint(modetext)
	else
		LWPrint(LWS.UsageSetting)
	end
end

-- note: overridden in simple mode
local function LWSlashClickStatus(button, options) -- subfunction used by status and click handlers
	local textout = format(LWS.ClickStatus,(LWL.Display[button] or button))
	for action, code in pairs(options) do
		textout = textout.." ".. action.."="..code
	end
	LWPrint(textout, true)
end

local function LWSlashButtonStatus() -- subfunction used by status and buttons handlers
	local textout = LWS.ButtonsEnabled
	local none = true
	for but, bool in pairs(LWSButtons) do
		if bool then
			textout=textout.." "..but
			none = false
		end
	end
	if none then
		textout=textout.." none"
	end
	LWPrint(textout, true)
end

local function LWSlashLinkTypeStatus() -- subfunction used by status and linktype handlers
	local textout = LWS.LinkTypes
	local none = true
	for linktype, bool in pairs(LWSLinkTypes) do
		if bool then
			textout = textout .. " " .. linktype
			none = false
		end
	end
	if none then
		textout = textout .. " none"
	end
	LWPrint(textout, true)
end

LWSlashJump["status"] = function (x,subcommand)
	subcommand = LWA[subcommand] or subcommand
	if subcommand == "default" then
		LinkWranglerSaved = LWGetDefaultSaveTable()
		LinkWrangler.SyncLocal()
		LWPrint(LWM.SavedVarsDefault)
	elseif subcommand == "test" then
		LinkWranglerSaved.Version = 0 -- force test on next reload
		LWPrint(LWS.ResetCheck)
		return -- don't show current status for this option
	elseif subcommand == "purge" then
		LinkWranglerSaved.AddOns = {}
		LinkWranglerSaved.Layout = {}
		LinkWrangler.SyncLocal()
		LWPrint(LWS.PurgeSavedVars)
		return
	end
	LWPrint(format(LWS.StatusHead, LWVersion, LWBoolStr(LWMasterEnable)))
	local modetext = format(LWS.SessionMode, LWSessionMode)
	if LWSessionMode ~= LWSConfig.mode then
		modetext = modetext..format(LWS.ChangedMode, LWSConfig.mode)
	end
	LWPrint(modetext, true)

	for clk, ops in pairs(LWSClick) do
		LWSlashClickStatus(clk, ops)
	end
	LWSlashButtonStatus()
	LWSlashLinkTypeStatus()
	LWPrint(format(LWS.SpacingStatus, LWSSpacing.top, LWSSpacing.bottom, LWSSpacing.left, LWSSpacing.right), true)
	for op, val in pairs(LWSConfig) do
		if op ~= "mode" then -- mode has special handling above
			local display
			if type(val) == "boolean" then
				display = LWBoolStr(val)
			else
				display = tostring(val)
			end
			LWPrint(format("%s : %s", op, display), true)
		end
	end
end

LWSlashJump["help"] = function ()
	for i = 1, #(LWS.HelpList) do
		LWPrint(LWS.HelpList[i], true)
	end
end

LWSlashJump["list"] = function ()
	LWPrint(LWS.ListAddonsHead)
	local enable = LWCallbackData.enable
	local enablecomp = LWCallbackData.enablecomp
	for count, addon in ipairs(LWCallbackData.list) do
		LWPrint(format(LWS.ListAddonsLine, count, addon, LWBoolStr(enable[addon]), LWBoolStr(enablecomp[addon])), true)
	end
end

LWSlashJump["addons"] = function (option, extra)
	local _, pos, subcommand, tail, addon, addonnumber
	local enable = LWCallbackData.enable
	local enablecomp = LWCallbackData.enablecomp

	_,pos,subcommand = strfind(extra, "(%S+)")
	subcommand = LWA[subcommand] or subcommand or "list"
	if subcommand == "list" then
		return LWSlashJump["list"]()
	elseif subcommand == "purge" then
		LinkWranglerSaved.AddOns = {}
		LinkWrangler.SyncLocal()
		LWPrint(LWS.PurgeSavedVars)
		return
	end

	if pos then
		tail = strmatch(extra, "%s+(.+)", pos+1)
	end
	if tail then
		-- obtain addon's number and properly capitalized name
		addonnumber = tonumber(tail)
		if addonnumber then
			addon = LWCallbackData.list[addonnumber]
		end
		if not addon then
			for number, name in ipairs(LWCallbackData.list) do
				if tail == strlower(name) then
					addonnumber = number
					addon = name
					break
				end
			end
		end
	else
		tail = "<blank>"
	end
	if not addon then
		LWPrint(format(LWS.UnknownAddon, tail))
		return
	end

	if subcommand == "enable" then
		enable[addon] = true
	elseif subcommand == "disable" then
		enable[addon] = false
	elseif subcommand == "enablecomp" then
		enablecomp[addon] = true
	elseif subcommand == "disablecomp" then
		enablecomp[addon] = false
	else
		LWPrint(format(LWS.InvalidOption, subcommand))
		return
	end
	LWPrint(format(LWS.ListAddonsLine, addonnumber, addon, LWBoolStr(enable[addon]), LWBoolStr(enablecomp[addon])))
end

local LWJumpConfig = function (option, extra)
	extra = LWA[extra] or extra
	if extra == "toggle" then
		LWSConfig[option] = not LWSConfig[option]
	elseif extra == "enable" then
		LWSConfig[option] = true
	elseif extra == "disable" then
		LWSConfig[option] = false
	elseif extra ~= "" then -- unknown extra param
		LWPrint(format(LWS.UsageGeneral, option))
	end
	LWPrint(option.." : "..LWBoolStr(LWSConfig[option]))
end
LWSlashJump["verbose"]=LWJumpConfig
LWSlashJump["savelayout"]=LWJumpConfig
LWSlashJump["comparestats"]=LWJumpConfig

local LWJumpLink = function (option, extra)
	extra = LWA[extra] or extra
	local linktype = strmatch(option, "(%l+)links")
	local value = LWSLinkTypes[linktype]
	local change = true

	if extra == "enable" then
		value = true
	elseif extra == "disable" then
		value = false
	elseif extra == "toggle" then
		value = not value
	elseif extra == "" then
		change = false
	else
		change = false
		LWPrint(format(LWS.UsageGeneral, option))
	end

	if change then
		LWSLinkTypes[linktype] = value
	end

	LWSlashLinkTypeStatus ()
end
LWSlashJump["itemlinks"]=LWJumpLink
LWSlashJump["spelllinks"]=LWJumpLink
LWSlashJump["questlinks"]=LWJumpLink
LWSlashJump["enchantlinks"]=LWJumpLink
LWSlashJump["achievementlinks"]=LWJumpLink
LWSlashJump["talentlinks"]=LWJumpLink

LWSlashJump["scale"] = function (command, extra)
	local val = tonumber(extra)
	local oldval = LWSConfig.scale
	local x, y
	local screeny = GetScreenHeight()
	if val then
		if val >= .2 and val <= 2.5 then
			LWSConfig.scale = val
			for frame,info in pairs(LWTooltipData) do
				x = frame:GetLeft() * oldval / val
				y = (frame:GetTop() * oldval - screeny) / val
				frame:SetScale(val)
				frame:ClearAllPoints()
				frame:SetPoint("TOPLEFT", nil, "TOPLEFT", x, y)
				if frame:IsVisible() then
					frame:Show()
					LWStartResizeTimer(frame, info) -- todo: are both of these needed?
				end
			end
			for frame,_ in pairs(LWCompareData) do
				frame:SetScale(val)
			end
		else
			LWPrint(LWS.UsageScale)
		end
	elseif #extra > 0 then
		LWPrint(format(LWS.InvalidOption, extra))
	end
	LWPrint("scale : "..LWSConfig.scale)
end

LWSlashJump["spacing"] = function (command, extra)
	local noheader
	if extra ~= "" then
		local side, value = extra:match("(%w+)%W+(%d+)")
		side = LWA[side] or side
		value = tonumber(value)
		if LWSSpacing[side] and value < 250 then
			LWSSpacing[side] = value
			for frame, info in pairs(LWTooltipData) do
				frame:SetClampRectInsets(-LWSSpacing.left, LWSSpacing.right, LWSSpacing.top, -LWSSpacing.bottom)
			end
			for frame, info in pairs(LWCompareData) do
				frame:SetClampRectInsets(-LWSSpacing.left, LWSSpacing.right, LWSSpacing.top, -LWSSpacing.bottom)
			end
			LWPrint(format(LWS.SpacingSetting, side, value))
		else
			LWPrint(LWS.UsageSpacing)
		end
		noheader = true
	end
	LWPrint(format(LWS.SpacingStatus, LWSSpacing.top, LWSSpacing.bottom, LWSSpacing.left, LWSSpacing.right), noheader)
end

-- note: overridden in simple mode
local LWJumpClick = function (click, extra)
	extra = LWA[extra] or extra
	LWPrint(format(LWS.ClickSetting,LWL.Display[click]))
	local saved=LWSClick[click]
	-- special cases first
	if extra == "default" then
		LWSClick[click] = LWGetDefaultClickTable(click)
	elseif extra == "disable" then
		saved.action = "bypass"
		saved.shift = "bypass"
		saved.ctrl = "bypass"
		saved.alt = "bypass"
	else
		local _, pos, action, code = strfind(extra, "(%w+)%W+(%w+)")
		while pos do
			action = LWA[action] or action
			code = LWA[code] or code
			if not (action=="action" or action=="shift" or action=="ctrl" or action=="alt") then
				LWPrint(format(LWS.InvalidOption,action))
			elseif not LWQuickActionJump[code] then
				LWPrint(format(LWS.InvalidOption,code))
			else
				saved[action]=code
			end
			_,pos,action,code = strfind(extra, "(%w+)%W+(%w+)", pos+1)
		end
	end

	LWSlashClickStatus(click, LWSClick[click])
end
LWSlashJump["LeftButton"]=LWJumpClick
LWSlashJump["RightButton"]=LWJumpClick
LWSlashJump["MiddleButton"]=LWJumpClick

-- note: overridden in simple mode
LWSlashJump["allclick"] = function (c, extra)
	for click, _ in pairs(LWSClick) do
		LWJumpClick(click, extra)
	end
end

LWSlashJump["buttons"] = function (cmd, extra)
	for p in string.gmatch(extra, "%S+") do
		local param = LWA[p] or p or "<unknown>"
		if param == "closeonly" then
			LWSButtons.close     = true
			LWSButtons.minimize  = false
			LWSButtons.compare   = false
			LWSButtons.whisper   = false
			LWSButtons.relink    = false
			LWSButtons.dressup   = false
			LWSButtons.capture   = false
		elseif param == "closemin" then
			LWSButtons.close     = true
			LWSButtons.minimize  = true
			LWSButtons.compare   = false
			LWSButtons.whisper   = false
			LWSButtons.relink    = false
			LWSButtons.dressup   = false
			LWSButtons.capture   = false
		elseif param == "all" or param == "default" then
			LWSButtons.close     = true
			LWSButtons.minimize  = true
			LWSButtons.compare   = true
			LWSButtons.whisper   = true
			LWSButtons.relink    = true
			LWSButtons.dressup   = true
			LWSButtons.capture   = true
		elseif param == "close" then LWSButtons.close = true
		elseif param == "noclose" then LWSButtons.close = false
		elseif param == "minimize" then LWSButtons.minimize = true
		elseif param == "nominimize" then LWSButtons.minimize = false
		elseif param == "compare" then LWSButtons.compare = true
		elseif param == "nocompare" then LWSButtons.compare = false
		elseif param == "whisper" then LWSButtons.whisper = true
		elseif param == "nowhisper" then LWSButtons.whisper = false
		elseif param == "relink" then LWSButtons.relink = true
		elseif param == "norelink" then LWSButtons.relink = false
		elseif param == "dressup" then LWSButtons.dressup = true
		elseif param == "nodressup" then LWSButtons.dressup = false
		elseif param == "capture" then LWSButtons.capture = true
		elseif param == "nocapture" then LWSButtons.capture = false
		else
			LWPrint(format(LWS.InvalidOption,param))
		end
	end
	LWSlashButtonStatus()
end

LWSlashJump["debug"] = function (command, extra)
	extra = LWA[extra] or extra
	--process debug commands
	if extra == "enable" then
		LWDebugEnable = true
	elseif extra == "disable" then
		LWDebugEnable = false
	elseif extra == "toggle" then
		LWDebugEnable = not LWDebugEnable
	end
	-- display debug data
	LWPrint("Debug : "..LWBoolStr(LWDebugEnable))
	LWPrint("Initialization : "..(LinkWrangler.Startup and "Failed" or "Complete"), true)
	LWPrint(format("Main windows %d, Compare windows %d", LWTooltipDataCount, LWCompareDataCount), true)
	if LinkWranglerLocal then
		LWPrint("Locale "..(LinkWranglerLocal.Locale or "Unknown").." version "..(LinkWranglerLocal.Version or "Unknown"), true)
	end
end

LinkWrangler.SlashHandler = function (cmd)
	cmd = strlower(cmd)

	local _,pos,command = strfind(cmd, "(%S+)")
	if pos then
		command = LWA[command] or command
		local sfunc= LWSlashJump[command]
		if sfunc then
			sfunc(command, strtrim(strsub(cmd, pos+1)))
			return
		end
	end

	-- unknown - basic help
	LWPrint(format(LWM.BasicHelp, LWVersion, LWBoolStr(LWMasterEnable)))
end

-------------------------------------------------------------------------------------------
-- QUICK ACTION SUBFUNCTIONS
-------------------------------------------------------------------------------------------
-- general format: LWQuickActionJump.<clickoption> = function(valuetable, link, textlink, button, linktype)

LWQuickActionJump.bypass = function(retval)
	retval.bypass = true
end

LWQuickActionJump.open = function()
	-- do nothing: opens standard window by default
end

LWQuickActionJump.openmin = function(retval)
	retval.openMinimize = true
end

LWQuickActionJump.relink = function(retval, link, textlink, button, linktype)
	retval.dropout = true
	if textlink then
		if linktype == "item" then
			-- special handling for 'item': verify link by passing it through GetItemInfo
			local _, fixedlink = GetItemInfo(textlink)
			textlink = fixedlink or textlink
		end
		if not ChatEdit_InsertLink(textlink) then
			ChatFrame_OpenChat(textlink)
		end
	end
end

LWQuickActionJump.dressup = function(retval, link)
	DressUpItemLink(link)
	retval.dropout = true
	return
end

-------------------------------------------------------------------------------------------
-- HOOK AND EXTERNAL LINK FUNCTIONS
-------------------------------------------------------------------------------------------

local function LWSplitLink(inputlink, inputtext)
	local link = strmatch(inputlink, "|H([%l%d%-%+%:]+)|h") or inputlink
	local linktype, linkID = strmatch(link, "^(%l+):(%-?%d+)")
	if LWSLinkTypes[linktype] then
		-- if inputtext is supplied, it is the first choice for textlink; make sure it's in a valid format
		local textlink
		if inputtext then
			textlink = strmatch(inputtext, "(|c%x+|H.+|h%[.+%]|h|r)")
		end
		-- check if inputlink looks like a valid textlink
		if not textlink then
			textlink = strmatch(inputlink, "(|c%x+|H.+|h%[.+%]|h|r)")
		end
		if linktype == "item" then -- for 'item' always pass textlink through GetItemInfo to verify it
			local _, t = GetItemInfo(textlink or inputlink)
			textlink = t
		elseif not textlink then
			if linktype == "spell" then
				textlink = GetSpellLink(tonumber(linkID))
			elseif linktype == "achivement" then
				textlink = GetAchievementLink(tonumber(linkID))
			end
		end
		return link, linktype, textlink
	end
end

local function LWTooltipSetHyperlink(link, linktype, valuetable)
	-- Find and setup frame
	local frame, info = LWGetCheckAvailableTooltip(link)
	if not frame then
		return
	end
	frame:SetOwner(UIParent, "ANCHOR_PRESERVE") -- todo: is this needed?
	frame:ClearLines() -- todo: is this needed?

	-- Setup info
	for key, value in pairs(valuetable) do
		info[key] = value
	end
	info.link = link
	info.state = -1 -- mark as partially open
	info.countSetLink = 0
	info.refreshStatus = 0
	info.linkType = linktype
	LWTimerReloadList[frame] = nil
	if linktype == "item" then
		info.itemInfoNeeded = true -- set flag to call GetItemInfo later
	end

	-- Protected call to SetHyperlink
	local errOK, errTXT = pcall(frame.SetHyperlink, frame, link)
	if not errOK then -- trap any errors
		LWCloseTooltipWindow(frame)
		local msg = "SetHyperlink error"
		if info.externalLink then
			msg = msg.." (external link)"
		end
		msg = msg..": "..tostring(errTXT)
		return LWReportError (msg, 2)
	elseif not frame:IsVisible() then -- check if SetHyperlink failed during call, but with no error - may succeed later
		LWStartTimeoutTimer(frame, info)
	end

	return errOK
end

-- Advanced Mode entry point
LinkWrangler.Startup.HookSetItemRef = function(link, text, button, chatFrame, ...)
	if not LWMasterEnable then
		return LWOriginalSetItemRef(link, text, button, chatFrame, ...)
	end

	local _, linktype, textlink = LWSplitLink(link, text)

	if linktype then
		local valuetable = LWGetValueTable()
		local clickOption = LWSClick[button]
		if clickOption then
			if IsShiftKeyDown() then
				LWQuickActionJump[clickOption.shift](valuetable,link,textlink,button,linktype)
			elseif IsControlKeyDown() then
				LWQuickActionJump[clickOption.ctrl](valuetable,link,textlink,button,linktype)
			elseif IsAltKeyDown() then
				LWQuickActionJump[clickOption.alt](valuetable,link,textlink,button,linktype)
			else
				LWQuickActionJump[clickOption.action](valuetable,link,textlink,button,linktype)
			end
		end

		if valuetable.bypass then
			return LWOriginalSetItemRef(link, text, button, chatFrame, ...)
		end
		if valuetable.dropout then
			return
		end

		valuetable.textlink = textlink
		valuetable.originalLink = text -- preserve link exactly as it appeared in chat

		LWTooltipSetHyperlink(link, linktype, valuetable)

	else -- Call original if not handled above
		return LWOriginalSetItemRef(link, text, button, chatFrame, ...)
	end
end

-- Simple Mode entry point
LinkWrangler.Startup.HookIRTSetHyperlink = function(tooltip, link, ...)
	if not LWMasterEnable or tooltip ~= ItemRefTooltip then
		return LWOriginalIRTSetHyperlink(tooltip, link, ...)
	end

	local baselink, linktype, textlink = LWSplitLink(link)
	if linktype then
		HideUIPanel(tooltip)
		local valuetable = LWGetValueTable()
		valuetable.textlink = textlink
		LWTooltipSetHyperlink(baselink, linktype, valuetable)
	else
		return LWOriginalIRTSetHyperlink(tooltip, link, ...)
	end
end

--[[ Open Tooltip
Opens a LinkWrangler tooltip using the supplied link
'options' table (optional) may hold additional info or instructions
--]]
LinkWrangler.OpenTooltip = function(extlink, options)
	if not LWMasterEnable then
		return
	end

	if type(extlink) ~= "string" then
		return LWReportError("OpenTooltip: link parameter must be a string", 2)
	elseif options ~= nil and type(options) ~= "table" then
		return LWReportError("OpenTooltip: options parameter must be a table or nil", 2)
	end

	local text = options and options.textlink
	local link, linktype, textlink = LWSplitLink(extlink, text)
	if not linktype then
		return
	end

	local valuetable = LWGetValueTable()
	valuetable.textlink = textlink
	if options then
		if type(options.whisper)=="string" and #options.whisper > 0 then
			valuetable.whisper = options.whisper
		end
		if options.openmin then
			valuetable.openMinimize = true
		end
	end
	valuetable.externalLink = true

	if LWTooltipSetHyperlink(link, linktype, valuetable) then
		return frame
	end
end

--[[ Capture Tooltip
Opens a LinkWrangler tooltip using the link from the current GameTooltip
i.e. captures link from whatever item is under the mouse
]]
LinkWrangler.CaptureTooltip = function()
	if GameTooltip:IsVisible() and LWMasterEnable then
		-- find link from tooltip
		local _, getlink = GetDisplayedItem(GameTooltip)
		if not getlink then
			local _, spellID = GetDisplayedSpell(GameTooltip)
			if spellID then
				getlink = GetSpellLink(spellID)
			end
		end
		if getlink then
			-- check type and setup other variables
			local link, linktype, textlink = LWSplitLink (getlink)
			if linktype then
				local valuetable = LWGetValueTable()
				valuetable.textlink = textlink
				if LWTooltipSetHyperlink (link, linktype, valuetable) then
					GameTooltip:Hide ()
				end
			end
		end
	end
end

--[[ Capture Compare
Called from the Capture button in a Compare tooltip
Opens the link from the Compare tooltip into a Main tooltip
]]
local function LWCaptureCompare(cframe)
	local cinfo = LWCompareData[cframe]
	if not (cinfo and cinfo.link) then return end
	local link, linktype, textlink = LWSplitLink(cinfo.link)
	if linktype then
		local valuetable = LWGetValueTable()
		valuetable.textlink = textlink
		if LWTooltipSetHyperlink(link, linktype, valuetable) then
			LWCloseOneCompareFrame(cframe)
		end
	end
end

-------------------------------------------------------------------------------------------
-- BUTTON SCRIPT HANDLERS
-------------------------------------------------------------------------------------------

-- Whisper button
LWButtonClickJump.Whisper = function(parent)
	local member = LWTooltipData[parent].whisper

	if member then
		ChatFrame_SendTell(member)
	end
end

-- Relink/Link buttons
LWButtonClickJump.Relink = function(parent)
	local textlink
	if parent.IsCompare then -- it's a compare window
		textlink = LWCompareData[parent].link
	else
		textlink = LWTooltipData[parent].textlink
	end

	if textlink then
		if not ChatEdit_InsertLink(textlink) then
			ChatFrame_OpenChat(textlink)
		end
	end
end
LWButtonClickJump.Link = LWButtonClickJump.Relink

-- Dress Up button
LWButtonClickJump.Dressup = function(parent)
	DressUpItemLink(LWTooltipData[parent].link)
end

-- Minimize button
LWButtonClickJump.Minimize = function(parent)
	LWMinimizeTooltip(parent)
end

-- Compare button
LWButtonClickJump.Compare = function(parent)
	local info = LWTooltipData[parent]

	if info.compare == 0 then
		for index, slot in pairs(info.slots) do
			local link = GetInventoryItemLink("player", slot)
			if link then
				LWOpenCompareWindow(parent, info, link)
			end
		end
	else
		LWCloseAllCompareFrames(info)
	end
end

-- All close buttons
LWButtonClickJump.CloseMain = function(parent)
	if IsShiftKeyDown() then
		LinkWrangler.CloseAllWindows()
	elseif parent.IsCompare then
		LWCloseOneCompareFrame(parent)
	else
		LWCloseTooltipWindow(parent)
	end
	GameTooltip:Hide()
end
LWButtonClickJump.CloseComp = LWButtonClickJump.CloseMain

-- Capture button on Compare tooltips
LWButtonClickJump.Capture = function(parent)
	LWCaptureCompare(parent)
end

LinkWrangler.ButtonClick = function(button)
	LWButtonClickJump[button.ButtonType](button:GetParent())
end

-- Show popup tooltip description for button on mouseover
LinkWrangler.ButtonTooltip = function(button)
	GameTooltip:SetOwner (button, "ANCHOR_RIGHT")
	GameTooltip:SetText (LWL.Tooltip[button.ButtonType])
	GameTooltip:Show()
end

-------------------------------------------------------------------------------------------
-- TOOLTIP SCRIPT HANDLERS
-------------------------------------------------------------------------------------------

LinkWrangler.TooltipOnSizeChanged = function(frame)
	LWStartResizeTimer (frame, LWTooltipData[frame])
end

LinkWrangler.TooltipOnEnter = function(frame, mouse)
	if not mouse then return end -- 'mouse' is false if mouse didn't move (i.e. window got moved over mouse cursor)
	local info = LWTooltipData[frame]

	if info.state == 1 then
		frame:Raise() -- bring frame to front of strata (only if frame is in fully shown state)
	end
end

LinkWrangler.TooltipOnHide = function(frame)
	GameTooltip_OnHide(frame)
	if LWTooltipData[frame].state ~= 0 then
		LWCloseTooltipWindow (frame)
	end
end

LinkWrangler.TooltipSetItem = function(frame, spell)
	-- normally called from OnTooltipSetItem handler
	-- 'spell' set to true if called from OnTooltipSetSpell handler
	-- note there is no equivalent handler for quest links (in "old" Tooltip API)

	-- New Tooltip API: We will emulate OnTooltipSetItem and OnTooltipSetSpell
	-- However we will receive calls for *every* tooltip, so we must check frame is a valid LW tooltip

	local info = LWTooltipData[frame]
	if not info then return end

	-- how many times has LinkWrangler.TooltipSetItem been called since last SetHyperlink
	local count = info.countSetLink + 1
	info.countSetLink = count

	local buttons

	--[[
	OnShow may now get called before the local cache is updated
	OnTooltipSetItem gets called each time the local cache is updated
	So this is now the best place to call GetItemInfo (it should succeed ... eventually)
	But we only want to call it if we (still) need the info
	A control flag will have been set to true for item links
	--]]
	if info.itemInfoNeeded then
		local name,textlink,_,_,_,_,_,_,equip = GetItemInfo(info.link)
		if name and textlink then
			info.itemInfoNeeded = nil

			buttons = not info.textlink
			info.textlink = textlink
			info.name = name

			if equip and not info.slots then
				-- setup compare slots: try to match to Equip code passed from getItemInfo
				local slots = LWInventorySlotTable[equip]
				if slots then
					info.slots = slots
					LWCheckCompareButtonStatus(frame, info) -- set compare button according to inventory
					buttons = true
				end
			end
			-- Set Dressup button
			if IsDressableItem(info.link) then
				info.canDressup = true
				buttons = true
			end
		end
	end

	if info.refreshStatus == 1 or info.refreshStatus == 3 then
		--[[
		We have detected a call to OnTooltipSetItem after a "refresh" event has been fired
		This can happen when some of the info for the tooltip is not held in the local cache at first -
		When the info is eventually downloaded, OnTooltipSetItem gets called again (possibly many times)
		We're going to wait a fraction of a second (to see if any more info arrives) then reload the tooltip
		Note that we only do this up to twice, to avoid runaway reloads...
		--]]
		LWStartReloadTimer(frame, info)
	end

	if count == 2 and not info.slots then -- possibly a recipe; check if the finished item is equippable
		-- if tooltip is fully open, scan text to search for equippable types
		if info.state == 1  then
			local frametext = frame:GetName().."TextLeft"
			for i=3,12 do -- the line we want is most likely line 7 or 8, but search either side
				local textfield = _G[frametext..i]
				if textfield then
					local slots = LWInventorySlotLocalTable[textfield:GetText()]
					if slots then
						info.slots = slots
						LWCheckCompareButtonStatus(frame, info) -- set compare button according to inventory
						buttons = true
						break
					end
				else -- textfile 'i' doesn't exist (yet) - no subsequent textfields will exist either
					break
				end
			end
		end
	end

	if buttons then
		-- Buttons settings have been changed - re-do layout
		LWTooltipButtonLayout (frame, info)
		LWStartResizeTimer (frame, info)
	end
end

--[[
Called when window first becomes visible after link has been loaded
Note about uncached items: some functions do not always work at this point, if the item is uncached.
Found this problem with: GetItemInfo, frame:GetItem
--]]
LinkWrangler.TooltipOnShow = function(frame)
	local info = LWTooltipData[frame]
	info.name = info.titleFrame:GetText() -- get (localised) item name as it appears in tooltip
	-- note: with some uncached items this returns the string "Retrieving item information" instead

	-- Set Whisper Player
	if info.originalLink then
		--[[
		originalLink holds the full text link as it appeared in chat
		may be different from textlink, e.g. due to localisation
		only gets set when clicking a link in chat (i.e. via SetItemRef)
		--]]

		local namepattern = strmatch(info.originalLink, "(%[.+%])")
		if namepattern then
			-- find most recent whisperer for the named item
			local counter = LWChatBufferIndex
			for i=1,LWChatBufferStored do
				counter = counter - 1
				if counter == 0 then
					counter = LWChatBufferStored
				end
				-- search for pattern using plain text matching
				if (strfind(LWChatBufferTextList[counter],namepattern,1,true)) then
					info.whisper = LWChatBufferNameList[counter]
					break
				end
			end
		end
		info.originalLink = nil
	end

	-- other Addon stuff
	info.state = 1
	LWTimerTimeoutList[frame] = nil
	LWCallbackAction (frame, info.link, "show") -- notify addons frame is being opened

	if info.openMinimize then
		info.openMinimize = nil
		LWMinimizeTooltip (frame)
	else
		LWStartRefreshTimer (frame, info)

		-- More drawing stuff
		LWCheckCompareButtonStatus (frame, info) -- set compare button according to inventory
		LWTooltipButtonLayout (frame, info)
		frame:Raise()
	end
end

-------------------------------------------------------------------------------------------
-- EVENTFRAME
-------------------------------------------------------------------------------------------

LinkWrangler.Startup.EventHandler1 = function(frame, event, addon)
	if event == "ADDON_LOADED" then
		if addon == "LinkWrangler" then
			-- saved variables and localization
			local retCheck = LinkWrangler.Startup.CheckSavedVariables()
			local retLocal = LinkWranglerLocal.Startup()
			LinkWrangler.SyncLocal()
			if retCheck then
				LWPrint(LWM[retCheck])
			end

			-- setup slash command handler
			SLASH_LinkWrangler1="/linkwrangler"
			SLASH_LinkWrangler2="/lw"
			if retLocal.AltSlash then
				SLASH_LinkWrangler3=retLocal.AltSlash
			end
			SlashCmdList["LinkWrangler"]=LinkWrangler.SlashHandler

			-- re-check addons that loaded before LWSAddOns became available
			for addon,_ in pairs(LinkWrangler.Startup.EarlyLoadAddOns) do
				LWSetAddOnSaved(addon)
			end

			frame:UnregisterEvent("ADDON_LOADED")
			frame:RegisterEvent("PLAYER_ENTERING_WORLD")
		end
	else -- "PLAYER_ENTERING_WORLD"
		-- Delay final setup until "PLAYER_ENTERING_WORLD" to allow Blizzard_CombatLog to load first (at "PLAYER_LOGIN")
		frame:UnregisterEvent("PLAYER_ENTERING_WORLD")

		-- setup hooks
		if LWSConfig.mode == "simple" then
			if ItemRefTooltip.ItemRefSetHyperlink then
				LWOriginalIRTSetHyperlink = ItemRefTooltip.ItemRefSetHyperlink
				ItemRefTooltip.ItemRefSetHyperlink = LinkWrangler.Startup.HookIRTSetHyperlink
			else
				LWOriginalIRTSetHyperlink = ItemRefTooltip.SetHyperlink
				ItemRefTooltip.SetHyperlink = LinkWrangler.Startup.HookIRTSetHyperlink
			end
			LWSessionMode = "simple"
			-- discard code not used by simple mode
			LWQuickActionJump = nil
			-- override settings that cannot be used in simple mode
			local function invalid()
				LWPrint(format(LWS.InvalidInMode, "simple"))
			end
			LWSlashJump["LeftButton"] = invalid
			LWSlashJump["RightButton"] = invalid
			LWSlashJump["MiddleButton"] = invalid
			LWSlashJump["allclick"] = invalid
			LWSlashClickStatus = function() end
		else
			LWOriginalSetItemRef = SetItemRef
			SetItemRef = LinkWrangler.Startup.HookSetItemRef
			LWSessionMode = "advanced"
			LWSConfig.mode = "advanced"
		end
		if LWIsNewTooltips then
			TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, LWTooltipSetItemWrapper)
			TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, LWTooltipSetSpellWrapper)
		end

		-- switch to main event handler
		frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
		frame:RegisterEvent("PLAYER_LOGOUT")
		frame:RegisterEvent("CHAT_MSG_ACHIEVEMENT")
		frame:RegisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT")
		frame:RegisterEvent("CHAT_MSG_GUILD_ITEM_LOOTED")
		--frame:RegisterEvent("CHAT_MSG_BATTLEGROUND") -- ### beta
		--frame:RegisterEvent("CHAT_MSG_BATTLEGROUND_LEADER")
		--frame:RegisterEvent("CHAT_MSG_BN_CONVERSATION")
		frame:RegisterEvent("CHAT_MSG_BN_WHISPER")
		frame:RegisterEvent("CHAT_MSG_CHANNEL")
		frame:RegisterEvent("CHAT_MSG_GUILD")
		frame:RegisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT")
		frame:RegisterEvent("CHAT_MSG_LOOT")
		frame:RegisterEvent("CHAT_MSG_OFFICER")
		frame:RegisterEvent("CHAT_MSG_PARTY")
		frame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
		frame:RegisterEvent("CHAT_MSG_RAID")
		frame:RegisterEvent("CHAT_MSG_RAID_LEADER")
		frame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT")
		frame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT_LEADER")
		frame:RegisterEvent("CHAT_MSG_SAY")
		frame:RegisterEvent("CHAT_MSG_WHISPER")
		frame:RegisterEvent("CHAT_MSG_YELL")
		frame:SetScript("OnEvent", LinkWrangler.Startup.EventHandler2)

		-- release startup code
		LinkWrangler.Startup = nil

		-- fire "gameactive" event
		LWIsGameActive = true
		LWCallbackEvent("gameactive")
	end
end

LinkWrangler.Startup.EventHandler2 = function(frame, eventname, data1, data2)
	if eventname == "UNIT_INVENTORY_CHANGED" then
		if LWInventoryHooked and data1 == "player" then
			LWCheckInventory ()
		end
	elseif eventname == "PLAYER_LOGOUT" then
		LWLogoutSaveLayout ()
		LWLogoutSaveAddOns ()
	-- at this point, event must be a chat message of some sort
	elseif LWMasterEnable and LWSButtons.whisper and data2 and #data2 > 0 and strmatch(data1, "|H") then
		-- only save lines which have a valid player name and have hyperlink escape codes
		LWChatBufferTextList[LWChatBufferIndex] = data1
		LWChatBufferNameList[LWChatBufferIndex] = data2

		-- keep count of how many strings are stored
		if LWChatBufferIndex > LWChatBufferStored then
			LWChatBufferStored = LWChatBufferIndex
		end

		LWChatBufferIndex = LWChatBufferIndex + 1
		-- reuse oldest indexes once we reach maximum size
		if (LWChatBufferIndex > LWCHATBUFFERMAX) then
			LWChatBufferIndex = 1
		end
	end
end

LinkWrangler.Startup.UpdateHandler = function(self, elapsed)
	-- Perform refresh callbacks
	for frame, info in pairs(LWTimerRefreshList) do
		LWTimerRefreshList[frame] = nil
		if info.state == 1 then
			info.refreshStatus = info.refreshStatus + 1 -- should now be an odd number
			LWCallbackRefresh(frame, info.link, info.linkType)
		end
	end

	-- Check for frames that need resizing
	for frame,info in pairs(LWTimerResizeList) do
		LWTimerResizeList[frame] = nil
		if info.minimized then
			frame:SetHeight(36)
			local titleWidth = info.titleFrame:GetStringWidth() + 36
			if LWSButtons.close then
				titleWidth = titleWidth + 22
			end
			frame:SetWidth(titleWidth)
		elseif info.state == 1 then
			if frame:GetHeight() < info.buttonHeight then
				frame:SetHeight(info.buttonHeight)
			end
		end
	end

	-- stop timer if other lists are empty
	if not next (LWTimerTimeoutList) and not next (LWTimerReloadList) then
		LWStopTimer()
		return
	end

	LWTimerTimeoutElapsed = LWTimerTimeoutElapsed + elapsed
	if LWTimerTimeoutElapsed > 2 then -- 2 second timeout
		-- close all windows in timeout list
		for frame, _ in pairs(LWTimerTimeoutList) do
			LWCloseTooltipWindow(frame, true) -- also removes from list
		end
	end

	LWTimerReloadElapsed = LWTimerReloadElapsed + elapsed
	if LWTimerReloadElapsed > .15 then -- 0.15 second delay
		-- force refresh for frames where delayed info has been received
		for frame, info in pairs(LWTimerReloadList) do
			LWTimerReloadList[frame] = nil
			if info.state == 1 then
				local refresh = info.refreshStatus + 1 -- should now be an even number
				LWReloadTooltip(frame, info)
				info.refreshStatus = refresh
			end
		end
	end
end

-- The Frame
local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", LinkWrangler.Startup.EventHandler1)
frame:SetScript("OnUpdate", LinkWrangler.Startup.UpdateHandler)
LWTimerFrame = frame
frame:Hide()
LWTimerRunning = false
frame:RegisterEvent("ADDON_LOADED")

-------------------------------------------------------------------------------------------
-- OLD STUFF
-------------------------------------------------------------------------------------------

--[[
This emulates the original Addon hook created by Fallan
This will continue to be supported for the forseeable future, for compatibility
The metatable redirects table inserts so that they get included in the real callback table
--]]
LINK_WRANGLER_CALLER = setmetatable({},{__newindex=function (t,k,v) LinkWrangler.RegisterCallback(k, v, "redirect") end})
