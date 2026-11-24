-- VANTA UI Library 1.0 | Roblox client ModuleScript
local Player = game:GetService("Players").LocalPlayer
assert(Player, "VANTA must be required on the client")
local Library = {}
-- A capture belongs to one control across all instances of this module.
local KeyCapture = nil
local CapturedInput = nil
function Library.new()
    local Connections = {}
    local Running = true
    local PendingTasks = {}
    local NotificationQueue = {}
    local NotificationActive = false
    local NotificationHost
    local function delay(seconds, callback)
        local thread
        thread = task.delay(seconds, function()
            PendingTasks[thread] = nil
            if Running then
                callback()
            end
        end)
        PendingTasks[thread] = true
        return thread
    end
    local function invoke(cb, ...)
        if not Running or type(cb) ~= "function" then
            return
        end
        local ok, err = pcall(cb, ...)
        if not ok then
            warn("[VANTA] " .. tostring(err))
        end
    end
    local TweenService = game:GetService("TweenService")
    local UIS = game:GetService("UserInputService")
    local Native = {}
    local palette = {
        Dark = {
            base = Color3.fromRGB(17, 17, 17),
            side = Color3.fromRGB(17, 17, 17),
            card = Color3.fromRGB(40, 40, 40),
            hover = Color3.fromRGB(53, 53, 53),
            text = Color3.fromRGB(240, 240, 245),
            muted = Color3.fromRGB(155, 155, 168),
            line = Color3.fromRGB(53, 53, 61),
            accent = Color3.fromRGB(155, 155, 155),
        },
        Light = {
            base = Color3.fromRGB(245, 245, 248),
            side = Color3.fromRGB(231, 231, 237),
            card = Color3.fromRGB(255, 255, 255),
            hover = Color3.fromRGB(218, 218, 229),
            text = Color3.fromRGB(25, 25, 33),
            muted = Color3.fromRGB(85, 85, 100),
            line = Color3.fromRGB(205, 205, 216),
            accent = Color3.fromRGB(95, 85, 220),
        },
    }
    palette.Dark.base = Color3.fromRGB(8, 8, 8)
    palette.Dark.side = Color3.fromRGB(12, 12, 12)
    palette.Dark.card = Color3.fromRGB(21, 21, 21)
    palette.Dark.hover = Color3.fromRGB(34, 34, 34)
    palette.Dark.line = Color3.fromRGB(48, 48, 48)
    palette.Light.side = Color3.fromRGB(240, 240, 243)
    palette.Light.base = Color3.fromRGB(250, 250, 252)
    palette.Light.accent = Color3.fromRGB(65, 65, 80)
    local theme = "Dark"
    local bindings = setmetatable({}, { __mode = "k" })
    local function make(class, parent, props)
        local o = Instance.new(class)
        for k, v in pairs(props or {}) do
            o[k] = v
        end
        o.Parent = parent
        return o
    end
    local function tween(o, props, t)
        local a =
            TweenService:Create(o, TweenInfo.new(t or 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
        a:Play()
        return a
    end
    local function paint(o, prop, key)
        bindings[o] = bindings[o] or {}
        bindings[o][prop] = key
        o[prop] = palette[theme][key]
    end
    function Native:SetTheme(name)
        if not palette[name] then
            return
        end
        theme = name
        for o, props in pairs(bindings) do
            if o.Parent then
                local target = {}
                for prop, key in pairs(props) do
                    target[prop] = palette[theme][key]
                end
                tween(o, target)
            end
        end
    end
    local function corner(o, r)
        make("UICorner", o, { CornerRadius = UDim.new(0, r or 14) })
    end
    local function stroke(o)
        local st = make("UIStroke", o, { Thickness = 1, Transparency = 0.85 })
        paint(st, "Color", "line")
    end
    local function label(parent, text, size, muted)
        local l = make("TextLabel", parent, {
            BackgroundTransparency = 1,
            Text = text,
            TextSize = size or 14,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextWrapped = true,
            Size = UDim2.new(1, 0, 0, 22),
        })
        paint(l, "TextColor3", muted and "muted" or "text")
        return l
    end
    -- Lucide icons, pre-uploaded Roblox image assets.
    -- Source: https://github.com/Snxdfer/Roblox-UI-Libraries/blob/main/rbxassetidIcons.lua
    local icons = {
        ["layout-dashboard"] = 10723424646,
        ["arrow-up-circle"] = 10747363465,
        footprints = 10723377305,
        ["git-branch"] = 10723387085,
        ["door-open"] = 10709782497,
        ["map-pin"] = 10723417608,
        settings = 10734950309,
        resize = 10734942072,
        close = 10734909375,
        minus = 10723343737,
        down = 10734965115,
        chevron = 10723346684,
    }
    local function glyph(parent, name, size, pos)
        local f = make("ImageLabel", parent, {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(size, size),
            Position = pos,
            Image = "rbxassetid://" .. tostring(icons[name] or icons.chevron),
            ScaleType = Enum.ScaleType.Fit,
        })
        paint(f, "ImageColor3", "muted")
        return f
    end
    local function list(parent, gap)
        return make("UIListLayout", parent, { Padding = UDim.new(0, gap or 8), SortOrder = Enum.SortOrder.LayoutOrder })
    end
    local function pad(parent, n)
        make("UIPadding", parent, {
            PaddingTop = UDim.new(0, n),
            PaddingBottom = UDim.new(0, n),
            PaddingLeft = UDim.new(0, n),
            PaddingRight = UDim.new(0, n),
        })
    end
    local function frame(parent, key)
        local f = make(
            "Frame",
            parent,
            { BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }
        )
        paint(f, "BackgroundColor3", key or "card")
        corner(f)
        return f
    end
    local function button(parent, text, callback)
        local b = make("TextButton", parent, {
            Text = text,
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, 38),
            BorderSizePixel = 0,
            TextWrapped = true,
        })
        paint(b, "BackgroundColor3", "hover")
        paint(b, "TextColor3", "text")
        corner(b, 10)
        b.MouseEnter:Connect(function()
            tween(b, { BackgroundColor3 = palette[theme].hover })
        end)
        b.MouseLeave:Connect(function()
            tween(b, { BackgroundColor3 = palette[theme].hover })
        end)
        local scale = make("UIScale", b, { Scale = 1 })
        b.Activated:Connect(function()
            tween(scale, { Scale = 0.97 }, 0.07)
            delay(0.08, function()
                if scale.Parent then
                    tween(scale, { Scale = 1 })
                end
            end)
            if callback then
                callback()
            end
        end)
        return b
    end
    local function input(parent, placeholder, value)
        local b = make("TextBox", parent, {
            Text = tostring(value or ""),
            PlaceholderText = placeholder or "",
            ClearTextOnFocus = false,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            Size = UDim2.new(1, 0, 0, 36),
            BorderSizePixel = 0,
        })
        paint(b, "BackgroundColor3", "base")
        paint(b, "TextColor3", "text")
        paint(b, "PlaceholderColor3", "muted")
        corner(b)
        return b
    end
    local function scroll(parent)
        local f = make("ScrollingFrame", parent, {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Size = UDim2.fromScale(1, 1),
        })
        paint(f, "ScrollBarImageColor3", "muted")
        return f
    end
    local function tabAPI(page)
        local tab = {}
        local controlConnections = {}
        local function trackControlConnection(connection)
            table.insert(Connections, connection)
            table.insert(controlConnections, connection)
            return connection
        end
        function tab:Clear()
            for _, connection in ipairs(controlConnections) do
                connection:Disconnect()
                local index = table.find(Connections, connection)
                if index then
                    table.remove(Connections, index)
                end
            end
            table.clear(controlConnections)
            for _, child in ipairs(page:GetChildren()) do
                if child:IsA("GuiObject") then
                    child:Destroy()
                end
            end
        end
        local function card(title, desc, controlWidth)
            local f = frame(page)
            pad(f, 12)
            if not controlWidth then
                list(f, 5)
            else
                f.AutomaticSize = Enum.AutomaticSize.None
                f.Size = UDim2.new(1, 0, 0, (desc and desc ~= "") and 66 or 46)
            end
            local body = make(
                "Frame",
                f,
                { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }
            )
            list(body, 2)
            local text = make("Frame", body, {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -(controlWidth or 0), 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
            })
            list(text, 2)
            local t = label(text, title, 15)
            t.Font = Enum.Font.GothamMedium
            t.Size = UDim2.new(1, 0, 0, 20)
            local d = label(text, desc or "", 13, true)
            d.AutomaticSize = Enum.AutomaticSize.Y
            d.Size = UDim2.new(1, 0, 0, 0)
            d.Visible = desc ~= nil and desc ~= ""
            local api = {}
            function api:SetDesc(value)
                value = tostring(value or "")
                if d.Text ~= value then
                    d.Text = value
                end
                d.Visible = value ~= ""
            end
            return f, api
        end
        function tab:Section(p)
            local l = label(page, p.Title, 16)
            l.Size = UDim2.new(1, 0, 0, 34)
            l.Font = Enum.Font.GothamMedium
        end
        function tab:Paragraph(p)
            local _, a = card(p.Title, p.Desc)
            return a
        end
        function tab:Button(p)
            local f, a = card(p.Title, p.Desc, 38)
            local hit = make("TextButton", f, {
                BackgroundTransparency = 1,
                Text = "",
                Size = UDim2.fromScale(1, 1),
                ZIndex = 5,
                AutoButtonColor = false,
            })
            local arrow = label(hit, " >", 19, true)
            arrow.AnchorPoint = Vector2.new(1, 0.5)
            arrow.Position = UDim2.new(1, -4, 0.5, 0)
            arrow.Size = UDim2.fromOffset(24, 24)
            hit.MouseEnter:Connect(function()
                tween(f, { BackgroundColor3 = palette[theme].hover })
            end)
            hit.MouseLeave:Connect(function()
                tween(f, { BackgroundColor3 = palette[theme].card })
            end)
            hit.Activated:Connect(function()
                tween(f, { BackgroundColor3 = palette[theme].hover }, 0.08)
                invoke(p.Callback)
            end)
            return a
        end
        function tab:Toggle(p)
            local f, a = card(p.Title, p.Desc, 58)
            local v = p.Value == true
            local b = make(
                "TextButton",
                f,
                { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5 }
            )
            local track = make("Frame", b, {
                Size = UDim2.fromOffset(42, 24),
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -2, 0.5, 0),
                BorderSizePixel = 0,
            })
            corner(track, 12)
            local knob = make("Frame", track, {
                Size = UDim2.fromOffset(18, 18),
                Position = UDim2.fromOffset(3, 3),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
            })
            corner(knob, 9)
            local function update()
                paint(track, "BackgroundColor3", v and "accent" or "line")
                tween(knob, { Position = UDim2.fromOffset(v and 21 or 3, 3) }, 0.28)
            end
            function a:SetValue(value, silent)
                v = value == true
                update()
                if not silent then
                    invoke(p.Callback, v)
                end
            end
            function a:GetValue()
                return v
            end
            b.Activated:Connect(function()
                a:SetValue(not v)
            end)
            update()
            return a
        end
        function tab:Input(p)
            local f, a = card(p.Title, p.Desc)
            local b = input(f, p.Placeholder, p.Value)
            b:GetPropertyChangedSignal("Text"):Connect(function()
                invoke(p.Callback, b.Text)
            end)
            function a:SetValue(v)
                b.Text = tostring(v or "")
            end
            function a:GetValue()
                return b.Text
            end
            return a
        end
        function tab:Slider(p)
            local f, a = card(p.Title, p.Desc)
            local min, max = p.Value.Min, p.Value.Max
            assert(max > min, "Slider Max must exceed Min")
            local step = p.Step or 1
            assert(step > 0, "Slider Step must be positive")
            local function snap(value)
                assert(
                    type(value) == "number" and value == value and math.abs(value) < math.huge,
                    "Slider value must be finite"
                )
                return math.clamp(min + math.floor((value - min) / step + 0.5) * step, min, max)
            end
            local v = snap(p.Value.Default or min)
            local l = label(f, tostring(v), 13, true)
            local bar = button(f, "", nil)
            bar.Text = ""
            bar.Size = UDim2.new(1, 0, 0, 26)
            local fill = make("Frame", bar, { BorderSizePixel = 0, Size = UDim2.new((v - min) / (max - min), 0, 1, 0) })
            corner(fill)
            paint(fill, "BackgroundColor3", "accent")
            function a:SetValue(value, silent)
                v = snap(value)
                l.Text = tostring(v)
                tween(fill, { Size = UDim2.new((v - min) / (max - min), 0, 1, 0) }, 0.1)
                if not silent then
                    invoke(p.Callback, v)
                end
            end
            function a:GetValue()
                return v
            end
            local function set(x)
                a:SetValue(
                    min + (max - min) * math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
                )
            end
            local dragging = false
            bar.InputBegan:Connect(function(i)
                if
                    i.UserInputType == Enum.UserInputType.MouseButton1
                    or i.UserInputType == Enum.UserInputType.Touch
                then
                    dragging = true
                    set(i.Position.X)
                end
            end)
            trackControlConnection(UIS.InputChanged:Connect(function(i)
                if
                    dragging
                    and (
                        i.UserInputType == Enum.UserInputType.MouseMovement
                        or i.UserInputType == Enum.UserInputType.Touch
                    )
                then
                    set(i.Position.X)
                end
            end))
            trackControlConnection(UIS.InputEnded:Connect(function(i)
                if
                    i.UserInputType == Enum.UserInputType.MouseButton1
                    or i.UserInputType == Enum.UserInputType.Touch
                then
                    dragging = false
                end
            end))
            return a
        end
        function tab:Dropdown(p)
            local f = card(p.Title)
            local values = p.Values or {}
            local selected = p.Value
            local open = false
            local body = f:FindFirstChildWhichIsA("Frame")
            body.Size = UDim2.new(1, -155, 0, 30)
            body.AutomaticSize = Enum.AutomaticSize.None
            local head = button(body, tostring(selected or "Select"), nil)
            head.AnchorPoint = Vector2.new(1, 0)
            head.Size = UDim2.fromOffset(144, 30)
            head.Position = UDim2.new(1, 155, 0, 0)
            head.Parent = f
            head.Position = UDim2.new(1, -12, 0, 12)
            head.LayoutOrder = -1
            -- Overlay control is hosted in a non-list row.
            head.Parent = body:FindFirstChildWhichIsA("Frame") or body
            head.Position = UDim2.new(1, 155, 0, 0)
            head.AnchorPoint = Vector2.new(1, 0)
            head.Parent = body
            local layout = body:FindFirstChildOfClass("UIListLayout")
            if layout then
                layout:Destroy()
            end
            glyph(head, "down", 14, UDim2.new(1, -18, 0.5, -7))
            local panel =
                make("Frame", f, { BackgroundTransparency = 1, ClipsDescendants = true, Size = UDim2.new(1, 0, 0, 0) })
            list(panel, 5)
            local search = input(panel, "Search...", "")
            search.Visible = p.SearchBarEnabled == true
            local options = scroll(panel)
            options.Size = UDim2.new(1, 0, 0, 150)
            list(options, 4)
            local api = {}
            local function height()
                if open then
                    panel.Visible = true
                end
                tween(panel, { Size = UDim2.new(1, 0, 0, open and (search.Visible and 191 or 150) or 0) }, 0.32)
                if not open then
                    delay(0.33, function()
                        if not open and panel.Parent then
                            panel.Visible = false
                        end
                    end)
                end
            end
            panel.Visible = false
            local function rebuild()
                for _, o in ipairs(options:GetChildren()) do
                    if o:IsA("TextButton") then
                        o:Destroy()
                    end
                end
                for _, value in ipairs(values) do
                    if string.find(string.lower(value), string.lower(search.Text), 1, true) then
                        button(options, value, function()
                            api:Select(value)
                            open = false
                            height()
                        end)
                    end
                end
            end
            function api:Select(value)
                selected = value
                head.Text = tostring(value or "Select")
                invoke(p.Callback, value)
            end
            function api:GetValue()
                return selected
            end
            function api:SetValue(value)
                self:Select(value)
            end
            function api:Refresh(newValues, silent)
                local previous = selected
                values = newValues or {}
                selected = nil
                head.Text = "Select"
                rebuild()
                if previous ~= nil and not silent then
                    invoke(p.Callback, nil)
                end
            end
            head.Activated:Connect(function()
                open = not open
                height()
            end)
            search:GetPropertyChangedSignal("Text"):Connect(rebuild)
            rebuild()
            return api
        end
        function tab:Keybind(p)
            local f, a = card(p.Title, p.Desc, 120)
            local value = p.Value or "K"
            local b = button(f, value, nil)
            b.AnchorPoint = Vector2.new(1, 0.5)
            b.Position = UDim2.new(1, -3, 0.5, 0)
            b.Size = UDim2.fromOffset(106, 30)
            local token = { Owner = Native }
            function token.Cancel()
                if KeyCapture == token then
                    KeyCapture = nil
                end
                if b.Parent then
                    b.Text = value
                end
            end
            b.Destroying:Connect(function()
                if KeyCapture == token then
                    token.Cancel()
                end
            end)
            b.Activated:Connect(function()
                if not Running then
                    return
                end
                if KeyCapture then
                    KeyCapture.Cancel()
                end
                KeyCapture = token
                b.Text = "Press a key..."
            end)
            trackControlConnection(UIS.InputBegan:Connect(function(i)
                if KeyCapture ~= token or i.KeyCode == Enum.KeyCode.Unknown or UIS:GetFocusedTextBox() then
                    return
                end
                CapturedInput = i
                KeyCapture = nil
                task.defer(function()
                    if CapturedInput == i then
                        CapturedInput = nil
                    end
                end)
                if i.KeyCode == Enum.KeyCode.Escape then
                    token.Cancel()
                    return
                end
                value = i.KeyCode.Name
                b.Text = value
                invoke(p.Callback, value)
            end))
            function a:GetValue()
                return value
            end
            function a:SetValue(key)
                local name = typeof(key) == "EnumItem" and key.Name or key
                local ok, resolved = pcall(function()
                    return Enum.KeyCode[name]
                end)
                assert(ok and resolved and resolved ~= Enum.KeyCode.Unknown, "Invalid keybind key")
                token.Cancel()
                value = resolved.Name
                b.Text = value
                invoke(p.Callback, value)
            end
            return a
        end
        return tab
    end
    function Native:CreateWindow(p)
        assert(not self.gui, "Use VANTA.new() for another window")
        p = p or {}
        p.Title = p.Title or "Untitled"
        p.Author = p.Author or "VANTA UI"
        p.Size = p.Size or UDim2.fromOffset(760, 540)
        p.ToggleKey = p.ToggleKey or Enum.KeyCode.K
        theme = palette[p.Theme] and p.Theme or "Dark"
        local sideWidth = p.SideBarWidth or 190
        local gui = make("ScreenGui", Player:WaitForChild("PlayerGui"), {
            Name = "VantaUI",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 50,
            ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
        })
        self.gui = gui
        local screen =
            make("Frame", gui, { Name = "Viewport", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) })
        self.screen = screen
        local root = make("Frame", screen, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = p.Size,
            BorderSizePixel = 0,
        })
        paint(root, "BackgroundColor3", "base")
        corner(root, 18)
        stroke(root)
        root.ClipsDescendants = true
        local uiScale = make("UIScale", root, { Scale = 1 })
        local top = make("Frame", root, { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 54) })
        local function logo(parent, size, pos)
            local f = make(
                "Frame",
                parent,
                { BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), Position = pos }
            )
            local polygons = {
                { { 5, 10 }, { 21, 10 }, { 38, 49 }, { 30, 60 } },
                { { 43, 10 }, { 59, 10 }, { 42, 44 }, { 34, 26 } },
                { { 25, 10 }, { 37, 10 }, { 31, 23 } },
            }
            for index, poly in ipairs(polygons) do
                for y = 10, 59 do
                    local xs = {}
                    local yy = y + 0.5
                    for j, a in ipairs(poly) do
                        local b = poly[j % #poly + 1]
                        if (a[2] <= yy and b[2] > yy) or (b[2] <= yy and a[2] > yy) then
                            table.insert(xs, a[1] + (yy - a[2]) * (b[1] - a[1]) / (b[2] - a[2]))
                        end
                    end
                    table.sort(xs)
                    if #xs >= 2 then
                        local strip = make("Frame", f, {
                            BorderSizePixel = 0,
                            Position = UDim2.fromScale(xs[1] / 64, y / 64),
                            Size = UDim2.fromScale((xs[2] - xs[1]) / 64, 1.15 / 64),
                        })
                        paint(strip, "BackgroundColor3", index == 2 and "muted" or "text")
                    end
                end
            end
            return f
        end
        logo(top, 32, UDim2.fromOffset(13, 10))
        local title = label(top, "VANTA  /  " .. p.Title, 15)
        title.Font = Enum.Font.GothamMedium
        title.Position = UDim2.fromOffset(52, 7)
        title.Size = UDim2.new(1, -150, 0, 21)
        local subtitle = label(top, p.Author, 12, true)
        subtitle.Position = UDim2.fromOffset(52, 28)
        subtitle.Size = UDim2.new(1, -150, 0, 18)
        local shown = true
        local splash = make("Frame", gui, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(320, 100),
            BackgroundTransparency = 1,
        })
        local word = label(splash, "V A N T A", 32)
        word.Font = Enum.Font.GothamBold
        word.TextColor3 = Color3.new(1, 1, 1)
        word.TextStrokeTransparency = 0.65
        word.TextXAlignment = Enum.TextXAlignment.Center
        word.Size = UDim2.fromScale(1, 1)
        word.TextTransparency = 1
        root.Visible = false
        tween(word, { TextTransparency = 0 }, 0.8)
        delay(2.1, function()
            if not splash.Parent then
                return
            end
            tween(word, { TextTransparency = 1 }, 0.55)
            delay(0.56, function()
                if splash.Parent then
                    splash:Destroy()
                end
                if root.Parent and Running then
                    root.Visible = shown
                    local target = root.Position
                    root.Position = target + UDim2.fromOffset(0, 18)
                    tween(root, { Position = target }, 0.5)
                end
            end)
        end)
        local sidebar = scroll(root)
        sidebar.Position = UDim2.fromOffset(0, 54)
        sidebar.Size = UDim2.new(0, sideWidth, 1, -54)
        sidebar.BackgroundTransparency = 0
        paint(sidebar, "BackgroundColor3", "side")
        pad(sidebar, 10)
        list(sidebar, 5)
        local content = make("Frame", root, {
            BackgroundTransparency = 0,
            BackgroundColor3 = Color3.fromRGB(27, 27, 27),
            Position = UDim2.fromOffset(sideWidth + 10, 54),
            Size = UDim2.new(1, -sideWidth - 22, 1, -66),
            ClipsDescendants = true,
        })
        paint(content, "BackgroundColor3", "side")
        corner(content, 12)
        local window = {}
        local active
        local activeNav
        local key = p.ToggleKey
        local destroyed = false
        local destroyCallback
        local collapsed = false
        local transitioning = false
        local expandedSize = p.Size
        local grip
        local collapseTween
        local requestedSize = p.Size
        local function viewport()
            local size = screen.AbsoluteSize
            if size.X <= 0 or size.Y <= 0 then
                return Vector2.new(760, 540)
            end
            return size
        end
        local function clampPosition()
            local size = viewport()
            local width = root.Size.X.Offset * uiScale.Scale
            local height = root.Size.Y.Offset * uiScale.Scale
            local margin = math.min(12, size.X / 4, size.Y / 4)
            local x = root.Position.X.Scale * size.X + root.Position.X.Offset
            local y = root.Position.Y.Scale * size.Y + root.Position.Y.Offset
            x = math.clamp(x, width / 2 + margin, math.max(width / 2 + margin, size.X - width / 2 - margin))
            y = math.clamp(y, height / 2 + margin, math.max(height / 2 + margin, size.Y - height / 2 - margin))
            root.Position = UDim2.fromOffset(x, y)
        end
        local function fitViewport()
            if destroyed then
                return
            end
            if collapseTween then
                collapseTween:Cancel()
            end
            transitioning = false
            local size = viewport()
            local availableW = math.max(1, size.X - 24)
            local availableH = math.max(1, size.Y - 24)
            local width =
                math.clamp(requestedSize.X.Scale * size.X + requestedSize.X.Offset, 560, math.max(560, availableW))
            local height =
                math.clamp(requestedSize.Y.Scale * size.Y + requestedSize.Y.Offset, 360, math.max(360, availableH))
            expandedSize = UDim2.fromOffset(width, height)
            uiScale.Scale = math.min(1, availableW / width, availableH / height)
            root.Size = collapsed and UDim2.fromOffset(width, 54) or expandedSize
            sidebar.Visible = not collapsed
            content.Visible = not collapsed
            if grip then
                grip.Visible = not collapsed
            end
            clampPosition()
        end
        table.insert(Connections, screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitViewport))
        local function visibility()
            if destroyed then
                return
            end
            shown = not shown
            root.Visible = shown
        end
        local function collapse()
            if destroyed or transitioning then
                return
            end
            transitioning = true
            collapsed = not collapsed
            if collapsed then
                expandedSize = root.Size
                local shift = (root.Size.Y.Offset - 54) * uiScale.Scale / 2
                if grip then
                    grip.Visible = false
                end
                collapseTween = tween(root, {
                    Size = UDim2.new(expandedSize.X.Scale, expandedSize.X.Offset, 0, 54),
                    Position = root.Position - UDim2.fromOffset(0, shift),
                }, 0.38)
                collapseTween.Completed:Connect(function()
                    if destroyed then
                        return
                    end
                    sidebar.Visible = false
                    content.Visible = false
                    transitioning = false
                    clampPosition()
                end)
            else
                sidebar.Visible = true
                content.Visible = true
                collapseTween = tween(root, {
                    Size = expandedSize,
                    Position = root.Position + UDim2.fromOffset(0, (expandedSize.Y.Offset - 54) * uiScale.Scale / 2),
                }, 0.38)
                local current = collapseTween
                current.Completed:Connect(function(state)
                    if
                        state == Enum.PlaybackState.Completed
                        and not collapsed
                        and not destroyed
                        and collapseTween == current
                    then
                        sidebar.Visible = true
                        content.Visible = true
                        if grip then
                            grip.Visible = true
                        end
                        transitioning = false
                        clampPosition()
                    end
                end)
            end
        end
        local function topButton(text, x, cb)
            local b = button(top, "", cb)
            b.Size = UDim2.fromOffset(32, 30)
            b.Position = UDim2.new(1, x, 0, 12)
            b.BackgroundTransparency = 1
            local mark = label(b, text == "minus" and "\u{2212}" or "\u{00D7}", 22)
            mark.Size = UDim2.fromScale(1, 1)
            mark.TextXAlignment = Enum.TextXAlignment.Center
            b.MouseEnter:Connect(function()
                tween(b, { BackgroundTransparency = 0 }, 0.18)
            end)
            b.MouseLeave:Connect(function()
                tween(b, { BackgroundTransparency = 1 }, 0.18)
            end)
        end
        topButton("minus", -80, collapse)
        topButton("close", -40, function()
            if shown then
                visibility()
            end
        end)
        function window:SetToggleKey(k)
            key = type(k) == "string" and Enum.KeyCode[k] or k
        end
        function window:SetVisible(v)
            if not destroyed then
                shown = v == true
                root.Visible = shown
            end
        end
        function window:Toggle()
            visibility()
        end
        function window:Collapse()
            collapse()
        end
        function window:SetTheme(name)
            Native:SetTheme(name)
        end
        function window:Notify(options)
            Native:Notify(options)
        end
        function window:OnDestroy(cb)
            destroyCallback = cb
        end
        local function shutdown()
            if destroyed then
                return false
            end
            destroyed = true
            Running = false
            if collapseTween then
                collapseTween:Cancel()
            end
            if KeyCapture and KeyCapture.Owner == Native then
                KeyCapture.Cancel()
            end
            for _, connection in ipairs(Connections) do
                connection:Disconnect()
            end
            table.clear(Connections)
            for thread in pairs(PendingTasks) do
                task.cancel(thread)
            end
            table.clear(PendingTasks)
            table.clear(NotificationQueue)
            table.clear(bindings)
            -- Global listeners are gone before application cleanup, even if it yields.
            local callback = destroyCallback
            destroyCallback = nil
            if type(callback) == "function" then
                local ok, err = pcall(callback)
                if not ok then
                    warn("[VANTA] " .. tostring(err))
                end
            end
            return true
        end
        table.insert(Connections, gui.Destroying:Connect(shutdown))
        table.insert(
            Connections,
            root.Destroying:Connect(function()
                shutdown()
                -- The root may be removed independently of its ScreenGui.
                task.defer(function()
                    if gui.Parent then
                        gui:Destroy()
                    end
                end)
            end)
        )
        function window:Destroy()
            if not shutdown() then
                return
            end
            if not gui.Parent then
                return
            end
            root.Visible = false
            if splash.Parent then
                splash:Destroy()
            end
            if NotificationHost then
                NotificationHost:Destroy()
            end
            local outro = make("Frame", gui, {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(320, 100),
                BackgroundTransparency = 1,
            })
            local goodbye = label(outro, "V A N T A", 32)
            goodbye.Font = Enum.Font.GothamBold
            goodbye.TextColor3 = Color3.new(1, 1, 1)
            goodbye.TextStrokeTransparency = 0.65
            goodbye.TextXAlignment = Enum.TextXAlignment.Center
            goodbye.Size = UDim2.fromScale(1, 1)
            goodbye.TextTransparency = 1
            tween(goodbye, { TextTransparency = 0 }, 0.45)
            task.delay(1.05, function()
                if outro.Parent then
                    tween(goodbye, { TextTransparency = 1 }, 0.7)
                    tween(outro, { Position = UDim2.fromScale(0.5, 0.47) }, 0.7)
                end
            end)
            task.delay(1.85, function()
                if gui.Parent then
                    gui:Destroy()
                end
            end)
        end
        table.insert(
            Connections,
            UIS.InputBegan:Connect(function(i, processed)
                if not Running or KeyCapture or i == CapturedInput then
                    return
                end
                if not processed and i.KeyCode == key and not UIS:GetFocusedTextBox() then
                    visibility()
                end
            end)
        )
        local drag, start, origin
        top.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                drag = true
                start = i.Position
                origin = root.Position
            end
        end)
        table.insert(
            Connections,
            UIS.InputChanged:Connect(function(i)
                if
                    drag
                    and not transitioning
                    and (
                        i.UserInputType == Enum.UserInputType.MouseMovement
                        or i.UserInputType == Enum.UserInputType.Touch
                    )
                then
                    local d = i.Position - start
                    root.Position = origin + UDim2.fromOffset(d.X, d.Y)
                    clampPosition()
                end
            end)
        )
        table.insert(
            Connections,
            UIS.InputEnded:Connect(function(i)
                if
                    i.UserInputType == Enum.UserInputType.MouseButton1
                    or i.UserInputType == Enum.UserInputType.Touch
                then
                    drag = false
                end
            end)
        )
        grip = make("TextButton", root, {
            Text = "",
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Size = UDim2.fromOffset(24, 24),
            Position = UDim2.new(1, -26, 1, -26),
            ZIndex = 10,
        })
        local ri = glyph(grip, "resize", 16, UDim2.fromOffset(4, 4))
        ri.Rotation = 0
        local resizing, rs, sz, resizeOrigin
        grip.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = true
                rs = i.Position
                sz = Vector2.new(root.Size.X.Offset, root.Size.Y.Offset)
                resizeOrigin = root.Position
            end
        end)
        table.insert(
            Connections,
            UIS.InputChanged:Connect(function(i)
                if resizing and not collapsed and i.UserInputType == Enum.UserInputType.MouseMovement then
                    local d = i.Position - rs
                    local w, h = math.max(560, sz.X + d.X / uiScale.Scale), math.max(360, sz.Y + d.Y / uiScale.Scale)
                    requestedSize = UDim2.fromOffset(w, h)
                    root.Position = resizeOrigin
                        + UDim2.fromOffset((w - sz.X) * uiScale.Scale / 2, (h - sz.Y) * uiScale.Scale / 2)
                    fitViewport()
                end
            end)
        )
        table.insert(
            Connections,
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    resizing = false
                end
            end)
        )
        function window:Section(section)
            local group = make(
                "Frame",
                sidebar,
                { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }
            )
            list(group, 4)
            local l = label(group, section.Title, 13, true)
            l.Size = UDim2.new(1, 0, 0, 30)
            l.Font = Enum.Font.GothamMedium
            local sec = {}
            function sec:Tab(t)
                local page = make(
                    "Frame",
                    content,
                    { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false }
                )
                local sc = scroll(page)
                pad(sc, 18)
                list(sc, 6)

                local nav
                local function selectTab()
                    if active == page then
                        return
                    end
                    if active then
                        active.Visible = false
                    end
                    if activeNav then
                        tween(activeNav, { BackgroundTransparency = 1 })
                    end
                    activeNav = nav
                    if nav then
                        tween(nav, { BackgroundTransparency = 0 })
                    end
                    active = page
                    page.Visible = true
                    page.Position = UDim2.fromOffset(0, 18)
                    tween(page, { Position = UDim2.fromOffset(0, 0) }, 0.55)
                end
                nav = button(group, "", selectTab)
                glyph(nav, t.Icon, 17, UDim2.fromOffset(8, 9))
                local nt = label(nav, t.Title, 14)
                nt.Position = UDim2.fromOffset(35, 0)
                nt.Size = UDim2.new(1, -35, 1, 0)
                nav.BackgroundTransparency = 1
                nav.Size = UDim2.new(1, 0, 0, 36)
                nav.TextXAlignment = Enum.TextXAlignment.Left
                if not active then
                    selectTab()
                end
                local api = tabAPI(sc)
                function api:Select()
                    selectTab()
                end
                return api
            end
            return sec
        end
        function window:Tab(t)
            if not self.defaultSection then
                self.defaultSection = self:Section({ Title = "General" })
            end
            return self.defaultSection:Tab(t)
        end
        fitViewport()
        return window
    end
    local function showNextNotification()
        if not Running or NotificationActive or #NotificationQueue == 0 then
            return
        end
        if not Native.gui or not Native.gui.Parent then
            return
        end
        NotificationActive = true
        local p = table.remove(NotificationQueue, 1)
        if not NotificationHost or not NotificationHost.Parent then
            NotificationHost = make("Frame", Native.screen, {
                Name = "Notifications",
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 1),
                Position = UDim2.new(1, -12, 1, -12),
                Size = UDim2.new(1, -24, 0, 86),
                ClipsDescendants = true,
            })
            make("UISizeConstraint", NotificationHost, { MaxSize = Vector2.new(280, 86) })
        end
        local f = frame(NotificationHost)
        f.AutomaticSize = Enum.AutomaticSize.None
        f.Size = UDim2.fromScale(1, 1)
        f.Position = UDim2.fromScale(1, 0)
        stroke(f)
        pad(f, 10)
        list(f, 3)
        label(f, p.Title, 15)
        local d = label(f, p.Content, 13, true)
        d.Size = UDim2.new(1, 0, 0, 36)
        tween(f, { Position = UDim2.fromScale(0, 0) })
        delay(p.Duration, function()
            if f.Parent then
                tween(f, { Position = UDim2.fromScale(1, 0) })
            end
            delay(0.25, function()
                if f.Parent then
                    f:Destroy()
                end
                NotificationActive = false
                showNextNotification()
            end)
        end)
    end
    function Native:Notify(p)
        if not Running or not self.gui or not self.gui.Parent then
            return
        end
        p = p or {}
        local duration = p.Duration or 3
        assert(
            type(duration) == "number" and duration == duration and duration >= 0 and duration < math.huge,
            "Notification Duration must be finite and nonnegative"
        )
        table.insert(
            NotificationQueue,
            { Title = tostring(p.Title or "Notice"), Content = tostring(p.Content or ""), Duration = duration }
        )
        showNextNotification()
    end

    return Native
end
local default = Library.new()
function Library:CreateWindow(options)
    return default:CreateWindow(options)
end
function Library:Notify(options)
    return default:Notify(options)
end
function Library:SetTheme(name)
    return default:SetTheme(name)
end
return Library
