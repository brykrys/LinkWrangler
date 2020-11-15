-- LinkWrangler zhTW

-- Localizations provided by: condywl

LinkWranglerLocal.zhTW = {

	Misc = {
		Locale = "zhTW",
		Version = "zhTW<CWDG-Condywl>v2",
	},

	Global = {
		BINDING_HEADER_LINKWRANGLER = "LinkWrangler",
		BINDING_NAME_LINKWRANGLERCLOSE = "關閉所有LW窗口",
		BINDING_NAME_LINKWRANGLERENABLE = "開啟/關閉LW",
		BINDING_NAME_LINKWRANGLERMINIMIZE = "最小/最大化LW窗口",
		BINDING_NAME_LINKWRANGLERCAPTURE = "從點下鼠標後打開LW提示框",
	},

	Tooltip = {
		Minimize	= "最小化這個窗口",
		CloseMain	= "關閉這個窗口和其子窗口.\n(Shift+左鍵關閉所有窗口)",
		CloseComp	= "關閉這個窗口.\n(Shift+左鍵關閉所有窗口)",
		Compare		= "比較裝備物品",
		Whisper		= "密語此物品鏈接發起者",
		Relink		= "重發此物品到聊天欄",
		Link		= "發鏈接到聊天框",
		Dressup		= "在試衣間試穿此裝備",
		Capture		= "在拾取欄點擊打開一個Linkwrangler窗口",
	},

	Message = {
		Enabled = "開啟",
		Disabled = "關閉",
		BasicHelp = "獲取幫助: \'/lw help\'. 版本: %g : %s",
		MaxWindows = "所有LinkWrangler已用盡;請關閉一個窗口再打開新鏈接.",
		CannotDressup = "這個物品不能被裝備.",
		SavedVarsTest = "檢查保存的變量值.",
		SavedVarsDefault = "保存有效參數為默認設置.",
	},

	Slash = {
		ListAddonsHead = "正使用的隸屬插件:",
		ListAddonsLine = "%d. %s: 主 %s, 對比 %s",
		StatusHead = " 版本: %g : %s\n配置狀態:",
		LinkTypes = "激活鏈接類型:",
		ClickSetting = "設置 %s:",
		InvalidOption = "有效設置: %s",
		UnknownAddon = "未知插件: %s",
		ClickStatus = "%s 已運行 :",
		ButtonsEnabled = "開啟按鈕 :",
		UsageGeneral = "用法: /lw %s [on|off|toggle]",

		UsageScale = "用法: /lw scale <0.2-2.5>",

		ResetCheck = "當UI重載後保存被檢查過的變量值.",

		ResetSetting = "當UI重載後執行設置效果.",
		PurgeSavedVars = "清除被保存未使用的參數設置",
		HelpList = {
			"LinkWrangler設置摘要:", --[1]
			"  enable||disable||toggle - 開啟|關閉|切換",
			"  status - 察看狀態",
			"  list - 使用的跟隨插件",
			"  addons [enable||disable||enablecomp||disablecomp <addon>] - 插件設置",
			"  help - 獲取幫助",
			"  buttons [closeonly||closemin||all||[no]close||[no]minimize||[no]compare||",
			"            [no]whisper||[no]relink||[no]dressup||[no]capture] - 按鈕各類設置",
			"  leftclick||rightclick||middleclick||allclick <action>=<command> - 鼠標按鍵設置",
			"    <action> = shift||ctrl||alt||action - 鍵盤動作",
			"    <command> = open||bypass||relink||dressup||openmin - 擴展命令",
			"  leftclick||rightclick||middleclick||allclick [default||disable] - 鼠標按鍵開關",
			"  scale <0.2-2.5> - 縮放設置",
			"  verbose [ on||off||toggle ] - 詳情[開|關|切換]",
			"  savelayout [on||off||toggle ] - 保存樣式[開|關|切換]",
			"  itemlinks||spelllinks||questlinks [on||off||toggle] - 物品|法術|任務鏈接開關",
			"  enchantlinks||talentlinks||achievementlinks [on||off|toggle] - 附魔|天賦|成就鏈接開關",
		},
	},
}
