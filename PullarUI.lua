local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Library = {}
Library.__index = Library

local function Tween(object, properties, duration)
	duration = duration or 0.3
	local tween = TweenService:Create(object, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
	tween:Play()
	return tween
end

local function GetFont()
	local FontData = {
		name = "Sega",
		faces = { {
			name = "Regular",
			weight = 400,
			style = "Normal",
			assetId = getcustomasset("Minecraft.ttf")
		} }
	}
	pcall(function()
		writefile("Minecraft.json", HttpService:JSONEncode(FontData))
	end)
	return Font.new(getcustomasset("Minecraft.json"))
end

local function MakeDraggable(frame, dragHandle)
	local dragging = false
	local dragInput, mousePos, framePos
	dragHandle = dragHandle or frame
	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			mousePos = input.Position
			framePos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - mousePos
			frame.Position = UDim2.new(
				framePos.X.Scale,
				framePos.X.Offset + delta.X,
				framePos.Y.Scale,
				framePos.Y.Offset + delta.Y
			)
		end
	end)
end

function Library.new(title)
	local self = setmetatable({}, Library)

	self.Title = title or "PULLAR"
	self.Tabs = {}
	self.TitlePointer = nil
	self.CurrentTab = nil
	self.Minimized = false
	self.SettingsOpen = false

	self.RainbowEnabled = false
	self.RainbowSpeed = 1
	self.GradientUI = false
	self.RainbowHue = 0
	self.RainbowConnection = nil
	self.WaveSpread = 0.6
	self.GUIColor = {
		Hue = 0.44,
		Sat = 1,
		Value = 1
	}

	self.ModuleStatusEnabled = false
	self.ModuleStatusEntries = {}
	self.ColorPreviewPointer = nil
	self.ModuleStatusRainbowConnection = nil
	self.ModuleStatusRainbowHue = 0

	self.ConfigFile = "PullarConfig_" .. title:gsub("%s+", "_") .. ".json"
	self.AutoSave = true
	self.IsLoading = false
	self.ConfigLoadScheduled = false

	self.UIVisible = false
	self.UIBindKey = Enum.KeyCode.RightShift
	self.UIBindListening = false

	self.ActiveNotifications = {}
	self.NotifHeight = 90
	self.NotifGap = 8

	self.ScreenGui = Instance.new("ScreenGui")
	self.ScreenGui.Name = "Pullar"
	self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local coreGui = cloneref(game:GetService("CoreGui"))
	pcall(function() self.ScreenGui.Parent = gethui and gethui() or coreGui end)

	self.ModuleStatusHolder = Instance.new("Frame")
	self.ModuleStatusHolder.Name = "ModuleStatusHolder"
	self.ModuleStatusHolder.Parent = self.ScreenGui
	self.ModuleStatusHolder.BackgroundTransparency = 1
	self.ModuleStatusHolder.BorderSizePixel = 0
	self.ModuleStatusHolder.Position = UDim2.new(0, 0, 0, 0)
	self.ModuleStatusHolder.Size = UDim2.new(0, 262, 0, 164)
	self.ModuleStatusHolder.Visible = false
	self.ModuleStatusHolder.ZIndex = 50
	self.ModuleStatusHolder.ClipsDescendants = false

	local statusLogo = Instance.new("ImageLabel")
	statusLogo.Parent = self.ModuleStatusHolder
	statusLogo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	statusLogo.BackgroundTransparency = 1
	statusLogo.BorderSizePixel = 0
	statusLogo.Position = UDim2.new(-0.024, 0, -0.053, 0)
	statusLogo.Size = UDim2.new(0, 262, 0, 164)
	statusLogo.Image = "rbxassetid://139155875516382"
	statusLogo.ZIndex = 51

	self.ModuleListFrame = Instance.new("Frame")
	self.ModuleListFrame.Name = "ModuleList"
	self.ModuleListFrame.Parent = self.ModuleStatusHolder
	self.ModuleListFrame.BackgroundTransparency = 1
	self.ModuleListFrame.BorderSizePixel = 0
	self.ModuleListFrame.Position = UDim2.new(0, 0, 0, 164)
	self.ModuleListFrame.Size = UDim2.new(0, 210, 0, 0)
	self.ModuleListFrame.ZIndex = 51

	local moduleListLayout = Instance.new("UIListLayout")
	moduleListLayout.Name = "UIListLayout"
	moduleListLayout.Parent = self.ModuleListFrame
	moduleListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	moduleListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	moduleListLayout.Padding = UDim.new(0, 0)

	moduleListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		local h = moduleListLayout.AbsoluteContentSize.Y
		local w = moduleListLayout.AbsoluteContentSize.X
		self.ModuleListFrame.Size = UDim2.new(0, w, 0, h)
		self.ModuleStatusHolder.Size = UDim2.new(0, math.max(w + 10, 262), 0, 164 + h)
	end)

	self.NotificationLayer = Instance.new("Frame")
	self.NotificationLayer.Name = "NotificationLayer"
	self.NotificationLayer.Parent = self.ScreenGui
	self.NotificationLayer.BackgroundTransparency = 1
	self.NotificationLayer.AnchorPoint = Vector2.new(1, 1)
	self.NotificationLayer.Position = UDim2.new(1, -16, 1, -16)
	self.NotificationLayer.Size = UDim2.new(0, 300, 1, 0)
	self.NotificationLayer.ZIndex = 100

	self.MainHolder = Instance.new("Frame")
	self.MainHolder.Name = "MainHolder"
	self.MainHolder.Parent = self.ScreenGui
	self.MainHolder.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
	self.MainHolder.BorderSizePixel = 0
	self.MainHolder.Position = UDim2.new(0.227, 0, 0.188, 0)
	self.MainHolder.Size = UDim2.new(0, 666, 0, 386)
	self.MainHolder.Visible = false

	local mainCorner = Instance.new("UICorner")
	mainCorner.Parent = self.MainHolder

	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Parent = self.MainHolder
	topBar.BackgroundTransparency = 1
	topBar.Size = UDim2.new(1, 0, 0, 50)
	topBar.ZIndex = 0

	MakeDraggable(self.MainHolder, topBar)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Parent = self.MainHolder
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(0, 102, 0, 50)

	self.TitlePointer = titleLabel

	local titleGradient = Instance.new("UIGradient")
	titleGradient.Name = "Gradient"
	titleGradient.Enabled = true
	titleGradient.Parent = self.TitlePointer

	self.TitleGradientPointer = titleGradient

	pcall(function()
		titleLabel.FontFace = GetFont()
	end)
	if not pcall then titleLabel.Font = Enum.Font.SourceSansBold end

	titleLabel.Text = "		" .. self.Title
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 24
	titleLabel.ZIndex = 1

	self.CloseButton = Instance.new("Frame")
	self.CloseButton.Name = "Close"
	self.CloseButton.Parent = self.MainHolder
	self.CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	self.CloseButton.BorderSizePixel = 0
	self.CloseButton.Position = UDim2.new(0.946, 0, 0.026, 0)
	self.CloseButton.Size = UDim2.new(0, 22, 0, 23)

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(1, 0)
	closeCorner.Parent = self.CloseButton

	local closeText = Instance.new("TextLabel")
	closeText.Parent = self.CloseButton
	closeText.BackgroundTransparency = 1
	closeText.Position = UDim2.new(0, 0, -0.305, 0)
	closeText.Size = UDim2.new(0, 22, 0, 33)
	closeText.Font = Enum.Font.SourceSans
	closeText.Text = "x"
	closeText.TextColor3 = Color3.fromRGB(0, 0, 0)
	closeText.TextSize = 20

	local closeButton = Instance.new("TextButton")
	closeButton.Parent = self.CloseButton
	closeButton.BackgroundTransparency = 1
	closeButton.Size = UDim2.new(1, 0, 1, 0)
	closeButton.Text = ""
	closeButton.MouseButton1Click:Connect(function()
		if self.AutoSave and not self.IsLoading then
			self:SaveConfig()
		end
		self.ScreenGui:Destroy()
	end)

	self.MinimizeButton = Instance.new("Frame")
	self.MinimizeButton.Name = "Minimize"
	self.MinimizeButton.Parent = self.MainHolder
	self.MinimizeButton.BackgroundColor3 = Color3.fromRGB(255, 255, 6)
	self.MinimizeButton.BorderSizePixel = 0
	self.MinimizeButton.Position = UDim2.new(0.898, 0, 0.026, 0)
	self.MinimizeButton.Size = UDim2.new(0, 22, 0, 23)

	local minCorner = Instance.new("UICorner")
	minCorner.CornerRadius = UDim.new(1, 0)
	minCorner.Parent = self.MinimizeButton

	local minText = Instance.new("TextLabel")
	minText.Parent = self.MinimizeButton
	minText.BackgroundTransparency = 1
	minText.Position = UDim2.new(0, 0, -0.435, 0)
	minText.Size = UDim2.new(0, 22, 0, 33)
	minText.Font = Enum.Font.SourceSans
	minText.Text = "-"
	minText.TextColor3 = Color3.fromRGB(0, 0, 0)
	minText.TextSize = 50

	local minButton = Instance.new("TextButton")
	minButton.Parent = self.MinimizeButton
	minButton.BackgroundTransparency = 1
	minButton.Size = UDim2.new(1, 0, 1, 0)
	minButton.Text = ""
	minButton.MouseButton1Click:Connect(function()
		self:ToggleMinimize()
	end)

	self.SettingsButton = Instance.new("Frame")
	self.SettingsButton.Name = "Settings"
	self.SettingsButton.Parent = self.MainHolder
	self.SettingsButton.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
	self.SettingsButton.BorderSizePixel = 0
	self.SettingsButton.Position = UDim2.new(0.850, 0, 0.026, 0)
	self.SettingsButton.Size = UDim2.new(0, 22, 0, 23)

	local setCorner = Instance.new("UICorner")
	setCorner.CornerRadius = UDim.new(1, 0)
	setCorner.Parent = self.SettingsButton

	local setIcon = Instance.new("ImageLabel")
	setIcon.Parent = self.SettingsButton
	setIcon.BackgroundTransparency = 1
	setIcon.Size = UDim2.new(0, 22, 0, 23)
	setIcon.Image = "rbxassetid://7059346373"

	local setButton = Instance.new("TextButton")
	setButton.Parent = self.SettingsButton
	setButton.BackgroundTransparency = 1
	setButton.Size = UDim2.new(1, 0, 1, 0)
	setButton.Text = ""
	setButton.MouseButton1Click:Connect(function()
		self:ToggleSettings()
	end)

	self.TabsHolder = Instance.new("ScrollingFrame")
	self.TabsHolder.Name = "TabsHolder"
	self.TabsHolder.Parent = self.MainHolder
	self.TabsHolder.Active = true
	self.TabsHolder.BackgroundTransparency = 1
	self.TabsHolder.BorderSizePixel = 0
	self.TabsHolder.Position = UDim2.new(0, 0, 0.137, 0)
	self.TabsHolder.Size = UDim2.new(0, 102, 0, 258)
	self.TabsHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.TabsHolder.ScrollBarThickness = 4

	local tabsList = Instance.new("UIListLayout")
	tabsList.Parent = self.TabsHolder
	tabsList.SortOrder = Enum.SortOrder.LayoutOrder
	tabsList.Padding = UDim.new(0, 2)

	tabsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self.TabsHolder.CanvasSize = UDim2.new(0, 0, 0, tabsList.AbsoluteContentSize.Y)
	end)

	self.SettingsPage = Instance.new("ScrollingFrame")
	self.SettingsPage.Name = "SettingsPage"
	self.SettingsPage.Parent = self.MainHolder
	self.SettingsPage.Active = true
	self.SettingsPage.BackgroundTransparency = 1
	self.SettingsPage.BorderSizePixel = 0
	self.SettingsPage.Position = UDim2.new(0.174, 0, 0.137, 0)
	self.SettingsPage.Size = UDim2.new(0, 536, 0, 312)
	self.SettingsPage.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.SettingsPage.ScrollBarThickness = 4
	self.SettingsPage.Visible = false

	local settingsLayout = Instance.new("UIListLayout")
	settingsLayout.Parent = self.SettingsPage
	settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	settingsLayout.Padding = UDim.new(0, 2)

	settingsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self.SettingsPage.CanvasSize = UDim2.new(0, 0, 0, settingsLayout.AbsoluteContentSize.Y)
	end)

	local themeHeader = Instance.new("TextButton")
	themeHeader.Name = "ThemeSettings"
	themeHeader.Parent = self.SettingsPage
	themeHeader.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	themeHeader.BorderSizePixel = 0
	themeHeader.Size = UDim2.new(0, 536, 0, 38)
	themeHeader.Font = Enum.Font.SourceSans
	themeHeader.Text = "               Theme Settings"
	themeHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
	themeHeader.TextSize = 20
	themeHeader.TextXAlignment = Enum.TextXAlignment.Left

	local themeCorner = Instance.new("UICorner")
	themeCorner.CornerRadius = UDim.new(0, 4)
	themeCorner.Parent = themeHeader

	local themeIcon = Instance.new("ImageLabel")
	themeIcon.Parent = themeHeader
	themeIcon.BackgroundTransparency = 1
	themeIcon.Size = UDim2.new(0, 41, 0, 38)
	themeIcon.Image = "rbxassetid://7059346373"

	local themeArrow = Instance.new("ImageLabel")
	themeArrow.Parent = themeHeader
	themeArrow.BackgroundTransparency = 1
	themeArrow.Position = UDim2.new(0.931, 0, 0.026, 0)
	themeArrow.Rotation = 90
	themeArrow.Size = UDim2.new(0, 33, 0, 35)
	themeArrow.Image = "rbxassetid://120072340768479"

	local themeSubHolder = Instance.new("ScrollingFrame")
	themeSubHolder.Name = "ThemeSubHolder"
	themeSubHolder.Parent = self.SettingsPage
	themeSubHolder.Active = true
	themeSubHolder.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	themeSubHolder.BorderSizePixel = 0
	themeSubHolder.Size = UDim2.new(0, 536, 0, 0)
	themeSubHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
	themeSubHolder.ScrollBarThickness = 4
	themeSubHolder.Visible = false
	themeSubHolder.LayoutOrder = 1

	local themeSubCorner = Instance.new("UICorner")
	themeSubCorner.CornerRadius = UDim.new(0, 4)
	themeSubCorner.Parent = themeSubHolder

	local themeSubList = Instance.new("UIListLayout")
	themeSubList.Parent = themeSubHolder
	themeSubList.SortOrder = Enum.SortOrder.LayoutOrder
	themeSubList.Padding = UDim.new(0, 10)

	local themeSubPadding = Instance.new("UIPadding")
	themeSubPadding.Parent = themeSubHolder
	themeSubPadding.PaddingTop = UDim.new(0, 10)
	themeSubPadding.PaddingBottom = UDim.new(0, 10)
	themeSubPadding.PaddingLeft = UDim.new(0, 5)
	themeSubPadding.PaddingRight = UDim.new(0, 5)

	themeSubList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		themeSubHolder.CanvasSize = UDim2.new(0, 0, 0, themeSubList.AbsoluteContentSize.Y + 20)
	end)

	local themeExpanded = false

	themeHeader.MouseButton2Click:Connect(function()
		themeExpanded = not themeExpanded
		if themeExpanded then
			themeSubHolder.Visible = true
			local contentHeight = themeSubList.AbsoluteContentSize.Y + 20
			local targetHeight = math.min(contentHeight, 250)
			Tween(themeSubHolder, {Size = UDim2.new(0, 536, 0, targetHeight)}, 0.3)
		else
			Tween(themeSubHolder, {Size = UDim2.new(0, 536, 0, 0)}, 0.3).Completed:Connect(function()
				themeSubHolder.Visible = false
			end)
		end
	end)

	local rainbowLabel = Instance.new("TextLabel")
	rainbowLabel.Parent = themeSubHolder
	rainbowLabel.BackgroundTransparency = 1
	rainbowLabel.Size = UDim2.new(0, 93, 0, 18)
	rainbowLabel.Font = Enum.Font.SourceSans
	rainbowLabel.Text = "      Rainbow Theme"
	rainbowLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	rainbowLabel.TextSize = 20
	rainbowLabel.TextXAlignment = Enum.TextXAlignment.Left

	local rainbowKnob = Instance.new("TextButton")
	rainbowKnob.Name = "RainbowKnob"
	rainbowKnob.Parent = rainbowLabel
	rainbowKnob.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	rainbowKnob.BorderSizePixel = 0
	rainbowKnob.Position = UDim2.new(5.2, 0, 0, 0)
	rainbowKnob.Size = UDim2.new(0, 33, 0, 20)
	rainbowKnob.Text = ""

	local rainbowKnobCorner = Instance.new("UICorner")
	rainbowKnobCorner.CornerRadius = UDim.new(0, 4)
	rainbowKnobCorner.Parent = rainbowKnob

	local rainbowIndicator = Instance.new("Frame")
	rainbowIndicator.Parent = rainbowKnob
	rainbowIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	rainbowIndicator.BorderSizePixel = 0
	rainbowIndicator.Size = UDim2.new(0, 15, 0, 20)

	local rainbowIndCorner = Instance.new("UICorner")
	rainbowIndCorner.CornerRadius = UDim.new(0, 4)
	rainbowIndCorner.Parent = rainbowIndicator

	rainbowKnob.MouseButton1Click:Connect(function()
		self.RainbowEnabled = not self.RainbowEnabled
		if self.RainbowEnabled then
			Tween(rainbowIndicator, {Position = UDim2.new(0, 18, 0, 0), BackgroundColor3 = Color3.fromRGB(0, 255, 0)}, 0.2)
			self:StartRainbow()
		else
			Tween(rainbowIndicator, {Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(255, 0, 0)}, 0.2)
			self:StopRainbow()
		end
		if self.AutoSave and not self.IsLoading then
			self:SaveConfig()
		end
	end)

	local speedContainer = Instance.new("Frame")
	speedContainer.Parent = themeSubHolder
	speedContainer.BackgroundTransparency = 1
	speedContainer.Size = UDim2.new(0, 520, 0, 45)

	local speedLabel = Instance.new("TextLabel")
	speedLabel.Parent = speedContainer
	speedLabel.BackgroundTransparency = 1
	speedLabel.Position = UDim2.new(0, 6, 0, 0)
	speedLabel.Size = UDim2.new(0, 200, 0, 18)
	speedLabel.Font = Enum.Font.SourceSans
	speedLabel.Text = "      Rainbow Speed"
	speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	speedLabel.TextSize = 20
	speedLabel.TextXAlignment = Enum.TextXAlignment.Left

	local speedValueBox = Instance.new("TextBox")
	speedValueBox.Parent = speedContainer
	speedValueBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	speedValueBox.BorderSizePixel = 0
	speedValueBox.Position = UDim2.new(0, 456, 0, -2)
	speedValueBox.Size = UDim2.new(0, 60, 0, 22)
	speedValueBox.Font = Enum.Font.SourceSans
	speedValueBox.Text = "1"
	speedValueBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	speedValueBox.TextSize = 18

	local speedValueCorner = Instance.new("UICorner")
	speedValueCorner.CornerRadius = UDim.new(0, 4)
	speedValueCorner.Parent = speedValueBox

	local speedSliderBg = Instance.new("Frame")
	speedSliderBg.Parent = speedContainer
	speedSliderBg.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	speedSliderBg.BorderSizePixel = 0
	speedSliderBg.Position = UDim2.new(0, 16, 0, 25)
	speedSliderBg.Size = UDim2.new(0, 490, 0, 6)

	local speedSliderCorner = Instance.new("UICorner")
	speedSliderCorner.CornerRadius = UDim.new(1, 0)
	speedSliderCorner.Parent = speedSliderBg

	local speedSliderFill = Instance.new("Frame")
	speedSliderFill.Parent = speedSliderBg
	speedSliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	speedSliderFill.BorderSizePixel = 0
	speedSliderFill.Size = UDim2.new(0, 0, 1, 0)

	local speedFillCorner = Instance.new("UICorner")
	speedFillCorner.CornerRadius = UDim.new(1, 0)
	speedFillCorner.Parent = speedSliderFill

	local speedHandle = Instance.new("Frame")
	speedHandle.Parent = speedContainer
	speedHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	speedHandle.BorderSizePixel = 0
	speedHandle.Position = UDim2.new(0, 16, 0, 16)
	speedHandle.Size = UDim2.new(0, 24, 0, 24)
	speedHandle.ZIndex = 2

	local speedHandleCorner = Instance.new("UICorner")
	speedHandleCorner.CornerRadius = UDim.new(1, 0)
	speedHandleCorner.Parent = speedHandle

	local speedHandleButton = Instance.new("TextButton")
	speedHandleButton.Parent = speedHandle
	speedHandleButton.BackgroundTransparency = 1
	speedHandleButton.Size = UDim2.new(1, 0, 1, 0)
	speedHandleButton.Text = ""
	speedHandleButton.ZIndex = 3

	local speedDragging = false

	local function updateSpeedSlider(inputPos)
		local relativeX = inputPos.X - speedSliderBg.AbsolutePosition.X
		local pos = math.clamp(relativeX / speedSliderBg.AbsoluteSize.X, 0, 1)
		self.RainbowSpeed = math.floor(1 + (10 - 1) * pos)
		speedValueBox.Text = tostring(self.RainbowSpeed)
		speedSliderFill.Size = UDim2.new(pos, 0, 1, 0)
		speedHandle.Position = UDim2.new(0, 16 + (490 * pos) - 12, 0, 16)
		if self.AutoSave and not self.IsLoading then
			self:SaveConfig()
		end
	end

	speedHandleButton.MouseButton1Down:Connect(function()
		speedDragging = true
	end)

	speedSliderBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			speedDragging = true
			updateSpeedSlider(input.Position)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			speedDragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if speedDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSpeedSlider(input.Position)
		end
	end)

	speedValueBox.FocusLost:Connect(function()
		local inputValue = tonumber(speedValueBox.Text)
		if inputValue then
			self.RainbowSpeed = math.clamp(math.floor(inputValue), 1, 10)
			speedValueBox.Text = tostring(self.RainbowSpeed)
			local pos = (self.RainbowSpeed - 1) / (10 - 1)
			speedSliderFill.Size = UDim2.new(pos, 0, 1, 0)
			speedHandle.Position = UDim2.new(0, 16 + (490 * pos) - 12, 0, 16)
			if self.AutoSave and not self.IsLoading then
				self:SaveConfig()
			end
		else
			speedValueBox.Text = tostring(self.RainbowSpeed)
		end
	end)

	local waveSpreadContainer = Instance.new("Frame")
	waveSpreadContainer.Parent = themeSubHolder
	waveSpreadContainer.BackgroundTransparency = 1
	waveSpreadContainer.Size = UDim2.new(0, 520, 0, 45)

	local waveSpreadLabel = Instance.new("TextLabel")
	waveSpreadLabel.Parent = waveSpreadContainer
	waveSpreadLabel.BackgroundTransparency = 1
	waveSpreadLabel.Position = UDim2.new(0, 6, 0, 0)
	waveSpreadLabel.Size = UDim2.new(0, 200, 0, 18)
	waveSpreadLabel.Font = Enum.Font.SourceSans
	waveSpreadLabel.Text = "      Gradient Intensity"
	waveSpreadLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	waveSpreadLabel.TextSize = 20
	waveSpreadLabel.TextXAlignment = Enum.TextXAlignment.Left

	local waveSpreadValueBox = Instance.new("TextBox")
	waveSpreadValueBox.Parent = waveSpreadContainer
	waveSpreadValueBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	waveSpreadValueBox.BorderSizePixel = 0
	waveSpreadValueBox.Position = UDim2.new(0, 456, 0, -2)
	waveSpreadValueBox.Size = UDim2.new(0, 60, 0, 22)
	waveSpreadValueBox.Font = Enum.Font.SourceSans
	waveSpreadValueBox.Text = "0.6"
	waveSpreadValueBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	waveSpreadValueBox.TextSize = 18

	local waveSpreadValueCorner = Instance.new("UICorner")
	waveSpreadValueCorner.CornerRadius = UDim.new(0, 4)
	waveSpreadValueCorner.Parent = waveSpreadValueBox

	local waveSpreadSliderBg = Instance.new("Frame")
	waveSpreadSliderBg.Parent = waveSpreadContainer
	waveSpreadSliderBg.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	waveSpreadSliderBg.BorderSizePixel = 0
	waveSpreadSliderBg.Position = UDim2.new(0, 16, 0, 25)
	waveSpreadSliderBg.Size = UDim2.new(0, 490, 0, 6)

	local waveSpreadSliderCorner = Instance.new("UICorner")
	waveSpreadSliderCorner.CornerRadius = UDim.new(1, 0)
	waveSpreadSliderCorner.Parent = waveSpreadSliderBg

	local waveSpreadSliderFill = Instance.new("Frame")
	waveSpreadSliderFill.Parent = waveSpreadSliderBg
	waveSpreadSliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	waveSpreadSliderFill.BorderSizePixel = 0
	waveSpreadSliderFill.Size = UDim2.new(0.6, 0, 1, 0)

	local waveSpreadFillCorner = Instance.new("UICorner")
	waveSpreadFillCorner.CornerRadius = UDim.new(1, 0)
	waveSpreadFillCorner.Parent = waveSpreadSliderFill

	local waveSpreadHandle = Instance.new("Frame")
	waveSpreadHandle.Parent = waveSpreadContainer
	waveSpreadHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	waveSpreadHandle.BorderSizePixel = 0
	waveSpreadHandle.Position = UDim2.new(0, 16 + (490 * 0.6) - 12, 0, 16)
	waveSpreadHandle.Size = UDim2.new(0, 24, 0, 24)
	waveSpreadHandle.ZIndex = 2

	local waveSpreadHandleCorner = Instance.new("UICorner")
	waveSpreadHandleCorner.CornerRadius = UDim.new(1, 0)
	waveSpreadHandleCorner.Parent = waveSpreadHandle

	local waveSpreadHandleButton = Instance.new("TextButton")
	waveSpreadHandleButton.Parent = waveSpreadHandle
	waveSpreadHandleButton.BackgroundTransparency = 1
	waveSpreadHandleButton.Size = UDim2.new(1, 0, 1, 0)
	waveSpreadHandleButton.Text = ""
	waveSpreadHandleButton.ZIndex = 3

	local waveSpreadDragging = false

	local function updateWaveSpreadSlider(inputPos)
		local relativeX = inputPos.X - waveSpreadSliderBg.AbsolutePosition.X
		local pos = math.clamp(relativeX / waveSpreadSliderBg.AbsoluteSize.X, 0, 1)
		self.WaveSpread = math.floor(pos * 100 + 0.5) / 100
		waveSpreadValueBox.Text = tostring(self.WaveSpread)
		waveSpreadSliderFill.Size = UDim2.new(pos, 0, 1, 0)
		waveSpreadHandle.Position = UDim2.new(0, 16 + (490 * pos) - 12, 0, 16)
		self:UpdateGUI(self.GUIColor.Hue, self.GUIColor.Sat, self.GUIColor.Value)
		if self.AutoSave and not self.IsLoading then
			self:SaveConfig()
		end
	end

	waveSpreadHandleButton.MouseButton1Down:Connect(function()
		waveSpreadDragging = true
	end)

	waveSpreadSliderBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			waveSpreadDragging = true
			updateWaveSpreadSlider(input.Position)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			waveSpreadDragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if waveSpreadDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateWaveSpreadSlider(input.Position)
		end
	end)

	waveSpreadValueBox.FocusLost:Connect(function()
		local inputValue = tonumber(waveSpreadValueBox.Text)
		if inputValue then
			self.WaveSpread = math.clamp(inputValue, 0, 1)
			waveSpreadValueBox.Text = tostring(self.WaveSpread)
			local pos = self.WaveSpread
			waveSpreadSliderFill.Size = UDim2.new(pos, 0, 1, 0)
			waveSpreadHandle.Position = UDim2.new(0, 16 + (490 * pos) - 12, 0, 16)
			self:UpdateGUI(self.GUIColor.Hue, self.GUIColor.Sat, self.GUIColor.Value)
			if self.AutoSave and not self.IsLoading then
				self:SaveConfig()
			end
		else
			waveSpreadValueBox.Text = tostring(self.WaveSpread)
		end
	end)

	local colorPickerSeparator = Instance.new("Frame")
	colorPickerSeparator.Parent = themeSubHolder
	colorPickerSeparator.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	colorPickerSeparator.BorderSizePixel = 0
	colorPickerSeparator.Size = UDim2.new(0, 510, 0, 1)

	local colorPickerHeaderRow = Instance.new("Frame")
	colorPickerHeaderRow.Parent = themeSubHolder
	colorPickerHeaderRow.BackgroundTransparency = 1
	colorPickerHeaderRow.Size = UDim2.new(0, 520, 0, 24)

	local colorPickerHeaderLabel = Instance.new("TextLabel")
	colorPickerHeaderLabel.Parent = colorPickerHeaderRow
	colorPickerHeaderLabel.BackgroundTransparency = 1
	colorPickerHeaderLabel.Position = UDim2.new(0, 6, 0, 0)
	colorPickerHeaderLabel.Size = UDim2.new(0, 200, 0, 24)
	colorPickerHeaderLabel.Font = Enum.Font.SourceSans
	colorPickerHeaderLabel.Text = "      GUI Color"
	colorPickerHeaderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	colorPickerHeaderLabel.TextSize = 20
	colorPickerHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left

	local colorPreviewFrame = Instance.new("Frame")
	colorPreviewFrame.Parent = colorPickerHeaderRow
	colorPreviewFrame.BackgroundColor3 = Color3.fromHSV(self.GUIColor.Hue, self.GUIColor.Sat, self.GUIColor.Value)
	colorPreviewFrame.BorderSizePixel = 0
	colorPreviewFrame.Position = UDim2.new(0, 456, 0, 1)
	colorPreviewFrame.Size = UDim2.new(0, 60, 0, 22)

	local colorPreviewCorner = Instance.new("UICorner")
	colorPreviewCorner.CornerRadius = UDim.new(0, 4)
	colorPreviewCorner.Parent = colorPreviewFrame

	self.ColorPreviewPointer = colorPreviewFrame

	local function makeColorSlider(parent, labelText, initialPos)
		local container = Instance.new("Frame")
		container.Parent = parent
		container.BackgroundTransparency = 1
		container.Size = UDim2.new(0, 520, 0, 38)

		local lbl = Instance.new("TextLabel")
		lbl.Parent = container
		lbl.BackgroundTransparency = 1
		lbl.Position = UDim2.new(0, 6, 0, 0)
		lbl.Size = UDim2.new(0, 200, 0, 16)
		lbl.Font = Enum.Font.SourceSans
		lbl.Text = "      " .. labelText
		lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
		lbl.TextSize = 17
		lbl.TextXAlignment = Enum.TextXAlignment.Left

		local valBox = Instance.new("TextBox")
		valBox.Parent = container
		valBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		valBox.BorderSizePixel = 0
		valBox.Position = UDim2.new(0, 456, 0, -1)
		valBox.Size = UDim2.new(0, 60, 0, 20)
		valBox.Font = Enum.Font.SourceSans
		valBox.Text = tostring(math.floor(initialPos * 100))
		valBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		valBox.TextSize = 16

		local valBoxCorner = Instance.new("UICorner")
		valBoxCorner.CornerRadius = UDim.new(0, 4)
		valBoxCorner.Parent = valBox

		local bg = Instance.new("Frame")
		bg.Parent = container
		bg.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		bg.BorderSizePixel = 0
		bg.Position = UDim2.new(0, 16, 0, 22)
		bg.Size = UDim2.new(0, 490, 0, 5)

		local bgCorner = Instance.new("UICorner")
		bgCorner.CornerRadius = UDim.new(1, 0)
		bgCorner.Parent = bg

		local fill = Instance.new("Frame")
		fill.Parent = bg
		fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		fill.BorderSizePixel = 0
		fill.Size = UDim2.new(initialPos, 0, 1, 0)

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(1, 0)
		fillCorner.Parent = fill

		local handle = Instance.new("Frame")
		handle.Parent = container
		handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		handle.BorderSizePixel = 0
		handle.Position = UDim2.new(0, 16 + (490 * initialPos) - 10, 0, 14)
		handle.Size = UDim2.new(0, 20, 0, 20)
		handle.ZIndex = 2

		local handleCorner = Instance.new("UICorner")
		handleCorner.CornerRadius = UDim.new(1, 0)
		handleCorner.Parent = handle

		local hBtn = Instance.new("TextButton")
		hBtn.Parent = handle
		hBtn.BackgroundTransparency = 1
		hBtn.Size = UDim2.new(1, 0, 1, 0)
		hBtn.Text = ""
		hBtn.ZIndex = 3

		return container, bg, fill, handle, hBtn, valBox
	end

	local hContainer, hBg, hFill, hHandle, hBtn, hValBox = makeColorSlider(themeSubHolder, "Hue", self.GUIColor.Hue)
	local sContainer, sBg, sFill, sHandle, sBtn, sValBox = makeColorSlider(themeSubHolder, "Saturation", self.GUIColor.Sat)
	local vContainer, vBg, vFill, vHandle, vBtn, vValBox = makeColorSlider(themeSubHolder, "Brightness", self.GUIColor.Value)

	local hDrag, sDrag, vDrag = false, false, false

	local function applyColorFromSliders()
		colorPreviewFrame.BackgroundColor3 = Color3.fromHSV(self.GUIColor.Hue, self.GUIColor.Sat, self.GUIColor.Value)
		if not self.RainbowEnabled then
			self:UpdateGUI(self.GUIColor.Hue, self.GUIColor.Sat, self.GUIColor.Value)
		end
		if self.AutoSave and not self.IsLoading then
			self:SaveConfig()
		end
	end

	local function updateHSlider(inputPos)
		local pos = math.clamp((inputPos.X - hBg.AbsolutePosition.X) / hBg.AbsoluteSize.X, 0, 1)
		self.GUIColor.Hue = pos
		hFill.Size = UDim2.new(pos, 0, 1, 0)
		hHandle.Position = UDim2.new(0, 16 + (490 * pos) - 10, 0, 14)
		hValBox.Text = tostring(math.floor(pos * 100))
		applyColorFromSliders()
	end

	local function updateSSlider(inputPos)
		local pos = math.clamp((inputPos.X - sBg.AbsolutePosition.X) / sBg.AbsoluteSize.X, 0, 1)
		self.GUIColor.Sat = pos
		sFill.Size = UDim2.new(pos, 0, 1, 0)
		sHandle.Position = UDim2.new(0, 16 + (490 * pos) - 10, 0, 14)
		sValBox.Text = tostring(math.floor(pos * 100))
		applyColorFromSliders()
	end

	local function updateVSlider(inputPos)
		local pos = math.clamp((inputPos.X - vBg.AbsolutePosition.X) / vBg.AbsoluteSize.X, 0, 1)
		self.GUIColor.Value = pos
		vFill.Size = UDim2.new(pos, 0, 1, 0)
		vHandle.Position = UDim2.new(0, 16 + (490 * pos) - 10, 0, 14)
		vValBox.Text = tostring(math.floor(pos * 100))
		applyColorFromSliders()
	end

	hBtn.MouseButton1Down:Connect(function() hDrag = true end)
	sBtn.MouseButton1Down:Connect(function() sDrag = true end)
	vBtn.MouseButton1Down:Connect(function() vDrag = true end)

	hBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			hDrag = true
			updateHSlider(input.Position)
		end
	end)
	sBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sDrag = true
			updateSSlider(input.Position)
		end
	end)
	vBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			vDrag = true
			updateVSlider(input.Position)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			hDrag = false
			sDrag = false
			vDrag = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if hDrag then updateHSlider(input.Position) end
			if sDrag then updateSSlider(input.Position) end
			if vDrag then updateVSlider(input.Position) end
		end
	end)

	hValBox.FocusLost:Connect(function()
		local v = tonumber(hValBox.Text)
		if v then
			self.GUIColor.Hue = math.clamp(v / 100, 0, 1)
			hValBox.Text = tostring(math.floor(self.GUIColor.Hue * 100))
			local pos = self.GUIColor.Hue
			hFill.Size = UDim2.new(pos, 0, 1, 0)
			hHandle.Position = UDim2.new(0, 16 + (490 * pos) - 10, 0, 14)
			applyColorFromSliders()
		else
			hValBox.Text = tostring(math.floor(self.GUIColor.Hue * 100))
		end
	end)

	sValBox.FocusLost:Connect(function()
		local v = tonumber(sValBox.Text)
		if v then
			self.GUIColor.Sat = math.clamp(v / 100, 0, 1)
			sValBox.Text = tostring(math.floor(self.GUIColor.Sat * 100))
			local pos = self.GUIColor.Sat
			sFill.Size = UDim2.new(pos, 0, 1, 0)
			sHandle.Position = UDim2.new(0, 16 + (490 * pos) - 10, 0, 14)
			applyColorFromSliders()
		else
			sValBox.Text = tostring(math.floor(self.GUIColor.Sat * 100))
		end
	end)

	vValBox.FocusLost:Connect(function()
		local v = tonumber(vValBox.Text)
		if v then
			self.GUIColor.Value = math.clamp(v / 100, 0, 1)
			vValBox.Text = tostring(math.floor(self.GUIColor.Value * 100))
			local pos = self.GUIColor.Value
			vFill.Size = UDim2.new(pos, 0, 1, 0)
			vHandle.Position = UDim2.new(0, 16 + (490 * pos) - 10, 0, 14)
			applyColorFromSliders()
		else
			vValBox.Text = tostring(math.floor(self.GUIColor.Value * 100))
		end
	end)

	self._hValBox = hValBox
	self._sValBox = sValBox
	self._vValBox = vValBox
	self._hFill = hFill
	self._sFill = sFill
	self._vFill = vFill
	self._hHandle = hHandle
	self._sHandle = sHandle
	self._vHandle = vHandle

	local gradientLabel = Instance.new("TextLabel")
	gradientLabel.Parent = themeSubHolder
	gradientLabel.BackgroundTransparency = 1
	gradientLabel.Size = UDim2.new(0, 93, 0, 18)
	gradientLabel.Font = Enum.Font.SourceSans
	gradientLabel.Text = "      Gradient UI"
	gradientLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	gradientLabel.TextSize = 20
	gradientLabel.TextXAlignment = Enum.TextXAlignment.Left

	local gradientKnob = Instance.new("TextButton")
	gradientKnob.Name = "GradientKnob"
	gradientKnob.Parent = gradientLabel
	gradientKnob.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	gradientKnob.BorderSizePixel = 0
	gradientKnob.Position = UDim2.new(5.2, 0, 0, 0)
	gradientKnob.Size = UDim2.new(0, 33, 0, 20)
	gradientKnob.Text = ""

	local gradientKnobCorner = Instance.new("UICorner")
	gradientKnobCorner.CornerRadius = UDim.new(0, 4)
	gradientKnobCorner.Parent = gradientKnob

	local gradientIndicator = Instance.new("Frame")
	gradientIndicator.Parent = gradientKnob
	gradientIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	gradientIndicator.BorderSizePixel = 0
	gradientIndicator.Size = UDim2.new(0, 15, 0, 20)

	local gradientIndCorner = Instance.new("UICorner")
	gradientIndCorner.CornerRadius = UDim.new(0, 4)
	gradientIndCorner.Parent = gradientIndicator

	gradientKnob.MouseButton1Click:Connect(function()
		self.GradientUI = not self.GradientUI
		if self.GradientUI then
			Tween(gradientIndicator, {Position = UDim2.new(0, 18, 0, 0), BackgroundColor3 = Color3.fromRGB(0, 255, 0)}, 0.2)
			self:ApplyGradients()
		else
			Tween(gradientIndicator, {Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(255, 0, 0)}, 0.2)
			self:RemoveGradients()
		end
		if self.AutoSave and not self.IsLoading then
			self:SaveConfig()
		end
	end)

	local uiBindHeader = Instance.new("TextButton")
	uiBindHeader.Name = "UIBindSettings"
	uiBindHeader.Parent = self.SettingsPage
	uiBindHeader.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	uiBindHeader.BorderSizePixel = 0
	uiBindHeader.Size = UDim2.new(0, 536, 0, 38)
	uiBindHeader.Font = Enum.Font.SourceSans
	uiBindHeader.Text = "               UI Visibility"
	uiBindHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
	uiBindHeader.TextSize = 20
	uiBindHeader.TextXAlignment = Enum.TextXAlignment.Left
	uiBindHeader.LayoutOrder = 1

	local uiBindHeaderCorner = Instance.new("UICorner")
	uiBindHeaderCorner.CornerRadius = UDim.new(0, 4)
	uiBindHeaderCorner.Parent = uiBindHeader

	local uiBindIcon = Instance.new("ImageLabel")
	uiBindIcon.Parent = uiBindHeader
	uiBindIcon.BackgroundTransparency = 1
	uiBindIcon.Size = UDim2.new(0, 41, 0, 38)
	uiBindIcon.Image = "rbxassetid://7059346373"

	local uiBindArrow = Instance.new("ImageLabel")
	uiBindArrow.Parent = uiBindHeader
	uiBindArrow.BackgroundTransparency = 1
	uiBindArrow.Position = UDim2.new(0.931, 0, 0.026, 0)
	uiBindArrow.Rotation = 90
	uiBindArrow.Size = UDim2.new(0, 33, 0, 35)
	uiBindArrow.Image = "rbxassetid://120072340768479"

	local uiBindSubHolder = Instance.new("Frame")
	uiBindSubHolder.Name = "UIBindSubHolder"
	uiBindSubHolder.Parent = self.SettingsPage
	uiBindSubHolder.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	uiBindSubHolder.BorderSizePixel = 0
	uiBindSubHolder.Size = UDim2.new(0, 536, 0, 0)
	uiBindSubHolder.Visible = false
	uiBindSubHolder.LayoutOrder = 2
	uiBindSubHolder.ClipsDescendants = true

	local uiBindSubCorner = Instance.new("UICorner")
	uiBindSubCorner.CornerRadius = UDim.new(0, 4)
	uiBindSubCorner.Parent = uiBindSubHolder

	local uiBindLabel = Instance.new("TextLabel")
	uiBindLabel.Parent = uiBindSubHolder
	uiBindLabel.BackgroundTransparency = 1
	uiBindLabel.Position = UDim2.new(0, 12, 0, 10)
	uiBindLabel.Size = UDim2.new(0, 200, 0, 18)
	uiBindLabel.Font = Enum.Font.SourceSans
	uiBindLabel.Text = "      Toggle UI Keybind"
	uiBindLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	uiBindLabel.TextSize = 20
	uiBindLabel.TextXAlignment = Enum.TextXAlignment.Left

	local uiKeybindButton = Instance.new("TextButton")
	uiKeybindButton.Name = "UIKeybindButton"
	uiKeybindButton.Parent = uiBindSubHolder
	uiKeybindButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	uiKeybindButton.BorderSizePixel = 0
	uiKeybindButton.Position = UDim2.new(0, 380, 0, 6)
	uiKeybindButton.Size = UDim2.new(0, 80, 0, 25)
	uiKeybindButton.Font = Enum.Font.SourceSans
	uiKeybindButton.Text = "RSHIFT"
	uiKeybindButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	uiKeybindButton.TextSize = 15
	uiKeybindButton.ZIndex = 2

	local uiKeybindCorner = Instance.new("UICorner")
	uiKeybindCorner.CornerRadius = UDim.new(0, 4)
	uiKeybindCorner.Parent = uiKeybindButton

	uiKeybindButton.MouseButton1Click:Connect(function()
		if not self.UIBindListening then
			self.UIBindListening = true
			uiKeybindButton.Text = "..."
			local conn
			conn = UserInputService.InputBegan:Connect(function(input, gp)
				if input.UserInputType == Enum.UserInputType.Keyboard then
					self.UIBindListening = false
					self.UIBindKey = input.KeyCode
					uiKeybindButton.Text = input.KeyCode.Name:sub(1, 6):upper()
					conn:Disconnect()
					self:Notify("UI Bind", "Keybind set to " .. input.KeyCode.Name, 3)
				end
			end)
		end
	end)

	local uiBindExpanded = false

	uiBindHeader.MouseButton2Click:Connect(function()
		uiBindExpanded = not uiBindExpanded
		if uiBindExpanded then
			uiBindSubHolder.Visible = true
			Tween(uiBindSubHolder, {Size = UDim2.new(0, 536, 0, 42)}, 0.3)
		else
			Tween(uiBindSubHolder, {Size = UDim2.new(0, 536, 0, 0)}, 0.3).Completed:Connect(function()
				uiBindSubHolder.Visible = false
			end)
		end
	end)

	local moduleStatusHeader = Instance.new("TextButton")
	moduleStatusHeader.Name = "ModuleStatusSettings"
	moduleStatusHeader.Parent = self.SettingsPage
	moduleStatusHeader.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	moduleStatusHeader.BorderSizePixel = 0
	moduleStatusHeader.Size = UDim2.new(0, 536, 0, 38)
	moduleStatusHeader.Font = Enum.Font.SourceSans
	moduleStatusHeader.Text = "               Module Status"
	moduleStatusHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
	moduleStatusHeader.TextSize = 20
	moduleStatusHeader.TextXAlignment = Enum.TextXAlignment.Left
	moduleStatusHeader.LayoutOrder = 2

	local moduleStatusHeaderCorner = Instance.new("UICorner")
	moduleStatusHeaderCorner.CornerRadius = UDim.new(0, 4)
	moduleStatusHeaderCorner.Parent = moduleStatusHeader

	local moduleStatusIcon = Instance.new("ImageLabel")
	moduleStatusIcon.Parent = moduleStatusHeader
	moduleStatusIcon.BackgroundTransparency = 1
	moduleStatusIcon.Size = UDim2.new(0, 41, 0, 38)
	moduleStatusIcon.Image = "rbxassetid://7059346373"

	local moduleStatusArrow = Instance.new("ImageLabel")
	moduleStatusArrow.Parent = moduleStatusHeader
	moduleStatusArrow.BackgroundTransparency = 1
	moduleStatusArrow.Position = UDim2.new(0.931, 0, 0.026, 0)
	moduleStatusArrow.Rotation = 90
	moduleStatusArrow.Size = UDim2.new(0, 33, 0, 35)
	moduleStatusArrow.Image = "rbxassetid://120072340768479"

	local moduleStatusSubHolder = Instance.new("Frame")
	moduleStatusSubHolder.Name = "ModuleStatusSubHolder"
	moduleStatusSubHolder.Parent = self.SettingsPage
	moduleStatusSubHolder.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	moduleStatusSubHolder.BorderSizePixel = 0
	moduleStatusSubHolder.Size = UDim2.new(0, 536, 0, 0)
	moduleStatusSubHolder.Visible = false
	moduleStatusSubHolder.LayoutOrder = 3
	moduleStatusSubHolder.ClipsDescendants = true

	local moduleStatusSubCorner = Instance.new("UICorner")
	moduleStatusSubCorner.CornerRadius = UDim.new(0, 4)
	moduleStatusSubCorner.Parent = moduleStatusSubHolder

	local moduleStatusEnableLabel = Instance.new("TextLabel")
	moduleStatusEnableLabel.Parent = moduleStatusSubHolder
	moduleStatusEnableLabel.BackgroundTransparency = 1
	moduleStatusEnableLabel.Position = UDim2.new(0, 12, 0, 10)
	moduleStatusEnableLabel.Size = UDim2.new(0, 200, 0, 18)
	moduleStatusEnableLabel.Font = Enum.Font.SourceSans
	moduleStatusEnableLabel.Text = "      Show Module Status"
	moduleStatusEnableLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	moduleStatusEnableLabel.TextSize = 20
	moduleStatusEnableLabel.TextXAlignment = Enum.TextXAlignment.Left

	local moduleStatusKnob = Instance.new("TextButton")
	moduleStatusKnob.Name = "ModuleStatusKnob"
	moduleStatusKnob.Parent = moduleStatusSubHolder
	moduleStatusKnob.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	moduleStatusKnob.BorderSizePixel = 0
	moduleStatusKnob.Position = UDim2.new(0, 380, 0, 8)
	moduleStatusKnob.Size = UDim2.new(0, 33, 0, 20)
	moduleStatusKnob.Text = ""
	moduleStatusKnob.ZIndex = 2

	local moduleStatusKnobCorner = Instance.new("UICorner")
	moduleStatusKnobCorner.CornerRadius = UDim.new(0, 4)
	moduleStatusKnobCorner.Parent = moduleStatusKnob

	local moduleStatusIndicator = Instance.new("Frame")
	moduleStatusIndicator.Parent = moduleStatusKnob
	moduleStatusIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	moduleStatusIndicator.BorderSizePixel = 0
	moduleStatusIndicator.Size = UDim2.new(0, 15, 0, 20)

	local moduleStatusIndCorner = Instance.new("UICorner")
	moduleStatusIndCorner.CornerRadius = UDim.new(0, 4)
	moduleStatusIndCorner.Parent = moduleStatusIndicator

	moduleStatusKnob.MouseButton1Click:Connect(function()
		self.ModuleStatusEnabled = not self.ModuleStatusEnabled
		if self.ModuleStatusEnabled then
			Tween(moduleStatusIndicator, {Position = UDim2.new(0, 18, 0, 0), BackgroundColor3 = Color3.fromRGB(0, 255, 0)}, 0.2)
			self.ModuleStatusHolder.Visible = true
			self:RebuildModuleStatus()
			if not self.ModuleStatusRainbowConnection then
				self.ModuleStatusRainbowHue = 0
				self.ModuleStatusRainbowConnection = RunService.Heartbeat:Connect(function(delta)
					self.ModuleStatusRainbowHue = (self.ModuleStatusRainbowHue + (delta * 0.1)) % 1
					self:UpdateModuleStatusColors(self.ModuleStatusRainbowHue)
				end)
			end
		else
			Tween(moduleStatusIndicator, {Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(255, 0, 0)}, 0.2)
			self.ModuleStatusHolder.Visible = false
			if self.ModuleStatusRainbowConnection then
				self.ModuleStatusRainbowConnection:Disconnect()
				self.ModuleStatusRainbowConnection = nil
			end
		end
		if self.AutoSave and not self.IsLoading then
			self:SaveConfig()
		end
	end)

	local moduleStatusExpanded = false

	moduleStatusHeader.MouseButton2Click:Connect(function()
		moduleStatusExpanded = not moduleStatusExpanded
		if moduleStatusExpanded then
			moduleStatusSubHolder.Visible = true
			Tween(moduleStatusSubHolder, {Size = UDim2.new(0, 536, 0, 44)}, 0.3)
		else
			Tween(moduleStatusSubHolder, {Size = UDim2.new(0, 536, 0, 0)}, 0.3).Completed:Connect(function()
				moduleStatusSubHolder.Visible = false
			end)
		end
	end)

	local fileHeader = Instance.new("TextButton")
	fileHeader.Name = "FileSettings"
	fileHeader.Parent = self.SettingsPage
	fileHeader.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	fileHeader.BorderSizePixel = 0
	fileHeader.Size = UDim2.new(0, 536, 0, 38)
	fileHeader.Font = Enum.Font.SourceSans
	fileHeader.Text = "               File System"
	fileHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
	fileHeader.TextSize = 20
	fileHeader.TextXAlignment = Enum.TextXAlignment.Left
	fileHeader.LayoutOrder = 4

	local fileCorner = Instance.new("UICorner")
	fileCorner.CornerRadius = UDim.new(0, 4)
	fileCorner.Parent = fileHeader

	local fileIcon = Instance.new("ImageLabel")
	fileIcon.Parent = fileHeader
	fileIcon.BackgroundTransparency = 1
	fileIcon.Size = UDim2.new(0, 41, 0, 38)
	fileIcon.Image = "rbxassetid://7059346373"

	local fileArrow = Instance.new("ImageLabel")
	fileArrow.Parent = fileHeader
	fileArrow.BackgroundTransparency = 1
	fileArrow.Position = UDim2.new(0.931, 0, 0.026, 0)
	fileArrow.Rotation = 90
	fileArrow.Size = UDim2.new(0, 33, 0, 35)
	fileArrow.Image = "rbxassetid://120072340768479"

	local fileSubHolder = Instance.new("ScrollingFrame")
	fileSubHolder.Name = "FileSubHolder"
	fileSubHolder.Parent = self.SettingsPage
	fileSubHolder.Active = true
	fileSubHolder.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	fileSubHolder.BorderSizePixel = 0
	fileSubHolder.Size = UDim2.new(0, 536, 0, 0)
	fileSubHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
	fileSubHolder.ScrollBarThickness = 4
	fileSubHolder.Visible = false
	fileSubHolder.LayoutOrder = 5

	local fileSubCorner = Instance.new("UICorner")
	fileSubCorner.CornerRadius = UDim.new(0, 4)
	fileSubCorner.Parent = fileSubHolder

	local fileSubList = Instance.new("UIListLayout")
	fileSubList.Parent = fileSubHolder
	fileSubList.SortOrder = Enum.SortOrder.LayoutOrder
	fileSubList.Padding = UDim.new(0, 10)

	local fileSubPadding = Instance.new("UIPadding")
	fileSubPadding.Parent = fileSubHolder
	fileSubPadding.PaddingTop = UDim.new(0, 10)
	fileSubPadding.PaddingBottom = UDim.new(0, 10)
	fileSubPadding.PaddingLeft = UDim.new(0, 5)
	fileSubPadding.PaddingRight = UDim.new(0, 5)

	fileSubList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		fileSubHolder.CanvasSize = UDim2.new(0, 0, 0, fileSubList.AbsoluteContentSize.Y + 20)
	end)

	local fileExpanded = false

	fileHeader.MouseButton2Click:Connect(function()
		fileExpanded = not fileExpanded
		if fileExpanded then
			fileSubHolder.Visible = true
			local contentHeight = fileSubList.AbsoluteContentSize.Y + 20
			local targetHeight = math.min(contentHeight, 200)
			Tween(fileSubHolder, {Size = UDim2.new(0, 536, 0, targetHeight)}, 0.3)
		else
			Tween(fileSubHolder, {Size = UDim2.new(0, 536, 0, 0)}, 0.3).Completed:Connect(function()
				fileSubHolder.Visible = false
			end)
		end
	end)

	local autoSaveLabel = Instance.new("TextLabel")
	autoSaveLabel.Parent = fileSubHolder
	autoSaveLabel.BackgroundTransparency = 1
	autoSaveLabel.Size = UDim2.new(0, 93, 0, 18)
	autoSaveLabel.Font = Enum.Font.SourceSans
	autoSaveLabel.Text = "      Auto Save"
	autoSaveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	autoSaveLabel.TextSize = 20
	autoSaveLabel.TextXAlignment = Enum.TextXAlignment.Left

	local autoSaveKnob = Instance.new("TextButton")
	autoSaveKnob.Name = "AutoSaveKnob"
	autoSaveKnob.Parent = autoSaveLabel
	autoSaveKnob.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	autoSaveKnob.BorderSizePixel = 0
	autoSaveKnob.Position = UDim2.new(5.2, 0, 0, 0)
	autoSaveKnob.Size = UDim2.new(0, 33, 0, 20)
	autoSaveKnob.Text = ""

	local autoSaveKnobCorner = Instance.new("UICorner")
	autoSaveKnobCorner.CornerRadius = UDim.new(0, 4)
	autoSaveKnobCorner.Parent = autoSaveKnob

	local autoSaveIndicator = Instance.new("Frame")
	autoSaveIndicator.Parent = autoSaveKnob
	autoSaveIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	autoSaveIndicator.BorderSizePixel = 0
	autoSaveIndicator.Size = UDim2.new(0, 15, 0, 20)
	autoSaveIndicator.Position = UDim2.new(0, 18, 0, 0)

	local autoSaveIndCorner = Instance.new("UICorner")
	autoSaveIndCorner.CornerRadius = UDim.new(0, 4)
	autoSaveIndCorner.Parent = autoSaveIndicator

	autoSaveKnob.MouseButton1Click:Connect(function()
		self.AutoSave = not self.AutoSave
		if self.AutoSave then
			Tween(autoSaveIndicator, {Position = UDim2.new(0, 18, 0, 0), BackgroundColor3 = Color3.fromRGB(0, 255, 0)}, 0.2)
		else
			Tween(autoSaveIndicator, {Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(255, 0, 0)}, 0.2)
		end
	end)

	local deleteConfigButton = Instance.new("TextButton")
	deleteConfigButton.Parent = fileSubHolder
	deleteConfigButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	deleteConfigButton.BorderSizePixel = 0
	deleteConfigButton.Size = UDim2.new(0, 520, 0, 30)
	deleteConfigButton.Font = Enum.Font.SourceSans
	deleteConfigButton.Text = "Delete Config File"
	deleteConfigButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	deleteConfigButton.TextSize = 18

	local deleteCorner = Instance.new("UICorner")
	deleteCorner.CornerRadius = UDim.new(0, 4)
	deleteCorner.Parent = deleteConfigButton

	deleteConfigButton.MouseButton1Click:Connect(function()
		self:DeleteConfig()
		deleteConfigButton.Text = "Config Deleted!"
		wait(2)
		deleteConfigButton.Text = "Delete Config File"
	end)

	local saveNowButton = Instance.new("TextButton")
	saveNowButton.Parent = fileSubHolder
	saveNowButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	saveNowButton.BorderSizePixel = 0
	saveNowButton.Size = UDim2.new(0, 520, 0, 30)
	saveNowButton.Font = Enum.Font.SourceSans
	saveNowButton.Text = "Save Config Now"
	saveNowButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	saveNowButton.TextSize = 18

	local saveCorner = Instance.new("UICorner")
	saveCorner.CornerRadius = UDim.new(0, 4)
	saveCorner.Parent = saveNowButton

	saveNowButton.MouseButton1Click:Connect(function()
		self:SaveConfig()
		saveNowButton.Text = "Config Saved!"
		wait(2)
		saveNowButton.Text = "Save Config Now"
	end)

	local loadNowButton = Instance.new("TextButton")
	loadNowButton.Parent = fileSubHolder
	loadNowButton.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
	loadNowButton.BorderSizePixel = 0
	loadNowButton.Size = UDim2.new(0, 520, 0, 30)
	loadNowButton.Font = Enum.Font.SourceSans
	loadNowButton.Text = "Load Config"
	loadNowButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	loadNowButton.TextSize = 18

	local loadCorner = Instance.new("UICorner")
	loadCorner.CornerRadius = UDim.new(0, 4)
	loadCorner.Parent = loadNowButton

	loadNowButton.MouseButton1Click:Connect(function()
		self:LoadConfig()
		loadNowButton.Text = "Config Loaded!"
		wait(2)
		loadNowButton.Text = "Load Config"
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if not gp and input.UserInputType == Enum.UserInputType.Keyboard then
			if not self.UIBindListening and input.KeyCode == self.UIBindKey then
				self.UIVisible = not self.UIVisible
				self.MainHolder.Visible = self.UIVisible
			end
		end
	end)

	task.defer(function()
		task.wait(0.5)
		local keyName = self.UIBindKey.Name
		self:Notify("Pullar", "Press " .. keyName .. " to open the UI", 5)
	end)

	return self
