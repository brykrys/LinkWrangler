local LWIsClassic = WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE
if not LWIsClassic then
    --Only Load for WoW Classic as these shims are specifically for them.
    return
end

local eventFrame = CreateFrame("frame")

eventFrame:SetScript(
    "OnEvent",
    function(frame, event)
        --LibExtraTip is an Library for adding things to tooltips.
        local LibExtraTip = LibStub("LibExtraTip-1", true)
        if LibExtraTip then
            LinkWrangler.RegisterCallback(
                "LibExtraTip.RegisterTooltip",
                function(tip)
                    LibExtraTip:RegisterTooltip(tip)
                end,
                "allocate",
                "allocatecomp"
            )
        end

        --Auctionator: https://www.curseforge.com/wow/addons/auctionator
        if Auctionator then
            LinkWrangler.RegisterCallback("Auctionator.Tooltip.ShowTipWithPricing", Auctionator.Tooltip.ShowTipWithPricing, "item")
        end

        --Profession Master - Guild Trade Skills: https://www.curseforge.com/wow/addons/profession-master
        if ProfessionMasterAddon and TooltipService then
            LinkWrangler.RegisterCallback(
                "ProfessionMaster.TooltipService",
                function(tip)
                    TooltipService:CheckTooltip(tip)
                end,
                "refresh"
            )
        end

        --Atlas Loot Classic : https://www.curseforge.com/wow/addons/atlaslootclassic
        if AtlasLoot and AtlasLoot.Tooltip then
            LinkWrangler.RegisterCallback(
                "AtlasLoot.Tooltip",
                function(tip)
                    AtlasLoot.Tooltip:AddTooltipSource(tip:GetName())
                end,
                "allocate",
                "allocatecomp"
            )
        end

        --Gargul : https://www.curseforge.com/wow/addons/gargul
        if Gargul and Gargul.onTooltipSetItemFunc then
            LinkWrangler.RegisterCallback(
                "Gargul.onTooltipSetItemFunc",
                function(tip)
                    Gargul.onTooltipSetItemFunc(tip)
                end,
                "item"
            )
        end

        --BagSync : https://www.curseforge.com/wow/addons/bagsync
        local AceAddon = LibStub("AceAddon-3.0", true)              --Extra Checks to see if the addon is present.
        local BagSync = AceAddon and AceAddon:GetAddon("BagSync", true)          --Don't Error out if it's not there.
        local BagSync_Tooltip = BagSync and BagSync:GetModule("Tooltip", true)
        if BagSync_Tooltip then
            LinkWrangler.RegisterCallback(
                "BagSync.HookTooltip",
                function(tip)
                    BagSync_Tooltip:HookTooltip(tip)
                end,
                "allocate",
                "allocatecomp"
            )
        end

        --none of these addons should be load on demand, but just in case.
        frame:RegisterEvent("ADDON_LOADED")
    end
)

eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
