local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))();

-- ======================================================
--  云端版本检测
-- ======================================================
local LOCAL_VERSION = "v0.1 Beta";
local UPDATE_URL = "https://your-update-server.com/rustplane/version.json";

local function checkCloudUpdate()
	local ok, raw = pcall(function()
		return game:HttpGet(UPDATE_URL);
	end);
	if not ok or not raw then return end

	local ok2, data = pcall(function()
		return game:GetService("HttpService"):JSONDecode(raw);
	end);
	if not ok2 or not data then return end

	local cloudVer = data.version;
	local forceUpdate = data.force_update or false;

	if cloudVer and cloudVer ~= LOCAL_VERSION then
		local msg = "检测到新版本 " .. cloudVer .. "，当前版本 " .. LOCAL_VERSION .. "。";
		if forceUpdate then
			msg = msg .. "此更新为强制更新。";
		end
		msg = msg .. "请前往下载最新版本。";

		task.spawn(function()
			repeat task.wait(0.1) until OrionLib and pcall(function() return OrionLib:IsRunning() end);
			OrionLib:MakeNotification({
				Name = "版本更新",
				Content = msg,
				Image = "rbxassetid://4483345998",
				Time = 10
			});
		end);
	end
end

task.spawn(checkCloudUpdate);

local Workspace = game:GetService("Workspace");
local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local LocalPlayer = Players.LocalPlayer;

-- ==============================
--  辅助函数
-- ==============================

local function safeGet(ancestor, path)
	for _, name in ipairs(path) do
		if not ancestor then return nil end
		ancestor = ancestor:FindFirstChild(name);
	end
	return ancestor;
end

local function getCharacter()
	return LocalPlayer.Character;
end

local function getRootPart()
	local char = getCharacter();
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso");
end

-- ==============================
--  角色控制器
-- ==============================

local CharacterController = {};
CharacterController.__index = CharacterController;

function CharacterController.new(TargetPlayer)
	local self = setmetatable({}, CharacterController);
	self.Player = TargetPlayer;
	return self;
end

function CharacterController:TeleportToCFrame(TargetCFrame)
	local Ok = pcall(function()
		local root = getRootPart();
		if root then
			root.CFrame = TargetCFrame + Vector3.new(0, 3, 0);
		end
	end);
	return Ok;
end

function CharacterController:TeleportToPart(TargetPart)
	if not TargetPart then return false end
	return self:TeleportToCFrame(TargetPart.CFrame);
end

function CharacterController:PerformRefuel()
	local Ok = pcall(function()
		local Plane = Workspace:FindFirstChild("Plane");
		if not Plane then return end

		local GasCan = safeGet(Plane, {"GrabGasCan", "GrabGasCan"});
		if GasCan then
			self:TeleportToPart(GasCan);
			task.wait(0.1);
			local Prompt = GasCan:FindFirstChild("GrabCan");
			if Prompt then fireproximityprompt(Prompt); end
		end

		local TempPart = Instance.new("Part");
		TempPart.CanCollide = false;
		TempPart.Transparency = 1;
		TempPart.Anchored = true;
		TempPart.CFrame = CFrame.new(0.628192008, 18.8988991, -86.9489975);
		TempPart.Parent = Workspace;

		self:TeleportToPart(TempPart);
		task.wait(0.2);

		pcall(function() TempPart:Destroy(); end);

		local FuelUpPrompt = safeGet(Plane, {"Machines", "Generator", "DumpFuel", "FuelUp"});
		if FuelUpPrompt then fireproximityprompt(FuelUpPrompt); end
	end);
	return Ok;
end

-- ==============================
--  UI 管理器
-- ==============================

local UiManager = {};
UiManager.__index = UiManager;

function UiManager.new(Title, Version)
	local self = setmetatable({}, UiManager);
	self.Window = OrionLib:MakeWindow({
		Name = Title .. " " .. Version,
		HidePremium = true,
		SaveConfig = false,
		ConfigFolder = "rustware"
	});
	return self;
end

function UiManager:Notify(Title, Text)
	OrionLib:MakeNotification({
		Name = Title,
		Content = Text,
		Image = "rbxassetid://4483345998",
		Time = 3
	});
end

-- ==============================
--  初始化
-- ==============================

local CharController = CharacterController.new(LocalPlayer);
local Interface = UiManager.new("生锈的飞机", LOCAL_VERSION);

