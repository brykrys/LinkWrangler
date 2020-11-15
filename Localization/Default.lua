-- LinkWrangler default localization file

-- Default strings in english language

LinkWranglerLocal.Default = {
	Misc = {
		Locale = "enGB",
		Version = "enGB(default)<brykrys>v2",
		-- AltSlash = nil,
	},

	Global = {
		-- Bindings (used in bindings.xml) - Blizzard requires these to be separate Global variables
		BINDING_HEADER_LINKWRANGLER = "LinkWrangler",
		BINDING_NAME_LINKWRANGLERCLOSE = "Close all LinkWrangler windows",
		BINDING_NAME_LINKWRANGLERENABLE = "Enable or Disable LinkWrangler",
		BINDING_NAME_LINKWRANGLERMINIMIZE = "Minimize or Maximize all LinkWrangler windows",
		BINDING_NAME_LINKWRANGLERCAPTURE = "Open LinkWrangler tooltip from item under mouse",
	},

	Alias = {
		["reset"] = "default",
		["on"] = "enable",
		["off"] = "disable",
		["minimise"] = "minimize",
		["nominimise"] = "nominimize",
		["openminimized"] = "openmin",
		["openminimised"] = "openmin",
		["bothclick"] = "allclick",
		["control"] = "ctrl",
		["nokey"] = "action",
		["nomod"] = "action",
		["recipelinks"] = "enchantlinks",
		["padding"] = "spacing",
		["compstats"] = "comparestats",

		["leftclick"] = "LeftButton",
		["leftbutton"] = "LeftButton",
		["rightclick"] = "RightButton",
		["rightbutton"] = "RightButton",
		["middleclick"] = "MiddleButton",
		["middlebutton"] = "MiddleButton",
	},

	Display = {
		["LeftButton"] = "leftclick",
		["RightButton"] = "rightclick",
		["MiddleButton"] = "middleclick",
	},

	Tooltip = {
		Minimize	= "Minimize this window",
		CloseMain	= "Close this window and its child windows.\n(Shift-Click to close all windows)",
		CloseComp	= "Close this window.\n(Shift-Click to close all windows)", -- for compare window
		Compare		= "Compare Equipped Items",
		Whisper		= "Whisper to link originator",
		Relink		= "Relink this item",
		Link		= "Link this item",
		Dressup		= "View this item in the Dressing Room",
		Capture		= "Open in a normal LinkWrangler window",
	},

	Message = {
		Enabled = "enabled",
		Disabled = "disabled",
		BasicHelp = "for help: \'/lw help\'. version: %g : %s",
		MaxWindows = "Maximum number of LinkWrangler windows reached",
		CannotDressup = "That item cannot be equipped.",
		SavedVarsTest = "Checking saved variables.",
		SavedVarsDefault = "Saved variables have been set to defaults.",
		CompStats = "Stat changes when replaced by %s:",
	},

	Slash = {
		ListAddonsHead = "Using the following AddOns:",
		ListAddonsLine = "%d. %s: main %s, compare %s",
		StatusHead = " version: %g : %s\nConfiguration status:",

		SessionMode = "Mode %s",
		ChangedMode = " (mode will change to %s on reload)",
		SettingMode = "Setting mode to %s",
		UsageSetting = "usage: /lw mode simple||advanced",
		InvalidInMode = "This setting is not available in %s mode",

		LinkTypes = "Active link types:",
		ClickSetting = "Setting %s:",
		InvalidOption = "invalid option: %s",
		UnknownAddon = "unknown AddOn: %s",
		ClickStatus = "%s actions :",
		ButtonsEnabled = "Enabled buttons :",
		UsageGeneral = "usage: /lw %s [on||off||toggle]",

		UsageScale = "usage: /lw scale <0.2-2.5>",

		UsageSpacing = "usage: /lw spacing top||bottom||left||right <0-250>",
		SpacingStatus = "Spacing: top %d, bottom %d, left %d, right %d",
		SpacingSetting = "Setting spacing on side %1$s to %2$d",

		ResetCheck = "Saved variables will be checked when UI is reloaded.",

		ResetSetting = "Setting will take effect when UI is reloaded.",
		PurgeSavedVars = "Cleaning out unused Saved Variables settings",
		HelpList = {
			"LinkWrangler options summary:", --[1]
			"  enable||disable||toggle",
			"  status",
			"  list",
			"  addons [enable||disable||enablecomp||disablecomp <addon>]",
			"  help",
			"  buttons [closeonly||closemin||all||[no]close||[no]minimize||[no]compare||",
			"            [no]whisper||[no]relink||[no]dressup||[no]capture]",
			"  leftclick||rightclick||middleclick||allclick <action>=<command>",
			"    <action> = shift||ctrl||alt||action",
			"    <command> = open||bypass||relink||dressup||openmin",
			"  leftclick||rightclick||middleclick||allclick [default||disable]",
			"  scale [<0.2-2.5>]",
			"  spacing [top||bottom||left||right <0-250>]",
			"  verbose [on||off||toggle]",
			"  savelayout [on||off||toggle]",
			"  comparestats [on||off||toggle]", -- new in version 1.87
			"  itemlinks||spelllinks||questlinks [on||off||toggle]",
			"  enchantlinks||talentlinks||achievementlinks [on||off||toggle]",
		},
	},
}