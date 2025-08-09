if setfpscap then
    setfpscap(3)
end

local folderName = "Idiothub"
local configFiles = {
    ["bgsiEggs.json"] = "{}",
    ["Bubble Gum Simulator Infinity.rfld"] = [[{"AutoCompetitionQuests":false,"ShinyRatio":"0","alien-shop":[],"fishing-shop":[],"HideHatchAnim":false,"SelectMasteries":[],"GameEggPriority":false,"SellSlider":100,"AutoDiceChest":false,"Webhook":"","shard-shop":[],"UniqueEggToHatch":["Infinity Egg"],"EpicEggToHatch":["Infinity Egg"],"NormalRatio":"0","SelectTeamThe Overworld":[],"AutoChest":false,"EnchantMethod":["Gems first, get one, use reroll Orb"],"AutoMastery":false,"SelectChests":[],"Autofestival-shop":false,"AutoCartEscape":false,"SpecificRatio":"0","SelectDonateItems":[],"RareEggToHatch":["Infinity Egg"],"SelectEgg":[],"StartEnchanting":false,"SelectPotionsToUseRift10":[],"AutoPlaytime":false,"SelectPotionsToUseRift1":[],"CommonEggToHatch":["Infinity Egg"],"LegendaryEggToHatch":["Infinity Egg"],"AutoPetMatch":false,"dice-shop":[],"AutoShrine":false,"AlwaysNotifySecrets":true,"AutoGoldChest":false,"BlessingTime":1,"ShinyOnly":false,"Autodice-shop":false,"MythicEggToHatch":["Infinity Egg"],"AutoGoToRiftEggs":true,"GoldKeySlider":1,"MinigameDifficulties":["Insane"],"AutoRiftGift":false,"AutoRoyalChest":false,"SelectTiles":[],"AutoOpenEgg":false,"AutoSpinWheel":false,"DetermineBestEgg":["Mythic","Legendary","Epic","Rare","Unique","Common"],"AutoCoinsForce":false,"AutoSellBubble":false,"SelectPotionsToUseNormal":[],"Autoshard-shop":false,"traveling-merchant":[],"Autotraveling-merchant":false,"RareEggPriority":false,"AutoPotion":false,"AutoBubble":false,"SelectSellLocation":[],"MythicOnly":false,"AutoRollDice":false,"AutoFishing":true,"RenderDistance":2,"HatchAmount":[],"festival-shop":[],"AutoCoins":false,"EnabledQuestTypes":["Mythic","Shiny","SpecificRarity","SpecificEgg","Normal"],"AutoHyperDarts":false,"Autofishing-shop":false,"AutoPressE":false,"AutoRobotClaw":false,"SelectPotionsToUseRift25":[],"MythicRatio":"0","SelectMinigamesToSkipTime":[],"SelectPotionsToUseAura":[],"SelectEggRift":[],"AutoDogRun":false,"NotifyLegendary":true,"Autoalien-shop":false,"SelectedEnchants":["gleaming 1"],"ShinyMythicOnly":false,"HideTransition":true,"SelectPotionsToUseRift5":[],"AutoMysteryBox":false,"SelectTeamMinigame Paradise":[],"PreferredEggToHatch":["Infinity Egg"],"MinimumRarity":"69420","AutoClaimFreeSpin":false}]]
}
if not isfolder(folderName) then makefolder(folderName) end
for fileName, content in pairs(configFiles) do
    local filePath = folderName .. "/" .. fileName
    if not isfile(filePath) then writefile(filePath, content) end
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local remoteEvent = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network"):WaitForChild("Remote"):WaitForChild("RemoteEvent")
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local FishingAreas = require(ReplicatedStorage.Shared.Data.FishingAreas)

local LOCATION_DATA = {
	["Fisher's Island"] = { LevelReq = 1, TeleportArg = "Workspace.Worlds.Seven Seas.Areas.Fisher's Island.IslandTeleport.Spawn", FishingCFrame = CFrame.new(-23622, 9, -159) },
	["Blizzard Hills"] = { LevelReq = 3, TeleportArg = "Workspace.Worlds.Seven Seas.Areas.Blizzard Hills.IslandTeleport.Spawn", FishingCFrame = CFrame.new(-21412, 8, -101001) },
	["Poison Jungle"] = { LevelReq = 8, TeleportArg = "Workspace.Worlds.Seven Seas.Areas.Poison Jungle.IslandTeleport.Spawn", FishingCFrame = CFrame.new(-19282, 8, 18681) },
	["Infernite Volcano"] = { LevelReq = 20, TeleportArg = "Workspace.Worlds.Seven Seas.Areas.Infernite Volcano.IslandTeleport.Spawn", FishingCFrame = CFrame.new(0, 0, 0) }
}
local AREA_MAP = { starter = "Fisher's Island", blizzard = "Blizzard Hills", jungle = "Poison Jungle", lava = "Infernite Volcano" }