local AutoTab = Interface.Window:MakeTab({ Name = "自动化", Icon = "rbxassetid://7733960981", PremiumOnly = false });
local ManualTab = Interface.Window:MakeTab({ Name = "手动修复", Icon = "rbxassetid://7733992789", PremiumOnly = false });
local TeleportsTab = Interface.Window:MakeTab({ Name = "传送", Icon = "rbxassetid://7733992789", PremiumOnly = false });
local ClassesTab = Interface.Window:MakeTab({ Name = "职业", Icon = "rbxassetid://7743876054", PremiumOnly = false });
local StatusTab = Interface.Window:MakeTab({ Name = "检修状态", Icon = "rbxassetid://7743876054", PremiumOnly = false });
local MiscTab = Interface.Window:MakeTab({ Name = "其他", Icon = "rbxassetid://8997386997", PremiumOnly = false });
local UpdateTab = Interface.Window:MakeTab({ Name = "更新日志", Icon = "rbxassetid://7733960981", PremiumOnly = false });
local AuthorTab = Interface.Window:MakeTab({ Name = "作者", Icon = "rbxassetid://7733960981", PremiumOnly = false });

-- ==============================
--  自动化
-- ==============================

AutoTab:AddSection({ Name = "自动功能" });

local AutoThrottleEnabled = false;
AutoTab:AddToggle({
	Name = "自动油门",
	Default = false,
	Callback = function(Value)
		AutoThrottleEnabled = Value;
		if not Value then return end

		task.spawn(function()
			while AutoThrottleEnabled do
				local Ok = pcall(function()
					local Console = safeGet(Workspace:FindFirstChild("Plane"), {"Machines", "CenterConsole"});
					if not Console then return end

					for _, name in ipairs({"ThrottlesLow", "ThrottlesMid"}) do
						local Detector = safeGet(Console, {name, "ClickTing", "ClickDetector"});
						if Detector and Detector:IsA("ClickDetector") and Detector.MaxActivationDistance > 0 then
							fireclickdetector(Detector);
						end
					end
				end);
				task.wait(0.15);
			end
		end);
	end
});

local AutoFixNavEnabled = false;
local NavConnection = nil;

AutoTab:AddToggle({
	Name = "自动修复导航",
	Default = false,
	Callback = function(Value)
		AutoFixNavEnabled = Value;

		if NavConnection then NavConnection:Disconnect(); NavConnection = nil; end
		if not Value then return end

		local Ok = pcall(function()
			local FixNav = safeGet(Workspace:FindFirstChild("Plane"), {"Machines", "NavigationVFX", "FixNav"});
			if not FixNav then return end

			NavConnection = FixNav:GetPropertyChangedSignal("Enabled"):Connect(function()
				if not AutoFixNavEnabled then return end
				if FixNav.Enabled then
					task.wait(1);
					pcall(function() ReplicatedStorage:WaitForChild("FixNav"):FireServer(); end);
				end
			end);
		end);
		if not Ok then
			Interface:Notify("错误", "自动修复导航无法初始化");
		end
	end
});

local AutoTurnEngineEnabled = false;
local EngineConnections = {};

AutoTab:AddToggle({
	Name = "自动启动引擎（鸟击修复）",
	Default = false,
	Callback = function(Value)
		AutoTurnEngineEnabled = Value;

		for _, conn in ipairs(EngineConnections) do conn:Disconnect(); end
		EngineConnections = {};
		if not Value then return end

		task.spawn(function()
			local Plane = Workspace:FindFirstChild("Plane");
			if not Plane then
				AutoTurnEngineEnabled = false;
				Interface:Notify("错误", "找不到飞机");
				return;
			end

			local Ok = pcall(function()
				local LeftButton = safeGet(Plane, {"Machines", "CenterConsole", "LeftButton"});
				local RightButton = safeGet(Plane, {"Machines", "CenterConsole", "RightButton"});
				if not LeftButton or not RightButton then return end

				local LeftDetector = LeftButton.ClickDetector;
				local RightDetector = RightButton.ClickDetector;
				if not LeftDetector or not RightDetector then return end

				table.insert(EngineConnections, LeftButton:GetPropertyChangedSignal("Material"):Connect(function()
					if AutoTurnEngineEnabled and LeftButton.Material ~= Enum.Material.Neon then
						fireclickdetector(LeftDetector);
					end
				end));

				table.insert(EngineConnections, RightButton:GetPropertyChangedSignal("Material"):Connect(function()
					if AutoTurnEngineEnabled and RightButton.Material ~= Enum.Material.Neon then
						fireclickdetector(RightDetector);
					end
				end));

				local ConditionFrame = safeGet(Plane, {"Machines", "EngineConditionMachine", "Screen2", "SurfaceGui", "Frame"});
				if ConditionFrame then
					table.insert(EngineConnections, ConditionFrame:GetPropertyChangedSignal("Visible"):Connect(function()
						if not AutoTurnEngineEnabled then return end
						if ConditionFrame.Visible then
							pcall(function() fireclickdetector(RightDetector); end);
							task.wait(0.2);
							pcall(function() fireclickdetector(LeftDetector); end);
							Interface:Notify("鸟击", "引擎已自动关闭");
						end
					end));
				end
			end);

			if Ok then
				Interface:Notify("已启用", "自动引擎启动已开启");
			else
				AutoTurnEngineEnabled = false;
				Interface:Notify("错误", "自动引擎启动初始化失败");
			end
		end);
	end
});