end

function Library:RebuildModuleStatus()
    self.ModuleStatusEntries = {}

    local layout = self.ModuleListFrame:FindFirstChildOfClass("UIListLayout")
    for _, child in pairs(self.ModuleListFrame:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end

    if not layout then
        layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = self.ModuleListFrame
    end

    local activeToggles = {}
    for _, tab in pairs(self.Tabs) do
        for _, toggle in pairs(tab.Toggles) do
            if toggle.State then
                table.insert(activeToggles, toggle)
            end
        end
    end
    table.sort(activeToggles, function(a, b) return a.Name < b.Name end)

    local initialHue = self.ModuleStatusRainbowHue or 0
    local TextService = game:GetService("TextService")

    for i, toggle in ipairs(activeToggles) do
        
        local barColor = Color3.fromHSV((initialHue - (i * 0.025)) % 1, 0.7, 1)

        
        local holder = Instance.new("Frame")
        holder.Name = toggle.Name
        holder.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        holder.BackgroundTransparency = 0.5 
        holder.BorderSizePixel = 0
        holder.Size = UDim2.new(0, 204, 0, 30) 
        holder.LayoutOrder = i
        holder.ClipsDescendants = true
        holder.Parent = self.ModuleListFrame

        
        local colorBar = Instance.new("Frame")
        colorBar.Name = "ColorBar"
        colorBar.Size = UDim2.new(0, 5, 0, 30) 
        colorBar.BackgroundColor3 = barColor
        colorBar.BorderSizePixel = 0
        colorBar.Parent = holder

        
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(0, 204, 0, 31)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.SourceSansBold
        label.Text = "    " .. toggle.Name 
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 24 
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 2
        label.Parent = holder

        
        local shadow = label:Clone()
        shadow.Name = "Shadow"
        shadow.Position = UDim2.new(0, 1, 0, 1)
        shadow.TextColor3 = Color3.new(0, 0, 0)
        shadow.TextTransparency = 0.5
        shadow.ZIndex = 1
        shadow.Parent = holder

        
        local textSize = TextService:GetTextSize(label.Text, label.TextSize, label.Font, Vector2.new(1000, 30))
        holder.Size = UDim2.new(0, textSize.X + 10, 0, 30)

        table.insert(self.ModuleStatusEntries, {
            toggle = toggle,
            colorBar = colorBar,
            holder = holder,
            index = i,
        })
    end
end

function Library:UpdateModuleStatusColors(hue)
	if not self.ModuleStatusEnabled then return end
	local total = #self.ModuleStatusEntries
	if total == 0 then return end
	
	for i, entry in ipairs(self.ModuleStatusEntries) do
		
	end
end

function Library:_GetNotifStackY(index)
	return -((self.NotifHeight + self.NotifGap) * index)
end

function Library:_RepositionNotifications()
	for i, entry in ipairs(self.ActiveNotifications) do
		local targetY = self:_GetNotifStackY(i - 1)
		Tween(entry.frame, {Position = UDim2.new(0, 0, 1, targetY)}, 0.25)
	end
end

function Library:Notify(title, text, duration)
	duration = duration or 3

	local h = self.NotifHeight
	local layer = self.NotificationLayer

	local frame = Instance.new("Frame")
	frame.Name = "Notif"
	frame.Parent = layer
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	frame.BorderSizePixel = 0
	frame.AnchorPoint = Vector2.new(0, 1)
	frame.Position = UDim2.new(0, 0, 1, 20)
	frame.Size = UDim2.new(1, 0, 0, h)
	frame.BackgroundTransparency = 1
	frame.ZIndex = 100
	frame.ClipsDescendants = true

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(60, 60, 60)
	stroke.Thickness = 1
	stroke.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Parent = frame
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.new(0, 12, 0, 8)
	titleLabel.Size = UDim2.new(1, -24, 0, 20)
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 16
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTransparency = 1
	titleLabel.ZIndex = 101

	local textLabel = Instance.new("TextLabel")
	textLabel.Parent = frame
	textLabel.BackgroundTransparency = 1
	textLabel.Position = UDim2.new(0, 12, 0, 30)
	textLabel.Size = UDim2.new(1, -24, 0, 36)
	textLabel.Font = Enum.Font.SourceSans
	textLabel.Text = text
	textLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	textLabel.TextSize = 15
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextWrapped = true
	textLabel.TextTransparency = 1
	textLabel.ZIndex = 101

	local timerLabel = Instance.new("TextLabel")
	timerLabel.Parent = frame
	timerLabel.BackgroundTransparency = 1
	timerLabel.Position = UDim2.new(1, -44, 0, 6)
	timerLabel.Size = UDim2.new(0, 36, 0, 16)
	timerLabel.Font = Enum.Font.SourceSans
	timerLabel.Text = tostring(duration) .. "s"
	timerLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	timerLabel.TextSize = 13
	timerLabel.TextTransparency = 1
	timerLabel.ZIndex = 101

	local timerBg = Instance.new("Frame")
	timerBg.Parent = frame
	timerBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	timerBg.BorderSizePixel = 0
	timerBg.Position = UDim2.new(0, 0, 1, -6)
	timerBg.Size = UDim2.new(1, 0, 0, 6)
	timerBg.BackgroundTransparency = 1
	timerBg.ZIndex = 101

	local timerBgCorner = Instance.new("UICorner")
	timerBgCorner.CornerRadius = UDim.new(0, 4)
	timerBgCorner.Parent = timerBg

	local timerBar = Instance.new("Frame")
	timerBar.Parent = timerBg
	timerBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	timerBar.BorderSizePixel = 0
	timerBar.Size = UDim2.new(1, 0, 1, 0)
	timerBar.BackgroundTransparency = 1
	timerBar.ZIndex = 102

	local timerBarCorner = Instance.new("UICorner")
	timerBarCorner.CornerRadius = UDim.new(0, 4)
	timerBarCorner.Parent = timerBar

	local entry = {frame = frame}
	table.insert(self.ActiveNotifications, 1, entry)

	self:_RepositionNotifications()

	Tween(frame, {BackgroundTransparency = 0.1}, 0.3)
	Tween(titleLabel, {TextTransparency = 0}, 0.3)
	Tween(textLabel, {TextTransparency = 0}, 0.3)
	Tween(timerLabel, {TextTransparency = 0}, 0.3)
	Tween(timerBg, {BackgroundTransparency = 0}, 0.3)
	Tween(timerBar, {BackgroundTransparency = 0}, 0.3)

	local elapsed = 0
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		elapsed = elapsed + dt
		local remaining = math.max(0, duration - elapsed)
		local frac = remaining / duration

		timerBar.Size = UDim2.new(frac, 0, 1, 0)
		timerLabel.Text = string.format("%.1fs", remaining)

		if elapsed >= duration then
			connection:Disconnect()

			Tween(frame, {BackgroundTransparency = 1}, 0.25)
			Tween(titleLabel, {TextTransparency = 1}, 0.25)
			Tween(textLabel, {TextTransparency = 1}, 0.25)
			Tween(timerLabel, {TextTransparency = 1}, 0.25)
			Tween(timerBg, {BackgroundTransparency = 1}, 0.25)
			Tween(timerBar, {BackgroundTransparency = 1}, 0.25)

			task.delay(0.3, function()
				for i, e in ipairs(self.ActiveNotifications) do
					if e.frame == frame then
						table.remove(self.ActiveNotifications, i)
						break
					end
				end
				frame:Destroy()
				self:_RepositionNotifications()
			end)
		end
	end)
