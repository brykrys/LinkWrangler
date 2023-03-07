-- LinkWrangler-LibExtraTip patch plugin
-- by brykrys
-- version 1.70 (previously part of LinkWranglerAuctioneer plugin)
-- release

LinkWrangler.RegisterCallback("LWLibExtraTip", function(_event)

	local function InstallLext()
		if LibStub then
			local lext = LibStub("LibExtraTip-1", true) -- silent
			if lext then
				LinkWrangler.RegisterCallback("LWLibExtraTip", function(frame)
					lext:RegisterTooltip(frame) -- Register LinkWrangler tooltips with Auctioneer's LibExtraTip library
				end, "allocate", "allocatecomp")
				InstallLext = nil
				return true
			end
		end
	end

	if InstallLext() then
		return
	end

	-- All further code uses Stubby to react to specific Load-on-Demand AddOns being loaded
	if not Stubby then
		return
	end

	-- Helper function to test if AddOn is enabled and loadable
	local TestAddOn = function(addon)
		local _, _, _, loadable, reason = GetAddOnInfo(addon)
		if not loadable then
			loadable = reason == "DEMAND_LOADED"
		end
		return loadable
	end

	-- LoadOnDemand AddOns may not have loaded yet - we have to detect them individually as they load
	local flagEnx, flagInf
	flagEnx = TestAddOn("Enchantrix")
	if flagEnx then
		Stubby.RegisterAddOnHook("Enchantrix", "LWLibExtraTip", function()
			if Enchantrix then -- check it has loaded
				Stubby.UnregisterAddOnHook("Enchantrix", "LWLibExtraTip")
				if not InstallLext or InstallLext() then
					if flagInf then
						Stubby.UnregisterAddOnHook("Informant", "LWLibExtraTip")
					end
				end
			end
		end)
	end
	flagInf = TestAddOn("Informant")
	if flagInf then
		Stubby.RegisterAddOnHook("Informant", "LWLibExtraTip", function()
			if Informant then -- check it has loaded
				Stubby.UnregisterAddOnHook("Informant", "LWLibExtraTip")
				if not InstallLext or InstallLext() then
					if flagEnx then
						Stubby.UnregisterAddOnHook("Enchantrix", "LWLibExtraTip")
					end
				end
			end
		end)
	end

end, "gameactive")