local SpamOxygenEnabled = false;
AutoTab:AddToggle({
	Name = "持续供氧",
	Default = false,
	Callback = function(Value)
		SpamOxygenEnabled = Value;
		if not Value then return end

		task.spawn(function()
			local AirEvent = safeGet(Workspace:FindFirstChild("Values"), {"RepumpAirEvent"});
			if not AirEvent then
				SpamOxygenEnabled = false;
				Interface:Notify("错误", "找不到供氧事件");
				return;
			end
			while SpamOxygenEnabled do
				pcall(function() AirEvent:FireServer(); end);
				task.wait(0.01);
			end
		end);
	end
});

local SpamTempEnabled = false;
AutoTab:AddToggle({
	Name = "恒温控制（22°C）",
	Default = false,
	Callback = function(Value)
		SpamTempEnabled = Value;
		if not Value then return end

		task.spawn(function()
			local TempEvent = ReplicatedStorage:FindFirstChild("ACTempChange");
			if not TempEvent then
				SpamTempEnabled = false;
				Interface:Notify("错误", "找不到温控事件");
				return;
			end
			while SpamTempEnabled do
				pcall(function()
					local Label = safeGet(Workspace:FindFirstChild("Plane"), {"Machines", "AirConditionner", "Screen", "SurfaceGui", "Frame", "TemperatureLabel"});
					if not Label then return end

					local CurrentTemp = tonumber(Label.Text:match("-?%d+"));
					if not CurrentTemp then return end

					if CurrentTemp < 22 then
						TempEvent:FireServer(true);
					elseif CurrentTemp > 22 then
						TempEvent:FireServer(false);
					end
				end);
				task.wait(0.1);
			end
		end);
	end
});

local AutoSteerEnabled = false;
local SteerConnection = nil;
AutoTab:AddToggle({
	Name = "自动转向（躲避导弹）",
	Default = false,
	Callback = function(Value)
		AutoSteerEnabled = Value;
		if SteerConnection then
			SteerConnection:Disconnect();
			SteerConnection = nil;
		end
		if not Value then return end

		local Ok = pcall(function()
			local DirectionText = safeGet(Workspace:FindFirstChild("Plane"), {"Machines", "MissileDodgerMachine", "Screen", "SurfaceGui", "Frame", "Direction"});
			local DodgeEvent = ReplicatedStorage:WaitForChild("SteeringWheelDodge");
			if not DirectionText then return end

			SteerConnection = DirectionText:GetPropertyChangedSignal("Text"):Connect(function()
				if not AutoSteerEnabled then return end
				if DirectionText.Text ~= "WAIT BEFORE STEERING" then
					DodgeEvent:FireServer(math.random() < 0.5);
					Interface:Notify("自动转向", "已躲避导弹");
				end
			end);
		end);
		if not Ok then
			Interface:Notify("错误", "自动转向初始化失败");
		end
	end
});

local AutoRefuelEnabled = false;
AutoTab:AddToggle({
	Name = "自动加油",
	Default = false,
	Callback = function(Value)
		AutoRefuelEnabled = Value;
		if not Value then return end

		task.spawn(function()
			while AutoRefuelEnabled do
				local NeedsRefuel = false;
				local Ok = pcall(function()
					local Bar = safeGet(Workspace:FindFirstChild("Plane"), {"Machines", "GasAmount", "SurfaceGui", "MainFrame", "Frame", "Bar"});
					if Bar and Bar.Size.X.Scale <= 0.45 then
						NeedsRefuel = true;
					end
				end);

				if Ok and NeedsRefuel then
					local RootPart = getRootPart();
					local OriginalCFrame = RootPart and RootPart.CFrame;
					local JerryCan = LocalPlayer.Backpack:FindFirstChild("JerryCan");

					if JerryCan then
						local char = getCharacter();
						if char then JerryCan.Parent = char; end

						task.wait(0.1);
						CharController:PerformRefuel();
						Interface:Notify("完成", "已自动加油");

						if OriginalCFrame then
							local CurRoot = getRootPart();
							if CurRoot then CurRoot.CFrame = OriginalCFrame; end
						end
					else
						local TargetGasCan = safeGet(Workspace:FindFirstChild("Plane"), {"GrabGasCan", "GrabGasCan"});
						if TargetGasCan then
							CharController:TeleportToPart(TargetGasCan);
							task.wait(0.51);
							local Prompt = TargetGasCan:FindFirstChild("GrabCan");
							if Prompt then
								pcall(function() fireproximityprompt(Prompt); end);
							end
						end
					end
				end
				task.wait(1);
			end
		end);
	end
});