end

local Tab = {}
Tab.__index = Tab

function Library:CreateTab(name, imageId)
	local tab = setmetatable({}, Tab)

	tab.Name = name
	tab.ImageId = imageId
	tab.Library = self
	tab.Toggles = {}

	tab.Button = Instance.new("TextButton")
	tab.Button.Name = name
	tab.Button.Parent = self.TabsHolder
	tab.Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	tab.Button.BorderSizePixel = 0
	tab.Button.Size = UDim2.new(0, 102, 0, 38)
	tab.Button.Font = Enum.Font.SourceSans
	tab.Button.Text = "            " .. name
	tab.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
	tab.Button.TextSize = 20
	tab.Button.TextXAlignment = Enum.TextXAlignment.Left

	local tabGradient = Instance.new("UIGradient")
	tabGradient.Name = "Gradient"
	tabGradient.Enabled = false
	tabGradient.Parent = tab.Button

	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0, 4)
	tabCorner.Parent = tab.Button

	local tabIcon = Instance.new("ImageLabel")
	tabIcon.Parent = tab.Button
	tabIcon.BackgroundTransparency = 1
	tabIcon.Size = UDim2.new(0, 41, 0, 38)
	tabIcon.Image = imageId or ""

	tab.TogglesHolder = Instance.new("ScrollingFrame")
	tab.TogglesHolder.Name = name .. "TogglesHolder"
	tab.TogglesHolder.Parent = self.MainHolder
	tab.TogglesHolder.Active = true
	tab.TogglesHolder.BackgroundTransparency = 1
	tab.TogglesHolder.BorderSizePixel = 0
	tab.TogglesHolder.Position = UDim2.new(0.174, 0, 0.137, 0)
	tab.TogglesHolder.Size = UDim2.new(0, 536, 0, 312)
	tab.TogglesHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
	tab.TogglesHolder.ScrollBarThickness = 4
	tab.TogglesHolder.Visible = false

	local togglesList = Instance.new("UIListLayout")
	togglesList.Parent = tab.TogglesHolder
	togglesList.SortOrder = Enum.SortOrder.LayoutOrder
	togglesList.Padding = UDim.new(0, 2)

	togglesList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tab.TogglesHolder.CanvasSize = UDim2.new(0, 0, 0, togglesList.AbsoluteContentSize.Y)
	end)

	tab.Button.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)

	table.insert(self.Tabs, tab)

	if #self.Tabs == 1 then
		self:SelectTab(tab)
	end

	if not self.ConfigLoadScheduled then
		self.ConfigLoadScheduled = true
		self.IsLoading = true
		task.delay(0, function()
			self:LoadConfig()
		end)
	end

	return tab
