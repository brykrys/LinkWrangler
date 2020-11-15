-- LinkWrangler Chinese zhCN

-- Localizations provided by: condywl

LinkWranglerLocal.zhCN = {

	Misc = {
		Locale = "zhCN",
		Version = "zhCN<CWDG-Condywl>v2",
	},

	Global = {
		BINDING_HEADER_LINKWRANGLER = "LinkWrangler",
		BINDING_NAME_LINKWRANGLERCLOSE = "关闭所有LW窗口",
		BINDING_NAME_LINKWRANGLERENABLE = "开启/关闭LW",
		BINDING_NAME_LINKWRANGLERMINIMIZE = "最小/最大化LW窗口",
		BINDING_NAME_LINKWRANGLERCAPTURE = "从点下鼠标后打开LW提示框",
	},

	Tooltip = {
		Minimize	= "最小化这个窗口",
		CloseMain	= "关闭这个窗口和其子窗口.\n(Shift+左键关闭所有窗口)",
		CloseComp	= "关闭这个窗口.\n(Shift+左键关闭所有窗口)",
		Compare		= "比较装备物品",
		Whisper		= "密语此物品链接发起者",
		Relink		= "重发此物品到聊天栏",
		Link		= "发链接到聊天框",
		Dressup		= "在试衣间试穿此装备",
		Capture		= "在拾取栏点击打开一个Linkwrangler窗口",
	},

	Message = {
		Enabled = "开启",
		Disabled = "关闭",
		BasicHelp = "获取帮助: \'/lw help\'. 版本: %g : %s",
		MaxWindows = "所有LinkWrangler已用尽;请关闭一个窗口再打开新链接.",
		CannotDressup = "这个物品不能被装备.",
		SavedVarsTest = "检查保存的变量值.",
		SavedVarsDefault = "保存有效参数为默认设置.",
	},

	Slash = {
		ListAddonsHead = "正使用的隶属插件:",
		ListAddonsLine = "%d. %s: 主 %s, 对比 %s",
		StatusHead = " 版本: %g : %s\n配置状态:",
		LinkTypes = "激活链接类型:",
		ClickSetting = "设置 %s:",
		InvalidOption = "有效设置: %s",
		UnknownAddon = "未知插件: %s",
		ClickStatus = "%s 已运行 :",
		ButtonsEnabled = "开启按钮 :",
		UsageGeneral = "用法: /lw %s [on|off|toggle]",

		UsageScale = "用法: /lw scale <0.2-2.5>",

		ResetCheck = "当UI重载后保存被检查过的变量值.",

		ResetSetting = "当UI重载后执行设置效果.",
		PurgeSavedVars = "清除被保存未使用的参数设置",
		HelpList = {
			"LinkWrangler设置摘要:", --[1]
			"  enable||disable||toggle - 开启|关闭|切换",
			"  status - 察看状态",
			"  list - 使用的跟随插件",
			"  addons [enable||disable||enablecomp||disablecomp <addon>] - 插件设置",
			"  help - 获取帮助",
			"  buttons [closeonly||closemin||all||[no]close||[no]minimize||[no]compare||",
			"            [no]whisper||[no]relink||[no]dressup||[no]capture] - 按钮各类设置",
			"  leftclick||rightclick||middleclick||allclick <action>=<command> - 鼠标按键设置",
			"    <action> = shift||ctrl||alt||action - 键盘动作",
			"    <command> = open||bypass||relink||dressup||openmin - 扩展命令",
			"  leftclick||rightclick||middleclick||allclick [default||disable] - 鼠标按键开关",
			"  scale <0.2-2.5> - 缩放设置",
			"  verbose [ on||off||toggle ] - 详情[开|关|切换]",
			"  savelayout [on||off||toggle ] - 保存样式[开|关|切换]",
			"  itemlinks||spelllinks||questlinks [on||off||toggle] - 物品|法术|任务链接开关",
			"  enchantlinks||talentlinks||achievementlinks [on||off|toggle] - 附魔|天赋|成就链接开关",
		},
	},
}