local InstantHookActive = false;
local DescendantConnection = nil;

AutoTab:AddToggle({
	Name = "即时交互",
	Default = false,
	Callback = function(Value)
		InstantHookActive = Value;
		if not Value then
			if DescendantConnection then
				DescendantConnection:Disconnect();
				DescendantConnection = nil;
			end
			return;
		end

		local function applyHook(obj)
			if not obj:IsA("ProximityPrompt") then return end
			obj.HoldDuration = 0;
			if not obj:GetAttribute("InstantHooked") then
				obj:GetPropertyChangedSignal("HoldDuration"):Connect(function()
					if obj.HoldDuration ~= 0 then obj.HoldDuration = 0; end
				end);
				obj:SetAttribute("InstantHooked", true);
			end
		end

		for _, obj in ipairs(Workspace:GetDescendants()) do applyHook(obj); end
		DescendantConnection = Workspace.DescendantAdded:Connect(applyHook);
		Interface:Notify("完成", "即时交互已启用");
	end
});

-- ==============================
--  手动修复
-- ==============================

ManualTab:AddSection({ Name = "一键修复" });

ManualTab:AddButton({
	Name = "修复灯光",
	Callback = function()
		local Ok = pcall(function()
			local LightEvent = safeGet(LocalPlayer:WaitForChild("PlayerGui"), {"FixLightMinigame", "Frame", "CablesFrame", "FixLight"});
			if not LightEvent then return end
			for i = 1, 5 do
				LightEvent:FireServer("Light" .. i);
			end
			LightEvent:FireServer("LightPilot");
		end);
		if Ok then Interface:Notify("完成", "灯光已修复"); end
	end
});

ManualTab:AddButton({
	Name = "灭火",
	Callback = function()
		local FireRemote = ReplicatedStorage:FindFirstChild("FixFire");
		if not FireRemote then return end
		for i = 1, 160 do
			task.spawn(function()
				pcall(function() FireRemote:FireServer("Fire" .. i); end);
			end);
		end
		Interface:Notify("完成", "火焰已扑灭");
	end
});

ManualTab:AddButton({
	Name = "修补破洞（需要胶带）",
	Callback = function()
		local HoleRemote = ReplicatedStorage:FindFirstChild("HoleFix") or ReplicatedStorage:FindFirstChild("FixHole");
		if not HoleRemote then
			Interface:Notify("错误", "找不到修补事件");
			return;
		end

		local char = getCharacter();
		if char then
			local TapeItem = LocalPlayer.Backpack:FindFirstChild("Tape") or char:FindFirstChild("Tape");
			if TapeItem then
				TapeItem.Parent = char;
				task.wait(0.15);
			end
		end

		local isEvent = HoleRemote:IsA("RemoteEvent");
		for i = 1, 160 do
			task.spawn(function()
				pcall(function()
					if isEvent then
						HoleRemote:FireServer("Hole" .. i);
					else
						HoleRemote:InvokeServer("Hole" .. i);
					end
				end);
			end);
		end
		Interface:Notify("完成", "破洞已修补");
	end
});

ManualTab:AddButton({
	Name = "修复导航",
	Callback = function()
		pcall(function() ReplicatedStorage:WaitForChild("FixNav"):FireServer(); end);
		Interface:Notify("完成", "导航已修复");
	end
});

ManualTab:AddButton({
	Name = "修复引擎",
	Callback = function()
		task.spawn(function()
			local EngineRemote = safeGet(ReplicatedStorage, {"EngineFixEvents", "FixEngineMinigame"});
			if not EngineRemote then return end
			pcall(function() EngineRemote:FireServer(true); end);
			pcall(function() EngineRemote:FireServer(false); end);
			Interface:Notify("完成", "引擎已修复");
		end);
	end
});

ManualTab:AddButton({
	Name = "修复窗户",
	Callback = function()
		local WindowRemote = ReplicatedStorage:FindFirstChild("WindowMinigame");
		if not WindowRemote then return end
		for i = 1, 20 do
			pcall(function() WindowRemote:FireServer("Window" .. i, false); end);
		end
		Interface:Notify("完成", "窗户已修复");
	end
});

ManualTab:AddButton({
	Name = "释放诱饵弹",
	Callback = function()
		local FlareEvent = ReplicatedStorage:FindFirstChild("SteeringFlares");
		if not FlareEvent then
			Interface:Notify("错误", "找不到诱饵弹事件");
			return;
		end
		FlareEvent:FireServer();
		Interface:Notify("完成", "诱饵弹已释放");
	end
});

