local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- UI Configuration
local UI_CONFIG = {
	CORNER_RADIUS = UDim.new(0, 12),
	ANIMATION_SPEED = 0.15,
	SPACING = 12,
	PADDING = 18,
	ELEMENT_HEIGHT = 48,
	TRANSITION_EASING = Enum.EasingStyle.Sine
}

-- Theme
local DEFAULT_THEME = {
	Primary = Color3.fromRGB(60, 60, 70),
	Secondary = Color3.fromRGB(80, 80, 90),
	Accent = Color3.fromRGB(64, 172, 255),
	Hover = Color3.fromRGB(67, 128, 181),
	Text = Color3.fromRGB(255, 255, 255),
	Disabled = Color3.fromRGB(100, 100, 110),
	Success = Color3.fromRGB(50, 143, 81),
	Warning = Color3.fromRGB(255, 200, 0)
}

-- Global States
local isDraggingSlider = false
local activeWindows = 0

-- Utility Functions
local function makeDraggable(frame)
	local dragging = false
	local dragStart = Vector2.new(0, 0)
	local startPos

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and not isDraggingSlider then
			dragging = true
			dragStart = UserInputService:GetMouseLocation()
			startPos = frame.Position
			activeWindows = activeWindows + 1
			frame.ZIndex = activeWindows + 2
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	local connection
	connection = RunService.RenderStepped:Connect(function(dt)
		if dragging then
			local mousePos = UserInputService:GetMouseLocation()
			local delta = mousePos - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	frame.Destroying:Connect(function()
		if connection then connection:Disconnect() end
	end)
end

local function createTween(object, properties, speed)
	return TweenService:Create(
		object,
		TweenInfo.new(speed or UI_CONFIG.ANIMATION_SPEED, UI_CONFIG.TRANSITION_EASING, Enum.EasingDirection.Out),
		properties
	)
end

local function applyTheme(element, theme, properties)
	for prop, value in pairs(properties) do
		if element[prop] ~= nil then
			if prop == "BackgroundColor3" or prop == "TextColor3" or prop == "BorderColor3" or prop == "ScrollBarImageColor3" then
				element[prop] = (typeof(value) == "string" and theme[value]) or value
			else
				element[prop] = value
			end
		end
	end
end

-- Main GUI
local ARCGUI = {}

function ARCGUI:CreateWindow(config)
	local window = {
		Config = {
			Title = config.Title or "ARCGUI Elite",
			Size = config.Size or UDim2.new(0, 640, 0, 480),
			Theme = config.Theme or DEFAULT_THEME,
			Keybind = config.Keybind or Enum.KeyCode.RightShift,
			MinSize = config.MinSize or UDim2.new(0, 360, 0, 48)
		},
		State = {
			Visible = true,
			Tabs = {},
			Notifications = {},
			Minimized = false,
			ZIndex = 1
		}
	}

	-- ScreenGui Setup
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ARCGUI_" .. window.Config.Title:gsub("%s+", "_")
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = PlayerGui

	-- Main Frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.Position = UDim2.new(0.5, -window.Config.Size.X.Offset/2, 0.5, -window.Config.Size.Y.Offset/2)
	mainFrame.ZIndex = 2
	applyTheme(mainFrame, window.Config.Theme, {BackgroundColor3 = "Primary"})
	mainFrame.Parent = screenGui
	window.MainFrame = mainFrame

	Instance.new("UICorner", mainFrame).CornerRadius = UI_CONFIG.CORNER_RADIUS
	makeDraggable(mainFrame)
	createTween(mainFrame, {Size = window.Config.Size}, 0.25):Play()

	-- Title Bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 48)
	titleBar.ZIndex = 3
	applyTheme(titleBar, window.Config.Theme, {BackgroundColor3 = "Secondary"})
	titleBar.Parent = mainFrame
	Instance.new("UICorner", titleBar).CornerRadius = UI_CONFIG.CORNER_RADIUS

	local titleLabel = Instance.new("TextLabel")
	titleLabel.ZIndex = 4
	applyTheme(titleLabel, window.Config.Theme, {
		Size = UDim2.new(1, -140, 1, 0),
		Position = UDim2.fromOffset(UI_CONFIG.PADDING, 0),
		BackgroundTransparency = 1,
		Text = window.Config.Title,
		TextColor3 = "Text",
		TextSize = 20,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd
	})
	titleLabel.Parent = titleBar

	-- Window Controls
	local function createControlButton(icon, offset, color, callback)
		local button = Instance.new("TextButton")
		button.ZIndex = 5
		applyTheme(button, window.Config.Theme, {
			Size = UDim2.fromOffset(32, 32),
			Position = UDim2.new(1, offset, 0, 8),
			BackgroundColor3 = color,
			Text = icon,
			TextColor3 = "Text",
			TextSize = 18,
			Font = Enum.Font.GothamBold
		})
		Instance.new("UICorner", button).CornerRadius = UI_CONFIG.CORNER_RADIUS
		button.Parent = titleBar

		button.MouseEnter:Connect(function()
			createTween(button, {BackgroundColor3 = window.Config.Theme.Hover, Size = UDim2.fromOffset(34, 34)}):Play()
		end)
		button.MouseLeave:Connect(function()
			createTween(button, {BackgroundColor3 = color, Size = UDim2.fromOffset(32, 32)}):Play()
		end)
		button.MouseButton1Click:Connect(callback)
		return button
	end

	createControlButton("─", -100, window.Config.Theme.Warning, function()
		window.State.Minimized = not window.State.Minimized
		createTween(mainFrame, {
			Size = window.State.Minimized and window.Config.MinSize or window.Config.Size
		}):Play()
	end)

	createControlButton("✕", -62, Color3.fromRGB(255, 80, 80), function()
		createTween(mainFrame, {Size = UDim2.new(0, 0, 0, 0)}):Play()
		task.delay(UI_CONFIG.ANIMATION_SPEED + 0.1, function()
			screenGui:Destroy()
		end)
	end)

	-- Tab Navigation
	local tabNav = Instance.new("Frame")
	tabNav.Name = "TabNav"
	tabNav.ZIndex = 3
	applyTheme(tabNav, window.Config.Theme, {
		Size = UDim2.new(1, 0, 0, 48),
		Position = UDim2.fromOffset(0, 48),
		BackgroundColor3 = "Secondary"
	})
	tabNav.Parent = mainFrame

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, UI_CONFIG.SPACING)
	tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabLayout.Parent = tabNav

	local tabContent = Instance.new("Frame")
	tabContent.Name = "TabContent"
	tabContent.ZIndex = 3
	tabContent.Size = UDim2.new(1, 0, 1, -96)
	tabContent.Position = UDim2.fromOffset(0, 96)
	tabContent.BackgroundTransparency = 1
	tabContent.Parent = mainFrame

	-- Tab Creation
	function window:AddTab(tabConfig)
		local tab = {
			Name = tabConfig.Name or "Tab",
			Content = Instance.new("ScrollingFrame"),
			Sections = {}
		}

		local tabButton = Instance.new("TextButton")
		tabButton.ZIndex = 4
		applyTheme(tabButton, window.Config.Theme, {
			Size = UDim2.new(0, 140, 0, 40),
			BackgroundColor3 = "Secondary",
			Text = tab.Name,
			TextColor3 = "Text",
			TextSize = 16,
			Font = Enum.Font.GothamSemibold
		})
		Instance.new("UICorner", tabButton).CornerRadius = UI_CONFIG.CORNER_RADIUS
		tabButton.Parent = tabNav

		tab.Content.Name = "TabScroll"
		tab.Content.ZIndex = 4
		tab.Content.Size = UDim2.new(1, 0, 1, 0)
		tab.Content.BackgroundTransparency = 1
		tab.Content.ScrollBarThickness = 6
		tab.Content.CanvasSize = UDim2.new(0, 0, 0, 0)
		applyTheme(tab.Content, window.Config.Theme, {ScrollBarImageColor3 = "Accent"})
		tab.Content.Parent = tabContent
		tab.Content.Visible = #window.State.Tabs == 0

		local function switchTab()
			for _, otherTab in pairs(window.State.Tabs) do
				otherTab.Content.Visible = false
				createTween(otherTab.Button, {BackgroundColor3 = window.Config.Theme.Secondary, TextColor3 = window.Config.Theme.Text, Size = UDim2.new(0, 140, 0, 40)}):Play()
			end
			tab.Content.Visible = true
			createTween(tabButton, {
				BackgroundColor3 = window.Config.Theme.Accent,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Size = UDim2.new(0, 144, 0, 42)
			}):Play()
		end

		tabButton.MouseButton1Click:Connect(switchTab)
		tabButton.MouseEnter:Connect(function()
			if not tab.Content.Visible then
				createTween(tabButton, {BackgroundColor3 = window.Config.Theme.Hover, Size = UDim2.new(0, 142, 0, 41)}):Play()
			end
		end)
		tabButton.MouseLeave:Connect(function()
			if not tab.Content.Visible then
				createTween(tabButton, {BackgroundColor3 = window.Config.Theme.Secondary, Size = UDim2.new(0, 140, 0, 40)}):Play()
			end
		end)
		tab.Button = tabButton

		if #window.State.Tabs == 0 then
			tabButton.BackgroundColor3 = window.Config.Theme.Accent
			tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			tabButton.Size = UDim2.new(0, 144, 0, 42)
		end

		-- Section System
		function tab:AddSection(sectionConfig)
			local section = {
				Name = sectionConfig.Name or "Section",
				Expanded = true,
				Elements = {},
				Content = Instance.new("Frame")
			}

			local sectionFrame = Instance.new("Frame")
			sectionFrame.Name = "SectionFrame"
			sectionFrame.ZIndex = 5
			sectionFrame.Size = UDim2.new(1, -UI_CONFIG.PADDING*2, 0, 0)
			sectionFrame.Position = UDim2.fromOffset(UI_CONFIG.PADDING, UI_CONFIG.PADDING)
			sectionFrame.BackgroundTransparency = 1
			sectionFrame.Parent = tab.Content

			local sectionButton = Instance.new("TextButton")
			sectionButton.ZIndex = 6
			applyTheme(sectionButton, window.Config.Theme, {
				Size = UDim2.new(1, 0, 0, 42),
				BackgroundColor3 = "Accent",
				Text = "▼ " .. section.Name,
				TextColor3 = "Text",
				TextSize = 16,
				Font = Enum.Font.GothamSemibold,
				TextXAlignment = Enum.TextXAlignment.Left
			})
			Instance.new("UICorner", sectionButton).CornerRadius = UI_CONFIG.CORNER_RADIUS
			sectionButton.Parent = sectionFrame

			section.Content.Name = "SectionContent"
			section.Content.ZIndex = 6
			section.Content.Size = UDim2.new(1, 0, 0, 0)
			section.Content.BackgroundTransparency = 1
			section.Content.ClipsDescendants = true
			section.Content.Position = UDim2.fromOffset(0, 46)
			section.Content.Parent = sectionFrame

			local function updateLayout()
				local yOffset = UI_CONFIG.PADDING
				for _, sec in ipairs(tab.Sections) do
					sec.Frame.Position = UDim2.fromOffset(UI_CONFIG.PADDING, yOffset)
					local contentHeight = sec.Expanded and #sec.Elements * (UI_CONFIG.ELEMENT_HEIGHT + UI_CONFIG.SPACING) or 0
					sec.Content.Size = UDim2.new(1, 0, 0, contentHeight)
					yOffset = yOffset + (sec.Expanded and 
						(46 + #sec.Elements * (UI_CONFIG.ELEMENT_HEIGHT + UI_CONFIG.SPACING) + UI_CONFIG.SPACING) or 46 + UI_CONFIG.SPACING)
				end
				tab.Content.CanvasSize = UDim2.fromOffset(0, yOffset + UI_CONFIG.PADDING)
			end

			sectionButton.MouseButton1Click:Connect(function()
				section.Expanded = not section.Expanded
				sectionButton.Text = (section.Expanded and "▼ " or "▶ ") .. section.Name
				createTween(sectionButton, {
					BackgroundColor3 = section.Expanded and window.Config.Theme.Accent or window.Config.Theme.Secondary
				}):Play()
				createTween(section.Content, {
					Size = UDim2.new(1, 0, 0, section.Expanded and #section.Elements * (UI_CONFIG.ELEMENT_HEIGHT + UI_CONFIG.SPACING) or 0)
				}):Play()
				task.wait(UI_CONFIG.ANIMATION_SPEED)
				updateLayout()
			end)

			sectionButton.MouseEnter:Connect(function()
				if not section.Expanded then
					createTween(sectionButton, {BackgroundColor3 = window.Config.Theme.Hover}):Play()
				end
			end)
			sectionButton.MouseLeave:Connect(function()
				if not section.Expanded then
					createTween(sectionButton, {BackgroundColor3 = window.Config.Theme.Secondary}):Play()
				end
			end)

			-- Elements
			function section:AddButton(btnConfig)
				local button = Instance.new("TextButton")
				button.ZIndex = 7
				applyTheme(button, window.Config.Theme, {
					Size = UDim2.new(1, -14, 0, UI_CONFIG.ELEMENT_HEIGHT - 10),
					Position = UDim2.fromOffset(7, #section.Elements * (UI_CONFIG.ELEMENT_HEIGHT + UI_CONFIG.SPACING)),
					BackgroundColor3 = "Accent",
					Text = btnConfig.Text or "Button",
					TextColor3 = "Text",
					TextSize = 16,
					Font = Enum.Font.GothamSemibold
				})
				Instance.new("UICorner", button).CornerRadius = UI_CONFIG.CORNER_RADIUS
				button.Parent = section.Content

				button.MouseButton1Click:Connect(function()
					if btnConfig.Callback then 
						task.spawn(btnConfig.Callback)
					end
					local tween = createTween(button, {Size = UDim2.new(1, -18, 0, UI_CONFIG.ELEMENT_HEIGHT - 14)}, 0.03)
					tween:Play()
					tween.Completed:Wait()
					createTween(button, {Size = UDim2.new(1, -14, 0, UI_CONFIG.ELEMENT_HEIGHT - 10)}, 0.03):Play()
				end)

				button.MouseEnter:Connect(function()
					createTween(button, {BackgroundColor3 = window.Config.Theme.Hover}):Play()
				end)
				button.MouseLeave:Connect(function()
					createTween(button, {BackgroundColor3 = window.Config.Theme.Accent}):Play()
				end)

				table.insert(section.Elements, button)
				updateLayout()
				return button
			end

			function section:AddToggle(tglConfig)
				local toggle = Instance.new("Frame")
				toggle.ZIndex = 7
				toggle.Size = UDim2.new(1, 0, 0, UI_CONFIG.ELEMENT_HEIGHT)
				toggle.Position = UDim2.fromOffset(0, #section.Elements * (UI_CONFIG.ELEMENT_HEIGHT + UI_CONFIG.SPACING))
				toggle.BackgroundTransparency = 1
				toggle.Parent = section.Content

				local label = Instance.new("TextLabel")
				label.ZIndex = 8
				applyTheme(label, window.Config.Theme, {
					Size = UDim2.new(0, 260, 1, 0),
					Position = UDim2.fromOffset(7, 0),
					BackgroundTransparency = 1,
					Text = tglConfig.Text or "Toggle",
					TextColor3 = "Text",
					TextSize = 16,
					Font = Enum.Font.GothamSemibold
				})
				label.Parent = toggle

				local state = tglConfig.Default or false
				local toggleBtn = Instance.new("TextButton")
				toggleBtn.ZIndex = 8
				applyTheme(toggleBtn, window.Config.Theme, {
					Size = UDim2.fromOffset(60, 28),
					Position = UDim2.new(1, -66, 0, 10),
					BackgroundColor3 = state and "Accent" or "Disabled",
					Text = state and "ON" or "OFF",
					TextColor3 = "Text",
					TextSize = 15,
					Font = Enum.Font.GothamBold
				})
				Instance.new("UICorner", toggleBtn).CornerRadius = UI_CONFIG.CORNER_RADIUS
				toggleBtn.Parent = toggle

				toggleBtn.MouseButton1Click:Connect(function()
					state = not state
					createTween(toggleBtn, {
						BackgroundColor3 = state and window.Config.Theme.Accent or window.Config.Theme.Disabled,
						Size = UDim2.fromOffset(state and 60 or 58, state and 28 or 26)
					}):Play()
					toggleBtn.Text = state and "ON" or "OFF"
					if tglConfig.Callback then 
						task.spawn(tglConfig.Callback, state)
					end
				end)

				table.insert(section.Elements, toggle)
				updateLayout()
				return toggle
			end

			function section:AddSlider(sliderConfig)
				local slider = Instance.new("Frame")
				slider.ZIndex = 7
				slider.Size = UDim2.new(1, 0, 0, UI_CONFIG.ELEMENT_HEIGHT)
				slider.Position = UDim2.fromOffset(0, #section.Elements * (UI_CONFIG.ELEMENT_HEIGHT + UI_CONFIG.SPACING))
				slider.BackgroundTransparency = 1
				slider.Parent = section.Content

				local label = Instance.new("TextLabel")
				label.ZIndex = 8
				applyTheme(label, window.Config.Theme, {
					Size = UDim2.new(0, 180, 0, 24),
					Position = UDim2.fromOffset(7, 0),
					BackgroundTransparency = 1,
					Text = sliderConfig.Text or "Slider",
					TextColor3 = "Text",
					TextSize = 16,
					Font = Enum.Font.GothamSemibold
				})
				label.Parent = slider

				local sliderBar = Instance.new("Frame")
				sliderBar.ZIndex = 8
				applyTheme(sliderBar, window.Config.Theme, {
					Size = UDim2.new(1, -60, 0, 12),
					Position = UDim2.new(0, 7, 1, -16),
					BackgroundColor3 = "Disabled"
				})
				Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(0, 6)
				sliderBar.Parent = slider

				local fill = Instance.new("Frame")
				fill.ZIndex = 9
				applyTheme(fill, window.Config.Theme, {
					Size = UDim2.new(0, 0, 1, 0),
					BackgroundColor3 = "Accent"
				})
				Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 6)
				fill.Parent = sliderBar

				local knob = Instance.new("Frame")
				knob.ZIndex = 10
				applyTheme(knob, window.Config.Theme, {
					Size = UDim2.fromOffset(18, 18),
					Position = UDim2.new(0, 0, 0.5, 0),
					BackgroundColor3 = "Accent",
					AnchorPoint = Vector2.new(0.5, 0.5)
				})
				Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 9)
				knob.Parent = sliderBar

				local valueLabel = Instance.new("TextLabel")
				valueLabel.ZIndex = 8
				applyTheme(valueLabel, window.Config.Theme, {
					Size = UDim2.new(0, 50, 0, 24),
					Position = UDim2.new(1, -57, 0, 0),
					BackgroundTransparency = 1,
					Text = tostring(sliderConfig.Default or 0),
					TextColor3 = "Text",
					TextSize = 15,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Right
				})
				valueLabel.Parent = slider

				local minValue = sliderConfig.Min or 0
				local maxValue = sliderConfig.Max or 100
				local currentValue = math.clamp(sliderConfig.Default or minValue, minValue, maxValue)
				local dragging = false

				local function updateSlider(percent)
					currentValue = minValue + (maxValue - minValue) * percent
					fill.Size = UDim2.new(percent, 0, 1, 0)
					knob.Position = UDim2.new(percent, 0, 0.5, 0)
					valueLabel.Text = math.floor(currentValue + 0.5)
					if sliderConfig.Callback then 
						task.spawn(sliderConfig.Callback, currentValue)
					end
				end

				local initialPercent = (currentValue - minValue) / (maxValue - minValue)
				updateSlider(initialPercent)

				sliderBar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = true
						isDraggingSlider = true
					end
				end)

				sliderBar.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = false
						isDraggingSlider = false
					end
				end)

				local connection = RunService.RenderStepped:Connect(function()
					if dragging then
						local mouseX = UserInputService:GetMouseLocation().X
						local barX = sliderBar.AbsolutePosition.X
						local barWidth = sliderBar.AbsoluteSize.X
						local percent = math.clamp((mouseX - barX) / barWidth, 0, 1)
						updateSlider(percent)
					end
				end)

				slider.Destroying:Connect(function()
					connection:Disconnect()
				end)

				table.insert(section.Elements, slider)
				updateLayout()
				return slider
			end

			table.insert(tab.Sections, section)
			section.Frame = sectionFrame
			updateLayout()
			return section
		end

		table.insert(window.State.Tabs, tab)
		return tab
	end

	-- Notification System
	function window:Notify(config)
		local notif = Instance.new("Frame")
		notif.ZIndex = 10
		applyTheme(notif, window.Config.Theme, {
			Size = UDim2.fromOffset(320, 100),
			Position = UDim2.new(1, 330, 1, -110 - (#window.State.Notifications * 115)),
			BackgroundColor3 = "Primary"
		})
		Instance.new("UICorner", notif).CornerRadius = UI_CONFIG.CORNER_RADIUS
		notif.Parent = screenGui

		local title = Instance.new("TextLabel")
		title.ZIndex = 11
		applyTheme(title, window.Config.Theme, {
			Size = UDim2.new(1, -40, 0, 28),
			Position = UDim2.fromOffset(18, 10),
			BackgroundTransparency = 1,
			Text = config.Title or "Notification",
			TextColor3 = config.Type == "Success" and "Success" or "Accent",
			TextSize = 16,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left
		})
		title.Parent = notif

		local closeBtn = Instance.new("TextButton")
		closeBtn.ZIndex = 12
		applyTheme(closeBtn, window.Config.Theme, {
			Size = UDim2.fromOffset(28, 28),
			Position = UDim2.new(1, -32, 0, 10),
			BackgroundTransparency = 1,
			Text = "×",
			TextColor3 = "Text",
			TextSize = 20,
			Font = Enum.Font.GothamBold
		})
		closeBtn.Parent = notif

		local message = Instance.new("TextLabel")
		message.ZIndex = 11
		applyTheme(message, window.Config.Theme, {
			Size = UDim2.new(1, -36, 0, 52),
			Position = UDim2.fromOffset(18, 38),
			BackgroundTransparency = 1,
			Text = config.Text or "Message",
			TextColor3 = "Text",
			TextSize = 15,
			Font = Enum.Font.Gotham,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left
		})
		message.Parent = notif

		table.insert(window.State.Notifications, notif)
		local tweenIn = createTween(notif, {Position = UDim2.new(1, -330, 1, -110 - (#window.State.Notifications - 1) * 115)}, 0.15)
		tweenIn:Play()

		local function closeNotification()
			local tweenOut = createTween(notif, {Position = UDim2.new(1, 330, 1, notif.Position.Y.Offset)})
			tweenOut:Play()
			tweenOut.Completed:Connect(function()
				local index = table.find(window.State.Notifications, notif)
				if index then
					table.remove(window.State.Notifications, index)
					notif:Destroy()
					for i, remaining in ipairs(window.State.Notifications) do
						createTween(remaining, {Position = UDim2.new(1, -330, 1, -110 - (i - 1) * 115)}):Play()
					end
				end
			end)
		end

		closeBtn.MouseButton1Click:Connect(closeNotification)
		task.delay(config.Duration or 2.5, closeNotification)
	end

	-- Keybind Handling
	local connection = UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == window.Config.Keybind then
			if window.State.Minimized then
				window.State.Minimized = false
				createTween(mainFrame, {Size = window.Config.Size}):Play()
			else
				window.State.Visible = not window.State.Visible
				mainFrame.Visible = window.State.Visible
			end
		end
	end)

	screenGui.Destroying:Connect(function()
		connection:Disconnect()
	end)

	return window
end
