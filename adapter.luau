--[[
	Compatibility layer: the Deport UI, wearing the NeverLose API.

	main.lua is twenty-six thousand lines written against NeverLose - AddTab,
	AddSection, AddLabel():AddToggle{}, Flags, and so on. The library has a
	different shape (win:tab -> tab:sub -> sub:section -> sec:toggle{}), so
	the old surface is implemented on top of it here and the feature code is
	untouched: only the rendering changes.

	Navigation maps straight onto the design: a tab is an entry in the bar
	along the bottom, and its subs are the capsule of pages under the title.
]]

-- The library is handed over as a string or a function, as this chunk's own
-- argument. It is never written to disk and never sits in a global where a
-- second inject could clear it.
local UI_SOURCE, ASSETS = ...;

if type(UI_SOURCE) ~= "string" and type(UI_SOURCE) ~= "function"
	and readfile and isfile and isfile("UI-lib/deport.luau") then
	UI_SOURCE = readfile("UI-lib/deport.luau");
end;

local lib;

if type(UI_SOURCE) == "function" then
	lib = UI_SOURCE(ASSETS);
else
	assert(type(UI_SOURCE) == "string" and UI_SOURCE ~= "", "deport ui source missing");
	lib = assert(loadstring(UI_SOURCE, "@deport"))(ASSETS);
end;

UI_SOURCE = nil;

assert(type(lib) == "table" and type(lib.window) == "function", "deport ui did not load");

local NeverLose = {};

NeverLose.Lib = lib;
NeverLose.ScreenGui = lib.scr;
NeverLose.AccentColor = lib.theme.accent;
NeverLose.MainColor = lib.theme.bg;
local defaultTheme = table.clone(lib.theme);

-- Feature previews read the compatibility colors, not just lib.theme.
local retheme = lib.retheme;
function lib:retheme(map)
	retheme(self, map);
	NeverLose.AccentColor = self.theme.accent;
	NeverLose.MainColor = self.theme.bg;
end;

-- The old default was a neutral grey palette with a white accent. A config
-- saved under it would repaint the new black-blue menu grey on load, so a
-- palette that still matches that signature is replaced by the new default.
local function legacyTheme(theme)
	local accent, bg = theme.accent, theme.bg;

	if type(accent) ~= "string" or type(bg) ~= "string" then return false end;

	local ok, a, b = pcall(function() return Color3.fromHex(accent), Color3.fromHex(bg) end);

	if not ok or not a or not b then return false end;

	local neutral = math.abs(a.R - a.G) < 0.03 and math.abs(a.G - a.B) < 0.03;

	return neutral and a.R > 0.9 and b.R < 0.1
		and math.abs(b.R - b.G) < 0.02 and math.abs(b.G - b.B) < 0.02;
end;

-- Older configs saved a theme without palette flags. Keep the colour cards in
-- sync so a later save cannot replace it with defaults.
local applyConfig = lib.apply;
function lib:apply(data)
	if type(data) ~= "table" or type(data.flags) ~= "table" or type(data.theme) ~= "table" then
		return applyConfig(self, data);
	end;

	local source = data;

	if legacyTheme(data.theme) then
		source = table.clone(data);
		source.flags = table.clone(data.flags);
		source.theme = {};

		for key, color in pairs(defaultTheme) do
			local hex = color:ToHex();

			source.theme[key] = hex;

			local flag = "theme|" .. key;

			if self.pool[flag] then source.flags[flag] = hex end;
		end;
	end;

	local patched;

	for key, color in pairs(source.theme) do
		local flag = "theme|" .. key;
		if self.pool[flag] and source.flags[flag] == nil then
			if not patched then
				patched = table.clone(source);
				patched.flags = table.clone(source.flags);
			end;
			patched.flags[flag] = color;
		end;
	end;

	return applyConfig(self, patched or source);
end;

NeverLose.GlobalLogo = lib.logo;
NeverLose.EnabledBlur = false;
NeverLose.UnloadEnabled = false;
NeverLose.GlobalSignals = {};
NeverLose.Flags = {};
NeverLose.OnToggleChanged = function() end;
NeverLose.BuiltInRegular = Font.fromEnum(Enum.Font.GothamMedium);
NeverLose.BuiltInBold = Font.fromEnum(Enum.Font.GothamBold);
NeverLose.Mobile = lib.mobile and true or false;
NeverLose.IsMobile = NeverLose.Mobile;
NeverLose.Brand = "Deport";