ManualTab:AddButton({
	Name = "获取全部工具",
	Callback = function()
		local Ok = pcall(function()
			local BuyEvent = safeGet(LocalPlayer:WaitForChild("PlayerGui"), {"Shop", "ShopFrame", "BuyItem"});
			if not BuyEvent then return end
			for _, name in ipairs({"Tape", "Screwdriver", "Mop", "PropaneTorch", "DoorStopper", "Hammer", "Wrench"}) do
				pcall(function() BuyEvent:FireServer(name, 0); end);
			end
		end);
		if Ok then Interface:Notify("完成", "全部工具已获取"); end
	end
});

-- ==============================
--  传送
-- ==============================

local function createTeleportButton(Tab, label, finder)
	Tab:AddButton({
		Name = label,
		Callback = function()
			local target = finder();
			if target then
				CharController:TeleportToPart(target);
			end
		end
	});
end

createTeleportButton(TeleportsTab, "油罐", function()
	return safeGet(Workspace:FindFirstChild("Plane"), {"GrabGasCan", "GrabGasCan"});
end);

createTeleportButton(TeleportsTab, "驾驶座", function()
	return safeGet(Workspace:FindFirstChild("Plane"), {"PilotSeat", "Seat"});
end);

createTeleportButton(TeleportsTab, "机身中部", function()
	return Workspace:FindFirstChild("Plane") and Workspace.Plane:FindFirstChild("Fuselage");
end);

createTeleportButton(TeleportsTab, "拖把（工具）", function()
	return safeGet(Workspace:FindFirstChild("Plane"), {"Tools", "Mop"});
end);

TeleportsTab:AddButton({
	Name = "发电机",
	Callback = function()
		local TempPart = Instance.new("Part");
		TempPart.CanCollide = false;
		TempPart.Transparency = 1;
		TempPart.Anchored = true;
		TempPart.CFrame = CFrame.new(0.628192008, 18.8988991, -86.9489975);
		TempPart.Parent = Workspace;

		local Ok, Err = pcall(function()
			CharController:TeleportToPart(TempPart);
			task.wait(0.5);
		end);

		pcall(function() TempPart:Destroy(); end);
	end
});

for i = 1, 3 do
	createTeleportButton(TeleportsTab, "喷气位置 " .. i, function()
		return Workspace:FindFirstChild("JetPosition" .. i);
	end);
end

-- ==============================
--  职业
-- ==============================

local ClassList = {
	{ Name = "副驾驶", Id = "CoPilot" },
	{ Name = "机长", Id = "Pilot" },
	{ Name = "电工", Id = "Electrician" },
	{ Name = "机械师", Id = "Mechanic" },
	{ Name = "焊工", Id = "Welder" },
	{ Name = "清洁工", Id = "Janitor" },
	{ Name = "杂务工", Id = "Handyman" },
	{ Name = "加油工", Id = "Pumper" },
	{ Name = "军机飞行员", Id = "Military" },
	{ Name = "退役 FMRA", Id = "FMRA" },
	{ Name = "鸟类学家", Id = "Ornithologist" },
	{ Name = "慢跑者", Id = "Jogger" },
	{ Name = "工程师", Id = "Engineer" },
	{ Name = "建筑工人", Id = "Construction" },
	{ Name = "资深技师", Id = "ExperiencedTechnician" },
	{ Name = "资深飞行员", Id = "ExperiencedPilot" },
	{ Name = "圣诞老人", Id = "Santa" },
	{ Name = "Jenkins", Id = "Jenkins" },
	{ Name = "星际飞行员", Id = "PlanetPilot" }
};

for _, info in ipairs(ClassList) do
	ClassesTab:AddButton({
		Name = info.Name,
		Callback = function()
			pcall(function()
				ReplicatedStorage:WaitForChild("GameEvent"):FireServer("Equip", info.Id);
			end);

			pcall(function()
				ReplicatedStorage:WaitForChild("GameEvent"):FireServer("BuyClass", info.Id);
			end);

			pcall(function()
				local MainEvent = safeGet(LocalPlayer:WaitForChild("PlayerGui"), {"Classes", "Frame", "MainClassEvent"});
				if not MainEvent then return end
				local event = MainEvent;
				local classId = info.Id;
				if classId == "ExperiencedTechnician" then classId = "Technician"; end
				event:FireServer("Buy", 0, classId);
				event:FireServer("Equip", 0, info.Id);
			end);

			Interface:Notify("职业", "正在切换至：" .. info.Name);
		end
	});
end

-- ==============================
--  检修状态
-- ==============================

local COLOR_GREEN = Color3.fromRGB(0, 220, 80);
local COLOR_YELLOW = Color3.fromRGB(255, 200, 0);
local COLOR_RED = Color3.fromRGB(255, 60, 60);
local COLOR_GREY = Color3.fromRGB(160, 160, 160);