end

function Library:SelectTab(tab)
	for _, t in pairs(self.Tabs) do
		t.Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		t.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
		t.Button:FindFirstChildOfClass("ImageLabel").ImageColor3 = Color3.fromRGB(255, 255, 255)
		if t.Button:FindFirstChild("Gradient") then
			t.Button.Gradient.Enabled = false
		end
		t.TogglesHolder.Visible = false
	end

	tab.TogglesHolder.Visible = true
	tab.Button.TextColor3 = Color3.fromRGB(0, 0, 0)
	tab.Button:FindFirstChildOfClass("ImageLabel").ImageColor3 = Color3.fromRGB(0, 0, 0)

	self.CurrentTab = tab

	self:UpdateGUI(self.GUIColor.Hue, self.GUIColor.Sat, self.GUIColor.Value)

	if self.AutoSave and self.ConfigLoadScheduled then
		self:SaveConfig()
	end
end

function Library:ToggleMinimize()
	self.Minimized = not self.Minimized

	if self.Minimized then
		self.TabsHolder.Visible = false
		self.SettingsPage.Visible = false
		for _, tab in pairs(self.Tabs) do
			tab.TogglesHolder.Visible = false
		end
		Tween(self.MainHolder, {Size = UDim2.new(0, 666, 0, 50)})
	else
		if self.SettingsOpen then
			self.SettingsPage.Visible = true
		else
			self.TabsHolder.Visible = true
			if self.CurrentTab then
				self.CurrentTab.TogglesHolder.Visible = true
			end
		end
		Tween(self.MainHolder, {Size = UDim2.new(0, 666, 0, 386)})
	end
