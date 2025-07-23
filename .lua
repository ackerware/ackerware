
---[ SERVICE LOADING ]---
local function getService(name)
	return game:GetService(name)
end

local Players = getService("Players")
local UserInputService = getService("UserInputService")
local RunService = getService("RunService")
local TweenService = getService("TweenService")
local CoreGui = getService("CoreGui")
local ContextActionService = getService("ContextActionService")
local Workspace = getService("Workspace")
local HttpService = getService("HttpService")
local ReplicatedStorage = getService("ReplicatedStorage")
local CollectionService = getService("CollectionService")
local Network = getService("NetworkClient") -- For bypass

---[ CAPABILITIES & CONSTANTS ]---
local Capabilities = {
	canSave = type(writefile) == "function",
	canCopy = type(setclipboard) == "function",
}

local Constants = {
	SETTINGS_FILE = "Goonerhub_Settings.json",
	SETTINGS_VERSION = "2.10", -- Updated version for auto-buy removal fix
	-- Action Names for ContextActionService
	ACTION_TOGGLE_SPEED = "Goonerhub_ToggleSpeed",
	ACTION_TOGGLE_FLY = "Goonerhub_ToggleFly",
	ACTION_TELEPORT_UP = "Goonerhub_TeleportUp",
	ACTION_TOGGLE_UI = "Goonerhub_ToggleUI",
	ACTION_INFINITE_JUMP = "Goonerhub_InfiniteJump",
	-- Animation IDs
	ANIMATION_RUN = "rbxassetid://180426354",
	-- Folder & Object Names
	FOLDER_PLOTS = "Plots",
	FOLDER_BASES = "Bases",
	FOLDER_ITEMS = "Items",
	-- Performance
	THROTTLE_INTERVAL_FAST = 5, -- e.g., for ESP distance, every 5 render frames
	BACKGROUND_LOOP_WAIT = 1, -- 1 second wait for slow updates
    -- Teleport Up Settings
    TELEPORT_UP_INCREMENT = 10, -- How much to move per step
    TELEPORT_UP_STEPS = 15,    -- How many steps to take
    TELEPORT_UP_TWEEN_TIME = 0.05, -- Time for each small tween
}

---[ LOCAL PLAYER & CAMERA ]---
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

---[ CONFIGURATION ]---
local Config = {
	Key = "6969goonerhubontop",
	DiscordLink = "https://discord.gg/VWTsQtPaac",
	Colors = {
		PrimaryBg = Color3.fromRGB(24, 24, 27),
		SecondaryBg = Color3.fromRGB(39, 39, 42),
		Accent = Color3.fromRGB(0, 150, 255),
		AccentDark = Color3.fromRGB(0, 120, 200),
		Inactive = Color3.fromRGB(55, 55, 60),
		TextPrimary = Color3.fromRGB(255, 255, 255),
		TextSecondary = Color3.fromRGB(180, 180, 180),
		Border = Color3.fromRGB(60, 60, 65),
		HighlightFill = Color3.fromRGB(255, 255, 255),
		HighlightOutline = Color3.fromRGB(255, 255, 255),
		Skeleton = Color3.fromRGB(255, 255, 255),
		Error = Color3.fromRGB(255, 60, 60),
	},
	UISize = {
		MainFrameWidth = 554,
		MainFrameHeight = 400,
		TitleBarHeight = 35,
		TabContainerWidth = 140,
		TabButtonHeight = 35,
		ElementHeight = 36,
		Padding = 15,
		SmallPadding = 3,
		CornerRadius = 12,
		SmallCornerRadius = 8,
	},
	ButtonTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	SpeedRun = { Min = 0.1, Max = 0.25, Default = 0.25 },
	InfiniteJump = { Default = 80 },
	Fly = { Min = 1, Max = 50, Default = 50 },
	InfiniteZoom = { Max = 10000 },
	DefaultWalkSpeed = 16,
	DefaultJumpPower = 50,
}

---[ STATE & UI TABLES ]---
local State = {
	isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,
	savedKey = nil,
	speedRunActive = false,
	toggleSpeedRunKey = nil,
	speedRunDistance = Config.SpeedRun.Default,
	infiniteJumpChecked = false,
	flyEnabled = false,
	flySpeed = Config.Fly.Default,
	toggleFlyKey = nil,
	toggleTeleportUpKey = nil,
	flyAttachment = nil,
	flyLinearVelocity = nil,
	flyVectorForce = nil,
	infiniteZoomEnabled = false,
	antiAfkEnabled = false,
	espEnabled = false,
	espFillEnabled = false, -- ADDED: State for the highlight fill
	espDisplayNameEnabled = false,
	espSkeletonEnabled = false,
	espBoxEnabled = false,
	espDistanceEnabled = false,
	espTracersEnabled = false,
	showBaseNamesEnabled = false,
	showBaseTimerEnabled = false,
	brainrotGodsEspEnabled = false,
	espBrainrotGodNameEnabled = false,
	highlightSecretsEnabled = false,
	espSecretNameEnabled = false,
	toggleUIKey = nil,
	highlightedPlayers = {},
	baseNameVisuals = {},
	baseTimerVisuals = {},
	highlightedBrainrotGods = {},
	highlightedSecrets = {},
	globalConnections = {},
	flyUpActive = false,
	flyDownActive = false,
	smoothDragEnabled = true,
	autoSaveEnabled = true,
	originalAnimationScript = nil,
	speedRunAnimTrack = nil,
    isTeleporting = false, -- New state for smoother teleport
}

local UI = {}
local updateAllESPVisuals
local updateAllBaseNameVisuals
local updateAllBaseTimerVisuals
local updateAllBrainrotGodVisuals
local updateAllSecretVisuals
local runMainScript

---[ UTILITY FUNCTIONS ]---
local function getPlayerCharacterAndHumanoid(p)
	local char = p and p.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	return char, humanoid
end

---[ SETTINGS MANAGEMENT ]---
local function saveSettings(forceSave)
	if not State.autoSaveEnabled and not forceSave then return end
	if not Capabilities.canSave or not HttpService then return end

	local settingsToSave = {
		version = Constants.SETTINGS_VERSION,
		savedKey = State.savedKey,
		speedRunActive = State.speedRunActive,
		toggleSpeedRunKey = State.toggleSpeedRunKey,
		speedRunDistance = State.speedRunDistance,
		infiniteJumpChecked = State.infiniteJumpChecked,
		flyEnabled = State.flyEnabled,
		flySpeed = State.flySpeed,
		toggleFlyKey = State.toggleFlyKey,
		toggleTeleportUpKey = State.toggleTeleportUpKey,
		infiniteZoomEnabled = State.infiniteZoomEnabled,
		antiAfkEnabled = State.antiAfkEnabled,
		espEnabled = State.espEnabled,
		espFillEnabled = State.espFillEnabled, -- ADDED: Save fill state
		espDisplayNameEnabled = State.espDisplayNameEnabled,
		espSkeletonEnabled = State.espSkeletonEnabled,
		espBoxEnabled = State.espBoxEnabled,
		espDistanceEnabled = State.espDistanceEnabled,
		espTracersEnabled = State.espTracersEnabled,
		showBaseNamesEnabled = State.showBaseNamesEnabled,
		showBaseTimerEnabled = State.showBaseTimerEnabled,
		brainrotGodsEspEnabled = State.brainrotGodsEspEnabled,
		espBrainrotGodNameEnabled = State.espBrainrotGodNameEnabled,
		highlightSecretsEnabled = State.highlightSecretsEnabled,
		espSecretNameEnabled = State.espSecretNameEnabled,
		toggleUIKey = State.toggleUIKey,
		smoothDragEnabled = State.smoothDragEnabled,
		autoSaveEnabled = State.autoSaveEnabled
	}

	local success, encodedData = pcall(HttpService.JSONEncode, HttpService, settingsToSave)
	if success then
		writefile(Constants.SETTINGS_FILE, encodedData)
	else
		warn("Goonerhub: Failed to encode settings.", encodedData)
	end
end

local function loadSettings()
	if not isfile or not readfile or not HttpService then return end
	if isfile(Constants.SETTINGS_FILE) then
		local success, fileContent = pcall(readfile, Constants.SETTINGS_FILE)
		if success and fileContent then
			local decodedSuccess, loadedState = pcall(HttpService.JSONDecode, HttpService, fileContent)
			if decodedSuccess then
				if loadedState.version ~= Constants.SETTINGS_VERSION then
					warn("Goonerhub: Settings file has a different version. Defaults will be used for new/missing settings.")
				end

				for key, value in pairs(loadedState) do
					State[key] = value
				end

				if State.speedRunActive and State.flyEnabled then
					warn("Goonerhub: Conflict in loaded settings. Both Speed Run and Fly were enabled. Disabling Fly.")
					State.flyEnabled = false
				end
			else
				warn("Goonerhub: Failed to decode settings file. Using defaults.", loadedState)
			end
		else
			warn("Goonerhub: Failed to read settings file. Using defaults.", fileContent)
		end
	end
end