local function checkEngineStatus()
	local Plane = Workspace:FindFirstChild("Plane");
	if not Plane then return "未找到飞机", COLOR_GREY end

	local ConditionFrame = safeGet(Plane, {"Machines", "EngineConditionMachine", "Screen2", "SurfaceGui", "Frame"});
	if ConditionFrame and ConditionFrame.Visible then
		return "引擎故障", COLOR_RED
	end

	local LeftButton = safeGet(Plane, {"Machines", "CenterConsole", "LeftButton"});
	local RightButton = safeGet(Plane, {"Machines", "CenterConsole", "RightButton"});
	if LeftButton and LeftButton.Material == Enum.Material.Neon
	   and RightButton and RightButton.Material == Enum.Material.Neon then
		return "运转正常", COLOR_GREEN
	end

	return "引擎关闭", COLOR_YELLOW
end

local function checkNavigationStatus()
	local FixNav = safeGet(Workspace:FindFirstChild("Plane"), {"Machines", "NavigationVFX", "FixNav"});
	if not FixNav then return "未找到组件", COLOR_GREY end

	if FixNav.Enabled then
		return "导航故障", COLOR_RED
	end

	return "导航正常", COLOR_GREEN
end

local function checkLightStatus()
	local LightFrame = safeGet(LocalPlayer.PlayerGui, {"FixLightMinigame", "Frame"});
	if not LightFrame then return "灯光正常", COLOR_GREEN end

	if LightFrame.Visible then
		return "灯光故障", COLOR_RED
	end

	return "灯光正常", COLOR_GREEN
end

local function checkFireStatus()
	local Plane = Workspace:FindFirstChild("Plane");
	if not Plane then return "未找到飞机", COLOR_GREY end

	local hasFire = false;
	for _, obj in ipairs(Plane:GetDescendants()) do
		if obj:IsA("Fire") or obj:IsA("Sparkles") or (obj:IsA("ParticleEmitter") and obj.Enabled) then
			local name = obj.Name:lower();
			if name:find("fire") or name:find("flame") or name:find("smoke") then
				hasFire = true;
				break;
			end
		end
	end

	if hasFire then
		return "发现火灾", COLOR_RED
	end

	return "无火灾", COLOR_GREEN
end

local function checkHoleStatus()
	local Plane = Workspace:FindFirstChild("Plane");
	if not Plane then return "未找到飞机", COLOR_GREY end

	local holeCount = 0;
	for _, obj in ipairs(Plane:GetDescendants()) do
		local name = obj.Name:lower();
		if name:match("^hole%d+$") and (obj:IsA("BasePart") or obj:IsA("Model")) then
			holeCount = holeCount + 1;
		end
	end

	if holeCount > 0 then
		return holeCount .. " 处破洞", COLOR_RED
	end

	return "机身完整", COLOR_GREEN
end

local function checkWindowStatus()
	local WindowMinigame = LocalPlayer.PlayerGui:FindFirstChild("WindowMinigame");
	if WindowMinigame then
		local Frame = WindowMinigame:FindFirstChild("Frame");
		if Frame and Frame.Visible then
			return "窗户破损", COLOR_RED
		end
	end

	return "窗户完好", COLOR_GREEN
end

local function checkFuelStatus()
	local Bar = safeGet(Workspace:FindFirstChild("Plane"), {"Machines", "GasAmount", "SurfaceGui", "MainFrame", "Frame", "Bar"});
	if not Bar then return "未找到仪表", COLOR_GREY end

	local fuelLevel = Bar.Size.X.Scale;
	local fuelPercent = math.floor(fuelLevel * 100);

	if fuelLevel <= 0.25 then
		return fuelPercent .. "% 不足", COLOR_RED
	elseif fuelLevel <= 0.50 then
		return fuelPercent .. "% 偏低", COLOR_YELLOW
	else
		return fuelPercent .. "% 充足", COLOR_GREEN
	end
end

local function checkTemperatureStatus()
	local Label = safeGet(Workspace:FindFirstChild("Plane"), {"Machines", "AirConditionner", "Screen", "SurfaceGui", "Frame", "TemperatureLabel"});
	if not Label then return "未找到仪表", COLOR_GREY end

	local temp = tonumber(Label.Text:match("-?%d+"));
	if not temp then return "无法读取", COLOR_GREY end

	if temp < 10 then
		return temp .. "°C 过低", COLOR_YELLOW
	elseif temp > 35 then
		return temp .. "°C 过高", COLOR_RED
	else
		return temp .. "°C 正常", COLOR_GREEN
	end
end

local function checkOxygenStatus()
	local AirEvent = safeGet(Workspace:FindFirstChild("Values"), {"RepumpAirEvent"});
	if not AirEvent then return "未找到组件", COLOR_GREY end

	return "供氧正常", COLOR_GREEN
end

-- 浮动状态面板
local StatusPanel = nil;
local StatusLabels = {};
local StatusValueLabels = {};