end

function Library:ToggleSettings()
	self.SettingsOpen = not self.SettingsOpen

	self.TabsHolder.Visible = not self.SettingsOpen
	self.SettingsPage.Visible = self.SettingsOpen

	for _, tab in pairs(self.Tabs) do
		tab.TogglesHolder.Visible = false
	end

	if not self.SettingsOpen and self.CurrentTab then
		self.CurrentTab.TogglesHolder.Visible = true
	end
end

function Library:StartRainbow()
	if self.RainbowConnection then
		self.RainbowConnection:Disconnect()
	end

	self.RainbowConnection = RunService.Heartbeat:Connect(function(delta)
		self.RainbowHue = (self.RainbowHue + (delta * self.RainbowSpeed * 0.1)) % 1
		self:UpdateGUI(self.RainbowHue, 1, 1)
	end)
end

function Library:StopRainbow()
	if self.RainbowConnection then
		self.RainbowConnection:Disconnect()
		self.RainbowConnection = nil
	end

	self:UpdateGUI(self.GUIColor.Hue, self.GUIColor.Sat, self.GUIColor.Value)
end

function Library:ApplyGradients()
	self.GradientUI = true
	self:UpdateGUI(self.GUIColor.Hue, self.GUIColor.Sat, self.GUIColor.Value)
