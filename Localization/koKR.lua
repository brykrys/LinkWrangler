--[[ korean localization? Unknown source, may or may not work correctly...]]

LinkWranglerLocal.koKR = {

	Misc = {
		Locale = "koKR",
		Version = "koKR<?>v1",
	},

	Global = {
		-- Bindings (used in bindings.xml)
		BINDING_HEADER_LINKWRANGLER = "LinkWrangler",
		BINDING_NAME_LINKWRANGLERCLOSE = "모든 LinkWrangler 창 닫기",
		BINDING_NAME_LINKWRANGLERENABLE = "LinkWrangler 활성 / 비활성",
		BINDING_NAME_LINKWRANGLERMINIMIZE = "모든 LinkWrangler 창을 최소화 / 최대화",
		BINDING_NAME_LINKWRANGLERCAPTURE = "마우스 아래 아이템을 LinkWrangler 툴팁으로 열기",
	},

	Display = {
		["LeftButton"] = "왼클릭",
		["RightButton"] = "오른클릭",
		["MiddleButton"] = "휠클릭",
	},

	Tooltip = {
		Minimize	= "창을 최소화",
		CloseMain	= "창과 종속된 창을 모두 닫기.\n(Shift-Click: 모든 창을 닫기.)",
		CloseComp	= "창 닫기.\n(Shift-Click: 모든 창을 닫기)",
		Compare		= "착용중인 아이템과 비교",
		Whisper		= "링크자에게 귓속말",
		Relink		= "아이템 다시 링크",
		Link		= "아이템 링크",
		Dressup		= "아이템 미리보기",
		Capture		= "일반 Linkwrangler 창에서 열기",
	},

	Message = {
		Enabled = "활성",
		Disabled = "비활성",
		BasicHelp = "도움말: \'/lw help\'. version:",
		MaxWindows = "최대 링크 창 갯수 초과; 새 링크를 열기전에 창을 닫아주세요.",
		CannotDressup = "그 아이템은 착용 할수 없습니다.",
		SavedVarsTest = "설정값 체크",
		SavedVarsDefault = "기본 설정값으로 설정합니다.",
	},

	Slash = {
		ListAddonsHead = "AddOns 도움말:",
		ListAddonsLine = "%d. %s: 매인 %s, 비교 %s",
		StatusHead = " version: %g : %s\n설정 상태:",
		LinkTypes = "Active link types:",
		ClickSetting = "설정 %s:",
		InvalidOption = "잘못된 옵션: %s",
		UnknownAddon = "알수없는 애드온: %s",
		ClickStatus = "%s 키 수정:",
		ButtonsEnabled = "버튼 활성화 :",
		UsageGeneral = "도움말: /lw %s [on||off||toggle]",

		UsageScale = "도움말: /lw scale <0.2-2.5>",

		ResetCheck = "체크시 재시작 후 설정값이 저장됩니다.",

		ResetSetting = "재시작 후 적용 됩니다.",
		PurgeSavedVars = "설정된 저장값에서 쓰지 않는 부분 정리",
		HelpList = {
			"LinkWrangler 설정 요약:", --[1]
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
			"  scale <0.2-2.5>",
			"  verbose [on||off||toggle]",
			"  savelayout [on||off||toggle]",
			"  itemlinks||spelllinks||questlinks [on||off||toggle]",
			"  enchantlinks||talentlinks||achievementlinks [on||off|toggle]",
		},
	},

}