-- A phone gets one full-width column instead of two half-width ones.
local function laneFor(position)
	if position == "full" or NeverLose.Mobile then return "full" end;

	return (position == "right") and "right" or "left";
end;

-- ----------------------------------------------------------------- bits ----
function NeverLose.RandomString()
	local out = {};

	for _ = 1, 12 do out[#out + 1] = string.char(math.random(1, 7)) end;

	return table.concat(out);
end;

function NeverLose:AddSignal(signal)
	if not lib.alive then signal:Disconnect(); return signal end;
	if #NeverLose.GlobalSignals > 128 then
		for i = #NeverLose.GlobalSignals, 1, -1 do
			if not NeverLose.GlobalSignals[i].Connected then table.remove(NeverLose.GlobalSignals, i) end
		end
	end
	table.insert(NeverLose.GlobalSignals, signal);

	return signal;
end;

local playerSignals = {};
function NeverLose:AddPlayerSignal(player, signal)
	playerSignals[player] = playerSignals[player] or {};
	table.insert(playerSignals[player], signal);
	return self:AddSignal(signal);
end;
NeverLose:AddSignal(game:GetService("Players").PlayerRemoving:Connect(function(player)
	for _, connection in ipairs(playerSignals[player] or {}) do connection:Disconnect() end;
	playerSignals[player] = nil;
end));

function NeverLose:CreateNotification()
	return {
		new = function(c)
			c = c or {};

			lib:notify({
				title = c.Title or NeverLose.Brand,
				text = c.Content or "",
				icon = NeverLose.IconName(c.Icon or "info"),
				life = c.Duration or 5,
			});
		end,
	};
end;

function NeverLose:CreateLogger()
	return {
		new = function(ic, txt, dur, col)
			lib:notify({
				title = tostring(txt or ""),
				icon = NeverLose.IconName(ic or "file-text"),
				life = dur or 4,
				tone = (typeof(col) == "Color3") and col or nil,
			});
		end,
	};
end;

-- This script inherited the BuilderIcons vocabulary; the library ships a
-- Lucide set under different names.
local ICON_ALIAS = {
	["arrow-down"] = "chevron-down",
	["arrow-left"] = "chevron-right",
	["arrow-right"] = "chevron-right",
	["arrow-right-from-portrait-rectangle"] = "log-out",
	["arrow-rotate-right"] = "refresh-cw",
	["arrow-spin-clockwise"] = "refresh-cw",
	["arrow-up"] = "chevron-up",
	["bookmark"] = "book",
	["chart-four-vertical-bars"] = "activity",
	["chart-line"] = "activity",
	["chevron-large-left"] = "chevron-right",
	["chevron-large-right"] = "chevron-right",
	["chevron-small-down"] = "chevron-down",
	["chevron-small-left"] = "chevron-right",
	["chevron-small-right"] = "chevron-right",
	["chevron-small-up"] = "chevron-up",
	["circle"] = "circle-dot",
	["circle-check"] = "check",
	["circle-play"] = "circle-dot",
	["circle-x"] = "x",
	["crosshairs"] = "crosshair",
	["cube-vertexes"] = "box",
	["eye-slash"] = "eye-off",
	["file-box"] = "file-text",
	["flag"] = "map-pin",
	["floppy-disk"] = "save",
	["frame-corners"] = "monitor",
	["gear"] = "settings",
	["globe-detailed"] = "globe",
	["globe-simplified"] = "globe",
	["hammer-code"] = "wrench",
	["list-bulleted"] = "list",
	["magnifying-glass"] = "search",
	["music"] = "music-2",
	["music-note"] = "music-2",
	["paint-brush"] = "palette",
	["pause-large"] = "x",
	["pause-small"] = "x",
	["person"] = "user",
	["person-play"] = "hand",
	["person-running"] = "person-standing",
	["play-large"] = "zap",
	["play-small"] = "zap",
	["plus-large"] = "plus",
	["signal-exclamation"] = "wifi",
	["square"] = "x",
	["square-check"] = "check",
	["stop-large"] = "x",
	["stop-small"] = "x",
	["three-dots-horizontal"] = "ellipsis",
	["three-sliders-horizontal"] = "sliders-horizontal",
	["trash-can"] = "trash-2",
};

function NeverLose.IconName(name)
	local key = string.lower(tostring(name or "")):gsub("%-bold$", "");

	if lib.icons[key] then return key end;

	local alias = ICON_ALIAS[key];

	if alias and lib.icons[alias] then return alias end;

	return key;
end;

function NeverLose.ApplyIcon(label, name)
	if typeof(label) ~= "Instance" then return end;

	local id = lib.icons[NeverLose.IconName(name)];

	label.Text = "";

	if not id then return end;

	local image = label:FindFirstChild("Icon");

	if not image then
		image = Instance.new("ImageLabel");
		image.Name = "Icon";
		image.BackgroundTransparency = 1;
		image.AnchorPoint = Vector2.new(0.5, 0.5);
		image.Position = UDim2.fromScale(0.5, 0.5);
		image.Size = UDim2.fromScale(0.85, 0.85);
		image.ScaleType = Enum.ScaleType.Fit;
		image.Parent = label;
	end;

	image.Image = "rbxassetid://" .. id;
	image.ImageColor3 = label.TextColor3;
	image.ZIndex = label.ZIndex;
end;

function NeverLose.SetWatermark(on)
	pcall(function() lib:setwatermark(on and true or false) end);
end;

function NeverLose.SetWatermarkText(text)
	return pcall(function() lib:setwatermarktext(text) end);
end;

function NeverLose.SetKeybindList(on)
	pcall(function() lib:sethotkeys(on and true or false) end);
end;

function NeverLose:Unload()
	for _, connections in pairs(playerSignals) do for _, connection in ipairs(connections) do connection:Disconnect() end end;
	table.clear(playerSignals);
	for _, signal in ipairs(NeverLose.GlobalSignals) do
		pcall(function() signal:Disconnect() end);
	end;

	table.clear(NeverLose.GlobalSignals);

	pcall(function() lib:unload() end);
end;

-- --------------------------------------------------------------- widgets ----
-- NeverLose widgets carry cosmetic methods - SetRender, Generate, Refuse and
-- so on - with no counterpart here. Anything unknown resolves to a no-op.
local function tolerant(object)
	return setmetatable(object, {
		__index = function(_, key)
			if type(key) ~= "string" then return nil end;

			return function() end;
		end,
	});
end;

local function register(flag, item)
	if type(flag) ~= "string" or flag == "" then return item end;

	NeverLose.Flags[flag] = item;

	return item;
end;

-- NeverLose rounds with a digit count; the library steps by an increment.
local function stepOf(cfg)
	local digits = tonumber(cfg.Rounding or cfg.Round) or 0;

	return (digits > 0) and (1 / (10 ^ digits)) or 1;
end;

-- NeverLose had a global hook that fired whenever a control changed, and the
-- menu sound presets listen to it. Every widget reports through here; a
-- change made from code rather than by hand is marked quiet.
local silent = false;

local function report(flag, hook)
	return function(value, ...)
		if hook then hook(value, ...) end;

		local notify = NeverLose.OnToggleChanged;

		if notify then
			pcall(notify, value, flag, not silent and not lib.quiet);
		end;
	end;
end;

local function quietly(fn, ...)
	local was = silent;

	silent = true;

	local ok, err = pcall(fn, ...);

	silent = was;

	if not ok then error(err, 3) end;
end;

local function wrapValue(element, flag, extra)
	local item = { __el = element };

	function item:GetValue() return element:get() end;
	function item:SetValue(v) quietly(element.set, element, v) end;
	function item:Set(v) quietly(element.set, element, v) end;
	function item:SetVisible(state)
		local row = type(element) == "table" and rawget(element, "row");

		if typeof(row) == "Instance" then row.Visible = state and true or false end;
	end;

	if extra then extra(item, element) end;

	return register(flag, tolerant(item));
end;

-- A row is what AddLabel returns: it remembers the caption, and whichever
-- control is hung off it is created with that caption as its name. NeverLose
-- hangs several controls off one label - a toggle and its colour, a colour
-- and its opacity - so the first control takes the caption and the row, and
-- the ones after it go into the toggle's own fold-out panel.
local function makeRow(section, caption)
	-- while the features load, main.lua hands in a breather
	if NeverLose.Breathe then NeverLose.Breathe() end;

	local row = { Name = caption, __section = section };
	local first = true;

	local function placeFor(kind)
		if first then
			first = false;

			return section.__sec, caption;
		end;

		local toggle = rawget(row, "__toggle");
		local panel = toggle and toggle.options;

		if panel then
			panel.reveal();

			return panel, kind;
		end;

		return section.__sec, caption;
	end;

	row.RevealOptions = function()
		local toggle = rawget(row, "__toggle");

		if toggle and toggle.options then toggle.options.reveal() end;
	end;

	function row:AddToggle(cfg)
		cfg = cfg or {};

		local target, name = placeFor("Enabled");

		local element = target:toggle({
			name = name,
			default = cfg.Default and true or false,
			options = true,
			flag = cfg.Flag,
			callback = report(cfg.Flag, cfg.Callback),
		});

		row.__toggle = element;

		return wrapValue(element, cfg.Flag);
	end;

	function row:AddSlider(cfg)
		cfg = cfg or {};

		local target, name = placeFor("Amount");

		return wrapValue(target:slider({
			name = name,
			min = tonumber(cfg.Min) or 0,
			max = tonumber(cfg.Max) or 100,
			default = cfg.Default,
			step = stepOf(cfg),
			suffix = (type(cfg.Type) == "string") and cfg.Type or "",
			flag = cfg.Flag,
			callback = report(cfg.Flag, cfg.Callback),
		}), cfg.Flag);
	end;

	function row:AddDropdown(cfg)
		cfg = cfg or {};

		local target, name = placeFor("Mode");

		local element = target:combo({
			name = cfg.FullWidth and "" or name,
			list = cfg.Values or {},
			default = cfg.Default,
			multi = cfg.Multi and true or false,
			flag = cfg.Flag,
			callback = report(cfg.Flag, cfg.Callback),
		});

		return wrapValue(element, cfg.Flag, function(item)
			function item:SetValues(list)
				if element.setlist then element:setlist(list) end;
			end;
		end);
	end;

	function row:AddColorPicker(cfg)
		cfg = cfg or {};

		local hook = cfg.Callback;
		local target, name = placeFor("Color");

		return wrapValue(target:color({
			name = cfg.Name or name,
			default = cfg.Default,
			flag = cfg.Flag,
			callback = report(cfg.Flag, hook and function(colour) hook(colour, cfg.Transparency) end or nil),
		}), cfg.Flag);
	end;

	function row:AddKeybind(cfg)
		cfg = cfg or {};

		local target, name = placeFor("Key");

		return wrapValue(target:keybind({
			name = name,
			default = cfg.Default,
			flag = cfg.Flag,
			callback = report(cfg.Flag, cfg.Callback),
		}), cfg.Flag);
	end;

	function row:AddTextInput(cfg)
		cfg = cfg or {};

		local target = placeFor("Text");

		local element = target:input({
			name = caption,
			placeholder = cfg.Placeholder or caption,
			default = cfg.Default or "",
			flag = cfg.Flag,
			callback = cfg.Callback,
		});

		local item = { __el = element };

		function item:GetValue() return element:get() end;

		function item:SetValue(v) element:set(v) end;

		return register(cfg.Flag, tolerant(item));
	end;

	-- NeverLose hangs extra controls off a gear on the row; here that is the
	-- toggle's own fold-out panel.
	function row:AddOption()
		local toggle = rawget(row, "__toggle");
		local panel = toggle and toggle.options;

		if not panel then return section end;

		panel.reveal();

		local nested = { __sec = panel, __parentSection = section };

		function nested:AddLabel(name) return makeRow(nested, name) end;

		function nested:AddButton(cfg)
			cfg = cfg or {};

			panel:button({
				name = cfg.Name or "Button",
				icon = cfg.Icon and NeverLose.IconName(cfg.Icon) or nil,
				callback = cfg.Callback,
			});

			return {};
		end;

		return tolerant(nested);
	end;

	function row:SetText(value)
		if row.__label and row.__label.set then row.__label:set(value) end;
	end;

	return tolerant(row);
end;

local function wrapSection(sec)
	local section = { __sec = sec, Root = sec.items, Items = sec.items };

	function section:SetVisible(state)
		if sec.setvisible then sec:setvisible(state) end;
	end;

	function section:AddLabel(name, isStatus)
		local caption = tostring(name or "");

		-- a status label is a real label element; a naming label is just a
		-- caption waiting for the control that follows it
		if isStatus then
			local element = sec:label({ name = caption, wrap = true });
			local row = makeRow(section, caption);

			row.__label = element;

			function row:SetText(value)
				if element.set then element:set(value) end;
			end;

			return row;
		end;

		return makeRow(section, caption);
	end;

	function section:AddButton(cfg)
		cfg = cfg or {};

		return tolerant({ __el = sec:button({
			name = cfg.Name or "Button",
			icon = cfg.Icon and NeverLose.IconName(cfg.Icon) or nil,
			callback = cfg.Callback,
		}) });
	end;

	return tolerant(section);
end;

-- The virtualised grids need to know when their page goes off screen. The
-- library calls node.hit(selected) when the selection changes, so the
-- existing handler is chained rather than replaced.
local function pageSignal(node)
	local bindable = Instance.new("BindableEvent");
	bindable.Parent = NeverLose.ScreenGui;
	local value = false;
	local previous = node.hit;

	node.hit = function(selected)
		value = selected and true or false;

		if previous then previous(selected) end;

		bindable:Fire(value);
	end;

	return {
		GetValue = function() return value end,
		SetValue = function(_, v) value = v; bindable:Fire(v) end,
		Connect = function(_, fn) return NeverLose:AddSignal(bindable.Event:Connect(fn)) end,
	};
end;

-- On a phone the desktop size is both too wide to fit and too tall to reach
-- past, so the window is measured from the viewport instead.
local function windowSize(fallback)
	if not NeverLose.Mobile then return fallback end;

	local camera = workspace.CurrentCamera;
	local view = (camera and camera.ViewportSize) or Vector2.new(640, 480);

	pcall(function()
		local fake = getgenv().VISUALS_FAKE_VIEWPORT;
		if typeof(fake) == "Vector2" then view = fake end;
	end);

	local scale = lib.scale;

	if type(scale) ~= "number" or scale <= 0 then scale = 1 end;

	local inset = game:GetService("GuiService"):GetGuiInset().Y;
	local roomX, roomY = math.max(view.X - 16, 160), math.max(view.Y - inset - 30, 120);
	local wide = math.clamp(math.floor(view.X * 0.92), math.min(320, roomX), math.min(560, roomX));
	local tall = math.clamp(roomY, math.min(260, roomY), 620);

	return UDim2.fromOffset(math.floor(wide / scale), math.floor(tall / scale));
end;

-- ---------------------------------------------------------------- window ----
function NeverLose:CreateWindow(cfg)
	cfg = cfg or {};

	local win = lib:window({
		size = windowSize(cfg.Size or UDim2.fromOffset(860, 600)),
		bind = cfg.Keybind or "Delete",
		title = cfg.Title or NeverLose.Brand,
		build = cfg.Build or "",
	});

	NeverLose.WindowFrame = win.shell;
	NeverLose.WindowRoot = win.root;

	if NeverLose.Mobile then
		local GuiService = game:GetService("GuiService");

		local function fit()
			local inset = GuiService:GetGuiInset().Y;

			pcall(function()
				win:setsize(windowSize(win.size or UDim2.fromOffset(860, 600)));
				win.shell.Position = UDim2.new(0.5, 0, 0.5, math.floor(inset / 2));
			end);
		end;

		fit();

		local camera = workspace.CurrentCamera;

		if camera then
			NeverLose:AddSignal(camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit));
		end;
	end;

	local Window = {
		__win = win,
		Frame = win.shell,
		Tabs = {},
		CurrentTab = 1,
		Keybind = cfg.Keybind or "Delete",
	};

	-- main.lua watches this to know whether the menu is on screen
	local signalValue = true;
	local bindable = Instance.new("BindableEvent");
	bindable.Parent = NeverLose.ScreenGui;

	Window.Signal = {
		GetValue = function() return signalValue end,
		SetValue = function(_, v) signalValue = v; bindable:Fire(v) end,
		Connect = function(_, fn) return NeverLose:AddSignal(bindable.Event:Connect(fn)) end,
	};

	function Window:ToggleInterface()
		win:render(not win.open);
	end;

	-- all open/close routes call render; notify once when its state changes
	local render = win.render;
	function win:render(value)
		render(self, value);

		local open = self.open and true or false;

		if open ~= signalValue then
			signalValue = open;
			bindable:Fire(open);
		end;
	end;

	function Window:SetSize(size)
		if typeof(size) ~= "UDim2" or NeverLose.Mobile then return end;

		pcall(function() win:setsize(size) end);
	end;

	function Window:SetKeybind(value)
		if value == nil then return end;

		Window.Keybind = value;

		pcall(function() win:setbind(value) end);
	end;

	-- Settings is a tab like any other, with its own pages.
	local settingsTab, settingsPages, settingsSection = nil, {}, nil;

	local function settingsPage(name, iconName)
		if not settingsTab then
			settingsTab = win:tab({ name = "Settings", icon = "settings" });
			settingsTab.head.LayoutOrder = 100001;
		end;

		if not settingsPages[name] then
			settingsPages[name] = settingsTab:sub({ name = name, icon = iconName });
		end;

		return settingsPages[name];
	end;

	-- Whole palettes. Every one keeps the same ladder as the default - the
	-- background darkest, then panel, sidebar, header, a mid outline, a muted
	-- and a bright text - so nothing loses contrast.
	local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end;
	local function palette(bg, side, panel, head, line, glow, text, dim, accent)
		return { bg = bg, side = side, panel = panel, head = head, line = line,
			glow = glow, text = text, dim = dim, accent = accent };
	end;
	local THEMES = {
		Default = defaultTheme,
		Midnight = palette(rgb(6, 8, 14), rgb(11, 14, 23), rgb(10, 13, 21), rgb(15, 19, 30), rgb(44, 54, 82),
			rgb(130, 160, 230), rgb(232, 238, 255), rgb(112, 124, 156), rgb(96, 156, 255)),
		Ocean = palette(rgb(4, 9, 12), rgb(8, 16, 21), rgb(7, 14, 19), rgb(11, 21, 27), rgb(36, 66, 82),
			rgb(120, 210, 240), rgb(232, 248, 255), rgb(104, 136, 150), rgb(56, 200, 240)),
		Mint = palette(rgb(5, 10, 9), rgb(10, 17, 16), rgb(9, 15, 14), rgb(13, 22, 20), rgb(42, 70, 64),
			rgb(140, 230, 200), rgb(234, 252, 247), rgb(108, 142, 134), rgb(94, 234, 186)),
		Forest = palette(rgb(6, 9, 5), rgb(11, 16, 10), rgb(10, 14, 9), rgb(15, 21, 13), rgb(50, 70, 44),
			rgb(170, 230, 140), rgb(242, 252, 236), rgb(122, 142, 112), rgb(150, 230, 90)),
		Gold = palette(rgb(8, 7, 5), rgb(15, 13, 9), rgb(13, 11, 8), rgb(20, 17, 12), rgb(70, 62, 44),
			rgb(230, 210, 150), rgb(255, 250, 238), rgb(144, 134, 112), rgb(232, 196, 96)),
		Amber = palette(rgb(10, 8, 5), rgb(18, 14, 9), rgb(16, 12, 8), rgb(23, 18, 11), rgb(78, 62, 40),
			rgb(240, 190, 120), rgb(255, 246, 232), rgb(150, 132, 108), rgb(255, 176, 64)),
		Crimson = palette(rgb(9, 5, 5), rgb(16, 9, 9), rgb(14, 8, 8), rgb(21, 12, 12), rgb(74, 40, 40),
			rgb(240, 130, 130), rgb(255, 238, 238), rgb(150, 110, 110), rgb(240, 62, 72)),
		Rose = palette(rgb(10, 6, 9), rgb(17, 11, 15), rgb(15, 10, 14), rgb(22, 14, 19), rgb(74, 46, 62),
			rgb(230, 150, 190), rgb(255, 236, 244), rgb(150, 112, 130), rgb(255, 120, 170)),
		Sakura = palette(rgb(12, 9, 11), rgb(20, 15, 18), rgb(18, 13, 16), rgb(26, 19, 23), rgb(84, 62, 74),
			rgb(255, 196, 220), rgb(255, 242, 247), rgb(164, 132, 146), rgb(255, 176, 206)),
		Violet = palette(rgb(8, 6, 13), rgb(15, 11, 22), rgb(13, 10, 20), rgb(20, 15, 29), rgb(62, 48, 92),
			rgb(190, 160, 255), rgb(244, 238, 255), rgb(132, 118, 160), rgb(168, 124, 255)),
	};
	local THEME_ORDER = { "Default", "Midnight", "Ocean", "Mint", "Forest", "Gold", "Amber", "Crimson", "Rose", "Sakura", "Violet" };

	local colorsTab;

	function Window:ApplyMenuTheme(name)
		local theme = THEMES[name];

		if not theme then return end;

		lib:retheme(theme);

		-- the cards follow quietly; the theme already holds their colours
		local quiet = lib.quiet;

		lib.quiet = true;

		for key, color in pairs(theme) do
			local entry = lib.pool["theme|" .. key];

			if entry and entry.set then pcall(entry.set, color) end;
		end;

		lib.quiet = quiet;
	end;

	function Window:ResetMenuColors()
		Window:ApplyMenuTheme("Default");
	end;

	function Window:AddColorsTab()
		if colorsTab then return colorsTab end;

		colorsTab = settingsPage("Colors", "palette");

		local presets = wrapSection(colorsTab:section({ name = "Presets", side = laneFor("left") }));

		presets:AddLabel("Palette"):AddDropdown({
			Default = "Default",
			Values = THEME_ORDER,
			Flag = "menu_theme",
			Callback = function(v) Window:ApplyMenuTheme(v) end,
		});

		presets:AddLabel("Font"):AddDropdown({
			Default = "Default",
			Values = lib:fontnames(),
			Flag = "menu_font",
			Callback = function(v) lib:setfont(v) end,
		});

		presets:AddButton({ Name = "Reset Colors", Icon = "refresh-cw", Callback = function() Window:ResetMenuColors() end });

		for _, color in ipairs({
			{ "Accent", "accent" }, { "Text", "text" }, { "Panel", "panel" }, { "Header", "head" },
			{ "Sidebar", "side" }, { "Outline", "line" }, { "Muted", "dim" }, { "Glow", "glow" },
			{ "Background", "bg" },
		}) do
			colorsTab:color({ name = color[1], key = color[2], side = laneFor("right") });
		end;

		return colorsTab;
	end;

	-- Saved profiles in the config folder, plus a copy/paste pair for passing
	-- one around as text.
	local configCard;

	function Window:AddConfigCard()
		if configCard then return configCard end;

		local tab = settingsPage("Configs", "folder");

		tab:configs({ name = "Configs", side = laneFor("left") });

		local card = wrapSection(tab:section({ name = "Share", side = laneFor("right") }));

		local function toast(text, failed)
			lib:notify({ title = text, icon = failed and "x" or "check", life = 3 });
		end;

		local field;

		card:AddButton({
			Name = "Share Code",
			Icon = "link",
			Callback = function()
				if type(NeverLose.ShareConfigCode) ~= "function" then
					toast("Not ready", true);

					return;
				end;

				local ok, code = NeverLose.ShareConfigCode();

				if not ok then
					toast(tostring(code), true);

					return;
				end;

				local copied = type(setclipboard) == "function" and pcall(setclipboard, code);

				if field then field:SetValue(code) end;

				toast(copied and "Code copied" or code);
			end,
		});

		card:AddButton({
			Name = "Copy Config Text",
			Icon = "copy",
			Callback = function()
				local ok, size = lib:clipboardExport();

				toast(ok and "Config copied" or tostring(size), not ok);
			end,
		});

		field = card:AddLabel("Code"):AddTextInput({ Placeholder = "Salad_ code or config text" });

		card:AddButton({
			Name = "Load",
			Icon = "clipboard-paste",
			Callback = function()
				local text = string.match(field:GetValue() or "", "^%s*(.-)%s*$") or "";
				local ok, reason;

				if string.match(text, "^Salad_%d+$") then
					if type(NeverLose.LoadConfigCode) ~= "function" then
						toast("Not ready", true);

						return;
					end;

					local who;

					ok, who = NeverLose.LoadConfigCode(text);

					if ok then
						field:SetValue("");
						toast("Config loaded");
					else
						toast(tostring(who), true);
					end;

					return;
				end;

				if text ~= "" then
					local data = lib:thaw(text);

					if data then
						ok = lib:apply(data) == true;
						reason = lib.configResult and lib.configResult.errors and lib.configResult.errors[1];
					else
						ok, reason = false, "That is not a config";
					end;

					if ok then field:SetValue("") end;
				else
					ok, reason = lib:clipboardLoad();
				end;

				toast(ok and "Config loaded" or tostring(reason or "Paste a config into the box first"), not ok);
			end,
		});

		configCard = { refresh = function() end };

		return configCard;
	end;

	function Window:AddSettingsSection(name, side)
		return wrapSection(settingsPage("Menu", "sliders-horizontal"):section({
			name = name or "section",
			side = laneFor(side),
		}));
	end;

	Window.UserSettings = setmetatable({}, {
		__index = function(_, key)
			if not settingsSection then
				settingsSection = wrapSection(settingsPage("Menu", "sliders-horizontal"):section({
					name = "Menu",
					side = laneFor("left"),
				}));
			end;

			local value = settingsSection[key];

			if type(value) ~= "function" then return value end;

			return function(_, ...) return value(settingsSection, ...) end;
		end,
	});

	-- The watermark on a phone is also the way back into the menu: there is
	-- no Delete key there. On a desktop it is just a watermark.
	do
		pcall(function() lib:setopener(NeverLose.Mobile) end);

		local watermarkOn = true;

		function NeverLose.SetWatermark(on)
			watermarkOn = on and true or false;

			pcall(function() lib:setwatermark(watermarkOn) end);
			pcall(function() lib:setopener(NeverLose.Mobile and not watermarkOn) end);
		end;
	end;

	-- A NeverLose tab becomes an entry in the bottom bar; the collapsing
	-- groups this script builds by hand are what tab:sub is for.
	function Window:AddTab(config)
		config = config or {};

		local tab = win:tab({ name = config.Name or "Tab", icon = NeverLose.IconName(config.Icon) });

		if config.Last then tab.head.LayoutOrder = 100000 end;

		local Tab = { __tab = tab, Name = config.Name, Signal = pageSignal(tab) };

		function Tab:AddSection(sectionConfig)
			sectionConfig = sectionConfig or {};

			return wrapSection(tab:section({
				name = sectionConfig.Name or "section",
				side = laneFor(sectionConfig.Position),
			}));
		end;

		function Tab.SetValue(value)
			if value and tab.select then tab.select() end;
		end;

		table.insert(Window.Tabs, Tab);

		return tolerant(Tab);
	end;

	function Window:AddGroup(name, iconName, entries)
		local tab = win:tab({ name = name, icon = NeverLose.IconName(iconName) });
		local group = { __tab = tab };

		for _, entry in ipairs(entries or {}) do
			local sub = tab:sub({ name = entry.Name, icon = NeverLose.IconName(entry.Icon) });
			local page = { __sub = sub, Name = entry.Name, Signal = pageSignal(sub) };

			function page:AddSection(sectionConfig)
				sectionConfig = sectionConfig or {};

				return wrapSection(sub:section({
					name = sectionConfig.Name or "section",
					side = laneFor(sectionConfig.Position),
				}));
			end;

			function page.SetValue(value)
				if value and sub.select then sub.select() end;
			end;

			-- The library ships a picture grid with search, thumbnails, a
			-- context menu and a toolbar; both hand-rolled grids go through it.
			function page:AddGallery(gcfg)
				gcfg = gcfg or {};

				-- the grid is as tall as its column leaves it: the card adds
				-- its header, search and padding, and the tool row
				local chrome = 104 + ((gcfg.Tools == true or type(gcfg.Buttons) == "table" or gcfg.Multi) and 36 or 0)
					- (gcfg.Search == false and 32 or 0);
				local tall = typeof(win.size) == "UDim2" and win.size.Y.Offset or 600;
				local height = math.max(110, math.min(gcfg.Height or 260, tall - 190 - chrome));

				return sub:gallery({
					name = gcfg.Name or "gallery",
					icon = gcfg.Icon and NeverLose.IconName(gcfg.Icon) or "image",
					side = laneFor(gcfg.Position),
					height = height,
					list = gcfg.Values or {},
					default = gcfg.Default,
					multi = gcfg.Multi and true or false,
					reset = gcfg.Reset == true,
					thumb = gcfg.Thumb or "Asset",
					blank = gcfg.Blank and NeverLose.IconName(gcfg.Blank) or "image",
					cell = gcfg.Cell or 76,
					search = gcfg.Search ~= false,
					tools = gcfg.Tools == true,
					buttons = gcfg.Buttons,
					action = type(gcfg.Action) == "table" and {
						icon = NeverLose.IconName(gcfg.Action.Icon or gcfg.Action.icon or "ellipsis"),
						callback = gcfg.Action.Callback or gcfg.Action.callback,
					} or nil,
					context = gcfg.Context,
					empty = gcfg.Empty or "nothing here",
					flag = gcfg.Flag,
					callback = report(gcfg.Flag, gcfg.Callback),
				});
			end;

			group[entry.Name] = tolerant(page);

			table.insert(Window.Tabs, group[entry.Name]);
		end;

		function group.Select()
			if tab.select then tab.select() end;
		end;

		function group.Toggle() return true end;

		function group.IsOpen() return true end;

		return group;
	end;

	return tolerant(Window);
end;

return NeverLose;