local function createStatusPanel()
	if StatusPanel then
		pcall(function() StatusPanel:Destroy(); end);
		StatusPanel = nil;
		StatusLabels = {};
		StatusValueLabels = {};
	end

	local Gui = Instance.new("ScreenGui");
	Gui.Name = "RustPlane_StatusPanel";
	Gui.ResetOnSpawn = false;
	Gui.Parent = LocalPlayer:WaitForChild("PlayerGui");

	local MainFrame = Instance.new("Frame");
	MainFrame.Name = "MainFrame";
	MainFrame.Size = UDim2.new(0, 200, 0, 260);
	MainFrame.Position = UDim2.new(1, -215, 0.3, 0);
	MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25);
	MainFrame.BackgroundTransparency = 0.2;
	MainFrame.BorderSizePixel = 0;
	MainFrame.Parent = Gui;

	local Corner = Instance.new("UICorner");
	Corner.CornerRadius = UDim.new(0, 8);
	Corner.Parent = MainFrame;

	local Title = Instance.new("TextLabel");
	Title.Name = "Title";
	Title.Size = UDim2.new(1, 0, 0, 30);
	Title.Position = UDim2.new(0, 0, 0, 5);
	Title.BackgroundTransparency = 1;
	Title.Font = Enum.Font.GothamBold;
	Title.TextSize = 15;
	Title.TextColor3 = Color3.fromRGB(255, 255, 255);
	Title.Text = "飞机检修状态";
	Title.Parent = MainFrame;

	local Divider = Instance.new("Frame");
	Divider.Size = UDim2.new(1, -20, 0, 1);
	Divider.Position = UDim2.new(0, 10, 0, 37);
	Divider.BackgroundColor3 = Color3.fromRGB(100, 100, 110);
	Divider.BorderSizePixel = 0;
	Divider.Parent = MainFrame;

	local items = {
		"引擎", "导航", "灯光", "火灾",
		"破洞", "窗户", "油量", "温度", "供氧"
	};

	for idx, name in ipairs(items) do
		local yPos = 40 + (idx - 1) * 24;

		local dot = Instance.new("TextLabel");
		dot.Name = "Dot_" .. name;
		dot.Size = UDim2.new(0, 16, 0, 16);
		dot.Position = UDim2.new(0, 14, 0, yPos);
		dot.BackgroundTransparency = 1;
		dot.Font = Enum.Font.GothamBold;
		dot.TextSize = 14;
		dot.Text = "●";
		dot.TextColor3 = COLOR_GREY;
		dot.Parent = MainFrame;
		table.insert(StatusLabels, dot);

		local itemLabel = Instance.new("TextLabel");
		itemLabel.Size = UDim2.new(0, 70, 0, 20);
		itemLabel.Position = UDim2.new(0, 34, 0, yPos - 1);
		itemLabel.BackgroundTransparency = 1;
		itemLabel.Font = Enum.Font.Gotham;
		itemLabel.TextSize = 13;
		itemLabel.TextColor3 = Color3.fromRGB(220, 220, 220);
		itemLabel.Text = name;
		itemLabel.TextXAlignment = Enum.TextXAlignment.Left;
		itemLabel.Parent = MainFrame;

		local valueLabel = Instance.new("TextLabel");
		valueLabel.Name = "Value_" .. name;
		valueLabel.Size = UDim2.new(0, 90, 0, 20);
		valueLabel.Position = UDim2.new(0, 105, 0, yPos - 1);
		valueLabel.BackgroundTransparency = 1;
		valueLabel.Font = Enum.Font.Gotham;
		valueLabel.TextSize = 12;
		valueLabel.TextColor3 = COLOR_GREY;
		valueLabel.Text = "检测中...";
		valueLabel.TextXAlignment = Enum.TextXAlignment.Left;
		valueLabel.Parent = MainFrame;
		table.insert(StatusValueLabels, valueLabel);
	end

	StatusPanel = Gui;
end

local function updateStatusPanel()
	local checks = {
		checkEngineStatus,
		checkNavigationStatus,
		checkLightStatus,
		checkFireStatus,
		checkHoleStatus,
		checkWindowStatus,
		checkFuelStatus,
		checkTemperatureStatus,
		checkOxygenStatus,
	};

	for i, checkFn in ipairs(checks) do
		if i > #StatusLabels or i > #StatusValueLabels then break end
		local Ok, text, color = pcall(checkFn);
		if Ok then
			if StatusLabels[i] then
				StatusLabels[i].TextColor3 = color;
			end
			if StatusValueLabels[i] then
				StatusValueLabels[i].Text = text;
				StatusValueLabels[i].TextColor3 = color;
			end
		end
	end
end

local PanelMonitorEnabled = false;