end

function Library:RemoveGradients()
	self.GradientUI = false
	self:UpdateGUI(self.GUIColor.Hue, self.GUIColor.Sat, self.GUIColor.Value)
end

function Library:UpdateGradients()
	self:UpdateGUI(self.GUIColor.Hue, self.GUIColor.Sat, self.GUIColor.Value)
end

function Library:UpdateGUI(hue, sat, val)
	self.GUIColor.Hue = hue
	self.GUIColor.Sat = sat
	self.GUIColor.Value = val

	if self.ColorPreviewPointer then
		self.ColorPreviewPointer.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
	end

	local useGradient = self.GradientUI
	local listOffset = 0.05
	local waveSpread = self.WaveSpread

	if self.CurrentTab then
		local btn = self.CurrentTab.Button
		local grad = btn:FindFirstChild("UIGradient")

		if useGradient and grad then
			grad.Enabled = true
			btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			local h1 = hue
			local h2 = (hue + waveSpread) % 1

			grad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(h1, sat, val)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(h2, sat, val))
			})
		else
			if grad then grad.Enabled = false end
			btn.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
		end
	end

	local toggleIndex = 0
	for _, tab in pairs(self.Tabs) do
		for _, toggle in pairs(tab.Toggles) do
			if toggle.State then
				toggleIndex = toggleIndex + 1
				local btn = toggle.Button
				local grad = btn:FindFirstChild("Gradient")

				if useGradient and grad then
					grad.Enabled = true
					btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					local baseHue = (hue - (toggleIndex * listOffset)) % 1
					local h1 = baseHue
					local h2 = (baseHue + waveSpread) % 1

					grad.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHSV(h1, sat, val)),
						ColorSequenceKeypoint.new(1, Color3.fromHSV(h2, sat, val))
					})
				else
					if grad then grad.Enabled = false end
					if self.RainbowEnabled then
						local shiftedHue = (hue - (toggleIndex * listOffset)) % 1
						btn.BackgroundColor3 = Color3.fromHSV(shiftedHue, sat, val)
					else
						btn.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
					end
				end
			end
		end
	end

	
end

function Library:SaveConfig()
	if self.IsLoading then
		return
	end

	local HttpService = game:GetService("HttpService")

	local config = {
		Theme = {
			RainbowEnabled = self.RainbowEnabled,
			RainbowSpeed = self.RainbowSpeed,
			GradientUI = self.GradientUI,
			WaveSpread = self.WaveSpread,
			GUIColor = self.GUIColor
		},
		UIBindKey = self.UIBindKey.Name,
		ModuleStatusEnabled = self.ModuleStatusEnabled,
		CurrentTab = self.CurrentTab and self.CurrentTab.Name or nil,
		Tabs = {}
	}

	for _, tab in pairs(self.Tabs) do
		config.Tabs[tab.Name] = {
			Toggles = {}
		}

		for _, toggle in pairs(tab.Toggles) do
			local subElements = {}

			for i, sub in pairs(toggle.SubElements) do
				local typeStr = "Textbox"
				if sub.DualMode then
					typeStr = "DualSlider"
				elseif sub.Min then
					typeStr = "Slider"
				elseif sub.State ~= nil and sub.Value == nil then
					typeStr = "Knob"
				end

				local key = sub.Name and sub.Name ~= "" and sub.Name or tostring(i)
				subElements[key] = {
					Type = typeStr,
					Value = sub.Value,
					State = sub.State
				}
			end

			config.Tabs[tab.Name].Toggles[toggle.Name] = {
				State = toggle.State,
				Keybind = toggle.Keybind and toggle.Keybind.Name or nil,
				SubElements = subElements
			}
		end
	end

	local success, err = pcall(function()
		print("saved")
		writefile(self.ConfigFile, HttpService:JSONEncode(config))
	end)

	if not success then
		warn("[Pullar] Failed to save config:", err)
	end
end

