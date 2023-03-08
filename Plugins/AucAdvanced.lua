-- LinkWrangler-AucAdvanced patch plugin
-- by brykrys
-- version 1.70 (previously part of LinkWranglerAuctioneer plugin)
-- release

-- AucAdvanced is curently only supported in Classic
if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then return end

LinkWrangler.RegisterCallback("LWAucAdvanced", function(_event)
	if not AucAdvanced then return end

	-- Install extra hooks for specific Auc-Advanced modules

	-- Declare locals to be used as upvalues in the main hook function
	local SnatchTest, AppraiserTest

	-- Flag whether to install the hook
	local doInstallHook = false

	-- Make SnatchTest
	local searchUI = AucAdvanced.GetModule("SearchUI")
	if searchUI then
		local Snatch = searchUI.Searchers.Snatch
		if Snatch then
			local function SnatchButtonHook(event, gui)
				if event == "guiconfig" then
					searchUI.RemoveCallback("LWAucAdvanced.SnatchHook", SnatchButtonHook)
					local SearchGUI = gui
					-- We use SearchUI's gui to detect when the Snatch tab is visible
					SnatchTest = function(button)
						if SearchGUI:IsShown() and SearchGUI.config.selectedTab == Snatch.tabname then
							local _, link = button:GetParent():GetItem()
							if link then
								Snatch.SetWorkingItem(link)
								return true -- chain stops here
							end
						end
					end
				end
			end
			searchUI.AddCallback("LWAucAdvanced.SnatchHook", SnatchButtonHook)
			doInstallHook = true
		end
	end

	-- Make AppraiserTest
	if AucAdvanced.GetModule("Appraiser") then
		AppraiserTest = function(button)
			local frame = AucAdvAppraiserFrame -- AucAdvAppraiserFrame is not created until first time opening AH
			if frame and frame.salebox and frame.salebox:IsVisible() then
				local _, link = button:GetParent():GetItem()
				if link then
					frame.GetItemByLink(link)
					return true -- break the chain
				end
			end
		end
		doInstallHook = true
	end

	-- Install hook
	if doInstallHook then
		local oldButtonClick = LinkWrangler.ButtonClick
		LinkWrangler.ButtonClick = function(button, ...)
			if button.ButtonType == "Relink" or button.ButtonType == "Link" then
				if SnatchTest and SnatchTest(button) then return end
				if AppraiserTest and AppraiserTest(button) then return end
			end
			return oldButtonClick(button, ...)
		end
	end

end, "gameactive")