local function teleportToLocation(locationName)
	local locationInfo = LOCATION_DATA[locationName]
	if not locationInfo then return end
	local destination = locationInfo.FishingCFrame
	if (humanoidRootPart.Position - destination.Position).Magnitude < 20 then return end
	remoteEvent:FireServer("Teleport", locationInfo.TeleportArg)
	task.wait(1.5)
	humanoidRootPart.CFrame = destination
end

teleportToLocation("Fisher's Island")
task.wait(2)

getgenv().boardSettings = { UseGoldenDice = true, GoldenDiceDistance = 1, DiceDistance = 6, GiantDiceDistance = 10 }
getgenv().remainingItems = {} 
loadstring(game:HttpGet("https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/BGSI/main.lua"))()

task.spawn(function()
    while task.wait(2) do
        remoteEvent:FireServer("StartFishingBounty")
    end
end)

local function getNextIndexLocation(playerData)
    local collectedFish = playerData.CollectedFish or {}
    local sortedAreas = {}
    for areaName, areaData in pairs(FishingAreas) do
        local fullName = AREA_MAP[areaName] or areaName
        if LOCATION_DATA[fullName] then
            table.insert(sortedAreas, { Name = fullName, Order = areaData.DisplayOrder, Pool = areaData.Pool })
        end
    end
    table.sort(sortedAreas, function(a, b) return a.Order < b.Order end)

    for _, areaInfo in ipairs(sortedAreas) do
        for _, fishData in ipairs(areaInfo.Pool) do
            if not collectedFish[fishData.Item] then
                return areaInfo.Name
            end
        end
    end
    return nil
end

local function doLevelLogic(playerLevel)
    local highestLevel = 0
    local targetIsland = "Fisher's Island"
    for name, data in pairs(LOCATION_DATA) do
        if playerLevel >= data.LevelReq and data.LevelReq > highestLevel then
            highestLevel = data.LevelReq
            targetIsland = name
        end
    end
    teleportToLocation(targetIsland)
end

while task.wait(5) do
    local playerData = LocalData:Get()
    if not playerData then
        warn("[DEBUG] No player data found.")
        continue
    end

    local playerLevel = playerData.Level or 0
    print("[DEBUG] Player level:", playerLevel)

    if playerLevel < 20 then
        print("[DEBUG] Level under 20, running level logic...")
        doLevelLogic(playerLevel)
        continue
    end

    local activeQuest = nil
    if playerData.Quests then
        print("[DEBUG] Quests found:", playerData.Quests)
        for questId, questData in pairs(playerData.Quests) do
            local realId = questData.Id or questId
            print(string.format("[DEBUG] Checking quest: key=%s, Id=%s, DisplayName=%s", tostring(questId), tostring(realId), tostring(questData.DisplayName)))
            if realId == "sailor-bounty" or questData.DisplayName == "Old Sailor" then
                activeQuest = questData
                print("[DEBUG] Active quest detected:", realId)
                break
            end
        end
    else
        print("[DEBUG] No quests found in player data.")
    end

    if activeQuest and activeQuest.Tasks then
        print("[DEBUG] Active quest tasks:", activeQuest.Tasks)
        local teleported = false

        for idx, task in pairs(activeQuest.Tasks) do
            print(string.format("[DEBUG] Task %s: Type=%s, Area=%s", idx, tostring(task.Type), tostring(task.Area)))
            
            if task.Type == "CatchFish" and task.Area and AREA_MAP[task.Area] then
                print("[DEBUG] Teleporting to quest area:", AREA_MAP[task.Area])
                teleportToLocation(AREA_MAP[task.Area])
                teleported = true
                break
            end

            if task.Type == "CatchSpecificFish" then
                print("[DEBUG] CatchSpecificFish task detected, going to next index location.")
                local nextLoc = getNextIndexLocation(playerData)
                teleportToLocation(nextLoc or "Fisher's Island")
                teleported = true
                break
            end
        end

        if not teleported then
            print("[DEBUG] No matching quest task found, defaulting to next index location.")
            local nextLoc = getNextIndexLocation(playerData)
            teleportToLocation(nextLoc or "Fisher's Island")
        end
    else
        print("[DEBUG] No active quest detected, doing index fishing...")
        local nextLoc = getNextIndexLocation(playerData)
        teleportToLocation(nextLoc or "Fisher's Island")
    end
end