function Library:LoadConfig()
	self.IsLoading = true

	local HttpService = game:GetService("HttpService")

	local success, result = pcall(function()
		return readfile(self.ConfigFile)
	end)

	if not success then
		self.IsLoading = false
		return
	end

	local config
	success, config = pcall(function()
		return HttpService:JSONDecode(result)
	end)

	if not success then
		warn("[Pullar] Failed to decode config:", config)
		self.IsLoading = false
		return
	end

	if config.Theme then
		self.RainbowSpeed = config.Theme.RainbowSpeed or 1
		self.GUIColor = config.Theme.GUIColor or self.GUIColor
		if config.Theme.WaveSpread then
			self.WaveSpread = config.Theme.WaveSpread
		end

		if self._hValBox then
			self._hValBox.Text = tostring(math.floor(self.GUIColor.Hue * 100))
			self._sValBox.Text = tostring(math.floor(self.GUIColor.Sat * 100))
			self._vValBox.Text = tostring(math.floor(self.GUIColor.Value * 100))
			local hp = self.GUIColor.Hue
			local sp = self.GUIColor.Sat
			local vp = self.GUIColor.Value
			self._hFill.Size = UDim2.new(hp, 0, 1, 0)
			self._sFill.Size = UDim2.new(sp, 0, 1, 0)
			self._vFill.Size = UDim2.new(vp, 0, 1, 0)
			self._hHandle.Position = UDim2.new(0, 16 + (490 * hp) - 10, 0, 14)
			self._sHandle.Position = UDim2.new(0, 16 + (490 * sp) - 10, 0, 14)
			self._vHandle.Position = UDim2.new(0, 16 + (490 * vp) - 10, 0, 14)
			if self.ColorPreviewPointer then
				self.ColorPreviewPointer.BackgroundColor3 = Color3.fromHSV(hp, sp, vp)
			end
		end

		local rainbowKnob = self.SettingsPage:FindFirstChild("ThemeSubHolder")
		if rainbowKnob then
			local rainbowLabel = rainbowKnob:FindFirstChild("TextLabel")
			if rainbowLabel then
				local knob = rainbowLabel:FindFirstChild("RainbowKnob")
				if knob then
					local indicator = knob:FindFirstChild("Frame")
					if config.Theme.RainbowEnabled and not self.RainbowEnabled then
						self.RainbowEnabled = true
						if indicator then
							Tween(indicator, {Position = UDim2.new(0, 18, 0, 0), BackgroundColor3 = Color3.fromRGB(0, 255, 0)}, 0.2)
						end
						self:StartRainbow()
					elseif not config.Theme.RainbowEnabled and self.RainbowEnabled then
						self.RainbowEnabled = false
						if indicator then
							Tween(indicator, {Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(255, 0, 0)}, 0.2)
						end
						self:StopRainbow()
					end
				end
			end

			local gradientLabel = rainbowKnob:FindFirstChild("TextLabel", true)
			for _, child in pairs(rainbowKnob:GetChildren()) do
				if child:IsA("TextLabel") and child.Text:find("Gradient UI") then
					gradientLabel = child
					break
				end
			end
			if gradientLabel then
				local knob = gradientLabel:FindFirstChild("GradientKnob")
				if knob then
					local indicator = knob:FindFirstChild("Frame")
					if config.Theme.GradientUI and not self.GradientUI then
						self.GradientUI = true
						if indicator then
							Tween(indicator, {Position = UDim2.new(0, 18, 0, 0), BackgroundColor3 = Color3.fromRGB(0, 255, 0)}, 0.2)
						end
						self:ApplyGradients()
					elseif not config.Theme.GradientUI and self.GradientUI then
						self.GradientUI = false
						if indicator then
							Tween(indicator, {Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(255, 0, 0)}, 0.2)
						end
						self:RemoveGradients()
					end
				end
			end
		end
	end

	if config.ModuleStatusEnabled ~= nil then
		self.ModuleStatusEnabled = config.ModuleStatusEnabled
		self.ModuleStatusHolder.Visible = self.ModuleStatusEnabled
		if self.ModuleStatusEnabled and not self.ModuleStatusRainbowConnection then
			self.ModuleStatusRainbowHue = 0
			self.ModuleStatusRainbowConnection = RunService.Heartbeat:Connect(function(delta)
				self.ModuleStatusRainbowHue = (self.ModuleStatusRainbowHue + (delta * 0.1)) % 1
				self:UpdateModuleStatusColors(self.ModuleStatusRainbowHue)
			end)
		end
		local msSubHolder = self.SettingsPage:FindFirstChild("ModuleStatusSubHolder")
		if msSubHolder then
			local knob = msSubHolder:FindFirstChild("ModuleStatusKnob")
			if knob then
				local indicator = knob:FindFirstChild("Frame")
				if indicator then
					if self.ModuleStatusEnabled then
						indicator.Position = UDim2.new(0, 18, 0, 0)
						indicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
					else
						indicator.Position = UDim2.new(0, 0, 0, 0)
						indicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
					end
				end
			end
		end
	end

	if config.UIBindKey then
		local keycode = Enum.KeyCode[config.UIBindKey]
		if keycode then
			self.UIBindKey = keycode
		end
	end

	for tabName, tabData in pairs(config.Tabs or {}) do
		local tab = nil
		for _, t in pairs(self.Tabs) do
			if t.Name == tabName then
				tab = t
				break
			end
		end

		if tab then
			for toggleName, toggleData in pairs(tabData.Toggles or {}) do
				local toggle = nil
				for _, tg in pairs(tab.Toggles) do
					if tg.Name == toggleName then
						toggle = tg
						break
					end
				end

				if toggle then
					if toggleData.State and not toggle.State then
						toggle:Toggle()
					elseif not toggleData.State and toggle.State then
						toggle:Toggle()
					end

					if toggleData.Keybind then
						local keycode = Enum.KeyCode[toggleData.Keybind]
						if keycode then
							toggle.Keybind = keycode
							local keybindButton = toggle.Button:FindFirstChild("KeybindButton")
							if keybindButton then
								keybindButton.Text = toggleData.Keybind:sub(1, 3):upper()
							end
						end
					end

					for keyStr, subData in pairs(toggleData.SubElements or {}) do
						local sub = nil
						local subIndex = nil
						for i, s in ipairs(toggle.SubElements) do
							if s.Name and s.Name == keyStr then
								sub = s
								subIndex = i
								break
							end
						end
						if not sub then
							local index = tonumber(keyStr)
							if index then
								sub = toggle.SubElements[index]
								subIndex = index
							end
						end

						if sub then
							if subData.Type == "Slider" and subData.Value then
								sub.Value = subData.Value

								task.defer(function()
									local count = 0
									local container = nil
									for _, child in ipairs(toggle.SubHolder:GetChildren()) do
										if child:IsA("Frame") or child:IsA("TextLabel") then
											count = count + 1
											if count == subIndex then
												container = child
												break
											end
										end
									end

									if container and container:IsA("Frame") then
										local valueBox = container:FindFirstChild("TextBox", true)

										local sliderBg = nil
										for _, child in pairs(container:GetChildren()) do
											if child:IsA("Frame") and child.Name ~= "UICorner" and child.ZIndex ~= 2 then
												sliderBg = child
												break
											end
										end

										local sliderFill = nil
										if sliderBg then
											sliderFill = sliderBg:FindFirstChildOfClass("Frame")
										end

										local handle = nil
										for _, child in pairs(container:GetChildren()) do
											if child:IsA("Frame") and child.ZIndex == 2 then
												handle = child
												break
											end
										end

										if valueBox then
											valueBox.Text = tostring(subData.Value)
										end

										if sliderFill and handle and sub.Min and sub.Max then
											local pos = (subData.Value - sub.Min) / (sub.Max - sub.Min)
											sliderFill.Size = UDim2.new(pos, 0, 1, 0)
											handle.Position = UDim2.new(0, 16 + (490 * pos) - 12, 0, 16)
										end
									end
								end)

								sub.Callback(sub.Value)
							elseif subData.Type == "DualSlider" and subData.Value and type(subData.Value) == "table" then
								sub.Value = subData.Value

								task.defer(function()
									local count = 0
									local container = nil
									for _, child in ipairs(toggle.SubHolder:GetChildren()) do
										if child:IsA("Frame") or child:IsA("TextLabel") then
											count = count + 1
											if count == subIndex then
												container = child
												break
											end
										end
									end

									if container and container:IsA("Frame") then
										local valueBox = container:FindFirstChild("TextBox", true)

										local sliderBg = nil
										for _, child in pairs(container:GetChildren()) do
											if child:IsA("Frame") and child.Name ~= "UICorner" and child.Name ~= "Handle1" and child.Name ~= "Handle2" then
												sliderBg = child
												break
											end
										end

										local sliderFill = nil
										if sliderBg then
											sliderFill = sliderBg:FindFirstChildOfClass("Frame")
										end

										local handle1 = container:FindFirstChild("Handle1", true)
										local handle2 = container:FindFirstChild("Handle2", true)

										if valueBox then
											valueBox.Text = subData.Value[1] .. " - " .. subData.Value[2]
										end

										if sliderFill and handle1 and handle2 and sub.Min and sub.Max then
											local range = sub.Max - sub.Min
											local pos1 = (subData.Value[1] - sub.Min) / range
											local pos2 = (subData.Value[2] - sub.Min) / range

											handle1.Position = UDim2.new(0, 16 + (490 * pos1) - 12, 0, 16)
											handle2.Position = UDim2.new(0, 16 + (490 * pos2) - 12, 0, 16)

											sliderFill.Position = UDim2.new(pos1, 0, 0, 0)
											sliderFill.Size = UDim2.new(pos2 - pos1, 0, 1, 0)
										end
									end
								end)

								sub.Callback(sub.Value)
							elseif subData.Type == "Knob" and subData.State ~= nil then
								sub.State = subData.State

								task.defer(function()
									local count = 0
									local label = nil
									for _, child in ipairs(toggle.SubHolder:GetChildren()) do
										if child:IsA("Frame") or child:IsA("TextLabel") then
											count = count + 1
											if count == subIndex then
												label = child
												break
											end
										end
									end

									if label and label:IsA("TextLabel") then
										local knobButton = label:FindFirstChild("Knob", true)
										if knobButton then
											local indicator = knobButton:FindFirstChildOfClass("Frame")
											if indicator then
												if subData.State then
													Tween(indicator, {Position = UDim2.new(0, 18, 0, 0), BackgroundColor3 = Color3.fromRGB(0, 255, 0)}, 0.2)
												else
													Tween(indicator, {Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(255, 0, 0)}, 0.2)
												end
											end
										end
									end
								end)

								sub.Callback(sub.State)
							elseif subData.Type == "Textbox" and subData.Value then
								sub.Value = subData.Value

								task.defer(function()
									local count = 0
									local container = nil
									for _, child in ipairs(toggle.SubHolder:GetChildren()) do
										if child:IsA("Frame") or child:IsA("TextLabel") then
											count = count + 1
											if count == subIndex then
												container = child
												break
											end
										end
									end

									if container and container:IsA("Frame") then
										local textBox = container:FindFirstChild("TextBox", true)
										if textBox then
											textBox.Text = subData.Value
										end
									end
								end)

								sub.Callback(sub.Value)
							end
						end
					end
				end
			end
		end
	end

	if config.CurrentTab then
		for _, tab in pairs(self.Tabs) do
			if tab.Name == config.CurrentTab then
				task.defer(function()
					self:SelectTab(tab)
				end)
				break
			end
		end
	end

	self.IsLoading = false
end

function Library:DeleteConfig()
	local success, err = pcall(function()
		delfile(self.ConfigFile)
	end)

	if not success then
		warn("[Pullar] Failed to delete config:", err)
	end
end

local Toggle = {}
Toggle.__index = Toggle

function Tab:CreateToggle(name, callback)
	local toggle = setmetatable({}, Toggle)

	toggle.Name = name
	toggle.Callback = callback or function() end
	toggle.State = false
	toggle.Tab = self
	toggle.SubElements = {}

	toggle.Button = Instance.new("TextButton")
	toggle.Button.Name = name
	toggle.Button.Parent = self.TogglesHolder
	toggle.Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	toggle.Button.BorderSizePixel = 0
	toggle.Button.Size = UDim2.new(0, 536, 0, 38)
	toggle.Button.Font = Enum.Font.SourceSans
	toggle.Button.Text = "               " .. name
	toggle.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggle.Button.TextSize = 20
	toggle.Button.TextXAlignment = Enum.TextXAlignment.Left

	local toggleGradient = Instance.new("UIGradient")
	toggleGradient.Name = "Gradient"
	toggleGradient.Enabled = false
	toggleGradient.Parent = toggle.Button

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 4)
	toggleCorner.Parent = toggle.Button

	local toggleIcon = Instance.new("ImageLabel")
	toggleIcon.Parent = toggle.Button
	toggleIcon.BackgroundTransparency = 1
	toggleIcon.Size = UDim2.new(0, 41, 0, 38)
	toggleIcon.Image = "rbxassetid://16081386298"

	local arrowIcon = Instance.new("ImageLabel")
	arrowIcon.Parent = toggle.Button
	arrowIcon.BackgroundTransparency = 1
	arrowIcon.Position = UDim2.new(0.931, 0, 0.026, 0)
	arrowIcon.Rotation = 90
	arrowIcon.Size = UDim2.new(0, 33, 0, 35)
	arrowIcon.Image = "rbxassetid://120072340768479"

	toggle.Keybind = nil
	toggle.ListeningForKey = false

	local keybindButton = Instance.new("TextButton")
	keybindButton.Name = "KeybindButton"
	keybindButton.Parent = toggle.Button
	keybindButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	keybindButton.BorderSizePixel = 0
	keybindButton.Position = UDim2.new(0.87, 0, 0.158, 0)
	keybindButton.Size = UDim2.new(0, 33, 0, 25)
	keybindButton.Font = Enum.Font.SourceSans
	keybindButton.Text = ""
	keybindButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	keybindButton.TextSize = 16
	keybindButton.ZIndex = 2

	local keybindCorner = Instance.new("UICorner")
	keybindCorner.CornerRadius = UDim.new(0, 4)
	keybindCorner.Parent = keybindButton

	keybindButton.MouseButton1Click:Connect(function()
		if not toggle.ListeningForKey then
			toggle.ListeningForKey = true
			keybindButton.Text = "..."

			local connection
			connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if input.UserInputType == Enum.UserInputType.Keyboard then
					toggle.ListeningForKey = false
					toggle.Keybind = input.KeyCode
					keybindButton.Text = input.KeyCode.Name:sub(1, 3):upper()
					connection:Disconnect()

					if self.Library.AutoSave and not self.Library.IsLoading then
						self.Library:SaveConfig()
					end
				end
			end)
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
			if toggle.Keybind and input.KeyCode == toggle.Keybind then
				toggle:Toggle()
			end
		end
	end)

	toggle.SubHolder = Instance.new("ScrollingFrame")
	toggle.SubHolder.Name = "SubHolder"
	toggle.SubHolder.Parent = self.TogglesHolder
	toggle.SubHolder.Active = true
	toggle.SubHolder.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	toggle.SubHolder.BorderSizePixel = 0
	toggle.SubHolder.Size = UDim2.new(0, 536, 0, 0)
	toggle.SubHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
	toggle.SubHolder.ScrollBarThickness = 4
	toggle.SubHolder.Visible = false
	toggle.SubHolder.LayoutOrder = toggle.Button.LayoutOrder + 0.5

	local subCorner = Instance.new("UICorner")
	subCorner.CornerRadius = UDim.new(0, 4)
	subCorner.Parent = toggle.SubHolder

	local subList = Instance.new("UIListLayout")
	subList.Parent = toggle.SubHolder
	subList.SortOrder = Enum.SortOrder.LayoutOrder
	subList.Padding = UDim.new(0, 10)

	local subPadding = Instance.new("UIPadding")
	subPadding.Parent = toggle.SubHolder
	subPadding.PaddingTop = UDim.new(0, 10)
	subPadding.PaddingBottom = UDim.new(0, 10)
	subPadding.PaddingLeft = UDim.new(0, 5)
	subPadding.PaddingRight = UDim.new(0, 5)

	subList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		toggle.SubHolder.CanvasSize = UDim2.new(0, 0, 0, subList.AbsoluteContentSize.Y + 20)
	end)

	toggle.Expanded = false

	toggle.Button.MouseButton1Click:Connect(function()
		toggle:Toggle()
	end)

	toggle.Button.MouseButton2Click:Connect(function()
		toggle:ToggleExpand()
	end)

	table.insert(self.Toggles, toggle)

	return toggle
end

function Toggle:Toggle()
	self.State = not self.State

	if self.State then
		self.Button.TextColor3 = Color3.fromRGB(0, 0, 0)
		self.Button:FindFirstChildOfClass("ImageLabel").ImageColor3 = Color3.fromRGB(0, 0, 0)
		local arrow = self.Button:FindFirstChild("ImageLabel", true)
		if arrow and arrow.Image:find("120072340768479") then
			arrow.ImageColor3 = Color3.fromRGB(0, 0, 0)
		end
	else
		self.Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		if self.Button:FindFirstChild("Gradient") then
			self.Button.Gradient.Enabled = false
		end
		self.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
		self.Button:FindFirstChildOfClass("ImageLabel").ImageColor3 = Color3.fromRGB(255, 255, 255)
		local arrow = self.Button:FindFirstChild("ImageLabel", true)
		if arrow and arrow.Image:find("120072340768479") then
			arrow.ImageColor3 = Color3.fromRGB(255, 255, 255)
		end
	end

	self.Tab.Library:UpdateGUI(self.Tab.Library.GUIColor.Hue, self.Tab.Library.GUIColor.Sat, self.Tab.Library.GUIColor.Value)

	if self.Tab.Library.ModuleStatusEnabled then
		self.Tab.Library:RebuildModuleStatus()
	end

	self.Callback(self.State)

	if not self.Tab.Library.IsLoading then
		local stateText = self.State and "Enabled" or "Disabled"
		self.Tab.Library:Notify(self.Name, self.Name .. " is now " .. stateText, 2)
	end

	if self.Tab.Library.AutoSave and not self.Tab.Library.IsLoading then
		self.Tab.Library:SaveConfig()
	end
end

function Toggle:ToggleExpand()
	self.Expanded = not self.Expanded

	if self.Expanded and #self.SubElements > 0 then
		self.SubHolder.Visible = true
		local contentHeight = self.SubHolder.UIListLayout.AbsoluteContentSize.Y + 20
		local targetHeight = math.min(contentHeight, 200)
		Tween(self.SubHolder, {Size = UDim2.new(0, 536, 0, targetHeight)}, 0.3)
	else
		Tween(self.SubHolder, {Size = UDim2.new(0, 536, 0, 0)}, 0.3).Completed:Connect(function()
			self.SubHolder.Visible = false
		end)
	end
