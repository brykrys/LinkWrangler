-- LinkWrangler Localization setup code

-- Main Localization Global
LinkWranglerLocal = {}

--[[
LinkWrangler uses an overloading scheme:
First the Default strings are loaded
Then the localized strings for the current locale are merged,
overwriting some or all of the default strings

Will contain the following subtables

Alias :
Used to map alternative keywords to ones recognised by LinkWrangler.lua
In this table the ["key"] is localized, the value must be one of the following:

enable, disable, toggle, help, status, list, addons, allclick, buttons, verbose, savelayout
itemlinks, spelllinks, questlinks, enchantlinks, talentlinks, achievementlinks
enablecomp, disablecomp, spacing, comparestats
shift, ctrl, alt, action, relink, open, bypass, openmin
closeonly, closemin, all, close, noclose, minimize, nominimize, compare, nocompare
whisper, nowhisper, relink, norelink, dressup, nodressup, capture, nocapture
default, test, clear, purge
note capitalisation in following: LeftButton, RightButton, MiddleButton


Display :
Converts internal variables to displayable option names

Tooltip :
Popup "newbie" tooltips

Message :
Warning and informative messages

Slash:
Messages for Slash Command handler (separated out for a future project)
Note: HELP is a subtable containing a summary of slash commands

Global :
the ["keys"] in this table will be defined as global variables containing the values.
Table is deleted after loading

Misc :
Other stuff that desn't belong elsewhere, including:
	Locale : identifier for the current locale
	AltSlash : extra code for slash handler
Table is deleted after loading

--]]

LinkWranglerLocal.Startup = function (uselocale)
	local sourcetable, worktable

	sourcetable = LinkWranglerLocal
	LinkWranglerLocal = sourcetable.Default
	sourcetable.Startup = nil
	sourcetable.Default = nil

	if uselocale then
		worktable = sourcetable[uselocale]
	else
		worktable = sourcetable[GetLocale()]
	end
	if worktable then
		for name, subtable in pairs (worktable) do
			for key, value in pairs (subtable) do
				LinkWranglerLocal[name][key] = value
			end
		end
	end

	for key, value in pairs (LinkWranglerLocal.Global) do
		_G[key] = value
	end

	worktable = {"enGB"}
	for code,_ in pairs (sourcetable) do
		tinsert (worktable, code)
	end

	sourcetable = LinkWranglerLocal.Misc
	LinkWranglerLocal.Global = nil
	LinkWranglerLocal.Misc = nil
	LinkWranglerLocal.KnownLocales = worktable
	LinkWranglerLocal.Locale = sourcetable.Locale
	LinkWranglerLocal.Version = sourcetable.Version

	return sourcetable
end