local function startPanelMonitor()
	createStatusPanel();
	PanelMonitorEnabled = true;
	task.spawn(function()
		while PanelMonitorEnabled do
			pcall(updateStatusPanel);
			task.wait(2);
		end
	end);
end

local function stopPanelMonitor()
	PanelMonitorEnabled = false;
	if StatusPanel then
		pcall(function() StatusPanel:Destroy(); end);
		StatusPanel = nil;
		StatusLabels = {};
		StatusValueLabels = {};
	end
end

StatusTab:AddSection({ Name = "状态面板" });

StatusTab:AddToggle({
	Name = "显示实时状态面板",
	Default = false,
	Callback = function(Value)
		if Value then
			startPanelMonitor();
		else
			stopPanelMonitor();
		end
	end
});

StatusTab:AddSection({ Name = "图例" });

StatusTab:AddLabel("绿色 ● = 正常");
StatusTab:AddLabel("黄色 ● = 需关注");
StatusTab:AddLabel("红色 ● = 故障");
StatusTab:AddLabel("灰色 ● = 无法检测");

StatusTab:AddSection({ Name = "说明" });

StatusTab:AddLabel("开启后屏幕右侧显示浮动面板");
StatusTab:AddLabel("面板每 2 秒自动刷新");
StatusTab:AddLabel("直接读取游戏内飞机实时数据");

-- ==============================
--  其他
-- ==============================

MiscTab:AddButton({
	Name = "获取 1 万积分",
	Callback = function()
		local Ok = pcall(function()
			local BuyItem = safeGet(LocalPlayer:WaitForChild("PlayerGui"), {"Shop", "ShopFrame", "BuyItem"});
			if BuyItem then
				BuyItem:FireServer("Mop", -10000);
			end
		end);
		if Ok then Interface:Notify("完成", "1 万积分已到账"); end
	end
});

MiscTab:AddButton({
	Name = "获取 5 万积分",
	Callback = function()
		local Ok = pcall(function()
			local BuyItem = safeGet(LocalPlayer:WaitForChild("PlayerGui"), {"Shop", "ShopFrame", "BuyItem"});
			if BuyItem then
				BuyItem:FireServer("Mop", -50000);
			end
		end);
		if Ok then Interface:Notify("完成", "5 万积分已到账"); end
	end
});

MiscTab:AddButton({
	Name = "手动加油",
	Callback = function()
		local ok = CharController:PerformRefuel();
		if ok then Interface:Notify("完成", "加油完成"); end
	end
});

-- ==============================
--  更新日志
-- ==============================

UpdateTab:AddSection({ Name = "版本信息" });

UpdateTab:AddLabel("当前版本：" .. LOCAL_VERSION);
UpdateTab:AddLabel("更新时间：2026-08-03");

UpdateTab:AddSection({ Name = "更新内容" });

UpdateTab:AddLabel("【" .. LOCAL_VERSION .. "】");
UpdateTab:AddLabel("- 新增云端版本检测，启动时自动比对");
UpdateTab:AddLabel("- 8 标签页：自动化 / 手动修复 / 传送 / 职业 / 检修状态 / 其他 / 更新日志 / 作者");
UpdateTab:AddLabel("- 全面汉化 + 中文 UI");
UpdateTab:AddLabel("- 自动化：油门 / 修复导航 / 引擎(鸟击) / 持续供氧 / 恒温控制 / 转向(躲导弹) / 加油 / 即时交互");
UpdateTab:AddLabel("- 手动修复：灯光 / 灭火 / 破洞 / 导航 / 引擎 / 窗户 / 诱饵弹 / 获取全部工具");
UpdateTab:AddLabel("- 检修状态：独立浮动面板，9 项实时检测");
UpdateTab:AddLabel("- 纯 Lua 5.1 兼容");

UpdateTab:AddSection({ Name = "检测更新" });

UpdateTab:AddButton({
	Name = "手动检测更新",
	Callback = function()
		checkCloudUpdate();
		Interface:Notify("更新检测", "检测完成，若无提示则为最新版本");
	end
});

-- ==============================
--  作者
-- ==============================

AuthorTab:AddSection({ Name = "脚本信息" });

AuthorTab:AddLabel("脚本名称：生锈的飞机");
AuthorTab:AddLabel("当前版本：" .. LOCAL_VERSION);
AuthorTab:AddLabel("适用游戏：Roblox 飞机模拟");

AuthorTab:AddSection({ Name = "联系方式" });

AuthorTab:AddLabel("如有问题或建议，请在脚本发布平台留言。");
AuthorTab:AddLabel("本脚本仅供学习交流使用，请勿用于商业用途。");

-- ==============================
--  启动
-- ==============================

Interface:Notify("生锈的飞机", "加载中……");
task.wait(0.1);
Interface:Notify("生锈的飞机", LOCAL_VERSION .. " 已准备就绪");
OrionLib:Init();