end

function Toggle:SetState(state)
	if self.State ~= state then
		self:Toggle()
	end
end

function Toggle:NewKnob(name, defaultState, callback)
	local knob = {}
	knob.Name = name
	knob.State = defaultState or false
	knob.Callback = callback or function() end

	local label = Instance.new("TextLabel")
	label.Parent = self.SubHolder
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0, 93, 0, 18)
	label.Font = Enum.Font.SourceSans
	label.Text = "      " .. name
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 20
	label.TextXAlignment = Enum.TextXAlignment.Left

	local knobButton = Instance.new("TextButton")
	knobButton.Name = "Knob"
	knobButton.Parent = label
	knobButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	knobButton.BorderSizePixel = 0
	knobButton.Position = UDim2.new(5.2, 0, 0, 0)
	knobButton.Size = UDim2.new(0, 33, 0, 20)
	knobButton.Text = ""

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(0, 4)
	knobCorner.Parent = knobButton

	local indicator = Instance.new("Frame")
	indicator.Parent = knobButton
	indicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	indicator.BorderSizePixel = 0
	indicator.Size = UDim2.new(0, 15, 0, 20)

	local indCorner = Instance.new("UICorner")
	indCorner.CornerRadius = UDim.new(0, 4)
	indCorner.Parent = indicator

	local function updateKnob()
		if knob.State then
			Tween(indicator, {Position = UDim2.new(0, 18, 0, 0), BackgroundColor3 = Color3.fromRGB(0, 255, 0)}, 0.2)
		else
			Tween(indicator, {Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(255, 0, 0)}, 0.2)
		end
		knob.Callback(knob.State)

		if self.Tab.Library.AutoSave and not self.Tab.Library.IsLoading then
			self.Tab.Library:SaveConfig()
		end
	end

	knobButton.MouseButton1Click:Connect(function()
		knob.State = not knob.State
		updateKnob()
	end)

	updateKnob()

	table.insert(self.SubElements, knob)
	return knob
end

function Toggle:NewSlider(name, min, max, default, callback)
	local slider = {}
	slider.Name = name
	slider.Min = min
	slider.Max = max
	slider.Value = default or min
	slider.Callback = callback or function() end

	local container = Instance.new("Frame")
	container.Parent = self.SubHolder
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(0, 520, 0, 45)

	local label = Instance.new("TextLabel")
	label.Parent = container
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 6, 0, 0)
	label.Size = UDim2.new(0, 200, 0, 18)
	label.Font = Enum.Font.SourceSans
	label.Text = "      " .. name
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 20
	label.TextXAlignment = Enum.TextXAlignment.Left

	local valueBox = Instance.new("TextBox")
	valueBox.Parent = container
	valueBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	valueBox.BorderSizePixel = 0
	valueBox.Position = UDim2.new(0, 456, 0, -2)
	valueBox.Size = UDim2.new(0, 60, 0, 22)
	valueBox.Font = Enum.Font.SourceSans
	valueBox.Text = tostring(slider.Value)
	valueBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	valueBox.TextSize = 18

	local valueCorner = Instance.new("UICorner")
	valueCorner.CornerRadius = UDim.new(0, 4)
	valueCorner.Parent = valueBox

	local sliderBg = Instance.new("Frame")
	sliderBg.Parent = container
	sliderBg.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	sliderBg.BorderSizePixel = 0
	sliderBg.Position = UDim2.new(0, 16, 0, 25)
	sliderBg.Size = UDim2.new(0, 490, 0, 6)

	local sliderCorner = Instance.new("UICorner")
	sliderCorner.CornerRadius = UDim.new(1, 0)
	sliderCorner.Parent = sliderBg

	local sliderFill = Instance.new("Frame")
	sliderFill.Parent = sliderBg
	sliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sliderFill.BorderSizePixel = 0
	sliderFill.Size = UDim2.new(0, 0, 1, 0)

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = sliderFill

	local handle = Instance.new("Frame")
	handle.Parent = container
	handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	handle.BorderSizePixel = 0
	handle.Position = UDim2.new(0, 16, 0, 16)
	handle.Size = UDim2.new(0, 24, 0, 24)
	handle.ZIndex = 2

	local handleCorner = Instance.new("UICorner")
	handleCorner.CornerRadius = UDim.new(1, 0)
	handleCorner.Parent = handle

	local handleButton = Instance.new("TextButton")
	handleButton.Parent = handle
	handleButton.BackgroundTransparency = 1
	handleButton.Size = UDim2.new(1, 0, 1, 0)
	handleButton.Text = ""
	handleButton.ZIndex = 3

	local dragging = false

	local function updateSlider(inputPos)
		local relativeX = inputPos.X - sliderBg.AbsolutePosition.X
		local pos = math.clamp(relativeX / sliderBg.AbsoluteSize.X, 0, 1)
		slider.Value = math.floor(min + (max - min) * pos)

		valueBox.Text = tostring(slider.Value)
		sliderFill.Size = UDim2.new(pos, 0, 1, 0)
		handle.Position = UDim2.new(0, 16 + (490 * pos) - 12, 0, 16)

		slider.Callback(slider.Value)

		if self.Tab.Library.AutoSave and not self.Tab.Library.IsLoading then
			self.Tab.Library:SaveConfig()
		end
	end

	handleButton.MouseButton1Down:Connect(function()
		dragging = true
	end)

	sliderBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			updateSlider(input.Position)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSlider(input.Position)
		end
	end)

	valueBox.FocusLost:Connect(function()
		local inputValue = tonumber(valueBox.Text)
		if inputValue then
			slider.Value = math.clamp(math.floor(inputValue), min, max)
			valueBox.Text = tostring(slider.Value)

			local pos = (slider.Value - min) / (max - min)
			sliderFill.Size = UDim2.new(pos, 0, 1, 0)
			handle.Position = UDim2.new(0, 16 + (490 * pos) - 12, 0, 16)

			slider.Callback(slider.Value)

			if self.Tab.Library.AutoSave and not self.Tab.Library.IsLoading then
				self.Tab.Library:SaveConfig()
			end
		else
			valueBox.Text = tostring(slider.Value)
		end
	end)

	local initialPos = (slider.Value - min) / (max - min)
	sliderFill.Size = UDim2.new(initialPos, 0, 1, 0)
	handle.Position = UDim2.new(0, 16 + (490 * initialPos) - 12, 0, 16)

	table.insert(self.SubElements, slider)
	return slider
end

function Toggle:NewDualSlider(name, min, max, defaultMin, defaultMax, callback)
	local dual = {}
	dual.Name = name
	dual.DualMode = true
	dual.Min = min
	dual.Max = max
	dual.Value = {defaultMin or min, defaultMax or max}
	dual.Callback = callback or function() end

	local container = Instance.new("Frame")
	container.Parent = self.SubHolder
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(0, 520, 0, 45)

	local label = Instance.new("TextLabel")
	label.Parent = container
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 6, 0, 0)
	label.Size = UDim2.new(0, 200, 0, 18)
	label.Font = Enum.Font.SourceSans
	label.Text = "      " .. name
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 20
	label.TextXAlignment = Enum.TextXAlignment.Left

	local valueBox = Instance.new("TextBox")
	valueBox.Parent = container
	valueBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	valueBox.BorderSizePixel = 0
	valueBox.Position = UDim2.new(0, 436, 0, -2)
	valueBox.Size = UDim2.new(0, 80, 0, 22)
	valueBox.Font = Enum.Font.SourceSans
	valueBox.Text = dual.Value[1] .. " - " .. dual.Value[2]
	valueBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	valueBox.TextSize = 16

	local valueCorner = Instance.new("UICorner")
	valueCorner.CornerRadius = UDim.new(0, 4)
	valueCorner.Parent = valueBox

	local sliderBg = Instance.new("Frame")
	sliderBg.Parent = container
	sliderBg.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	sliderBg.BorderSizePixel = 0
	sliderBg.Position = UDim2.new(0, 16, 0, 25)
	sliderBg.Size = UDim2.new(0, 490, 0, 6)

	local sliderCorner = Instance.new("UICorner")
	sliderCorner.CornerRadius = UDim.new(1, 0)
	sliderCorner.Parent = sliderBg

	local sliderFill = Instance.new("Frame")
	sliderFill.Parent = sliderBg
	sliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sliderFill.BorderSizePixel = 0
	sliderFill.Size = UDim2.new(0, 0, 1, 0)

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = sliderFill

	local function createHandle(text, name)
		local handle = Instance.new("Frame")
		handle.Name = name
		handle.Parent = container
		handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		handle.BorderSizePixel = 0
		handle.Position = UDim2.new(0, 16, 0, 16)
		handle.Size = UDim2.new(0, 24, 0, 24)
		handle.ZIndex = 2

		local handleCorner = Instance.new("UICorner")
		handleCorner.CornerRadius = UDim.new(1, 0)
		handleCorner.Parent = handle

		local handleButton = Instance.new("TextButton")
		handleButton.Parent = handle
		handleButton.BackgroundTransparency = 1
		handleButton.Size = UDim2.new(1, 0, 1, 0)
		handleButton.Text = ""
		handleButton.ZIndex = 3

		local handleText = Instance.new("TextLabel")
		handleText.Parent = handle
		handleText.BackgroundTransparency = 1
		handleText.Size = UDim2.new(1, 0, 1, 0)
		handleText.Font = Enum.Font.SourceSansBold
		handleText.Text = text
		handleText.TextColor3 = Color3.fromRGB(0, 0, 0)
		handleText.TextSize = 14
		handleText.ZIndex = 3

		return handle, handleButton
	end

	local handle1, handleButton1 = createHandle(">", "Handle1")
	local handle2, handleButton2 = createHandle("<", "Handle2")

	local dragging1, dragging2 = false, false

	local function updateDual(inputPos, mode)
		local relativeX = inputPos.X - sliderBg.AbsolutePosition.X
		local pos = math.clamp(relativeX / sliderBg.AbsoluteSize.X, 0, 1)
		local val = math.floor(min + (max - min) * pos)

		if mode == 1 then
			if val > dual.Value[2] then val = dual.Value[2] end
			dual.Value[1] = val
		elseif mode == 2 then
			if val < dual.Value[1] then val = dual.Value[1] end
			dual.Value[2] = val
		end

		local pos1 = (dual.Value[1] - min) / (max - min)
		local pos2 = (dual.Value[2] - min) / (max - min)

		handle1.Position = UDim2.new(0, 16 + (490 * pos1) - 12, 0, 16)
		handle2.Position = UDim2.new(0, 16 + (490 * pos2) - 12, 0, 16)

		sliderFill.Position = UDim2.new(pos1, 0, 0, 0)
		sliderFill.Size = UDim2.new(pos2 - pos1, 0, 1, 0)

		valueBox.Text = dual.Value[1] .. " - " .. dual.Value[2]
		dual.Callback(dual.Value)

		if self.Tab.Library.AutoSave and not self.Tab.Library.IsLoading then
			self.Tab.Library:SaveConfig()
		end
	end

	handleButton1.MouseButton1Down:Connect(function() dragging1 = true end)
	handleButton2.MouseButton1Down:Connect(function() dragging2 = true end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging1 = false
			dragging2 = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if dragging1 then
				updateDual(input.Position, 1)
			elseif dragging2 then
				updateDual(input.Position, 2)
			end
		end
	end)

	local initialPos1 = (dual.Value[1] - min) / (max - min)
	local initialPos2 = (dual.Value[2] - min) / (max - min)

	handle1.Position = UDim2.new(0, 16 + (490 * initialPos1) - 12, 0, 16)
	handle2.Position = UDim2.new(0, 16 + (490 * initialPos2) - 12, 0, 16)

	sliderFill.Position = UDim2.new(initialPos1, 0, 0, 0)
	sliderFill.Size = UDim2.new(initialPos2 - initialPos1, 0, 1, 0)

	table.insert(self.SubElements, dual)
	return dual
end

function Toggle:NewTextbox(name, placeholder, callback)
	local textbox = {}
	textbox.Name = name
	textbox.Value = ""
	textbox.Callback = callback or function() end

	local container = Instance.new("Frame")
	container.Parent = self.SubHolder
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(0, 520, 0, 35)

	local label = Instance.new("TextLabel")
	label.Parent = container
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 6, 0, 0)
	label.Size = UDim2.new(0, 200, 0, 18)
	label.Font = Enum.Font.SourceSans
	label.Text = "      " .. name
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 20
	label.TextXAlignment = Enum.TextXAlignment.Left

	local box = Instance.new("TextBox")
	box.Parent = container
	box.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	box.BorderSizePixel = 0
	box.Position = UDim2.new(0, 250, 0, -2)
	box.Size = UDim2.new(0, 266, 0, 25)
	box.Font = Enum.Font.SourceSans
	box.PlaceholderText = placeholder or ""
	box.Text = ""
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.TextSize = 18

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 4)
	boxCorner.Parent = box

	box.FocusLost:Connect(function()
		textbox.Value = box.Text
		textbox.Callback(textbox.Value)

		if self.Tab.Library.AutoSave and not self.Tab.Library.IsLoading then
			self.Tab.Library:SaveConfig()
		end
	end)

	table.insert(self.SubElements, textbox)
	return textbox
end

function Library:StartIndependentAutoSave()
	spawn(function()
		while task.wait(1) do
			if self.AutoSave then
				self:SaveConfig()
			end
		end
	end)
end

return Library