---[ KEY SYSTEM ]---
local function createKeySystem()
	UI.keySystemGui = Instance.new("ScreenGui")
	UI.keySystemGui.Name = "KeySystemUI"
	UI.keySystemGui.ResetOnSpawn = false
	UI.keySystemGui.Parent = player:WaitForChild("PlayerGui")

	local function createKeySystemElement(className, properties)
		local element = Instance.new(className)
		for prop, value in pairs(properties) do
			element[prop] = value
		end
		return element
	end
	UI.keySystemFrame = createKeySystemElement("Frame", {
		Name = "KeySystemFrame",
		Parent = UI.keySystemGui,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 400, 0, 250),
		BackgroundColor3 = Config.Colors.SecondaryBg,
		BorderSizePixel = 0
	})
	createKeySystemElement("UICorner", { Parent = UI.keySystemFrame, CornerRadius = UDim.new(0, 12) })
	createKeySystemElement("UIStroke", { Parent = UI.keySystemFrame, Color = Config.Colors.Border, Thickness = 1.5 })

	UI.titleLabel = createKeySystemElement("TextLabel", {
		Name = "TitleLabel",
		Parent = UI.keySystemFrame,
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Config.Colors.PrimaryBg,
		Text = "Authorization Required",
		Font = Enum.Font.SourceSansBold,
		TextColor3 = Config.Colors.Accent,
		TextSize = 22,
	})
	createKeySystemElement("UICorner", { Parent = UI.titleLabel, CornerRadius = UDim.new(0, 12) })

	UI.statusLabel = createKeySystemElement("TextLabel", {
		Name = "StatusLabel",
		Parent = UI.keySystemFrame,
		Position = UDim2.new(0, 0, 0, 195),
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Text = "",
		Font = Enum.Font.SourceSans,
		TextColor3 = Config.Colors.Error,
		TextSize = 16,
	})

	UI.keyInput = createKeySystemElement("TextBox", {
		Name = "KeyInput",
		Parent = UI.keySystemFrame,
		Position = UDim2.new(0.05, 0, 0, 60),
		Size = UDim2.new(0.9, 0, 0, 40),
		BackgroundColor3 = Config.Colors.PrimaryBg,
		PlaceholderText = "Enter Key...",
		PlaceholderColor3 = Config.Colors.TextSecondary,
		Text = "",
		Font = Enum.Font.SourceSans,
		TextColor3 = Config.Colors.TextPrimary,
		TextSize = 18,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	createKeySystemElement("UICorner", { Parent = UI.keyInput, CornerRadius = UDim.new(0, 8) })
	createKeySystemElement("UIPadding", { Parent = UI.keyInput, PaddingLeft = UDim.new(0, 10) })

	UI.checkKeyButton = createKeySystemElement("TextButton", {
		Name = "CheckKeyButton",
		Parent = UI.keySystemFrame,
		Position = UDim2.new(0.05, 0, 0, 110),
		Size = UDim2.new(0.9, 0, 0, 40),
		BackgroundColor3 = Config.Colors.Accent,
		Text = "Check Key",
		Font = Enum.Font.SourceSansBold,
		TextColor3 = Config.Colors.TextPrimary,
		TextSize = 18,
	})
	createKeySystemElement("UICorner", { Parent = UI.checkKeyButton, CornerRadius = UDim.new(0, 8) })

	UI.copyDiscordButton = createKeySystemElement("TextButton", {
		Name = "CopyDiscordButton",
		Parent = UI.keySystemFrame,
		Position = UDim2.new(0.05, 0, 0, 160),
		Size = UDim2.new(0.9, 0, 0, 30),
		BackgroundColor3 = Config.Colors.Inactive,
		Text = "Copy Discord Link",
		Font = Enum.Font.SourceSansBold,
		TextColor3 = Config.Colors.TextPrimary,
		TextSize = 16,
	})
	createKeySystemElement("UICorner", { Parent = UI.copyDiscordButton, CornerRadius = UDim.new(0, 8) })

	do
		local dragging = false
		local dragStart, startPos
		local targetPosition
		local smoothingFactor = 0.08
		local dragConnection = nil
		UI.titleLabel.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = UI.keySystemFrame.Position
				targetPosition = UI.keySystemFrame.Position
				if dragConnection and dragConnection.Connected then
					dragConnection:Disconnect()
				end
				dragConnection = RunService.RenderStepped:Connect(function()
					if dragging then
						local newPos
						if State.smoothDragEnabled then
							newPos = UI.keySystemFrame.Position:Lerp(targetPosition, smoothingFactor)
						else
							newPos = targetPosition
						end
						UI.keySystemFrame.Position = newPos
					else
						if dragConnection then
							dragConnection:Disconnect()
							dragConnection = nil
						end
					end
				end)
				local inputEndedConn
				inputEndedConn = UserInputService.InputEnded:Connect(function(endInput)
					if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
						dragging = false
						if inputEndedConn and inputEndedConn.Connected then
							inputEndedConn:Disconnect()
						end
					end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				targetPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end)
	end
	local function onCheckKey()
		if UI.keyInput.Text == Config.Key then
			UI.statusLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
			UI.statusLabel.Text = "Access Granted. Loading..."
			State.savedKey = Config.Key -- Save the key
			saveSettings(true) -- Force save the settings
			task.wait(1)
			UI.keySystemGui:Destroy()
			runMainScript()
		else
			UI.statusLabel.TextColor3 = Config.Colors.Error
			UI.statusLabel.Text = "Incorrect Key. Please try again."
			local originalPos = UI.keySystemFrame.Position
			local tweenInfo = TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
			for i = 1, 5 do
				TweenService:Create(UI.keySystemFrame, tweenInfo, {Position = originalPos + UDim2.new(0, i % 2 == 0 and 10 or -10, 0, 0)}):Play()
				task.wait(0.05)
			end
			TweenService:Create(UI.keySystemFrame, tweenInfo, {Position = originalPos}):Play()
		end
	end
	local function onCopyLink()
		if Capabilities.canCopy then
			setclipboard(Config.DiscordLink)
			local originalText = UI.copyDiscordButton.Text
			UI.copyDiscordButton.Text = "Copied!"
			task.wait(2)
			UI.copyDiscordButton.Text = originalText
		else
			warn("Goonerhub: setclipboard is not available in this environment.")
			UI.statusLabel.Text = "Could not copy link."
		end
	end

	UI.checkKeyButton.MouseButton1Click:Connect(onCheckKey)
	UI.keyInput.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			onCheckKey()
		end
	end)
	UI.copyDiscordButton.MouseButton1Click:Connect(onCopyLink)
end

---[ MAIN SCRIPT EXECUTION ]---
runMainScript = function()
	local playerModule = require(player.PlayerScripts:WaitForChild("PlayerModule"))
	local controls = playerModule:GetControls()

	local isInitialCharacter = true

	---[ UI CREATION FACTORIES ]---
	local function createFrame(parent, name, size, position, bgColor, bgTransparency, cornerRadius, addStroke)
		local frame = Instance.new("Frame")
		frame.Name = name
		frame.Size = size
		if position then frame.Position = position end
		frame.BackgroundColor3 = bgColor or Config.Colors.PrimaryBg
		frame.BackgroundTransparency = bgTransparency or 0
		frame.BorderSizePixel = 0
		if cornerRadius then
			Instance.new("UICorner", frame).CornerRadius = UDim.new(0, cornerRadius)
		end
		if addStroke then
			local stroke = Instance.new("UIStroke", frame)
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Color = Config.Colors.Border
			stroke.Thickness = 1.5
			stroke.Transparency = 0.5
			stroke.Parent = frame
		end
		frame.Parent = parent
		return frame
	end
	local function createCard(parent, name, height)
		local cardHeight = height or Config.UISize.ElementHeight
		local card = createFrame(parent, name .. "Card", UDim2.new(1, -Config.UISize.SmallPadding, 0, cardHeight), nil, Config.Colors.SecondaryBg, nil, Config.UISize.SmallCornerRadius, true)
		return card
	end
	local function createTextLabel(parent, name, size, position, text, textSize, textColor, font, transparency, textXAlignment)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Size = size
		if position then label.Position = position end
		label.BackgroundTransparency = transparency or 1
		label.Text = text
		label.Font = font or Enum.Font.SourceSans
		label.TextSize = textSize
		label.TextColor3 = textColor or Config.Colors.TextPrimary
		label.TextStrokeTransparency = 1
		label.TextXAlignment = textXAlignment or Enum.TextXAlignment.Center
		if State.isMobile then label.TextScaled = true end
		label.Parent = parent
		return label
	end
	local function createButton(parent, name, size, position, text, textSize, bgColor, textColor, cornerRadius, isStateful)
		local button = Instance.new("TextButton")
		button.Name = name
		button.Size = size
		if position then button.Position = position end
		button.BackgroundColor3 = bgColor
		button.TextColor3 = textColor or Config.Colors.TextPrimary
		button.Font = Enum.Font.SourceSansBold
		button.TextSize = textSize
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Text = text
		if cornerRadius then
			Instance.new("UICorner", button).CornerRadius = UDim.new(0, cornerRadius)
		end
		if State.isMobile then button.TextScaled = true end
		if not isStateful then
			button.MouseEnter:Connect(function()
				TweenService:Create(button, Config.ButtonTweenInfo, { BackgroundColor3 = bgColor:Lerp(Color3.new(1,1,1), 0.1) }):Play()
			end)
			button.MouseLeave:Connect(function()
				TweenService:Create(button, Config.ButtonTweenInfo, { BackgroundColor3 = bgColor }):Play()
			end)
		end
		button.Parent = parent
		return button
	end
	local function createCheckbox(parent, name, labelText, initialChecked)
		local frame = createCard(parent, name .. "Group")
		local layout = Instance.new("UIListLayout", frame)
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding = UDim.new(0, Config.UISize.SmallPadding)
		local framePadding = Instance.new("UIPadding", frame)
		framePadding.PaddingLeft = UDim.new(0, 10)
		framePadding.PaddingRight = UDim.new(0, 10)
		local leftSpacer = createFrame(frame, "LeftSpacer", UDim2.new(0, 40, 1, 0), nil, nil, 1)
		leftSpacer.LayoutOrder = 1
		local label = createTextLabel(frame, "Label", UDim2.new(0, 0, 1, 0), nil, labelText, 19, Config.Colors.TextPrimary, Enum.Font.SourceSans, 1, Enum.TextXAlignment.Left)
		label.AutomaticSize = Enum.AutomaticSize.X
		label.LayoutOrder = 2
		local spacer = createFrame(frame, "Spacer", UDim2.new(1, 0, 0, 0), nil, nil, 1)
		spacer.LayoutOrder = 3
		local checkboxSize = Config.UISize.ElementHeight * 0.5
		local checkbox = createButton(frame, "Checkbox", UDim2.new(0, checkboxSize, 0, checkboxSize), nil, "", 0, initialChecked and Config.Colors.Accent or Config.Colors.Inactive, nil, Config.UISize.SmallCornerRadius, true)
		checkbox.LayoutOrder = 4
		local checkboxStroke = Instance.new("UIStroke", checkbox)
		checkboxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		checkboxStroke.Color = Config.Colors.Border
		checkboxStroke.Thickness = 1.5
		return checkbox, label
	end
	local function createSlider(parent, name, initialValue, minValue, maxValue, valueFormat, labelText, customParent, spacerScale)
		local groupParent = customParent or parent
		local group = createCard(groupParent, name .. "Group")
		local layout = Instance.new("UIListLayout", group)
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding = UDim.new(0, 10)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		local groupPadding = Instance.new("UIPadding", group)
		groupPadding.PaddingLeft = UDim.new(0, 10)
		groupPadding.PaddingRight = UDim.new(0, 10)
		local label = createTextLabel(group, "Label", UDim2.new(0, 0, 1, 0), nil, labelText, 18, Config.Colors.TextSecondary, nil, 1, Enum.TextXAlignment.Left)
		label.AutomaticSize = Enum.AutomaticSize.X
		label.LayoutOrder = 1
		local finalSpacerScale = spacerScale or 0.2
		local spacer = createFrame(group, "Spacer", UDim2.new(finalSpacerScale, 0, 1, 0), nil, nil, 1)
		spacer.LayoutOrder = 2
		local valueLabel = createTextLabel(group, "ValueLabel", UDim2.new(0, 60, 1, 0), nil, string.format(valueFormat, initialValue), 18, Config.Colors.Accent, Enum.Font.SourceSansBold, 1, Enum.TextXAlignment.Right)
		valueLabel.LayoutOrder = 3

		local sliderContainer = createFrame(group, "SliderContainer", UDim2.new(0, 120, 0, 20), nil, nil, 1)
		sliderContainer.LayoutOrder = 4

		local sliderTrack = createFrame(sliderContainer, "SliderTrack", UDim2.new(1, 0, 0, 4), UDim2.new(0, 0, 0.5, -2), Config.Colors.Inactive, nil, 5)

		local thumbSize = 16
		local thumb = createButton(sliderTrack, "SliderThumb", UDim2.new(0, thumbSize, 0, thumbSize), UDim2.new(0, 0, 0.5, -thumbSize/2), "", 0, Config.Colors.Accent, nil, nil, true)
		Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

		return group, thumb, valueLabel, sliderTrack, label
	end

	---[ UI INITIALIZATION ]---
	UI.screenGui = Instance.new("ScreenGui")
	UI.screenGui.Name = "PrivateScriptUI"
	UI.screenGui.ResetOnSpawn = false
	UI.screenGui.Parent = player:WaitForChild("PlayerGui")
	UI.screenGui.Enabled = true
	local mainFrameSize = State.isMobile and UDim2.new(0.9, 0, 0.8, 0) or UDim2.new(0, Config.UISize.MainFrameWidth, 0, Config.UISize.MainFrameHeight)
	UI.mainFrame = createFrame(UI.screenGui, "MainFrame", mainFrameSize, UDim2.new(0.5, 0, 0.5, 0), Config.Colors.PrimaryBg, nil, Config.UISize.CornerRadius, true)
	UI.mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	if State.isMobile then
		Instance.new("UIAspectRatioConstraint", UI.mainFrame).AspectRatio = Config.UISize.MainFrameWidth / Config.UISize.MainFrameHeight
	end
	UI.titleBar = createTextLabel(UI.mainFrame, "TitleBar", UDim2.new(1, 0, 0, Config.UISize.TitleBarHeight), UDim2.new(0, 0, 0, 0), "Goonerhub", 20, Config.Colors.TextPrimary, Enum.Font.SourceSansBold, nil, Enum.TextXAlignment.Left)
	local titlePadding = Instance.new("UIPadding", UI.titleBar)
	titlePadding.PaddingLeft = UDim.new(0, 15)
	UI.titleBar.BackgroundColor3 = Config.Colors.SecondaryBg
	local titleBarStroke = Instance.new("UIStroke", UI.titleBar)
	titleBarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	titleBarStroke.Color = Config.Colors.Border
	titleBarStroke.Thickness = 1.5
	titleBarStroke.Transparency = 0.7

	UI.closeButton = createButton(UI.titleBar, "CloseButton", UDim2.new(0, Config.UISize.TitleBarHeight, 0, Config.UISize.TitleBarHeight), UDim2.new(1, 0, 0, 0), "❌", 24, Color3.new(1, 1, 1), Config.Colors.TextPrimary, 6, true)
	UI.closeButton.AnchorPoint = Vector2.new(1, 0)
	UI.closeButton.ZIndex = UI.titleBar.ZIndex + 1
	UI.closeButton.BackgroundTransparency = 1
	UI.closeButton.TextScaled = false

	do
		local dragging = false
		local dragStart, startPos
		local targetPosition
		local smoothingFactor = 0.08
		local dragConnection = nil
		UI.titleBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = UI.mainFrame.Position
				targetPosition = UI.mainFrame.Position
				if dragConnection and dragConnection.Connected then
					dragConnection:Disconnect()
				end
				dragConnection = RunService.RenderStepped:Connect(function()
					if dragging then
						local newPos
						if State.smoothDragEnabled then
							newPos = UI.mainFrame.Position:Lerp(targetPosition, smoothingFactor)
						else
							newPos = targetPosition
						end
						UI.mainFrame.Position = newPos
					else
						if dragConnection then
							dragConnection:Disconnect()
							dragConnection = nil
						end
					end
				end)
				local inputEndedConn
				inputEndedConn = UserInputService.InputEnded:Connect(function(endInput)
					if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
						dragging = false
						if inputEndedConn and inputEndedConn.Connected then
							inputEndedConn:Disconnect()
						end
					end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				targetPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end)
	end
	UI.tabContainer = createFrame(UI.mainFrame, "TabContainer", UDim2.new(0, Config.UISize.TabContainerWidth, 1, -Config.UISize.TitleBarHeight), UDim2.new(0, 0, 0, Config.UISize.TitleBarHeight), Config.Colors.SecondaryBg, nil, Config.UISize.CornerRadius, true)
	local tabListLayout = Instance.new("UIListLayout", UI.tabContainer)
	tabListLayout.Padding = UDim.new(0, 10)
	tabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	local tabPadding = Instance.new("UIPadding", UI.tabContainer)
	tabPadding.PaddingTop = UDim.new(0, Config.UISize.SmallPadding)
	tabPadding.PaddingBottom = UDim.new(0, Config.UISize.SmallPadding)
	tabPadding.PaddingLeft = UDim.new(0, Config.UISize.SmallPadding)
	tabPadding.PaddingRight = UDim.new(0, Config.UISize.SmallPadding)
	UI.contentPages = createFrame(UI.mainFrame, "ContentPages", UDim2.new(1, -Config.UISize.TabContainerWidth, 1, -Config.UISize.TitleBarHeight), UDim2.new(0, Config.UISize.TabContainerWidth, 0, Config.UISize.TitleBarHeight), Config.Colors.PrimaryBg, 1)
	local contentPadding = Instance.new("UIPadding", UI.contentPages)
	contentPadding.PaddingTop = UDim.new(0, Config.UISize.Padding)
	contentPadding.PaddingBottom = UDim.new(0, Config.UISize.Padding)
	contentPadding.PaddingLeft = UDim.new(0, Config.UISize.Padding)
	contentPadding.PaddingRight = UDim.new(0, Config.UISize.Padding)
	UI.homeTabButton = createButton(UI.tabContainer, "HomeTabButton", UDim2.new(1, -Config.UISize.SmallPadding * 2, 0, Config.UISize.TabButtonHeight), nil, "Movement", 18, Config.Colors.Accent, Config.Colors.TextPrimary, Config.UISize.SmallCornerRadius, true)
	UI.espTabButton = createButton(UI.tabContainer, "ESPTabButton", UDim2.new(1, -Config.UISize.SmallPadding * 2, 0, Config.UISize.TabButtonHeight), nil, "Visual", 18, Config.Colors.Inactive, Config.Colors.TextPrimary, Config.UISize.SmallCornerRadius, true)
	UI.funTabButton = createButton(UI.tabContainer, "FunTabButton", UDim2.new(1, -Config.UISize.SmallPadding * 2, 0, Config.UISize.TabButtonHeight), nil, "Fun", 18, Config.Colors.Inactive, Config.Colors.TextPrimary, Config.UISize.SmallCornerRadius, true)
	-- Removed Auto Buy Tab Button
	UI.settingsTabButton = createButton(UI.tabContainer, "SettingsTabButton", UDim2.new(1, -Config.UISize.SmallPadding * 2, 0, Config.UISize.TabButtonHeight), nil, "Settings", 18, Config.Colors.Inactive, Config.Colors.TextPrimary, Config.UISize.SmallCornerRadius, true)

	local function createScrollingPage(name, isVisible, layoutType)
		local page = Instance.new("ScrollingFrame")
		page.Name = name
		page.Parent = UI.contentPages
		page.Size = UDim2.new(1, 0, 1, 0)
		page.BackgroundTransparency = 1
		page.BorderSizePixel = 0
		page.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 120)
		page.ScrollBarThickness = 5
		page.Visible = isVisible

		local layout
		if layoutType == "Grid" then
			layout = Instance.new("UIGridLayout", page)
			layout.CellSize = UDim2.new(0.48, 0, 0, 50)
			layout.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
			layout.SortOrder = Enum.SortOrder.LayoutOrder
		else -- Default to List
			layout = Instance.new("UIListLayout", page)
			layout.Padding = UDim.new(0, Config.UISize.Padding)
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			layout.SortOrder = Enum.SortOrder.LayoutOrder
		end

		local pagePadding = Instance.new("UIPadding")
		pagePadding.PaddingRight = UDim.new(0, 11)
		pagePadding.Parent = page

		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
		end)

		return page
	end

	UI.homePage = createScrollingPage("HomePage", true, "List")
	UI.espPage = createScrollingPage("ESPPage", false, "List")
	UI.funPage = createScrollingPage("FunPage", false, "List")
	-- Removed Auto Buy Page
	UI.settingsPage = createScrollingPage("SettingsPage", false, "List")

	---[ UI CONTENT - HOME PAGE ]---
	local combinedSpeedCard = createCard(UI.homePage, "CombinedSpeedCard", 109)
	local combinedSpeedLayout = Instance.new("UIListLayout", combinedSpeedCard)
	combinedSpeedLayout.Padding = UDim.new(0, Config.UISize.Padding)
	combinedSpeedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local combinedPadding = Instance.new("UIPadding", combinedSpeedCard)
	combinedPadding.PaddingTop = UDim.new(0.04, Config.UISize.SmallPadding)
	combinedPadding.PaddingBottom = UDim.new(0, Config.UISize.SmallPadding)
	combinedPadding.PaddingLeft = UDim.new(0, Config.UISize.SmallPadding)
	combinedPadding.PaddingRight = UDim.new(0, Config.UISize.SmallPadding)
	local speedRunKeybindGroup = createFrame(combinedSpeedCard, "SpeedRunKeybindInnerGroup", UDim2.new(1, 0, 0, Config.UISize.ElementHeight), nil, Config.Colors.SecondaryBg, 1)
	speedRunKeybindGroup.Visible = not State.isMobile
	local speedRunKeybindGroupLayout = Instance.new("UIListLayout", speedRunKeybindGroup)
	speedRunKeybindGroupLayout.FillDirection = Enum.FillDirection.Horizontal
	speedRunKeybindGroupLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	speedRunKeybindGroupLayout.Padding = UDim.new(0, 10)
	speedRunKeybindGroupLayout.SortOrder = Enum.SortOrder.LayoutOrder
	local speedRunKeybindPadding = Instance.new("UIPadding", speedRunKeybindGroup)
	speedRunKeybindPadding.PaddingLeft = UDim.new(0, 10)
	speedRunKeybindPadding.PaddingRight = UDim.new(0, 10)
	local KEYBIND_BUTTON_WIDTH = 60
	local KEYBIND_PADDING = 10
	createTextLabel(speedRunKeybindGroup, "SpeedRunKeybindLabel", UDim2.new(1, -(KEYBIND_BUTTON_WIDTH + KEYBIND_PADDING), 1, 0), nil, "Toggle Speed Run Key:", 18, Config.Colors.TextSecondary, nil, 1, Enum.TextXAlignment.Left).LayoutOrder = 1
	UI.setSpeedRunKeyButton = createButton(speedRunKeybindGroup, "SetSpeedRunKeyButton", UDim2.new(0, KEYBIND_BUTTON_WIDTH, 0.8, 0), nil, "...", 18, Config.Colors.Inactive, Config.Colors.TextPrimary, Config.UISize.SmallCornerRadius)
	UI.setSpeedRunKeyButton.LayoutOrder = 2
	local sliderGroup, thumb, valueLabel, track
	sliderGroup, thumb, valueLabel, track, _ = createSlider(combinedSpeedCard, "SpeedSlider", State.speedRunDistance, Config.SpeedRun.Min, Config.SpeedRun.Max, "%.3f", "   Speed:", combinedSpeedCard, 0.22)
	sliderGroup.BackgroundTransparency = 1
	sliderGroup.Size = UDim2.new(0.95, 0, 0, Config.UISize.ElementHeight)
	UI.sliderThumb, UI.speedValueLabel, UI.sliderTrack = thumb, valueLabel, track
	local toggleButtonGroup = createCard(UI.homePage, "ToggleButtonGroup")
	UI.toggleButton = createButton(toggleButtonGroup, "ToggleButton", UDim2.new(1, 0, 1, 0), nil, "Speed Run: OFF", 20, Config.Colors.Inactive, Config.Colors.TextPrimary, Config.UISize.SmallCornerRadius)
	local combinedFlyCard = createCard(UI.homePage, "CombinedFlyCard", 109)
	local combinedFlyLayout = Instance.new("UIListLayout", combinedFlyCard)
	combinedFlyLayout.Padding = UDim.new(0, Config.UISize.Padding)
	combinedFlyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local combinedFlyPadding = Instance.new("UIPadding", combinedFlyCard)
	combinedFlyPadding.PaddingTop = UDim.new(0.04, Config.UISize.SmallPadding)
	combinedFlyPadding.PaddingBottom = UDim.new(0, Config.UISize.SmallPadding)
	combinedFlyPadding.PaddingLeft = UDim.new(0, Config.UISize.SmallPadding)
	combinedFlyPadding.PaddingRight = UDim.new(0, Config.UISize.SmallPadding)
	local flyKeybindGroup = createFrame(combinedFlyCard, "FlyKeybindInnerGroup", UDim2.new(1, 0, 0, Config.UISize.ElementHeight), nil, Config.Colors.SecondaryBg, 1)
	flyKeybindGroup.Visible = not State.isMobile
	local flyKeybindGroupLayout = Instance.new("UIListLayout", flyKeybindGroup)
	flyKeybindGroupLayout.FillDirection = Enum.FillDirection.Horizontal
	flyKeybindGroupLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	flyKeybindGroupLayout.Padding = UDim.new(0, 10)
	flyKeybindGroupLayout.SortOrder = Enum.SortOrder.LayoutOrder
	local flyKeybindPadding = Instance.new("UIPadding", flyKeybindGroup)
	flyKeybindPadding.PaddingLeft = UDim.new(0, 10)
	flyKeybindPadding.PaddingRight = UDim.new(0, 10)
	createTextLabel(flyKeybindGroup, "FlyKeybindLabel", UDim2.new(1, -(KEYBIND_BUTTON_WIDTH + KEYBIND_PADDING), 1, 0), nil, "Toggle Fly Key:", 18, Config.Colors.TextSecondary, nil, 1, Enum.TextXAlignment.Left).LayoutOrder = 1
	UI.setFlyKeyButton = createButton(flyKeybindGroup, "SetFlyKeyButton", UDim2.new(0, KEYBIND_BUTTON_WIDTH, 0.8, 0), nil, "...", 18, Config.Colors.Inactive, Config.Colors.TextPrimary, Config.UISize.SmallCornerRadius)
	UI.setFlyKeyButton.LayoutOrder = 2
	local flySliderGroup, flyThumb, flyValueLabel, flyTrack
	flySliderGroup, flyThumb, flyValueLabel, flyTrack, _ = createSlider(combinedFlyCard, "FlySpeedSlider", State.flySpeed, Config.Fly.Min, Config.Fly.Max, "%.1f", "   Fly Speed:", combinedFlyCard, 0.15)
	flySliderGroup.BackgroundTransparency = 1
	flySliderGroup.Size = UDim2.new(0.95, 0, 0, Config.UISize.ElementHeight)
	UI.flySliderThumb, UI.flySpeedValueLabel, UI.flySliderTrack = flyThumb, valueLabel, flyTrack
	local flyToggleButtonGroup = createCard(UI.homePage, "FlyToggleButtonGroup")
	UI.flyToggleButton = createButton(flyToggleButtonGroup, "FlyToggleButton", UDim2.new(1, 0, 1, 0), nil, "Fly: OFF", 20, Config.Colors.Inactive, Config.Colors.TextPrimary, Config.UISize.SmallCornerRadius)

	-- Teleport Up UI elements are now hidden
	local teleportUpCard = createFrame(UI.homePage, "TeleportUpCard", UDim2.new(1, -Config.UISize.SmallPadding, 0, 0), nil, Config.Colors.SecondaryBg, nil, Config.UISize.SmallCornerRadius, true)
	teleportUpCard.AutomaticSize = Enum.AutomaticSize.Y
    teleportUpCard.Visible = false -- Hide the entire card
	local teleportUpLayout = Instance.new("UIListLayout", teleportUpCard)
	teleportUpLayout.Padding = UDim.new(0, Config.UISize.SmallPadding)
	teleportUpLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	teleportUpLayout.SortOrder = Enum.SortOrder.LayoutOrder
	local teleportUpPadding = Instance.new("UIPadding", teleportUpCard)
	teleportUpPadding.PaddingTop = UDim.new(0, Config.UISize.SmallPadding)
	teleportUpPadding.PaddingBottom = UDim.new(0, Config.UISize.SmallPadding)
	teleportUpPadding.PaddingLeft = UDim.new(0, Config.UISize.SmallPadding)
	teleportUpPadding.PaddingRight = UDim.new(0, Config.UISize.SmallPadding)
	local teleportUpKeybindGroup = createFrame(teleportUpCard, "TeleportUpKeybindInnerGroup", UDim2.new(1, 0, 0, Config.UISize.ElementHeight), nil, Config.Colors.SecondaryBg, 1)
	teleportUpKeybindGroup.Visible = false -- Hide keybind group
	teleportUpKeybindGroup.LayoutOrder = 1
	local teleportUpKeybindGroupLayout = Instance.new("UIListLayout", teleportUpKeybindGroup)
	teleportUpKeybindGroupLayout.FillDirection = Enum.FillDirection.Horizontal
	teleportUpKeybindGroupLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	teleportUpKeybindGroupLayout.Padding = UDim.new(0, 10)
	teleportUpKeybindGroupLayout.SortOrder = Enum.SortOrder.LayoutOrder
	local teleportUpKeybindPadding = Instance.new("UIPadding", teleportUpKeybindGroup)
	teleportUpKeybindPadding.PaddingLeft = UDim.new(0, 10)
	teleportUpKeybindPadding.PaddingRight = UDim.new(0, 10)
	createTextLabel(teleportUpKeybindGroup, "TeleportUpKeybindLabel", UDim2.new(1, -(KEYBIND_BUTTON_WIDTH + KEYBIND_PADDING), 1, 0), nil, "Teleport Up Key:", 18, Config.Colors.TextSecondary, nil, 1, Enum.TextXAlignment.Left).LayoutOrder = 1
	UI.setTeleportUpKeyButton = createButton(teleportUpKeybindGroup, "SetTeleportUpKeyButton", UDim2.new(0, KEYBIND_BUTTON_WIDTH, 0.8, 0), nil, "...", 18, Config.Colors.Inactive, Config.Colors.TextPrimary, Config.UISize.SmallCornerRadius)
	UI.setTeleportUpKeyButton.LayoutOrder = 2
	local teleportUpButtonGroup = createFrame(UI.homePage, "TeleportUpButtonGroup", UDim2.new(1, -Config.UISize.SmallPadding, 0, Config.UISize.ElementHeight), nil, nil, 1)
	teleportUpButtonGroup.BackgroundTransparency = 1
    teleportUpButtonGroup.Visible = false -- Hide button group
	UI.teleportUpButton = createButton(teleportUpButtonGroup, "TeleportUpButton", UDim2.new(1, 0, 1, 0), nil, "Teleport Up", 20, Config.Colors.Inactive, Config.Colors.TextPrimary, Config.UISize.SmallCornerRadius)

	---[ UI CONTENT - ESP PAGE ]---
	local playerEspTitle = createTextLabel(UI.espPage, "PlayerEspTitle", UDim2.new(1, 0, 0, 30), nil, "Player ESP", 22, Config.Colors.TextPrimary, Enum.Font.SourceSansBold, 1, Enum.TextXAlignment.Left)
	playerEspTitle.LayoutOrder = 1
	local playerEspPadding = Instance.new("UIPadding", playerEspTitle)
	playerEspPadding.PaddingLeft = UDim.new(0, 2)

	UI.espEnableCheckbox, _ = createCheckbox(UI.espPage, "ESPEnable", "  Highlight Players", State.espEnabled)
	UI.espEnableCheckbox.Parent.LayoutOrder = 2

	UI.espFillCheckbox, _ = createCheckbox(UI.espPage, "ESPFill", "  Fill", State.espFillEnabled)
	UI.espFillCheckbox.Parent.LayoutOrder = 3

	UI.espDisplayNameCheckbox, _ = createCheckbox(UI.espPage, "ESPDisplayName", "  Show Display Names", State.espDisplayNameEnabled)
	UI.espDisplayNameCheckbox.Parent.LayoutOrder = 4
	UI.espDistanceCheckbox, _ = createCheckbox(UI.espPage, "ESPDistance", "  Show Distance", State.espDistanceEnabled)
	UI.espDistanceCheckbox.Parent.LayoutOrder = 5
	UI.espSkeletonCheckbox, _ = createCheckbox(UI.espPage, "ESPSkeleton", "  Show Body Dots", State.espSkeletonEnabled)
	UI.espSkeletonCheckbox.Parent.LayoutOrder = 6
	UI.espBoxCheckbox, _ = createCheckbox(UI.espPage, "ESPBox", "  Show Boxes", State.espBoxEnabled)
	UI.espBoxCheckbox.Parent.LayoutOrder = 7
	UI.espTracersCheckbox, _ = createCheckbox(UI.espPage, "ESPTracers", "  Show Tracers", State.espTracersEnabled)
	UI.espTracersCheckbox.Parent.LayoutOrder = 8

	local baseEspTitle = createTextLabel(UI.espPage, "BaseEspTitle", UDim2.new(1, 0, 0, 30), nil, "Base ESP", 22, Config.Colors.TextPrimary, Enum.Font.SourceSansBold, 1, Enum.TextXAlignment.Left)
	baseEspTitle.LayoutOrder = 9
	local baseEspPadding = Instance.new("UIPadding", baseEspTitle)
	baseEspPadding.PaddingLeft = UDim.new(0, 2)

	UI.showBaseNamesCheckbox, _ = createCheckbox(UI.espPage, "ShowBaseNames", "  Show Base Names", State.showBaseNamesEnabled)
	UI.showBaseNamesCheckbox.Parent.LayoutOrder = 10
	UI.showBaseTimerCheckbox, _ = createCheckbox(UI.espPage, "ShowBaseTimer", "  Show Base Timer", State.showBaseTimerEnabled)
	UI.showBaseTimerCheckbox.Parent.LayoutOrder = 11

	local brainrotTitle = createTextLabel(UI.espPage, "BrainrotTitle", UDim2.new(1, 0, 0, 30), nil, "Brainrot ESP", 22, Config.Colors.TextPrimary, Enum.Font.SourceSansBold, 1, Enum.TextXAlignment.Left)
	brainrotTitle.LayoutOrder = 12
	local brainrotPadding = Instance.new("UIPadding", brainrotTitle)
	brainrotPadding.PaddingLeft = UDim.new(0, 2)

	UI.brainrotGodsEspCheckbox, _ = createCheckbox(UI.espPage, "BrainrotGodsEsp", "  Highlight Brainrot Gods", State.brainrotGodsEspEnabled)
	UI.brainrotGodsEspCheckbox.Parent.LayoutOrder = 13
	UI.espBrainrotGodNameCheckbox, _ = createCheckbox(UI.espPage, "ESPBrainrotGodName", "  Show God Names", State.espBrainrotGodNameEnabled)
	UI.espBrainrotGodNameCheckbox.Parent.LayoutOrder = 14

	UI.highlightSecretsCheckbox, _ = createCheckbox(UI.espPage, "HighlightSecrets", "  Highlight Secrets", State.highlightSecretsEnabled)
	UI.highlightSecretsCheckbox.Parent.LayoutOrder = 15
	UI.espSecretNameCheckbox, _ = createCheckbox(UI.espPage, "ESPSecretName", "  Show Secret Names", State.espSecretNameEnabled)
	UI.espSecretNameCheckbox.Parent.LayoutOrder = 16

	---[ UI CONTENT - FUN PAGE ]---
	UI.ijCheckbox, _ = createCheckbox(UI.funPage, "InfiniteJump", "  Infinite Jump", State.infiniteJumpChecked)
	UI.infiniteZoomCheckbox, _ = createCheckbox(UI.funPage, "InfiniteZoom", "  Infinite Camera Zoom", State.infiniteZoomEnabled)
	UI.antiAfkCheckbox, _ = createCheckbox(UI.funPage, "AntiAFK", "  Anti-AFK", State.antiAfkEnabled)
	UI.forceResetButton = createButton(UI.funPage, "ForceResetButton", UDim2.new(1, -Config.UISize.SmallPadding, 0, Config.UISize.ElementHeight), nil, "Force Reset Character", 20, Config.Colors.Error, Config.Colors.TextPrimary, Config.UISize.SmallCornerRadius)

	---[ UI CONTENT - SETTINGS PAGE ]---
	local uiKeybindGroup = createCard(UI.settingsPage, "UIKeybindGroup")
	uiKeybindGroup.Visible = not State.isMobile
	local uiKeybindGroupLayout = Instance.new("UIListLayout", uiKeybindGroup)
	uiKeybindGroupLayout.FillDirection = Enum.FillDirection.Horizontal
	uiKeybindGroupLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	uiKeybindGroupLayout.Padding = UDim.new(0, KEYBIND_PADDING)
	uiKeybindGroupLayout.SortOrder = Enum.SortOrder.LayoutOrder
	local uiKeybindPadding = Instance.new("UIPadding", uiKeybindGroup)
	uiKeybindPadding.PaddingLeft = UDim.new(0, 10)
	uiKeybindPadding.PaddingRight = UDim.new(0, 10)
	createTextLabel(uiKeybindGroup, "UIKeybindLabel", UDim2.new(1, -(KEYBIND_BUTTON_WIDTH + KEYBIND_PADDING), 1, 0), nil, "Toggle UI Key:", 18, Config.Colors.TextSecondary, nil, 1, Enum.TextXAlignment.Left).LayoutOrder = 1
	UI.uiKeybindButton = createButton(uiKeybindGroup, "UIKeybindButton", UDim2.new(0, KEYBIND_BUTTON_WIDTH, 0.8, 0), nil, "...", 18, Config.Colors.Inactive, Config.Colors.TextPrimary, Config.UISize.SmallCornerRadius)
	UI.uiKeybindButton.LayoutOrder = 2
	local closeButtonGroup = createCard(UI.settingsPage, "CloseButtonGroup")
	UI.closeUIButton = createButton(closeButtonGroup, "CloseUIButton", UDim2.new(1, 0, 1, 0), nil, "Hide UI", 20, Config.Colors.Error, Config.Colors.TextPrimary, Config.UISize.SmallCornerRadius)
	UI.smoothDragCheckbox, _ = createCheckbox(UI.settingsPage, "SmoothDrag", "  Smooth UI Dragging", State.smoothDragEnabled)
	UI.autoSaveCheckbox, _ = createCheckbox(UI.settingsPage, "AutoSave", "  Auto-Save Settings", State.autoSaveEnabled)

	---[ UI CONTENT - MOBILE ]---
	UI.mobileToggleButton = createButton(UI.screenGui, "MobileToggleButton", UDim2.new(0, 150, 0, 45), UDim2.new(0.5, -75, 0, Config.UISize.Padding), "Goonerhub GUI", 20, Config.Colors.Accent, Config.Colors.TextPrimary, Config.UISize.CornerRadius)

	UI.mobileToggleButton.Visible = false
	UI.mobileToggleButton.ZIndex = 10
	UI.mobileToggleButton.TextWrapped = true
	local mobileButtonStroke = Instance.new("UIStroke", UI.mobileToggleButton)
	mobileButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	mobileButtonStroke.Color = Config.Colors.Border
	mobileButtonStroke.Thickness = 1.5
	mobileButtonStroke.Transparency = 0.5

	do
		local dragging = false
		local dragStart, startPos
		local dragThreshold = 5

		UI.mobileToggleButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = UI.mobileToggleButton.Position
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)

				if State.smoothDragEnabled then
					TweenService:Create(UI.mobileToggleButton, TweenInfo.new(0.08), {Position = newPos}):Play()
				else
					UI.mobileToggleButton.Position = newPos
				end
			end
		end)

		UI.mobileToggleButton.InputEnded:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
				if (input.Position - dragStart).Magnitude < dragThreshold then
					UI.mainFrame.Visible = true
					UI.mobileToggleButton.Visible = false
					if State.isMobile and UI.mobileControlsFrame then
						UI.mobileControlsFrame.Visible = true
					end
				end
				dragging = false
			end
		end)
	end

	local updateSpeedRunState
	local updateFlyToggleButton
	local toggleSpeedRun
	local toggleFly
	local handleTeleportToggle

	if State.isMobile then
		UI.mobileControlsFrame = createFrame(UI.screenGui, "MobileControlsFrame", UDim2.new(1, 0, 0, 80), UDim2.new(0, 0, 1, -80), nil, 1)
		UI.mobileControlsFrame.ZIndex = 10

		local buttonWidth = UDim2.new(0.2, 0, 0.8, 0)
		local mobileSpeedButton = createButton(UI.mobileControlsFrame, "MobileSpeedButton", buttonWidth, UDim2.new(0.05, 0, 0.1, 0), "Speed", 18, Config.Colors.Inactive, Config.Colors.TextPrimary, Config.UISize.CornerRadius)
		local mobileFlyButton = createButton(UI.mobileControlsFrame, "MobileFlyButton", buttonWidth, UDim2.new(0.27, 0, 0.1, 0), "Fly", 18, Config.Colors.Inactive, Config.Colors.TextPrimary, Config.UISize.CornerRadius)
		local mobileTeleportButton = createButton(UI.mobileControlsFrame, "MobileTeleportButton", buttonWidth, UDim2.new(0.49, 0, 0.1, 0), "Teleport", 18, Config.Colors.Accent, Config.Colors.TextPrimary, Config.UISize.CornerRadius)
		local mobileFlyUpButton = createButton(UI.mobileControlsFrame, "MobileFlyUpButton", buttonWidth, UDim2.new(0.71, 0, 0.1, 0), "Up", 18, Config.Colors.Accent, Config.Colors.TextPrimary, Config.UISize.CornerRadius)
		local mobileFlyDownButton = createButton(UI.mobileControlsFrame, "MobileFlyDownButton", buttonWidth, UDim2.new(0.71, 0, 0.1, 0), "Down", 18, Config.Colors.Accent, Config.Colors.TextPrimary, Config.UISize.CornerRadius)

		mobileFlyUpButton.Visible = false
		mobileFlyDownButton.Visible = false

		local function updateMobileButtons()
			TweenService:Create(mobileSpeedButton, Config.ButtonTweenInfo, { BackgroundColor3 = State.speedRunActive and Config.Colors.Accent or Config.Colors.Inactive }):Play()
			TweenService:Create(mobileFlyButton, Config.ButtonTweenInfo, { BackgroundColor3 = State.flyEnabled and Config.Colors.Accent or Config.Colors.Inactive }):Play()
			mobileFlyUpButton.Visible = State.flyEnabled
			mobileFlyDownButton.Visible = State.flyEnabled
			if State.flyEnabled then
				mobileTeleportButton.Position = UDim2.new(0.49, 0, 0.1, 0)
				mobileFlyUpButton.Position = UDim2.new(0.71, 0, 0.1, 0)
				mobileFlyDownButton.Position = UDim2.new(0.71, 0, 0.1, 0)
			else
				mobileTeleportButton.Position = UDim2.new(0.49, 0, 0.1, 0)
			end
		end

		mobileSpeedButton.MouseButton1Click:Connect(function() toggleSpeedRun(); updateMobileButtons() end)
		mobileFlyButton.MouseButton1Click:Connect(function() toggleFly(); updateMobileButtons() end)
		mobileTeleportButton.MouseButton1Click:Connect(function() handleTeleportToggle() end)
		mobileFlyUpButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then State.flyUpActive = true end end)
		mobileFlyUpButton.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then State.flyUpActive = false end end)
		mobileFlyDownButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then State.flyDownActive = true end end)
		mobileFlyDownButton.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then State.flyDownActive = false end end)
	end

	---[ ANTI-CHEAT BYPASS & MOVEMENT ENHANCEMENTS ]---

    --[[
        hookmetamethod Utility:
        This function attempts to hook a metamethod of an object.
        NOTE: In standard Roblox Luau, 'debug.getmetatable' and 'debug.setmetatable'
        are typically restricted for security reasons. This utility is provided
        conceptually as requested, assuming a privileged execution environment
        (e.g., an exploit) where such functions might be available).
        It will not work in a regular Roblox script.
    ]]
    local function hookmetamethod(obj, metamethodName, hookFunction)
        local originalMetatable = getmetatable(obj)
        if not originalMetatable then
            warn("Goonerhub Hook: Object does not have a metatable.")
            return nil
        end

        local originalMetamethod = originalMetatable[metamethodName]
        if not originalMetamethod then
            warn("Goonerhub Hook: Metamethod '" .. metamethodName .. "' not found.")
            return nil
        end

        local newMetatable = {}
        for k, v in pairs(originalMetatable) do
            newMetatable[k] = v
        end

        setmetatable(obj, newMetatable)
        return originalMetamethod
    end

    -- Conceptual hooks for fly anti-detection:
    -- These hooks are illustrative and would only function in a privileged environment.
    -- Their effectiveness depends on the specific anti-cheat mechanisms in the game.
    local function setupFlyHooks()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        -- Attempt to hook __namecall for any RemoteEvent/RemoteFunction in ReplicatedStorage
        -- This is a very broad hook and might interfere with legitimate game functions.
        -- In a real scenario, you'd target specific remotes known to be used for anti-cheat.
        for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                pcall(function() -- Use pcall as hookmetamethod might fail
                    hookmetamethod(obj, "__namecall", function(original, self, method, ...)
                        -- You could add logic here to filter or modify arguments
                        -- For example, if 'method' is related to 'fly_detection' or 'movement_check'
                        -- print("Goonerhub Fly Hook: Remote Call:", self.Name, method, ...)
                        return original(self, method, ...)
                    end)
                end)
            end
        end

        -- More specific potential hooks (highly speculative without game-specific knowledge):
        -- Hooking HumanoidRootPart's CFrame changes (if anti-cheat checks this directly)
        -- This is generally not recommended as it can break game physics.
        -- local originalCFrameSetter = hookmetamethod(player.Character.HumanoidRootPart, "__newindex", function(original, self, key, value)
        --     if key == "CFrame" then
        --         -- Potentially modify 'value' or suppress the write
        --         -- print("Goonerhub Fly Hook: HRP CFrame set attempted!")
        --     end
        --     return original(self, key, value)
        -- end)
    end

    -- Call setupFlyHooks when the main script runs (assuming privileged environment)
    setupFlyHooks()


	local teleportStateUp = true
    local currentTeleportTween = nil

	handleTeleportToggle = function()
		local char, _ = getPlayerCharacterAndHumanoid(player)
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp or State.isTeleporting then return end

        State.isTeleporting = true
        local startCFrame = hrp.CFrame -- Capture the actual starting CFrame for the entire sequence

        local totalMoveVector
        if teleportStateUp then
            totalMoveVector = Vector3.new(0, Constants.TELEPORT_UP_INCREMENT * Constants.TELEPORT_UP_STEPS, 0)
            -- UI.teleportUpButton.Text = "Teleport Down" -- Hidden UI
        else
            totalMoveVector = Vector3.new(0, -(Constants.TELEPORT_UP_INCREMENT * Constants.TELEPORT_UP_STEPS), 0)
            -- UI.teleportUpButton.Text = "Teleport Up" -- Hidden UI
        end

        local targetCFrameOverall = startCFrame * CFrame.new(totalMoveVector) -- Calculate the final target CFrame

        local function performTweenStep(currentStep)
            if not hrp or not hrp.Parent then
                State.isTeleporting = false
                return
            end

            -- Calculate the target CFrame for this specific step using Lerp
            local alpha = currentStep / Constants.TELEPORT_UP_STEPS
            local stepTargetCFrame = startCFrame:Lerp(targetCFrameOverall, alpha)

            currentTeleportTween = TweenService:Create(hrp, TweenInfo.new(Constants.TELEPORT_UP_TWEEN_TIME, Enum.EasingStyle.Linear), {CFrame = stepTargetCFrame})
            currentTeleportTween.Completed:Connect(function(status)
                if status == Enum.TweenStatus.Completed then
                    if currentStep < Constants.TELEPORT_UP_STEPS then
                        performTweenStep(currentStep + 1)
                    else
                        State.isTeleporting = false
                    end
                else
                    State.isTeleporting = false -- Tween was cancelled or interrupted
                end
            end)
            currentTeleportTween:Play()
        end

        performTweenStep(1)
		teleportStateUp = not teleportStateUp
	end

	function updateSpeedRunState()
		local newText = State.speedRunActive and "Speed Run: ON" or "Speed Run: OFF"
		local newBgColor = State.speedRunActive and Config.Colors.Accent or Config.Colors.Inactive
		TweenService:Create(UI.toggleButton, Config.ButtonTweenInfo, { BackgroundColor3 = newBgColor }):Play()
		UI.toggleButton.Text = newText

		local char, humanoid = getPlayerCharacterAndHumanoid(player)
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

		if State.speedRunActive then
			controls:Disable()
			if char then
				local animScript = char:FindFirstChild("Animate")
				if animScript and animScript.Enabled then
					State.originalAnimationScript = animScript
					animScript.Enabled = false
				end
			end
			if humanoid then
				humanoid.AutoRotate = false
				humanoid.WalkSpeed = 0 -- Set WalkSpeed to 0 for velocity-based movement
			end
			if animator then
				if State.speedRunAnimTrack then State.speedRunAnimTrack:Stop() end
				local runAnim = Instance.new("Animation")
				runAnim.AnimationId = Constants.ANIMATION_RUN
				State.speedRunAnimTrack = animator:LoadAnimation(runAnim)
				State.speedRunAnimTrack.Looped = true
				State.speedRunAnimTrack:Play()
				runAnim:Destroy()
			end
		else
			controls:Enable()
			if State.speedRunAnimTrack then
				State.speedRunAnimTrack:Stop()
				State.speedRunAnimTrack = nil
			end
			if State.originalAnimationScript and State.originalAnimationScript.Parent then
				State.originalAnimationScript.Enabled = true
			end
			State.originalAnimationScript = nil

			if humanoid then
				humanoid.AutoRotate = true
				humanoid.WalkSpeed = Config.DefaultWalkSpeed
			end
            if hrp then
                hrp.Velocity = Vector3.zero -- Stop any residual velocity
            end
		end
	end

	function updateFlyToggleButton()
		local newText = State.flyEnabled and "Fly: ON" or "Fly: OFF"
		local newBgColor = State.flyEnabled and Config.Colors.Accent or Config.Colors.Inactive
		TweenService:Create(UI.flyToggleButton, Config.ButtonTweenInfo, { BackgroundColor3 = newBgColor }):Play()
		UI.flyToggleButton.Text = newText
	end

	---[ UI UPDATE FUNCTIONS ]---
	function updateInfiniteJumpCheckbox()
		local newBgColor = State.infiniteJumpChecked and Config.Colors.Accent or Config.Colors.Inactive
		TweenService:Create(UI.ijCheckbox, Config.ButtonTweenInfo, { BackgroundColor3 = newBgColor }):Play()
	end

	function updateSliderPosition(thumb, track, valueLabel, stateValue, minVal, maxVal, format)
		if not track or not thumb then return end
		local thumbSize = thumb.AbsoluteSize.X
		local trackW = track.AbsoluteSize.X - thumbSize
		if trackW <= 0 then trackW = 0 end
		local norm = (stateValue - minVal) / (maxVal - minVal)
		thumb.Position = UDim2.new(0, norm * trackW, 0.5, -thumbSize/2)
		if valueLabel then
			valueLabel.Text = string.format(format, stateValue)
		end
	end

	function updateSpeedSliderPosition()
		updateSliderPosition(UI.sliderThumb, UI.sliderTrack.Parent, UI.speedValueLabel, State.speedRunDistance, Config.SpeedRun.Min, Config.SpeedRun.Max, "%.3f")
	end
	function updateFlySliderPosition()
		updateSliderPosition(UI.flySliderThumb, UI.flySliderTrack.Parent, State.flySpeed, Config.Fly.Min, Config.Fly.Max, "%.1f")
	end

	function updateInfiniteZoomCheckbox()
		local newBgColor = State.infiniteZoomEnabled and Config.Colors.Accent or Config.Colors.Inactive
		TweenService:Create(UI.infiniteZoomCheckbox, Config.ButtonTweenInfo, { BackgroundColor3 = newBgColor }):Play()
		local defaultCameraMinZoomDistance = 0.5
		local defaultCameraMaxZoomDistance = 400
		player.CameraMinZoomDistance = State.infiniteZoomEnabled and 0.5 or defaultCameraMinZoomDistance
		player.CameraMaxZoomDistance = State.infiniteZoomEnabled and Config.InfiniteZoom.Max or defaultCameraMaxZoomDistance
		if State.infiniteZoomEnabled and player.CameraMode ~= Enum.CameraMode.Classic and player.CameraMode ~= Enum.CameraMode.Follow then
			player.CameraMode = Enum.CameraMode.Classic
		end
	end
	function updateESPCheckbox(checkbox, isEnabled)
		local newBgColor = isEnabled and Config.Colors.Accent or Config.Colors.Inactive
		TweenService:Create(checkbox, Config.ButtonTweenInfo, { BackgroundColor3 = newBgColor }):Play()
	end
	local currentPage = UI.homePage
	function showPage(pageName)
		local tabs = {
			Home = { button = UI.homeTabButton, page = UI.homePage },
			ESP = { button = UI.espTabButton, page = UI.espPage },
			Fun = { button = UI.funTabButton, page = UI.funPage },
			-- Removed Auto Buy Tab
			Settings = { button = UI.settingsTabButton, page = UI.settingsPage },
		}

		local newPage = tabs[pageName] and tabs[pageName].page
		if not newPage or newPage == currentPage then return end

		if currentPage then
			currentPage.Visible = false
		end
		newPage.Visible = true

		for name, data in pairs(tabs) do
			local isActive = (name == pageName)
			TweenService:Create(data.button, Config.ButtonTweenInfo, { BackgroundColor3 = isActive and Config.Colors.Accent or Config.Colors.Inactive }):Play()
		end

		currentPage = newPage
	end

	---[ ESP LOGIC ]---
	local function removePlayerESPFeature(userId, featureName, destroyMethod)
		if State.highlightedPlayers[userId] and State.highlightedPlayers[userId][featureName] then
			destroyMethod(State.highlightedPlayers[userId][featureName])
			State.highlightedPlayers[userId][featureName] = nil
			return true
		end
		return false
	end
	local function removePlayerHighlight(p) removePlayerESPFeature(p.UserId, "Highlight", function(h) h:Destroy() end) end
	local function removePlayerDisplayName(p) removePlayerESPFeature(p.UserId, "NameGui", function(gui) gui:Destroy() end) end
	local function removePlayerBox(p) removePlayerESPFeature(p.UserId, "Box", function(box) box:Destroy() end) end
	local function removePlayerSkeleton(p)
		if removePlayerESPFeature(p.UserId, "Dots", function(dots)
				dots.Folder:Destroy()
				for _, conn in ipairs(dots.Connections) do conn:Disconnect() end
			end) then
		end
	end
	local function removePlayerTracer(p)
		removePlayerESPFeature(p.UserId, "Tracer", function(tracerData)
			if tracerData.Beam then tracerData.Beam:Destroy() end
			if tracerData.Attachment0 then tracerData.Attachment0:Destroy() end
			if tracerData.Attachment1 then tracerData.Attachment1:Destroy() end
		end)
	end
	local function applyPlayerHighlight(p)
		if p == player or (State.highlightedPlayers[p.UserId] and State.highlightedPlayers[p.UserId].Highlight) then return end
		local char = p.Character
		if not char then return end
		local highlight = Instance.new("Highlight")
		highlight.FillColor = Config.Colors.HighlightFill
		highlight.FillTransparency = State.espFillEnabled and 0.5 or 1 -- MODIFIED: Set transparency based on state
		highlight.OutlineColor = Config.Colors.HighlightOutline
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Adornee = char
		highlight.Parent = char
		State.highlightedPlayers[p.UserId].Highlight = highlight
	end
	local function applyPlayerDisplayName(p)
		if p == player or (State.highlightedPlayers[p.UserId] and State.highlightedPlayers[p.UserId].NameGui) then return end
		local char = p.Character
		local head = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
		if not head then return end
		local nameGui = Instance.new("BillboardGui")
		nameGui.AlwaysOnTop = true
		nameGui.Size = UDim2.new(0, 150, 0, 50)
		nameGui.StudsOffset = Vector3.new(0, 2.5, 0)
		nameGui.Adornee = head
		nameGui.Parent = char
		local nameLabel = createTextLabel(nameGui, "NameLabel", UDim2.new(1, 0, 0.5, 0), nil, p.DisplayName, 16, Config.Colors.TextPrimary, Enum.Font.SourceSansBold, 1)
		nameLabel.TextScaled = true
		local distanceLabel = createTextLabel(nameGui, "DistanceLabel", UDim2.new(1, 0, 0.5, 0), UDim2.new(0, 0, 0.5, 0), "", 14, Color3.new(1,1,1), Enum.Font.SourceSans, 1)
		distanceLabel.TextScaled = true
		State.highlightedPlayers[p.UserId].NameGui = nameGui
	end
	local function applyPlayerSkeleton(p)
		if p == player or (State.highlightedPlayers[p.UserId] and State.highlightedPlayers[p.UserId].Dots) then return end
		local char, humanoid = getPlayerCharacterAndHumanoid(p)
		if not humanoid then return end
		local dotFolder = Instance.new("Folder", UI.screenGui)
		dotFolder.Name = "DotAdornments_" .. p.UserId
		local dotsData = { Adornments = {}, Connections = {}, Folder = dotFolder }
		local partsToDot = humanoid.RigType == Enum.HumanoidRigType.R15 and {"Head", "UpperTorso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg"} or {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
		for _, partName in ipairs(partsToDot) do
			local part = char:FindFirstChild(partName, true)
			if part then
				local dot = Instance.new("BoxHandleAdornment")
				dot.Adornee, dot.AlwaysOnTop, dot.ZIndex, dot.Color3, dot.Size, dot.Transparency, dot.Parent = part, true, 5, Config.Colors.Skeleton, Vector3.new(0.3, 0.3, 0.3), 0.3, dotFolder
				table.insert(dotsData.Adornments, dot)
				table.insert(dotsData.Connections, part.AncestryChanged:Connect(function(_, newParent) if not newParent then dot:Destroy() end end))
			end
		end
		State.highlightedPlayers[p.UserId].Dots = dotsData
	end
	local function applyPlayerBox(p)
		if p == player or (State.highlightedPlayers[p.UserId] and State.highlightedPlayers[p.UserId].Box) then return end
		local rootPart = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end
		local box = Instance.new("BoxHandleAdornment")
		box.AlwaysOnTop, box.ZIndex, box.Color3, box.Transparency, box.Adornee, box.Size, box.Parent = true, 5, Config.Colors.TextPrimary, 0.5, rootPart, Vector3.new(4, 6, 2), UI.screenGui
		State.highlightedPlayers[p.UserId].Box = box
	end
	local function applyPlayerTracer(p)
		if p == player or (State.highlightedPlayers[p.UserId] and State.highlightedPlayers[p.UserId].Tracer) then return end

		local localChar, localHumanoid = getPlayerCharacterAndHumanoid(player)
		if not localHumanoid then return end
		local localTorsoName = localHumanoid.RigType == Enum.HumanoidRigType.R15 and "UpperTorso" or "Torso"
		local localTorso = localChar:FindFirstChild(localTorsoName)
		if not localTorso then return end

		local targetChar, targetHumanoid = getPlayerCharacterAndHumanoid(p)
		if not targetHumanoid then return end
		local targetTorsoName = targetHumanoid.RigType == Enum.HumanoidRigType.R15 and "UpperTorso" or "Torso"
		local targetTorso = targetChar:FindFirstChild(targetTorsoName)
		if not targetTorso then return end

		local attachment0 = Instance.new("Attachment", localTorso)
		local attachment1 = Instance.new("Attachment", targetTorso)

		local beam = Instance.new("Beam")
		beam.Name = "TracerBeam"
		beam.Attachment0 = attachment0
		beam.Attachment1 = attachment1
		beam.Color = ColorSequence.new(Color3.new(1, 1, 1))
		beam.Width0 = 0.1
		beam.Width1 = 0.1
		beam.Transparency = NumberSequence.new(0.5)
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.FaceCamera = true
		beam.Parent = localTorso

		State.highlightedPlayers[p.UserId].Tracer = { Beam = beam, Attachment0 = attachment0, Attachment1 = attachment1 }
	end
	local function updateESPForPlayer(p)
		if p == player then return end
		if not State.highlightedPlayers[p.UserId] then return end

		local char, _ = getPlayerCharacterAndHumanoid(p)
		if not (char and char.Parent and char:FindFirstChild("HumanoidRootPart")) then
			removePlayerHighlight(p); removePlayerDisplayName(p); removePlayerSkeleton(p); removePlayerBox(p); removePlayerTracer(p)
			return
		end

		-- MODIFIED: Handle highlight and fill logic
		if State.espEnabled then
			applyPlayerHighlight(p) -- Ensures the highlight object exists
			local data = State.highlightedPlayers[p.UserId]
			if data and data.Highlight then
				-- Update the fill transparency based on the fill checkbox
				data.Highlight.FillTransparency = State.espFillEnabled and 0.5 or 1
			end
		else
			removePlayerHighlight(p)
		end

		local needsNameGui = State.espDisplayNameEnabled or State.espDistanceEnabled
		if needsNameGui then
			applyPlayerDisplayName(p)
			local data = State.highlightedPlayers[p.UserId]
			if data and data.NameGui then
				data.NameGui.NameLabel.Visible = State.espDisplayNameEnabled
				data.NameGui.DistanceLabel.Visible = State.espDistanceEnabled
			end
		else
			removePlayerDisplayName(p)
		end
		if State.espSkeletonEnabled then applyPlayerSkeleton(p) else removePlayerSkeleton(p) end
		if State.espBoxEnabled then applyPlayerBox(p) else removePlayerBox(p) end
		if State.espTracersEnabled then applyPlayerTracer(p) else removePlayerTracer(p) end
	end
	updateAllESPVisuals = function()
		for _, p in pairs(Players:GetPlayers()) do
			updateESPForPlayer(p)
		end
	end
	local function fullCleanupESPForPlayer(p)
		if not p or not State.highlightedPlayers[p.UserId] then return end
		local data = State.highlightedPlayers[p.UserId]
		if data.CharacterAdded and data.CharacterAdded.Connected then data.CharacterAdded:Disconnect() end
		if data.CharacterRemoving and data.CharacterRemoving.Connected then data.CharacterRemoving:Disconnect() end
		removePlayerHighlight(p); removePlayerDisplayName(p); removePlayerSkeleton(p); removePlayerBox(p); removePlayerTracer(p)
		State.highlightedPlayers[p.UserId] = nil
	end

	local function setupPlayerEsp(p)
		if not p or p == player or State.highlightedPlayers[p.UserId] then return end

		State.highlightedPlayers[p.UserId] = {}
		local data = State.highlightedPlayers[p.UserId]
		data.CharacterAdded = p.CharacterAdded:Connect(function() task.wait(0.2); updateESPForPlayer(p) end)
		data.CharacterRemoving = p.CharacterRemoving:Connect(function()
			removePlayerHighlight(p)
			removePlayerDisplayName(p)
			removePlayerSkeleton(p)
			removePlayerBox(p)
			removePlayerTracer(p)
		end)
	end

	local function removeAllBaseNameVisuals()
		for plot, data in pairs(State.baseNameVisuals) do
			if data.gui and data.gui.Parent then
				data.gui:Destroy()
			end
			if data.connection and data.connection.Connected then
				data.connection:Disconnect()
			end
		end
		State.baseNameVisuals = {}
	end

	local function createOrUpdateVisualForPlot(plot)
		local plotSign = plot:FindFirstChild("PlotSign")
		if not plotSign then return end

		local surfaceGui = plotSign:FindFirstChild("SurfaceGui")
		if not surfaceGui then return end

		local frame = surfaceGui:FindFirstChild("Frame")
		if not frame then return end

		local textLabel = frame:FindFirstChild("TextLabel")
		if not textLabel then return end

		local mainRoot = plot:FindFirstChild("MainRoot")
		if not mainRoot then return end

		local ownerName = textLabel.Text
		local data = State.baseNameVisuals[plot]

		if ownerName ~= "" and ownerName ~= "Player's Base" then
			if not data or not data.gui or not data.gui.Parent then
				if data and data.gui then data.gui:Destroy() end
				local gui = Instance.new("BillboardGui")
				gui.Name = "BaseNameGui"
				gui.AlwaysOnTop = true
				gui.Size = UDim2.new(0, 250, 0, 50)
				gui.StudsOffset = Vector3.new(0, 10, 0)
				gui.Adornee = mainRoot

				local nameLabel = createTextLabel(gui, "NameLabel", UDim2.new(1, 0, 1, 0), nil, ownerName, 28, Color3.new(1,1,1), Enum.Font.SourceSansBold, 1)
				nameLabel.TextStrokeColor3 = Color3.new(0,0,0)
				nameLabel.TextStrokeTransparency = 0.5

				gui.Parent = mainRoot
				State.baseNameVisuals[plot] = {gui = gui, connection = nil}
			else
				data.gui.NameLabel.Text = ownerName
			end
		else
			if data and data.gui then
				data.gui:Destroy()
				State.baseNameVisuals[plot] = nil
			end
		end
	end

	local function setupVisualForPlot(plot)
		if not plot:IsA("Model") then return end

		local textLabel = plot:FindFirstChild("PlotSign.SurfaceGui.Frame.TextLabel", true)

		createOrUpdateVisualForPlot(plot)

		if textLabel and (not State.baseNameVisuals[plot] or not State.baseNameVisuals[plot].connection) then
			local connection = textLabel:GetPropertyChangedSignal("Text"):Connect(function()
				createOrUpdateVisualForPlot(plot)
			end)
			if State.baseNameVisuals[plot] then
				State.baseNameVisuals[plot].connection = connection
			end
		end
	end

	updateAllBaseNameVisuals = function()
		local plotsFolder = Workspace:FindFirstChild(Constants.FOLDER_PLOTS)
		if not plotsFolder then
			removeAllBaseNameVisuals()
			return
		end

		if State.showBaseNamesEnabled then
			for _, plot in ipairs(plotsFolder:GetChildren()) do
				setupVisualForPlot(plot)
			end
		else
			removeAllBaseNameVisuals()
		end
	end

	local function removeAllBaseTimerVisuals()
		for plot, data in pairs(State.baseTimerVisuals) do
			if data.gui and data.gui.Parent then
				data.gui:Destroy()
			end
			if data.connection and data.connection.Connected then
				data.connection:Disconnect()
			end
		end
		State.baseTimerVisuals = {}
	end

	local function createOrUpdateTimerForPlot(base)
		local timerLabel = base:FindFirstChild("RemainingTime", true)
		if not timerLabel then return end

		local adorneePart = base:FindFirstChild("Main") or base:FindFirstChild("PlotBlock") or base.PrimaryPart or base
		if not adorneePart then return end

		local timerText = timerLabel.Text
		local data = State.baseTimerVisuals[base]

		if data and not (data.gui and data.gui.Parent) then
			if data.connection and data.connection.Connected then data.connection:Disconnect() end
			data = nil
		end

		if not data then
			local gui = Instance.new("BillboardGui")
			gui.Name = "BaseTimerGui"
			gui.AlwaysOnTop = true
			gui.Size = UDim2.new(0, 250, 0, 50)
			gui.StudsOffset = Vector3.new(0, 15, 0)
			gui.Adornee = adorneePart

			local nameLabel = createTextLabel(gui, "TimerLabel", UDim2.new(1, 0, 1, 0), nil, timerText, 28, Color3.new(1,1,1), Enum.Font.SourceSansBold, 1)
			nameLabel.TextStrokeColor3 = Color3.new(0,0,0)
			nameLabel.TextStrokeTransparency = 0.5

			gui.Parent = adorneePart
			State.baseTimerVisuals[base] = {gui = gui, connection = nil}
		else
			if data.gui and data.gui:FindFirstChild("TimerLabel") then
				data.gui.TimerLabel.Text = timerText
			end
		end
	end

	local function setupTimerForPlot(base)
		if not base:IsA("Model") then return end

		local data = State.baseTimerVisuals[base]
		if data and data.gui and data.gui.Parent and data.connection and data.connection.Connected then
			return
		end

		local timerLabel = base:FindFirstChild("RemainingTime", true)

		if timerLabel then
			createOrUpdateTimerForPlot(base)

			local currentData = State.baseTimerVisuals[base]
			if currentData and (not currentData.connection or not currentData.connection.Connected) then
				if currentData.connection and currentData.connection.Connected then
					currentData.connection:Disconnect()
				end
				currentData.connection = timerLabel:GetPropertyChangedSignal("Text"):Connect(function()
					createOrUpdateTimerForPlot(base)
				end)
			end
		end
	end

	updateAllBaseTimerVisuals = function()
		local baseContainer = Workspace:FindFirstChild(Constants.FOLDER_PLOTS) or Workspace:FindFirstChild(Constants.FOLDER_BASES)
		if not baseContainer then
			removeAllBaseTimerVisuals()
			return
		end

		if State.showBaseTimerEnabled then
			for _, base in ipairs(baseContainer:GetChildren()) do
				setupTimerForPlot(base)
			end
		else
			removeAllBaseTimerVisuals()
		end
	end

	local brainrotGodNames = {
		["Cocofanto Elefanto"] = true,
		["Tralalero Tralala"] = true,
		["Girafa"] = true,
		["Odin Din Din Dun"] = true,
		["Matteo"] = true,
		["Trenostruzzo Turbo 3000"] = true,
		["Gattatino Nyanino"] = true,
		["Girafa Celestre"] = true
	}

	local function removeAllBrainrotGodVisuals()
		for god, data in pairs(State.highlightedBrainrotGods) do
			if data.Highlight and data.Highlight.Parent then
				data.Highlight:Destroy()
			end
			if data.NameGui and data.NameGui.Parent then
				data.NameGui:Destroy()
			end
		end
		State.highlightedBrainrotGods = {}
	end

	local function setupBrainrotGodVisual(god)
		if not god or not god:IsA("Model") then return end
		if not State.highlightedBrainrotGods[god] then
			State.highlightedBrainrotGods[god] = {}
		end
		local data = State.highlightedBrainrotGods[god]

		-- Handle Highlight
		if State.brainrotGodsEspEnabled then
			if not data.Highlight then
				local highlight = Instance.new("Highlight")
				highlight.FillColor = Config.Colors.HighlightFill
				highlight.FillTransparency = 0.5
				highlight.OutlineColor = Config.Colors.HighlightOutline
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Adornee = god
				highlight.Parent = god
				data.Highlight = highlight
			end
		else
			if data.Highlight then
				data.Highlight:Destroy()
				data.Highlight = nil
			end
		end

		-- Handle Name Tag
		if State.espBrainrotGodNameEnabled and State.brainrotGodsEspEnabled then
			if not data.NameGui then
				local head = god.PrimaryPart or god:FindFirstChild("Head")
				if head then
					local nameGui = Instance.new("BillboardGui")
					nameGui.AlwaysOnTop = true
					nameGui.Size = UDim2.new(0, 200, 0, 50)
					nameGui.StudsOffset = Vector3.new(0, 3, 0)
					nameGui.Adornee = head
					nameGui.Parent = god

					local nameLabel = createTextLabel(nameGui, "NameLabel", UDim2.new(1, 0, 1, 0), nil, god.Name, 20, Config.Colors.TextPrimary, Enum.Font.SourceSansBold, 1)
					nameLabel.TextStrokeColor3 = Color3.new(0,0,0)
					nameLabel.TextStrokeTransparency = 0.5
					data.NameGui = nameGui
				end
			end
		else
			if data.NameGui then
				data.NameGui:Destroy()
				data.NameGui = nil
			end
		end
	end

	updateAllBrainrotGodVisuals = function()
		local currentGods = {}
		for _, child in ipairs(Workspace:GetChildren()) do
			if brainrotGodNames[child.Name] then
				currentGods[child] = true
				setupBrainrotGodVisual(child)
			end
		end

		-- Cleanup for gods that no longer exist
		for god, _ in pairs(State.highlightedBrainrotGods) do
			if not currentGods[god] then
				if State.highlightedBrainrotGods[god].Highlight then
					State.highlightedBrainrotGods[god].Highlight:Destroy()
				end
				if State.highlightedBrainrotGods[god].NameGui then
					State.highlightedBrainrotGods[god].NameGui:Destroy()
				end
				State.highlightedBrainrotGods[god] = nil
			end
		end
	end

	local secretNpcNames = {
		["La Vacca Saturno Saturnita"] = true,
		["Sammyni Spyderini"] = true,
		["Los Tralaleritos"] = true,
		["Graipuss Medussi"] = true,
		["Garama"] = true,
		["Madundung"] = true,
		["La Grande Combinasion"] = true
	}

	local function removeAllSecretVisuals()
		for npc, data in pairs(State.highlightedSecrets) do
			if data.Highlight and data.Highlight.Parent then
				data.Highlight:Destroy()
			end
			if data.NameGui and data.NameGui.Parent then
				data.NameGui:Destroy()
			end
		end
		State.highlightedSecrets = {}
	end

	local function setupSecretVisual(npc)
		if not npc or not npc:IsA("Model") then return end
		if not State.highlightedSecrets[npc] then
			State.highlightedSecrets[npc] = {}
		end
		local data = State.highlightedSecrets[npc]

		-- Handle Highlight
		if State.highlightSecretsEnabled then
			if not data.Highlight then
				local highlight = Instance.new("Highlight")
				highlight.FillColor = Config.Colors.HighlightFill
				highlight.FillTransparency = 0.5
				highlight.OutlineColor = Config.Colors.HighlightOutline
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Adornee = npc
				highlight.Parent = npc
				data.Highlight = highlight
			end
		else
			if data.Highlight then
				data.Highlight:Destroy()
				data.Highlight = nil
			end
		end

		-- Handle Name Tag
		if State.espSecretNameEnabled and State.highlightSecretsEnabled then
			if not data.NameGui then
				local head = npc.PrimaryPart or npc:FindFirstChild("Head")
				if head then
					local nameGui = Instance.new("BillboardGui")
					nameGui.AlwaysOnTop = true
					nameGui.Size = UDim2.new(0, 200, 0, 50)
					nameGui.StudsOffset = Vector3.new(0, 3, 0)
					nameGui.Adornee = head
					nameGui.Parent = npc

					local nameLabel = createTextLabel(nameGui, "NameLabel", UDim2.new(1, 0, 1, 0), nil, npc.Name, 20, Config.Colors.TextPrimary, Enum.Font.SourceSansBold, 1)
					nameLabel.TextStrokeColor3 = Color3.new(0,0,0)
					nameLabel.TextStrokeTransparency = 0.5
					data.NameGui = nameGui
				end
			end
		else
			if data.NameGui then
				data.NameGui:Destroy()
				data.NameGui = nil
			end
		end
	end

	updateAllSecretVisuals = function()
		local currentSecrets = {}
		for _, child in ipairs(Workspace:GetChildren()) do
			if secretNpcNames[child.Name] then
				currentSecrets[child] = true
				setupSecretVisual(child)
			end
		end

		-- Cleanup for secrets that no longer exist
		for npc, _ in pairs(State.highlightedSecrets) do
			if not currentSecrets[npc] then
				if State.highlightedSecrets[npc].Highlight then
					State.highlightedSecrets[npc].Highlight:Destroy()
				end
				if State.highlightedSecrets[npc].NameGui then
					State.highlightedSecrets[npc].NameGui:Destroy()
				end
				State.highlightedSecrets[npc] = nil
			end
		end
	end

	---[ EVENT CONNECTIONS & HANDLERS ]---
	UI.homeTabButton.MouseButton1Click:Connect(function() showPage("Home") end)
	UI.espTabButton.MouseButton1Click:Connect(function() showPage("ESP") end)
	UI.funTabButton.MouseButton1Click:Connect(function() showPage("Fun") end)
	-- Removed Auto Buy Tab Button Click
	UI.settingsTabButton.MouseButton1Click:Connect(function() showPage("Settings") end)

	UI.closeButton.MouseEnter:Connect(function() TweenService:Create(UI.closeButton, Config.ButtonTweenInfo, { BackgroundColor3 = Config.Colors.Error }):Play() end)
	UI.closeButton.MouseLeave:Connect(function() TweenService:Create(UI.closeButton, Config.ButtonTweenInfo, { BackgroundColor3 = Color3.new(1, 1, 1) }):Play() end)

	toggleSpeedRun = function()
		State.speedRunActive = not State.speedRunActive
		if State.speedRunActive and State.flyEnabled then
			State.flyEnabled = false
			updateFlyToggleButton()
		end
		updateSpeedRunState()
		saveSettings()
	end

	toggleFly = function()
		State.flyEnabled = not State.flyEnabled
		if State.flyEnabled and State.speedRunActive then
			State.speedRunActive = false
			updateSpeedRunState()
		end
		updateFlyToggleButton()
		saveSettings()
	end

	local function handleTeleportUpAction(_, inputState) if inputState == Enum.UserInputState.Begin then handleTeleportToggle() end return Enum.ContextActionResult.Pass end
	local function handleToggleSpeedRun(_, inputState) if inputState == Enum.UserInputState.Begin then toggleSpeedRun() end return Enum.ContextActionResult.Pass end
	local function handleToggleFly(_, inputState) if inputState == Enum.UserInputState.Begin then toggleFly() end return Enum.ContextActionResult.Pass end

	local function handleToggleUI(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			UI.mainFrame.Visible = not UI.mainFrame.Visible
			UI.mobileToggleButton.Visible = not UI.mainFrame.Visible
			if State.isMobile and UI.mobileControlsFrame then
				UI.mobileControlsFrame.Visible = not UI.mainFrame.Visible
			end
		end
		return Enum.ContextActionResult.Pass
	end
	local function handleInfiniteJump(_, inputState)
		if inputState == Enum.UserInputState.Begin and State.infiniteJumpChecked and not State.flyEnabled then
			local char, _ = getPlayerCharacterAndHumanoid(player)
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then hrp.Velocity += Vector3.new(0, Config.InfiniteJump.Default, 0) end
		end
		return Enum.ContextActionResult.Pass
	end

	local function setKeybind(button, actionName, handler, currentKeyRef)
		button.Text = "..."
		TweenService:Create(button, Config.ButtonTweenInfo, { BackgroundColor3 = Config.Colors.AccentDark }):Play()
		local conn
		conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
				ContextActionService:UnbindAction(actionName)
				State[currentKeyRef] = input.KeyCode.Name
				ContextActionService:BindAction(actionName, handler, false, input.KeyCode)
				button.Text = input.KeyCode.Name
				TweenService:Create(button, Config.ButtonTweenInfo, { BackgroundColor3 = Config.Colors.Inactive }):Play()
				saveSettings()
				conn:Disconnect()
			end
		end)
	end
	if not State.isMobile then
		UI.setSpeedRunKeyButton.MouseButton1Click:Connect(function() setKeybind(UI.setSpeedRunKeyButton, Constants.ACTION_TOGGLE_SPEED, handleToggleSpeedRun, "toggleSpeedRunKey") end)
		UI.uiKeybindButton.MouseButton1Click:Connect(function() setKeybind(UI.uiKeybindButton, Constants.ACTION_TOGGLE_UI, handleToggleUI, "toggleUIKey") end)
		UI.setFlyKeyButton.MouseButton1Click:Connect(function() setKeybind(UI.setFlyKeyButton, Constants.ACTION_TOGGLE_FLY, handleToggleFly, "toggleFlyKey") end)
		-- UI.setTeleportUpKeyButton.MouseButton1Click:Connect(function() setKeybind(UI.setTeleportUpKeyButton, Constants.ACTION_TELEPORT_UP, handleTeleportToggle, "toggleTeleportUpKey") end) -- Hidden
	end
	local function handleSliderDrag(thumb, track, stateKey, minVal, maxVal, updateFunc)
		local dragging = false
		thumb.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if dragging then
					dragging = false
					saveSettings()
				end
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local thumbSize = thumb.AbsoluteSize.X
				local trackW = track.AbsoluteSize.X - thumbSize
				if trackW <= 0 then return end
				local relativeMouseX = input.Position.X - track.AbsolutePosition.X
				local norm = math.clamp(relativeMouseX / trackW, 0, 1)
				State[stateKey] = minVal + norm * (maxVal - minVal)
				updateFunc()
			end
		end)
	end
	handleSliderDrag(UI.sliderThumb, UI.sliderTrack.Parent, "speedRunDistance", Config.SpeedRun.Min, Config.SpeedRun.Max, updateSpeedSliderPosition)
	handleSliderDrag(UI.flySliderThumb, UI.flySliderTrack.Parent, "flySpeed", Config.Fly.Min, Config.Fly.Max, updateFlySliderPosition)

	UI.ijCheckbox.MouseButton1Click:Connect(function()
		State.infiniteJumpChecked = not State.infiniteJumpChecked
		updateInfiniteJumpCheckbox()
		if State.infiniteJumpChecked then ContextActionService:BindAction(Constants.ACTION_INFINITE_JUMP, handleInfiniteJump, false, Enum.KeyCode.Space)
		else ContextActionService:UnbindAction(Constants.ACTION_INFINITE_JUMP) end
		saveSettings()
	end)
	UI.infiniteZoomCheckbox.MouseButton1Click:Connect(function() State.infiniteZoomEnabled = not State.infiniteZoomEnabled; updateInfiniteZoomCheckbox(); saveSettings() end)
	UI.antiAfkCheckbox.MouseButton1Click:Connect(function() State.antiAfkEnabled = not State.antiAfkEnabled; updateESPCheckbox(UI.antiAfkCheckbox, State.antiAfkEnabled); saveSettings() end)
	UI.forceResetButton.MouseButton1Click:Connect(function()
		local _, humanoid = getPlayerCharacterAndHumanoid(player)
		if humanoid then
			humanoid.Health = 0
		end
	end)
	UI.smoothDragCheckbox.MouseButton1Click:Connect(function()
		State.smoothDragEnabled = not State.smoothDragEnabled
		updateESPCheckbox(UI.smoothDragCheckbox, State.smoothDragEnabled)
		saveSettings()
	end)
	UI.autoSaveCheckbox.MouseButton1Click:Connect(function()
		State.autoSaveEnabled = not State.autoSaveEnabled
		updateESPCheckbox(UI.autoSaveCheckbox, State.autoSaveEnabled)
		saveSettings(true)
	end)

	UI.toggleButton.MouseButton1Click:Connect(toggleSpeedRun)
	UI.flyToggleButton.MouseButton1Click:Connect(toggleFly)
	-- UI.teleportUpButton.MouseButton1Click:Connect(handleTeleportToggle) -- Hidden

	UI.espEnableCheckbox.MouseButton1Click:Connect(function() State.espEnabled = not State.espEnabled; updateESPCheckbox(UI.espEnableCheckbox, State.espEnabled); updateAllESPVisuals(); saveSettings() end)

	-- ADDED: Event handler for the new Fill checkbox
	UI.espFillCheckbox.MouseButton1Click:Connect(function()
		State.espFillEnabled = not State.espFillEnabled
		updateESPCheckbox(UI.espFillCheckbox, State.espFillEnabled)
		updateAllESPVisuals()
		saveSettings()
	end)

	UI.espDisplayNameCheckbox.MouseButton1Click:Connect(function() State.espDisplayNameEnabled = not State.espDisplayNameEnabled; updateESPCheckbox(UI.espDisplayNameCheckbox, State.espDisplayNameEnabled); updateAllESPVisuals(); saveSettings() end)
	UI.espDistanceCheckbox.MouseButton1Click:Connect(function() State.espDistanceEnabled = not State.espDistanceEnabled; updateESPCheckbox(UI.espDistanceCheckbox, State.espDistanceEnabled); updateAllESPVisuals(); saveSettings() end)
	UI.espSkeletonCheckbox.MouseButton1Click:Connect(function() State.espSkeletonEnabled = not State.espSkeletonEnabled; updateESPCheckbox(UI.espSkeletonCheckbox, State.espSkeletonEnabled); updateAllESPVisuals(); saveSettings() end)
	UI.espBoxCheckbox.MouseButton1Click:Connect(function() State.espBoxEnabled = not State.espBoxEnabled; updateESPCheckbox(UI.espBoxCheckbox, State.espBoxEnabled); updateAllESPVisuals(); saveSettings() end)
	UI.espTracersCheckbox.MouseButton1Click:Connect(function() State.espTracersEnabled = not State.espTracersEnabled; updateESPCheckbox(UI.espTracersCheckbox, State.espTracersEnabled); updateAllESPVisuals(); saveSettings() end)
	UI.showBaseNamesCheckbox.MouseButton1Click:Connect(function() State.showBaseNamesEnabled = not State.showBaseNamesEnabled; updateESPCheckbox(UI.showBaseNamesCheckbox, State.showBaseNamesEnabled); updateAllBaseNameVisuals(); saveSettings() end)
	UI.showBaseTimerCheckbox.MouseButton1Click:Connect(function()
		State.showBaseTimerEnabled = not State.showBaseTimerEnabled;
		updateESPCheckbox(UI.showBaseTimerCheckbox, State.showBaseTimerEnabled);
		updateAllBaseTimerVisuals();
		saveSettings()
	end)
	UI.brainrotGodsEspCheckbox.MouseButton1Click:Connect(function()
		State.brainrotGodsEspEnabled = not State.brainrotGodsEspEnabled;
		updateESPCheckbox(UI.brainrotGodsEspCheckbox, State.brainrotGodsEspEnabled);
		updateAllBrainrotGodVisuals();
		saveSettings()
	end)
	UI.espBrainrotGodNameCheckbox.MouseButton1Click:Connect(function()
		State.espBrainrotGodNameEnabled = not State.espBrainrotGodNameEnabled
		updateESPCheckbox(UI.espBrainrotGodNameCheckbox, State.espBrainrotGodNameEnabled)
		updateAllBrainrotGodVisuals()
		saveSettings()
	end)
	UI.highlightSecretsCheckbox.MouseButton1Click:Connect(function()
		State.highlightSecretsEnabled = not State.highlightSecretsEnabled;
		updateESPCheckbox(UI.highlightSecretsCheckbox, State.highlightSecretsEnabled);
		updateAllSecretVisuals();
		saveSettings()
	end)
	UI.espSecretNameCheckbox.MouseButton1Click:Connect(function()
		State.espSecretNameEnabled = not State.espSecretNameEnabled
		updateESPCheckbox(UI.espSecretNameCheckbox, State.espSecretNameEnabled)
		updateAllSecretVisuals()
		saveSettings()
	end)

	UI.closeUIButton.MouseButton1Click:Connect(function()
		UI.mainFrame.Visible = false
		UI.mobileToggleButton.Visible = true
		if State.isMobile and UI.mobileControlsFrame then
			UI.mobileControlsFrame.Visible = false
		end
	end)
	UI.closeButton.MouseButton1Click:Connect(function()
		saveSettings(true) -- Force save on close
		State.espEnabled, State.espFillEnabled, State.espDisplayNameEnabled, State.espDistanceEnabled, State.espSkeletonEnabled, State.espBoxEnabled, State.espTracersEnabled, State.showBaseNamesEnabled, State.showBaseTimerEnabled, State.brainrotGodsEspEnabled, State.highlightSecretsEnabled = false, false, false, false, false, false, false, false, false, false, false
		updateAllESPVisuals()
		updateAllBaseNameVisuals()
		updateAllBaseTimerVisuals()
		updateAllBrainrotGodVisuals()
		updateAllSecretVisuals()
		ContextActionService:UnbindAction(Constants.ACTION_TOGGLE_SPEED)
		ContextActionService:UnbindAction(Constants.ACTION_TOGGLE_FLY)
		ContextActionService:UnbindAction(Constants.ACTION_TOGGLE_UI)
		ContextActionService:UnbindAction(Constants.ACTION_INFINITE_JUMP)
		ContextActionService:UnbindAction(Constants.ACTION_TELEPORT_UP)
		for _, connection in ipairs(State.globalConnections) do connection:Disconnect() end
		controls:Enable()
		UI.screenGui:Destroy()
	end)

	---[ GAME EVENT HANDLERS ]---
	local function onCharacterAdded(char)
		if isInitialCharacter then
			isInitialCharacter = false
			State.initialSpawnLocation = char:WaitForChild("HumanoidRootPart").Position
		else
			State.speedRunActive, State.flyEnabled = false, false
			updateSpeedRunState()
			updateFlyToggleButton()
		end

		-- Wait a moment for replication before updating visuals
		task.wait(1)
		if State.infiniteZoomEnabled then updateInfiniteZoomCheckbox() end
		updateAllESPVisuals()
		updateAllBaseNameVisuals()
		updateAllBaseTimerVisuals()
		updateAllBrainrotGodVisuals()
		updateAllSecretVisuals()
	end
	table.insert(State.globalConnections, player.CharacterAdded:Connect(onCharacterAdded))

	table.insert(State.globalConnections, Players.PlayerAdded:Connect(function(p)
		task.wait(0.5)
		setupPlayerEsp(p)
		updateESPForPlayer(p)
	end))
	table.insert(State.globalConnections, Players.PlayerRemoving:Connect(fullCleanupESPForPlayer))

	local function onIdle()
		if State.antiAfkEnabled then
			local _, humanoid = getPlayerCharacterAndHumanoid(player)
			if humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end
	end
	table.insert(State.globalConnections, player.Idled:Connect(onIdle))

	for _, p in pairs(Players:GetPlayers()) do
		setupPlayerEsp(p)
	end

	local frameCounter = 0
	table.insert(State.globalConnections, RunService.RenderStepped:Connect(function(delta)
		local char, humanoid = getPlayerCharacterAndHumanoid(player)
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not (hrp and humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Dead) then
			return
		end
		if State.flyEnabled then
			if not State.flyAttachment then
				State.flyAttachment = Instance.new("Attachment", hrp)
				State.flyLinearVelocity = Instance.new("LinearVelocity", State.flyAttachment)
				State.flyLinearVelocity.MaxForce, State.flyLinearVelocity.Attachment0, State.flyLinearVelocity.RelativeTo = math.huge, State.flyAttachment, Enum.ActuatorRelativeTo.World
				State.flyVectorForce = Instance.new("VectorForce", State.flyAttachment)
				State.flyVectorForce.Force, State.flyVectorForce.Attachment0, State.flyVectorForce.RelativeTo = Vector3.new(0, Workspace.Gravity * hrp:GetMass(), 0), State.flyAttachment, Enum.ActuatorRelativeTo.World
			end
			local moveDirection
			if State.isMobile then
				moveDirection = humanoid.MoveDirection
				if State.flyUpActive then moveDirection += Vector3.yAxis end
				if State.flyDownActive then moveDirection -= Vector3.yAxis end
			else
				moveDirection = Vector3.new()
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection += camera.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection -= camera.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection -= camera.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection += camera.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection += Vector3.yAxis end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection -= Vector3.yAxis end
			end
			State.flyLinearVelocity.VectorVelocity = moveDirection.Magnitude > 0 and moveDirection.Unit * State.flySpeed or Vector3.zero
		elseif State.speedRunActive then
			local lookVector = camera.CFrame.LookVector
			local moveDirection = Vector3.new(lookVector.X, 0, lookVector.Z).Unit

            -- Velocity-based speed run
            local currentSpeed = State.speedRunDistance * 200
            hrp.Velocity = moveDirection * currentSpeed -- Apply velocity directly
		else
			if State.flyAttachment then State.flyAttachment:Destroy(); State.flyAttachment = nil end
		end
		frameCounter = frameCounter + 1
		if frameCounter >= Constants.THROTTLE_INTERVAL_FAST then
			frameCounter = 0
			if State.espDistanceEnabled then
				local localRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if localRoot then
					for userId, data in pairs(State.highlightedPlayers) do
						if data.NameGui and data.NameGui.DistanceLabel.Visible then
							local p = Players:GetPlayerByUserId(userId)
							local targetRoot = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
							if targetRoot then
								data.NameGui.DistanceLabel.Text = string.format("[%.1f studs]", (localRoot.Position - targetRoot.Position).Magnitude)
							else
								data.NameGui.DistanceLabel.Text = ""
							end
						end
					end
				end
			end
		end
	end))

	local function setupBaseListeners(container)
		if not container then return end
		table.insert(State.globalConnections, container.ChildAdded:Connect(function(base)
			if State.showBaseTimerEnabled then
				task.wait(0.5)
				setupTimerForPlot(base)
			end
			if State.showBaseNamesEnabled then
				task.wait(0.5)
				setupVisualForPlot(base)
			end
		end))

		table.insert(State.globalConnections, container.ChildRemoved:Connect(function(base)
			local timerData = State.baseTimerVisuals[base]
			if timerData then
				if timerData.gui then timerData.gui:Destroy() end
				if timerData.connection and timerData.connection.Connected then timerData.connection:Disconnect() end
				State.baseTimerVisuals[base] = nil
			end
			local nameData = State.baseNameVisuals[base]
			if nameData then
				if nameData.gui then nameData.gui:Destroy() end
				if nameData.connection and nameData.connection.Connected then nameData.connection:Disconnect() end
				State.baseNameVisuals[base] = nil
			end
		end))
	end

	setupBaseListeners(Workspace:FindFirstChild(Constants.FOLDER_PLOTS))
	setupBaseListeners(Workspace:FindFirstChild(Constants.FOLDER_BASES))

	table.insert(State.globalConnections, Workspace.ChildAdded:Connect(function(child)
		if brainrotGodNames[child.Name] and State.brainrotGodsEspEnabled then
			setupBrainrotGodVisual(child)
		end
		if secretNpcNames[child.Name] and State.highlightSecretsEnabled then
			setupSecretVisual(child)
		end
	end))
	table.insert(State.globalConnections, Workspace.ChildRemoved:Connect(function(child)
		if State.highlightedBrainrotGods[child] then
			if State.highlightedBrainrotGods[child].Highlight then State.highlightedBrainrotGods[child].Highlight:Destroy() end
			if State.highlightedBrainrotGods[child].NameGui then State.highlightedBrainrotGods[child].NameGui:Destroy() end
			State.highlightedBrainrotGods[child] = nil
		end
		if State.highlightedSecrets[child] then
			if State.highlightedSecrets[child].Highlight then State.highlightedSecrets[child].Highlight:Destroy() end
			if State.highlightedSecrets[child].NameGui then State.highlightedSecrets[child].NameGui:Destroy() end
			State.highlightedSecrets[child] = nil
		end
	end))

	---[ BACKGROUND UPDATE LOOP ]---
	local function backgroundLoop()
		while UI.screenGui.Parent do -- Loop as long as the UI exists
			pcall(function()
				if State.showBaseTimerEnabled then
					local baseContainer = Workspace:FindFirstChild(Constants.FOLDER_PLOTS) or Workspace:FindFirstChild(Constants.FOLDER_BASES)
					if baseContainer then
						for _, base in ipairs(baseContainer:GetChildren()) do
							if base:IsA("Model") then
								local data = State.baseTimerVisuals[base]
								if not (data and data.gui and data.gui.Parent and data.connection and data.connection.Connected) then
									setupTimerForPlot(base)
								end
							end
						end
					end
				end
			end)

			pcall(function()
				if State.showBaseNamesEnabled then
					updateAllBaseNameVisuals()
				end
			end)

			task.wait(Constants.BACKGROUND_LOOP_WAIT)
		end
	end

	---[ INITIALIZATION ]---
	local function applyInitialSettings()
		updateSpeedSliderPosition()
		updateInfiniteJumpCheckbox()
		updateSpeedRunState()
		updateInfiniteZoomCheckbox()
		updateESPCheckbox(UI.espEnableCheckbox, State.espEnabled)
		updateESPCheckbox(UI.espFillCheckbox, State.espFillEnabled) -- ADDED: Initialize new checkbox
		updateESPCheckbox(UI.espDisplayNameCheckbox, State.espDisplayNameEnabled)
		updateESPCheckbox(UI.espDistanceCheckbox, State.espDistanceEnabled)
		updateESPCheckbox(UI.espSkeletonCheckbox, State.espSkeletonEnabled)
		updateESPCheckbox(UI.espBoxCheckbox, State.espBoxEnabled)
		updateESPCheckbox(UI.espTracersCheckbox, State.espTracersEnabled)
		updateESPCheckbox(UI.showBaseNamesCheckbox, State.showBaseNamesEnabled)
		updateESPCheckbox(UI.showBaseTimerCheckbox, State.showBaseTimerEnabled)
		updateESPCheckbox(UI.brainrotGodsEspCheckbox, State.brainrotGodsEspEnabled)
		updateESPCheckbox(UI.espBrainrotGodNameCheckbox, State.espBrainrotGodNameEnabled)
		updateESPCheckbox(UI.highlightSecretsCheckbox, State.highlightSecretsEnabled)
		updateESPCheckbox(UI.espSecretNameCheckbox, State.espSecretNameEnabled)
		updateESPCheckbox(UI.antiAfkCheckbox, State.antiAfkEnabled)
		updateESPCheckbox(UI.smoothDragCheckbox, State.smoothDragEnabled)
		updateESPCheckbox(UI.autoSaveCheckbox, State.autoSaveEnabled)
		updateFlySliderPosition()
		updateFlyToggleButton()

		if State.infiniteJumpChecked then
			ContextActionService:BindAction(Constants.ACTION_INFINITE_JUMP, handleInfiniteJump, false, Enum.KeyCode.Space)
		end

		if State.toggleSpeedRunKey and Enum.KeyCode[State.toggleSpeedRunKey] then
			UI.setSpeedRunKeyButton.Text = State.toggleSpeedRunKey
			ContextActionService:BindAction(Constants.ACTION_TOGGLE_SPEED, handleToggleSpeedRun, false, Enum.KeyCode[State.toggleSpeedRunKey])
		end
		if State.toggleFlyKey and Enum.KeyCode[State.toggleFlyKey] then
			UI.setFlyKeyButton.Text = State.toggleFlyKey
			ContextActionService:BindAction(Constants.ACTION_TOGGLE_FLY, handleToggleFly, false, Enum.KeyCode[State.toggleFlyKey])
		end
		if State.toggleUIKey and Enum.KeyCode[State.toggleUIKey] then
			UI.uiKeybindButton.Text = State.toggleUIKey
			ContextActionService:BindAction(Constants.ACTION_TOGGLE_UI, handleToggleUI, false, Enum.KeyCode[State.toggleUIKey])
		end
		if State.toggleTeleportUpKey and Enum.KeyCode[State.toggleTeleportUpKey] then
			-- Teleport Up keybind is still active, but its UI button is hidden
			ContextActionService:BindAction(Constants.ACTION_TELEPORT_UP, handleTeleportUpAction, false, Enum.KeyCode[State.toggleTeleportUpKey])
		end
	end

	applyInitialSettings()
	-- Removed populateAutoBuyPage()
	coroutine.wrap(backgroundLoop)() -- Start the background loop

	if player.Character then
		onCharacterAdded(player.Character)
	else
		-- if character hasn't loaded, initial visual updates might fail.
		-- onCharacterAdded will handle it once the character appears.
	end

end

---[ SCRIPT START ]---
-- Load settings first to check for a saved key
loadSettings()

if State.savedKey == Config.Key then
	runMainScript()
else
	createKeySystem()
end
