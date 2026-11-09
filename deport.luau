local ASSETS = ...;



local next, pairs, ipairs = next, pairs, ipairs

cloneref = cloneref or function(o) return o end
gethui = gethui or get_hidden_gui
getcustomasset = getcustomasset or getsynasset
getgenv = getgenv or getfenv

-- Some mobile executors expose gethui/protect_gui but throw when the hidden
-- container is not ready. Keep that from aborting the whole UI bootstrap.
do
	local rawHui = gethui or get_hidden_gui
	local function safeHui()
		if type(rawHui) == "function" then
			local ok, result = pcall(rawHui)
			if ok and typeof(result) == "Instance" then return result end
		end
	end

	gethui = safeHui
	get_hidden_gui = safeHui
end

local tws = cloneref(game:GetService("TweenService"))
local txs = cloneref(game:GetService("TextService"))
local uis = cloneref(game:GetService("UserInputService"))
local rs = cloneref(game:GetService("RunService"))
local plrs = cloneref(game:GetService("Players"))
local gus = cloneref(game:GetService("GuiService"))
local lp = plrs.LocalPlayer
local mouse = lp:GetMouse()
local clipput = setclipboard or toclipboard or (clipboard and clipboard.set)
local clipget = getclipboard or readclipboard or (clipboard and clipboard.get)
local hui = gethui and gethui()

if not hui then
	local ok, core = pcall(function() return cloneref(game:GetService("CoreGui")) end)
	hui = ok and core or nil
end

hui = hui or lp:WaitForChild("PlayerGui")
local prot = protect_gui or protectgui or (syn and syn.protect_gui) or function(g) return g end

local visualsui = {}

visualsui.ver = "deport-1"
visualsui.wins = {}
visualsui.conns = {}

local drawmask = getgenv().visuals_drawmask

if type(drawmask) ~= "table" then
	drawmask = {}
	getgenv().visuals_drawmask = drawmask
end

visualsui.drawmask = drawmask

local function maskadd(f)
	for i = #drawmask, 1, -1 do
		local e = drawmask[i]

		if e == f or typeof(e) ~= "Instance" or not e.Parent then
			table.remove(drawmask, i)
		end
	end

	drawmask[#drawmask + 1] = f
end

-- Detect the device at load time. There is intentionally no persisted/manual
-- layout override: Delta can expose a stale layout file or a virtual input
-- device and make a desktop stick in the phone UI on later injects.
visualsui.layout = "auto"

local touch = uis.TouchEnabled
local keyboard = uis.KeyboardEnabled
local mouseEnabled = uis.MouseEnabled

local camera = workspace.CurrentCamera
local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
local preferredTouch = false
pcall(function() preferredTouch = uis.PreferredInput == Enum.PreferredInput.Touch end)
-- getgenv().VISUALS_FORCE_MOBILE is for looking at the phone layout on a PC;
-- it lives only in this session, so nothing can get stuck on it
local forced = false
pcall(function() forced = getgenv().VISUALS_FORCE_MOBILE == true end)
visualsui.mobile = forced or (touch and (preferredTouch or not mouseEnabled or math.min(viewport.X, viewport.Y) < 700))
visualsui.scale = visualsui.mobile and 0.85 or 1

local sc = visualsui.scale

-- Black-blue, not black-white. The menu sits on a deep navy rather than a
-- neutral gray so the blue accent reads as part of the surface instead of a
-- sticker on top of it.
visualsui.theme = {
	bg = Color3.fromRGB(6, 9, 16),
	side = Color3.fromRGB(10, 15, 26),
	panel = Color3.fromRGB(14, 21, 35),
	head = Color3.fromRGB(24, 35, 55),
	line = Color3.fromRGB(44, 62, 92),
	glow = Color3.fromRGB(96, 132, 196),
	text = Color3.fromRGB(236, 243, 255),
	dim = Color3.fromRGB(138, 154, 182),
	accent = Color3.fromRGB(74, 144, 255),
}

visualsui.sheet = {
	bg = Color3.fromRGB(14, 21, 35),
	row = Color3.fromRGB(24, 35, 55),
	press = Color3.fromRGB(36, 52, 80),
	sep = Color3.fromRGB(44, 62, 92),
	grab = Color3.fromRGB(96, 132, 196),
	blue = Color3.fromRGB(74, 144, 255),
}

visualsui.icons = {
	activity = 137527339160230,
	banknote = 113703117675594,
	bell = 84691420588185,
	book = 74111869099427,
	bot = 70979486241131,
	box = 117371753006597,
	boxes = 95055252135506,
	brain = 116902501990569,
	bug = 75649814233484,
	car = 91451724283877,
	["car-front"] = 79993076477613,
	check = 86817768619372,
	["chevron-down"] = 71457658246709,
	["chevron-right"] = 101007429951147,
	["chevron-up"] = 98648581502859,
	["circle-dot"] = 122878673716704,
	["clipboard-paste"] = 79192963603923,
	clock = 136533241128438,
	code = 75851496262862,
	copy = 116378866141355,
	pipette = 104047428948587,
	cog = 123222732420633,
	coins = 117341212186115,
	compass = 73836660434977,
	crosshair = 83752373575368,
	crown = 92253403464658,
	database = 99154172590159,
	dices = 116678154854810,
	ellipsis = 101330725759187,
	eye = 127234874352422,
	["eye-off"] = 85207295981701,
	["file-text"] = 92774566080911,
	fish = 114555142566431,
	flame = 125012650497883,
	folder = 77937190465422,
	footprints = 80792036653047,
	["gamepad-2"] = 99293705721130,
	gauge = 128279962545721,
	ghost = 132705178126217,
	globe = 125685532120024,
	hand = 83088528355903,
	heart = 88525382655929,
	home = 109841253338329,
	image = 114022611279795,
	info = 120620848266512,
	key = 83474888140571,
	keyboard = 121978468376124,
	layers = 114499998778667,
	link = 86131768436965,
	list = 101699539545687,
	lock = 119765975153029,
	["log-out"] = 140299936053191,
	map = 131325044235094,
	["map-pin"] = 137091405832737,
	["message-circle"] = 132757019038262,
	minus = 95070996149109,
	["music-2"] = 114903694643130,
	shapes = 123396423017215,
	monitor = 70520152532392,
	move = 77028714324861,
	["mouse-pointer"] = 113428527051320,
	package = 106101842173393,
	palette = 127369887384101,
	["person-standing"] = 101118444346965,
	pickaxe = 111300940329486,
	plus = 101123124881873,
	power = 89331085993646,
	radar = 132868138496209,
	["refresh-cw"] = 106497040962250,
	rocket = 109537053598807,
	save = 122894934359450,
	["scan-eye"] = 109514269737059,
	search = 72296609649861,
	send = 94849431195865,
	settings = 106205298246017,
	["settings-2"] = 109485777305919,
	shield = 106509993556171,
	["shield-check"] = 71867984579031,
	shirt = 128162112866809,
	["shopping-cart"] = 79435149356304,
	skull = 101060850237115,
	["sliders-horizontal"] = 125396339381135,
	sparkles = 105634041692696,
	star = 72669221096319,
	["swatch-book"] = 70990631477660,
	sword = 121406454377051,
	swords = 99199363807265,
	target = 121091323240554,
	terminal = 102379915564176,
	["toggle-right"] = 129483325318573,
	["trash-2"] = 126010725826757,
	user = 114567720540659,
	users = 85332511060401,
	["users-round"] = 103880524805720,
	video = 99411215690870,
	["volume-2"] = 129861259578431,
	["wand-sparkles"] = 115623066336607,
	wifi = 104941258142372,
	wrench = 85345725497834,
	x = 116396312853810,
	zap = 109718589733073,
}

local function icon(v)
	if type(v) == "number" then
		return "rbxassetid://" .. v
	end

	if type(v) ~= "string" or v == "" then
		return ""
	end

	if string.find(v, "://", 1, true) then
		-- Old catalogue rows still carry the web form
		-- (http://www.roblox.com/asset/?id=123); an ImageLabel will not fetch
		-- that, so hand it the content id instead of leaving the cell blank.
		-- rbxthumb/rbxasset schemes are left untouched.
		if string.find(string.lower(v), "roblox.com", 1, true) then
			local id = string.match(v, "asset/?id=(%d+)")
				or string.match(v, "assetId=(%d+)")
				or string.match(v, "[?&]id=(%d+)")

			if id then
				return "rbxassetid://" .. id
			end
		end

		return v
	end

	if string.match(v, "^%d+$") then
		return "rbxassetid://" .. v
	end

	local id = visualsui.icons[string.lower(v)]

	return id and ("rbxassetid://" .. id) or ""
end

local shots = {
	asset = "rbxthumb://type=Asset&id=%d&w=150&h=150",
	bundlethumbnail = "rbxthumb://type=BundleThumbnail&id=%d&w=150&h=150",
	avatarheadshot = "rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150",
	avatar = "rbxthumb://type=Avatar&id=%d&w=352&h=352",
	avatarbust = "rbxthumb://type=AvatarBust&id=%d&w=150&h=150",
	gameicon = "rbxthumb://type=GameIcon&id=%d&w=150&h=150",
	gamepass = "rbxthumb://type=GamePass&id=%d&w=150&h=150",
	badgeicon = "rbxthumb://type=BadgeIcon&id=%d&w=150&h=150",
	outfit = "rbxthumb://type=Outfit&id=%d&w=150&h=150",
	group = "rbxthumb://type=GroupIcon&id=%d&w=150&h=150",
}

local terse = {
	LeftAlt = "LAlt",
	RightAlt = "RAlt",
	LeftShift = "LShift",
	RightShift = "RShift",
	LeftControl = "LCtrl",
	RightControl = "RCtrl",
	LeftSuper = "LWin",
	RightSuper = "RWin",
	LeftMeta = "LMeta",
	RightMeta = "RMeta",
	Backspace = "Bksp",
	CapsLock = "Caps",
	Insert = "Ins",
	Delete = "Del",
	PageUp = "PgUp",
	PageDown = "PgDn",
	Escape = "Esc",
	Return = "Enter",
	PrintScreen = "PrtSc",
	ScrollLock = "ScrLk",
	NumLock = "NumLk",
	Semicolon = ";",
	Comma = ",",
	Period = ".",
	Slash = "/",
	BackSlash = "\\",
	Quote = "'",
	LeftBracket = "[",
	RightBracket = "]",
	Minus = "-",
	Equals = "=",
	Backquote = "`",
	Unknown = "None",
}

local function keyname(k)
	if typeof(k) ~= "EnumItem" then
		return "None"
	end

	local n = k.Name

	if terse[n] then
		return terse[n]
	end

	local pad = string.match(n, "^Keypad(.+)$")

	if pad then
		return "Num" .. pad
	end

	return n
end

local quick = TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local glide = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local soft = TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
-- The motion language: things arrive on a long ease-out, leave on a short
-- ease-in, and a highlight that follows the selection glides on the same
-- curve it arrived on. Nothing overshoots.
local arrive = TweenInfo.new(0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local depart = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local follow = TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)


local function rnd()
	local t = table.create(12)
	for i = 1, 12 do
		t[i] = string.char(math.random(97, 122))
	end
	return table.concat(t)
end

local function new(cls, props, parent)
	local o = Instance.new(cls)
	if cls == "Sound" then o:SetAttribute("VisualsOwned", true) end
	if cls == "ImageButton" or cls == "TextButton" then
		o.AutoButtonColor = false
		o.Selectable = false
	end
	for k, v in next, props do
		o[k] = v
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local function conn(sig, fn)
	if #visualsui.conns > 128 then
		for i = #visualsui.conns, 1, -1 do
			if not visualsui.conns[i].Connected then table.remove(visualsui.conns, i) end
		end
	end
	local c = sig:Connect(fn)
	table.insert(visualsui.conns, c)
	return c
end

local function anim(o, info, props)
	local t = tws:Create(o, info, props)
	t:Play()
	return t
end

local function shrink(o)
	if sc ~= 1 then
		new("UIScale", { Scale = sc }, o)
	end

	return o
end

-- A CanvasGroup draws its children into a texture and then draws that, and
-- text drawn that way loses its edges - soft, uneven letters all over the
-- menu, worst on phones where the texture is smaller than the screen it
-- covers. A group only has to be a group while it fades, so at rest what is
-- on screen moves into a plain twin laid under it. Hidden children (the
-- dropdown popups, over a thousand of them) stay put: moving them made
-- opening the menu hitch, and the group, lifted one layer, keeps them above.
local mirrored = { "AnchorPoint", "Position", "Size", "LayoutOrder" }

local function crisp(group)
	local twin = Instance.new("Frame")
	twin.Name = rnd()
	twin.BorderSizePixel = 0
	twin.ClipsDescendants = group.ClipsDescendants
	twin.ZIndex = group.ZIndex
	twin.Visible = false

	for _, key in next, mirrored do
		twin[key] = group[key]
	end

	for _, d in next, group:GetChildren() do
		if d:IsA("UICorner") then
			d:Clone().Parent = twin
		end
	end

	twin.Parent = group.Parent

	local resting, keep = false, nil

	local function shown(child)
		return child:IsA("GuiObject") and child.Visible
	end

	local function rest()
		if resting or group.GroupTransparency > 0.001 or not group.Parent then
			return
		end

		resting = true
		keep = { bg = group.BackgroundTransparency, active = group.Active, z = group.ZIndex }
		twin.BackgroundColor3 = group.BackgroundColor3
		twin.BackgroundTransparency = keep.bg
		twin.Active = keep.active
		twin.ZIndex = keep.z

		for _, child in next, group:GetChildren() do
			if shown(child) then
				child.Parent = twin
			end
		end

		group.BackgroundTransparency = 1
		group.Active = false
		group.ZIndex = keep.z + 1
		twin.Visible = group.Visible
	end

	local function wake()
		if not resting then
			return
		end

		resting = false

		for _, child in next, twin:GetChildren() do
			if not child:IsA("UICorner") then
				child.Parent = group
			end
		end

		group.BackgroundTransparency = keep.bg
		group.Active = keep.active
		group.ZIndex = keep.z
		twin.Visible = false
	end

	conn(group:GetPropertyChangedSignal("GroupTransparency"), function()
		if group.GroupTransparency > 0.001 then
			wake()
		else
			rest()
		end
	end)

	conn(group:GetPropertyChangedSignal("Visible"), function()
		twin.Visible = resting and group.Visible
	end)

	for _, key in next, mirrored do
		conn(group:GetPropertyChangedSignal(key), function()
			twin[key] = group[key]
		end)
	end

	-- something shown inside the group while it rests belongs on the twin
	conn(group.ChildAdded, function(child)
		if resting then
			task.defer(function()
				if resting and child.Parent == group and shown(child) then
					child.Parent = twin
				end
			end)
		end
	end)

	conn(group.Destroying, function()
		twin:Destroy()
	end)

	rest()

	return twin
end

local function apos(o)
	return o.AbsolutePosition / sc
end

local function asz(o)
	return o.AbsoluteSize / sc
end

local rides = setmetatable({}, { __mode = "k" })
local skip = setmetatable({}, { __mode = "k" })

local function outq(t)
	return 1 - (1 - t) ^ 5
end

local function inq(t)
	return t * t
end

local function flow(o, dur, curve, step, lag)
	local prev = rides[o]

	if prev then
		prev:Disconnect()
		rides[o] = nil
	end

	local t = -(lag or 0)
	local c

	c = rs.RenderStepped:Connect(function(dt)
		if not o.Parent then
			c:Disconnect()

			if rides[o] == c then
				rides[o] = nil
			end

			return
		end

		t = math.min(t + dt, dur)

		if t < 0 then
			step(0)

			return
		end

		step(curve(t / dur))

		if t >= dur then
			c:Disconnect()

			if rides[o] == c then
				rides[o] = nil
			end
		end
	end)

	rides[o] = c

	return c
end

local function round(o, r)
	return new("UICorner", { CornerRadius = UDim.new(0, r) }, o)
end

local function hexof(c)
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function fromhex(s)
	if type(s) ~= "string" then
		return nil
	end

	local raw = string.gsub(s, "[^%x]", "")

	if #raw == 3 then
		raw = string.gsub(raw, "%x", "%1%1")
	end

	if #raw ~= 6 then
		return nil
	end

	local n = tonumber(raw, 16)

	if not n then
		return nil
	end

	return Color3.fromRGB(math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256)
end

local function fade(o, rot, keys)
	return new("UIGradient", {
		Rotation = rot,
		Transparency = NumberSequence.new(keys),
	}, o)
end

local optionalAssetsBlocked = false
local function optionalAsset(fn)
	if optionalAssetsBlocked then return nil end
	local done, abandoned, result = false, false, nil
	task.spawn(function()
		local ok, value = pcall(fn)
		if not abandoned then result = ok and value or nil; done = true end
	end)
	local deadline = os.clock() + 1.5
	while not done and visualsui.alive ~= false and os.clock() < deadline do task.wait(0.03) end
	if not done or visualsui.alive == false then
		abandoned = true
		if not done and visualsui.alive ~= false then
			optionalAssetsBlocked = true
			visualsui.assetIssue = "optional UI asset timed out"
		end
		return nil
	end
	return result
end

local function pullasset(name)
	local grab = type(ASSETS) == "table" and ASSETS.asset or getgenv().visuals_asset

	if type(grab) ~= "function" or type(name) ~= "string" or name == "" then
		return nil
	end

	local res = optionalAsset(function() return grab(name) end)

	if type(res) == "string" and res ~= "" then
		return res
	end
end

local function pulllist(prefix)
	local names = type(ASSETS) == "table" and ASSETS.under or getgenv().visuals_assetlist

	if type(names) ~= "function" then
		return {}
	end

	local ok, res = pcall(names, prefix)

	if ok and type(res) == "table" then
		return res
	end

	return {}
end

local function asset(paths)
	if type(ASSETS) == "table" then
		return pullasset(paths[1]) or ""
	end
	if getcustomasset and isfile then
		for _, p in next, paths do
			local res = optionalAsset(function()
				return isfile(p) and getcustomasset(p) or nil
			end)
			if type(res) == "string" and res ~= "" then
				return res
			end
		end
	end
	local got = pullasset(string.match(tostring(paths[1] or ""), "([^/\\]+)$"))
	if got then
		return got
	end
	return ""
end

local locks = 0

local function latch(d)
	locks = math.max(locks + d, 0)
end

-- Calls done() once the pointer that started a drag is no longer down. A phone
-- does not always deliver the matching "ended" event, and a drag that never
-- ended kept the page it sits on from scrolling.
local function untilReleased(input, done)
	local watch
	watch = rs.Heartbeat:Connect(function()
		local down

		if input and input.UserInputType == Enum.UserInputType.Touch then
			down = input.UserInputState == Enum.UserInputState.Begin or input.UserInputState == Enum.UserInputState.Change
		else
			down = uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
		end

		if not down then
			watch:Disconnect()
			done()
		end
	end)

	return watch
end

-- A drag that ends off a control, or on one destroyed mid-drag, can leave the
-- counter standing. Nothing then closes again and the popup's backdrop eats
-- every click. With no button held and no box being typed in there is nothing
-- left to protect, so the counter is let go.
do
	local touches, idle = {}, 0

	conn(uis.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.Touch then
			touches[i] = true
		end
	end)

	local function held()
		for t in next, touches do
			if t.UserInputState == Enum.UserInputState.Begin or t.UserInputState == Enum.UserInputState.Change then
				return true
			end

			touches[t] = nil
		end

		return uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
	end

	conn(rs.Heartbeat, function(dt)
		if locks > 0 and not held() and not uis:GetFocusedTextBox() then
			idle += dt

			if idle > 0.4 then
				locks = 0
				idle = 0
			end
		else
			idle = 0
		end
	end)
end

local sky = nil
local skyzone = nil
local overkeys = nil

local function inset()
	local ok, v = pcall(function()
		return gus:GetGuiInset()
	end)

	if ok and typeof(v) == "Vector2" then
		return v
	end

	return Vector2.zero
end

local function inside(frame, slack)
	if not frame or not frame.Parent or not frame.Visible then
		return false
	end

	local s = frame.AbsoluteSize

	if s.X <= 0 or s.Y <= 0 then
		return false
	end

	local p = frame.AbsolutePosition + inset()

	slack = slack or 0

	local m = uis:GetMouseLocation()

	return m.X >= p.X - slack and m.X <= p.X + s.X + slack and m.Y >= p.Y - slack and m.Y <= p.Y + s.Y + slack
end

local function sink()
	local s = sky

	if not s then
		return
	end

	sky = nil
	skyzone = nil

	s()
end

conn(uis.InputBegan, function(i, typing)
	if not sky or typing then
		return
	end

	if locks > 0 then
		return
	end

	if overkeys and overkeys() then
		return
	end

	if skyzone and inside(skyzone, 2) then
		return
	end

	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		sink()
	end
end)

local function drag(handle, target, speed)
	local info = TweenInfo.new(speed or 0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	-- a finger is followed by that finger alone: with every touch counted, the
	-- thumb on the joystick pulled the window (or the watermark) across the
	-- screen and letting go of it dropped the drag
	local held, origin, base, finger = false, nil, nil, nil

	conn(handle.InputBegan, function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local spot, seat = i.Position, target.Position

		task.wait()

		if locks > 0 or i.UserInputState == Enum.UserInputState.End then
			return
		end

		held, origin, base = true, spot, seat
		finger = i.UserInputType == Enum.UserInputType.Touch and i or nil

		local stop
		stop = i.Changed:Connect(function()
			if i.UserInputState == Enum.UserInputState.End then
				held = false
				stop:Disconnect()
			end
		end)
	end)

	conn(uis.InputEnded, function(i)
		if finger then
			if i == finger then
				held = false
			end
		elseif i.UserInputType == Enum.UserInputType.MouseButton1 then
			held = false
		end
	end)

	conn(uis.InputChanged, function(i)
		if not held or locks > 0 then
			return
		end

		if finger then
			if i ~= finger then
				return
			end
		elseif i.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end

		local d = i.Position - origin
		local goal = UDim2.new(
			base.X.Scale,
			math.floor(base.X.Offset + d.X),
			base.Y.Scale,
			math.floor(base.Y.Offset + d.Y)
		)

		-- under a finger it sits where the finger is; the eased follow reads
		-- as lag on a touch screen
		if finger then
			target.Position = goal
		else
			anim(target, info, { Position = goal })
		end
	end)
end

local function params(cfg, def)
	cfg = cfg or {}
	for k, v in next, def do
		if cfg[k] == nil then
			cfg[k] = v
		end
	end
	return cfg
end

visualsui.logo = ""

do
	local before = getgenv().visualsui

	if type(before) == "table" and before ~= visualsui and typeof(before.scr) == "Instance" and before.scr.Parent then
		pcall(before.unload, before)

		pcall(function()
			before.scr:Destroy()
		end)
	end
end

local scr = new("ScreenGui", {
	Name = rnd(),
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 1000,
})

pcall(prot, scr)

local attached = pcall(function() scr.Parent = hui end)

if not attached or not scr.Parent then
	pcall(function() scr.Parent = lp:WaitForChild("PlayerGui") end)
end

local function supports(class)
	local ok, object = pcall(Instance.new, class)
	if ok then object:Destroy() end
	return ok
end

local function pointer(input)
	-- InputObject.Position and AbsolutePosition already share GUI coordinates.
	-- GetMouseLocation is screen-relative and is the only path needing inset.
	if input and input.UserInputType == Enum.UserInputType.Touch then
		return Vector2.new(input.Position.X, input.Position.Y)
	end
	return uis:GetMouseLocation() - gus:GetGuiInset()
end

local function callback(fn, ...)
	if not visualsui.alive or type(fn) ~= "function" then return end
	if visualsui.configApplying then return fn(...) end
	local args, epoch = table.pack(...), visualsui.applyEpoch
	task.spawn(function()
		if visualsui.alive and epoch == visualsui.applyEpoch then
			local ok, err = pcall(fn, table.unpack(args, 1, args.n))
			if not ok then warn("[visuals] UI callback: " .. tostring(err)) end
		end
	end)
end

visualsui.scr = scr

-- One wheel handler for every list in the menu. Roblox's own wheel scrolling
-- jumps a fixed step and snaps, and nested lists fight over it; here each
-- list's native wheel is off, a notch moves a target and the list eases to
-- it. The notch goes to the innermost list under the cursor that scrolls at
-- all; one at its end keeps it rather than scrolling the page around it.
-- ScrollingEnabled keeps its meaning for the code that switches it off while
-- a slider or a colour is dragged: off means the wheel leaves that list alone.
-- Touch devices keep native scrolling.
do
	local lists = {}
	local moving = {}
	local STEP = 120

	visualsui.floating = visualsui.floating or setmetatable({}, { __mode = "k" })

	local function range(sf)
		return math.max(sf.AbsoluteCanvasSize.Y - sf.AbsoluteWindowSize.Y, 0)
	end

	local function inside(o, p)
		local a, z = o.AbsolutePosition, o.AbsoluteSize

		return p.X >= a.X and p.Y >= a.Y and p.X <= a.X + z.X and p.Y <= a.Y + z.Y
	end

	-- visible all the way up, and the cursor inside every clipping frame
	-- above the list as well as the list itself; returns the depth
	local function reach(sf, p)
		local o, depth, lift = sf, 0, 0

		while o and o ~= scr do
			-- a popup floats over the page but sits shallower in the tree, so
			-- by depth alone the page column under it took the wheel
			if visualsui.floating[o] then
				lift = 1000
			end

			if o:IsA("GuiObject") then
				if not o.Visible then
					return nil
				end

				if (o == sf or o.ClipsDescendants) and not inside(o, p) then
					return nil
				end
			end

			depth += 1
			o = o.Parent
		end

		return o == scr and depth + lift or nil
	end

	local function watch(sf)
		if lists[sf] or visualsui.mobile or not sf.Parent then
			return
		end

		local st = { y = sf.CanvasPosition.Y, goal = sf.CanvasPosition.Y, allowed = sf.ScrollingEnabled, own = 0 }

		lists[sf] = st

		-- Our own writes are counted, not flagged: in a game with deferred
		-- signals the handler runs after a flag would already be cleared, read
		-- the false we just wrote as "a slider locked this list", and the list
		-- ignored the wheel for good. Only a real change fires, so only those
		-- are counted.
		local function shut()
			if sf.ScrollingEnabled then
				st.own += 1
				sf.ScrollingEnabled = false
			end
		end

		shut()

		st.links = {
			sf:GetPropertyChangedSignal("ScrollingEnabled"):Connect(function()
				if st.own > 0 then
					st.own -= 1

					return
				end

				st.allowed = sf.ScrollingEnabled

				shut()
			end),
		}

		st.links[3] = sf.AncestryChanged:Connect(function()
			if not sf:IsDescendantOf(game) then
				for _, c in next, st.links do
					c:Disconnect()
				end

				lists[sf] = nil
				moving[sf] = nil
			end
		end)
	end

	visualsui.glide = watch

	conn(uis.InputChanged, function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseWheel or not visualsui.shown then
			return
		end

		local p = pointer()
		local notch = -i.Position.Z
		local hits = {}

		for sf, st in next, lists do
			if st.allowed then
				local depth = reach(sf, p)

				if depth then
					hits[#hits + 1] = { sf = sf, depth = depth }
				end
			end
		end

		table.sort(hits, function(a, b)
			return a.depth > b.depth
		end)

		-- over an open popup the wheel stays in it: a short list, or one at its
		-- end, handed the notch to the page underneath and the tab scrolled
		local held = false

		for o in next, visualsui.floating do
			if o.Visible and o.Parent and inside(o, p) then
				held = true

				break
			end
		end

		-- The innermost list that scrolls at all owns the notch, even at its
		-- end. Handing it on to the list around it scrolled the whole tab
		-- whenever a preset list or a gallery ran out. A list too short to
		-- scroll is part of the page, so the page still scrolls over it.
		for _, hit in next, hits do
			if held and hit.depth < 1000 then
				return
			end

			local span = range(hit.sf)

			if span > 1 then
				local st = lists[hit.sf]

				if not st.moving then
					local now = hit.sf.CanvasPosition.Y
					st.y, st.goal = now, now
				end

				local goal = math.clamp(st.goal + notch * STEP, 0, span)

				if goal ~= st.goal then
					st.goal = goal
					st.moving = true
					moving[hit.sf] = st
				end

				return
			end
		end
	end)

	-- The list is driven from here, not from CanvasPosition changes: a drag,
	-- a jump from code or a canvas that grew is read back, and only a glide
	-- in flight writes. Watching the property instead cancelled the glide
	-- whenever the engine clamped a write or a virtualised list rebuilt.
	conn(rs.RenderStepped, function(dt)
		if not visualsui.shown then
			for sf, st in next, moving do
				st.moving = false
				moving[sf] = nil
			end

			return
		end

		if not next(moving) then return end

		local k = 1 - math.exp(-dt * 24)

		for sf, st in next, moving do
			local now = sf.CanvasPosition.Y

			-- something else moved it mid-glide: carry on from there
			if math.abs(now - st.y) > 1.5 then st.y = now end

			st.goal = math.clamp(st.goal, 0, range(sf))

			local y = st.y + (st.goal - st.y) * k

			if math.abs(st.goal - y) < 0.5 then
				y = st.goal
				st.moving = false
				moving[sf] = nil
			end

			st.y = y
			sf.CanvasPosition = Vector2.new(sf.CanvasPosition.X, y)
		end
	end)

	conn(scr.DescendantAdded, function(d)
		if d:IsA("ScrollingFrame") then
			task.defer(watch, d)
		end
	end)
end

local flock = {}
local flocked = 0
local inflock = setmetatable({}, { __mode = "k" })

conn(scr.DescendantAdded, function(o)
	if (o:IsA("GuiObject") or o:IsA("UIStroke") or o:IsA("UIShadow")) and not inflock[o] then
		inflock[o] = true
		table.insert(flock, o)
		flocked += 1

		-- dead entries used to go only on a recolour; lists that rebuild their
		-- rows (the chat, the galleries) piled them up for the whole session
		if flocked >= 4096 then
			flocked = 0

			local keep = 0

			for i = 1, #flock do
				local v = flock[i]

				if v.Parent then
					keep += 1
					flock[keep] = v
				else
					inflock[v] = nil
				end
			end

			for i = #flock, keep + 1, -1 do
				flock[i] = nil
			end
		end
	end
end)

-- Guis of the script's own that wear the theme outside this ScreenGui (the
-- music player and its lyrics): recoloured with everything else.
visualsui.themeroots = {}

-- The whole palette in one pass. Swapping one role at a time broke as soon
-- as a new colour of one role was the old colour of another: the second swap
-- took the first one's objects with it. Here every object is looked up once
-- against the old palette and gets its own role's new colour.
function visualsui:retheme(map)
	local swap, any = {}, false

	for key, c in next, map do
		local old = visualsui.theme[key]

		if typeof(c) == "Color3" and typeof(old) == "Color3" and c:ToHex() ~= old:ToHex() then
			swap[old:ToHex()] = c
			any = true
		end
	end

	for key, c in next, map do
		if typeof(c) == "Color3" and typeof(visualsui.theme[key]) == "Color3" then
			visualsui.theme[key] = c
		end
	end

	if not any then
		return
	end

	local function fix(o)
		if o:IsA("UIStroke") or o:IsA("UIShadow") then
			local n = swap[o.Color:ToHex()]

			if n then
				o.Color = n
			end
		elseif o:IsA("GuiObject") then
			local n = swap[o.BackgroundColor3:ToHex()]

			if n then
				o.BackgroundColor3 = n
			end

			if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
				n = swap[o.TextColor3:ToHex()]

				if n then
					o.TextColor3 = n
				end
			elseif o:IsA("ImageLabel") or o:IsA("ImageButton") then
				n = swap[o.ImageColor3:ToHex()]

				if n then
					o.ImageColor3 = n
				end
			end
		end
	end

	for i = #flock, 1, -1 do
		local o = flock[i]

		if not o.Parent then
			table.remove(flock, i)
			inflock[o] = nil
		else
			fix(o)
		end
	end

	for root in next, visualsui.themeroots do
		if root.Parent then
			for _, o in next, root:GetDescendants() do
				fix(o)
			end
		else
			visualsui.themeroots[root] = nil
		end
	end
end

function visualsui:recolor(key, c)
	visualsui:retheme({ [key] = c })
end

-- The menu's typeface. Every label keeps its own weight - a bold heading
-- stays bold in the new face - and only the menu's own faces are swapped:
-- anything drawn in another font on purpose (a code box, an emoji) is left be.
-- "Fortnite" is Oswald: Fortnite's own Burbank is not a Roblox font, and
-- Oswald is the nearest heavy condensed face there is.
local FONT_CHOICES = {
	{ "Default", nil },
	{ "Fortnite", "Oswald" },
	{ "Builder Sans", "BuilderSans" },
	{ "Montserrat", "Montserrat" },
	{ "Nunito", "Nunito" },
	{ "Fredoka", "FredokaOne" },
	{ "Luckiest Guy", "LuckiestGuy" },
	{ "Bangers", "Bangers" },
	{ "Titillium", "TitilliumWeb" },
	{ "Michroma", "Michroma" },
	{ "Ubuntu", "Ubuntu" },
	{ "Roboto", "Roboto" },
	{ "Jura", "Jura" },
}

local FACE_WEIGHT = {
	[Enum.Font.GothamBlack] = Enum.FontWeight.Heavy,
	[Enum.Font.GothamBold] = Enum.FontWeight.Bold,
	[Enum.Font.GothamSemibold] = Enum.FontWeight.SemiBold,
	[Enum.Font.GothamMedium] = Enum.FontWeight.Medium,
	[Enum.Font.Gotham] = Enum.FontWeight.Regular,
}

pcall(function()
	FACE_WEIGHT[Enum.Font.BuilderSansBold] = Enum.FontWeight.Bold
	FACE_WEIGHT[Enum.Font.BuilderSansMedium] = Enum.FontWeight.Medium
	FACE_WEIGHT[Enum.Font.BuilderSans] = Enum.FontWeight.Regular
end)

local fontFamily = nil
local fontBase = setmetatable({}, { __mode = "k" })

visualsui.font = "Default"

function visualsui:fontnames()
	local out = {}

	for _, choice in ipairs(FONT_CHOICES) do
		-- only faces this client actually has
		if not choice[2] or pcall(function() return Font.fromEnum(Enum.Font[choice[2]]) end) then
			out[#out + 1] = choice[1]
		end
	end

	return out
end

-- GothamSemibold is not a face of its own on every client: some map it
-- straight onto Medium, so a "semibold" label renders exactly like a plain
-- one. Build the real SemiBold face once, so the labels that must stand
-- apart (feature names, the chosen row) actually do.
local SEMIBOLD = nil

pcall(function()
	SEMIBOLD = Font.new(Font.fromEnum(Enum.Font.GothamMedium).Family, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
end)

local function refont(o)
	if not (o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")) then
		return
	end

	local base = fontBase[o]

	if base == nil then
		base = o.Font
		fontBase[o] = base
	end

	local weight = FACE_WEIGHT[base]

	if not weight then
		return
	end

	if o:GetAttribute("semi") then
		weight = Enum.FontWeight.SemiBold
	end

	if fontFamily then
		o.FontFace = Font.new(fontFamily, weight)
	elseif weight ~= FACE_WEIGHT[base] then
		if SEMIBOLD then
			o.FontFace = SEMIBOLD
		else
			o.Font = Enum.Font.GothamBold
		end
	elseif o.Font ~= base then
		o.Font = base
	end
end

-- a label that has to read a touch heavier than the rest
local function semi(o)
	fontBase[o] = Enum.Font.GothamMedium
	o:SetAttribute("semi", true)

	if SEMIBOLD then
		o.FontFace = SEMIBOLD
	else
		o.Font = Enum.Font.GothamBold
	end
end

local function plain(o)
	o:SetAttribute("semi", nil)
	o.Font = Enum.Font.GothamMedium
end

visualsui.refont = refont
visualsui.semi = semi
visualsui.plain = plain

function visualsui:setfont(name)
	local family = nil

	for _, choice in ipairs(FONT_CHOICES) do
		if choice[1] == name and choice[2] then
			local ok, face = pcall(function() return Font.fromEnum(Enum.Font[choice[2]]) end)

			family = ok and face.Family or nil
		end
	end

	if family == fontFamily then
		return
	end

	fontFamily = family
	visualsui.font = family and name or "Default"

	-- a few thousand labels: in slices, so the switch never stalls a frame
	task.spawn(function()
		local roots = { scr }

		for root in next, visualsui.themeroots do
			if root.Parent then roots[#roots + 1] = root end
		end

		local done = 0

		for _, root in ipairs(roots) do
			for _, o in next, root:GetDescendants() do
				pcall(refont, o)
				done += 1

				if done % 400 == 0 then
					task.wait()
				end
			end
		end
	end)
end

-- whatever is built later wears the chosen face too
conn(scr.DescendantAdded, function(o)
	if fontFamily and (o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")) then
		task.defer(function()
			pcall(refont, o)
		end)
	end
end)

visualsui.dir = "visualscfgs"
visualsui.pool = {}
visualsui.order = {}
visualsui.alive = true

local abc = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local rev = {}

for i = 1, 64 do
	rev[string.sub(abc, i, i)] = i - 1
end

local salt = "sh1t4r0::cfg::v1"

local function mask(raw)
	local out = table.create(#raw)

	for i = 1, #raw do
		local k = (string.byte(salt, (i - 1) % #salt + 1) + i * 31 + 91) % 256

		out[i] = string.char(bit32.bxor(string.byte(raw, i), k))
	end

	return table.concat(out)
end

local function pack(raw)
	local out = {}
	local i = 1

	while i <= #raw do
		local a = string.byte(raw, i)
		local b = string.byte(raw, i + 1)
		local c = string.byte(raw, i + 2)
		local v = a * 65536 + (b or 0) * 256 + (c or 0)
		local q = { math.floor(v / 262144) % 64, math.floor(v / 4096) % 64, math.floor(v / 64) % 64, v % 64 }

		out[#out + 1] = string.sub(abc, q[1] + 1, q[1] + 1)
		out[#out + 1] = string.sub(abc, q[2] + 1, q[2] + 1)
		out[#out + 1] = b and string.sub(abc, q[3] + 1, q[3] + 1) or "="
		out[#out + 1] = c and string.sub(abc, q[4] + 1, q[4] + 1) or "="

		i = i + 3
	end

	return table.concat(out)
end

local function peel(txt)
	txt = string.gsub(txt, "[^%w%+/=]", "")

	local out = {}
	local i = 1

	while i < #txt do
		local v, gap = 0, 0

		for j = 0, 3 do
			local ch = string.sub(txt, i + j, i + j)

			if ch == "=" or ch == "" then
				v = v * 64
				gap = gap + 1
			else
				v = v * 64 + (rev[ch] or 0)
			end
		end

		out[#out + 1] = string.char(math.floor(v / 65536) % 256)

		if gap < 2 then
			out[#out + 1] = string.char(math.floor(v / 256) % 256)
		end

		if gap < 1 then
			out[#out + 1] = string.char(v % 256)
		end

		i = i + 4
	end

	return table.concat(out)
end

local function esc(s)
	return (string.gsub(tostring(s), "[%%\1\2\r\n]", function(ch)
		return string.format("%%%02X", string.byte(ch))
	end))
end

local function unesc(s)
	return (string.gsub(s, "%%(%x%x)", function(h)
		return string.char(tonumber(h, 16))
	end))
end

local function slap(fn, ...)
	if type(fn) ~= "function" then
		return nil
	end

	local ok, res = pcall(fn, ...)

	if ok then
		return res
	end
	if visualsui.configApplying then error(res, 0) end
	warn("[visuals] UI: " .. tostring(res))
end

local function vault()
	if type(isfolder) ~= "function" or type(makefolder) ~= "function" then
		return false
	end

	local path = ""
	for piece in string.gmatch(string.gsub(visualsui.dir, "\\", "/"), "[^/]+") do
		path = path == "" and piece or (path .. "/" .. piece)
		if not slap(isfolder, path) then slap(makefolder, path) end
		if not slap(isfolder, path) then return false end
	end
	return path ~= ""
end

local function tidy(name)
	if type(name) ~= "string" then
		return nil
	end

	name = string.match(name, "^%s*(.-)%s*$") or ""
	name = string.gsub(name, "%.[yY][aA][nN]$", "")

	if #name == 0 or #name > 128 or name == "." or name == ".." or name:find('[%c<>:"/\\|?*]')
		or name:match("[%.%s]$") then
		return nil
	end

	return name
end

local function slot(name)
	return visualsui.dir .. "/" .. name .. ".yan"
end

function visualsui:hook(id, kind, get, set, schema)
	if type(id) ~= "string" or id == "" then
		return
	end

	if not visualsui.pool[id] then
		table.insert(visualsui.order, id)
	end

	visualsui.pool[id] = { kind = kind, get = get, set = set, schema = schema }
end

function visualsui:unhook(id)
	if type(id) ~= "string" or not visualsui.pool[id] then
		return
	end

	visualsui.pool[id] = nil

	local at = table.find(visualsui.order, id)

	if at then
		table.remove(visualsui.order, at)
	end
end

function visualsui:freeze()
	local rows = {}

	for _, id in next, visualsui.order do
		local e = visualsui.pool[id]

		if e and not (self.secrets and self.secrets[id]) then
			local v = slap(e.get)
			local t = nil

			if typeof(v) == "Color3" then
				t, v = "c", hexof(v)
			elseif type(v) == "boolean" then
				t, v = "b", v and "1" or "0"
			elseif type(v) == "number" and v == v and math.abs(v) < math.huge then
				t, v = "n", tostring(v)
			elseif type(v) == "string" then
				t = "s"
			elseif v == nil and e.kind == "key" then
				t, v = "s", "Unknown"
			end

			if t then
				rows[#rows + 1] = "f\1" .. esc(id) .. "\1" .. t .. "\1" .. esc(v)
			end
		end
	end

	for k, v in next, visualsui.theme do
		if typeof(v) == "Color3" then
			rows[#rows + 1] = "t\1" .. esc(k) .. "\1c\1" .. hexof(v)
		end
	end

	return "SHC1" .. pack(mask(table.concat(rows, "\2")))
end

function visualsui:thaw(blob)
	if type(blob) ~= "string" or #blob > 4 * 1024 * 1024 then return nil end
	blob = string.gsub(blob, "^\239\187\191", "")
	blob = string.match(blob, "^%s*(.-)%s*$") or ""
	if string.sub(blob, 1, 4) ~= "SHC1" then
		return nil
	end

	local encoded = string.gsub(string.sub(blob, 5), "%s", "")
	if encoded:find("[^%w+/=]") or #encoded % 4 ~= 0 or not encoded:match("^[%w+/]*=?=?$") then return nil end
	local raw = mask(peel(encoded))
	local flags, tint = {}, {}

	for chunk in string.gmatch(raw, "[^\2]+") do
		local kind, id, t, v = string.match(chunk, "^(%a)\1([^\1]*)\1(%a)\1(.*)$")

		if (kind == "f" or kind == "t") and (t == "b" or t == "n" or t == "s" or t == "c") then
			id = unesc(id)
			v = unesc(v)

			if t == "b" then
				if v ~= "1" and v ~= "0" then return nil end
				v = v == "1"
			elseif t == "n" then
				v = tonumber(v)
				if not v or v ~= v or math.abs(v) == math.huge then return nil end
			elseif t == "c" and not fromhex(v) then
				return nil
			end

			if v ~= nil then
				if kind == "f" then
					flags[id] = v
				elseif kind == "t" then
					tint[id] = v
				end
			end
		else return nil end
	end

	return { flags = flags, theme = tint }
end

-- Clipboard configs never touch the profile folder. Import only validates and
-- stages the decoded snapshot; Load applies that staged snapshot, or reads the
-- clipboard directly when the user skips Import.
function visualsui:clipboardExport()
	if type(clipput) ~= "function" then
		return false, "Clipboard write is unavailable"
	end

	local ok, blob = pcall(self.freeze, self)
	if not ok or type(blob) ~= "string" or blob == "" then
		return false, "Could not serialize current settings"
	end

	local copied, reason = pcall(clipput, blob)
	if not copied then
		return false, tostring(reason)
	end

	return true, #blob
end

function visualsui:clipboardImport()
	if type(clipget) ~= "function" then
		return false, "Clipboard read is unavailable"
	end

	local ok, blob = pcall(clipget)
	if not ok or type(blob) ~= "string" or blob == "" then
		return false, "Clipboard is empty or unavailable"
	end

	local fine, data = pcall(self.thaw, self, blob)
	if not fine or type(data) ~= "table" then
		return false, "Clipboard does not contain a valid config"
	end

	self.clipboardBlob = blob
	self.clipboardData = data
	return true
end

function visualsui:clipboardLoad()
	local data = self.clipboardData
	if type(data) ~= "table" then
		local imported, reason = self:clipboardImport()
		if not imported then return false, reason end
		data = self.clipboardData
	end

	local ok, result = pcall(self.apply, self, data)
	self.clipboardBlob, self.clipboardData = nil, nil
	if not ok then
		self.configResult = { ok = false, errors = { tostring(result) } }
		return false, tostring(result)
	end

	if result ~= true then
		local errors = self.configResult and self.configResult.errors
		return false, errors and errors[1] or "Could not apply clipboard config"
	end

	return true
end

function visualsui:apply(data)
	if type(data) ~= "table" or not self.alive then
		return false
	end
	local errors, warnings, prepared = {}, {}, {}
	local flags = data.flags or {}
	if type(flags) ~= "table" or (data.theme ~= nil and type(data.theme) ~= "table") then return false end
	for id, v in pairs(flags) do
		local e = self.pool[id]
		if e and not (self.secrets and self.secrets[id]) then
			local valid = true
			if e.kind == "number" then
				local n = tonumber(v)
				valid = n ~= nil and n == n and math.abs(n) < math.huge
				if valid then
					if e.schema and e.schema.min ~= nil then n = math.max(n, e.schema.min) end
					if e.schema and e.schema.max ~= nil then n = math.min(n, e.schema.max) end
					v = n
				end
			elseif e.kind == "toggle" then valid = type(v) == "boolean"
			elseif e.kind == "color" then valid = typeof(v) == "Color3" or (type(v) == "string" and fromhex(v) ~= nil)
			elseif e.kind == "key" then
				valid = type(v) == "string" and pcall(function() assert(Enum.KeyCode[v]) end)
			else valid = type(v) == "string" and #v <= 65536 end
			if not valid then errors[#errors + 1] = id .. ": invalid value" end
			if valid then prepared[id] = v end
		end
	end
	for key, value in pairs(data.theme or {}) do
		if type(key) ~= "string" or type(value) ~= "string" or not fromhex(value) then errors[#errors + 1] = "theme: invalid color" end
	end
	if #errors > 0 then self.configResult = { ok = false, errors = errors }; warn("[visuals] config: " .. table.concat(errors, "; ")); return false end
	-- Structural validation precedes catalogue imports, which may add valid
	-- accessory choices. A damaged profile must not mutate the local catalogue.
	if type(self.beforeConfigApply) == "function" then
		-- Pass the prepared values so migrations can safely rewrite a legacy
		-- selection before membership validation and application.
		local ok, reason = pcall(self.beforeConfigApply, { flags = prepared, theme = data.theme })
		if not ok then self.configResult = { ok = false, errors = { tostring(reason) } }; return false end
	end
	if not self.alive then return false end
	for id, v in pairs(prepared) do
		local e = self.pool[id]
		if e.schema and e.schema.validate then
			local ok, accepted = pcall(e.schema.validate, v)
			if ok and accepted ~= true and (e.kind == "list" or e.kind == "string") then
				warnings[#warnings + 1] = id .. ": selection unavailable on this device"
				prepared[id] = nil
			elseif not ok or accepted ~= true then errors[#errors + 1] = id .. ": invalid value" end
		end
	end
	if #errors > 0 then self.configResult = { ok = false, errors = errors }; return false end
	self.applyEpoch = (self.applyEpoch or 0) + 1
	local epoch = self.applyEpoch
	self.configApplying = true
	self.quiet = true
	self.configResult = { ok = false, pending = true, errors = errors, warnings = warnings }
	local function active() return self.alive and self.applyEpoch == epoch end
		local ok, err = pcall(function()
			local work = 0

			if type(data.theme) == "table" then
				-- the whole saved palette in one pass, like a preset
				local map = {}

				for k, v in next, data.theme do
					local c = fromhex(v)

					-- cards included: their own callbacks, a moment later, then
					-- find the colour already in place
					if c then
						map[k] = c
					end
				end

				if not active() then return end
				self:retheme(map)
				task.wait()
			end

			if type(data.flags) == "table" then
				for _, id in next, self.order do
					if not active() then return end
					local e = self.pool[id]
					local v = prepared[id]

					if e and v ~= nil then
						if not (self.secrets and self.secrets[id]) then
							local fine, reason = pcall(e.set, v)
							if not fine then errors[#errors + 1] = id .. ": " .. tostring(reason) end
						end
					end

					work += 1

					-- Keep the render/input thread responsive while a large profile
					-- restores dozens of controls and feature callbacks.
					if work % 6 == 0 then task.wait() end
				end
			end
		end)

		if self.applyEpoch == epoch then
			self.quiet = false
			self.configApplying = false
			self.appliedAt = os.clock()
			if not ok then errors[#errors + 1] = tostring(err) end
			self.configResult = { ok = ok and self.alive and #errors == 0, errors = errors, warnings = warnings }
		end

		if not ok then
			warn("[visuals] config apply: " .. tostring(err))
		end
	if #errors > 0 then warn("[visuals] config setters: " .. table.concat(errors, "; ")) end
	return ok and active() and #errors == 0
end

function visualsui:roster()
	local out = {}

	if type(listfiles) ~= "function" or not vault() then
		return out
	end

	for _, f in next, slap(listfiles, visualsui.dir) or {} do
		local nm = string.match(string.gsub(tostring(f), "\\", "/"), "([^/]+)%.yan$")

		if nm then
			table.insert(out, nm)
		end
	end

	table.sort(out, function(a, b)
		return string.lower(a) < string.lower(b)
	end)

	return out
end

-- The config loaded by itself after every inject. Only its name is kept, in
-- a file the host points autoloadfile at (outside the config folder, so that
-- folder holds nothing but configs).
visualsui.autoloadfile = nil

function visualsui:autoload()
	local path = visualsui.autoloadfile

	if not (path and type(isfile) == "function" and type(readfile) == "function") then
		return nil
	end

	local ok, has = pcall(isfile, path)

	if not (ok and has) then
		return nil
	end

	local read, name = pcall(readfile, path)
	name = read and tidy(tostring(name)) or nil

	return name
end

function visualsui:setautoload(name)
	local path = visualsui.autoloadfile

	if not path then
		return false
	end

	if not name then
		if type(isfile) == "function" and type(delfile) == "function" and select(2, pcall(isfile, path)) == true then
			pcall(delfile, path)
		end

		return true
	end

	local folder = string.match(path, "^(.*)/[^/]+$")

	if folder and type(isfolder) == "function" and type(makefolder) == "function" and not select(2, pcall(isfolder, folder)) then
		pcall(makefolder, folder)
	end

	return type(writefile) == "function" and pcall(writefile, path, name) or false
end

function visualsui:store(name)
	name = tidy(name)

	if not name or type(writefile) ~= "function" or not vault() then
		return nil
	end

	local ok, blob = pcall(visualsui.freeze, visualsui)

	if not ok or type(blob) ~= "string" then
		return nil
	end

	if not pcall(writefile, slot(name), blob) then
		return nil
	end
	if type(readfile) == "function" then
		local verified, saved = pcall(readfile, slot(name))
		if not verified or saved ~= blob then return nil end
	end

	return name
end

function visualsui:fetch(name)
	name = tidy(name)
	self.configResult = nil

	if not name or type(readfile) ~= "function" then
		self.configResult = { ok = false, errors = { "Config name or file API unavailable" } }
		return nil
	end

	local ok, blob = pcall(readfile, slot(name))

	if not ok or type(blob) ~= "string" then
		self.configResult = { ok = false, errors = { "Config file not found" } }
		return nil
	end

	local fine, data = pcall(visualsui.thaw, visualsui, blob)

	if not fine or not data then
		self.configResult = { ok = false, errors = { "Invalid or damaged config" } }
		return nil
	end

	local applied, result = pcall(self.apply, self, data)
	if not applied then
		self.quiet, self.configApplying = false, false
		self.configResult = { ok = false, errors = { tostring(result) } }
	end
	return applied and result and name or nil
end

function visualsui:erase(name)
	name = tidy(name)

	local kill = delfile or delete_file

	if not name or type(kill) ~= "function" then
		return nil
	end

	if not pcall(kill, slot(name)) then
		return nil
	end

	return name
end

function visualsui:retitle(from, to)
	from, to = tidy(from), tidy(to)

	if not from or not to or type(readfile) ~= "function" or type(writefile) ~= "function" then
		return nil
	end

	if from == to then
		return to
	end
	if type(isfile) ~= "function" or isfile(slot(to)) then return nil end

	local ok, blob = pcall(readfile, slot(from))

	if not ok or type(blob) ~= "string" then
		return nil
	end

	if not pcall(writefile, slot(to), blob) then
		return nil
	end

	local verified, saved = pcall(readfile, slot(to))
	if not verified or saved ~= blob or not visualsui:erase(from) then return nil end

	return to
end

local eyes = {}
local stamp = nil

local function sweep()
	local ls = visualsui:roster()
	local sig = table.concat(ls, "\1")

	if sig == stamp then
		return
	end

	stamp = sig

	for _, fn in next, eyes do
		task.spawn(fn, ls)
	end
end

function visualsui:watch(fn)
	local ls = visualsui:roster()

	stamp = table.concat(ls, "\1")

	table.insert(eyes, fn)

	task.spawn(fn, ls)
end

task.spawn(function()
	while visualsui.alive do
		task.wait(1.25)

		if #eyes > 0 then
			sweep()
		end
	end
end)

visualsui.shown = false

local reel = {
	Click = "click",
	Bubble = "bubble",
	Hentai = "hentai1",
}

visualsui.tonelist = { "Click", "Bubble", "Hentai" }
visualsui.tones = {}
visualsui.tone = "Click"
visualsui.sound = false

local spare = "rbxasset://sounds/electronicpingshort.wav"
local barns = { "visualsui/", "visualssnd/", "assets/", "" }
local looked = {}

local function lift(file)
	if type(isfile) == "function" and type(getcustomasset) == "function" then
		for _, dir in next, barns do
			for _, ext in next, { ".mp3", ".wav", ".ogg" } do
				local p = dir .. file .. ext

				if slap(isfile, p) then
					local asset = slap(getcustomasset, p)

					if type(asset) == "string" and asset ~= "" then
						return asset
					end
				end
			end
		end
	end

	for _, entry in next, pulllist("") do
		local stem, ext = string.match(entry, "^([^/]+)(%.[^%.]+)$")

		if stem == file and (ext == ".mp3" or ext == ".wav" or ext == ".ogg") then
			local got = pullasset(entry)

			if got then
				return got
			end
		end
	end
end

local function seek(name)
	if looked[name] ~= nil then
		return looked[name] or nil
	end

	local file = reel[name]
	local got = file and lift(file) or nil

	looked[name] = got or false

	return got
end

local bells = {}
local turnbell = 0

for i = 1, 4 do
	bells[i] = new("Sound", {
		Name = rnd(),
		SoundId = spare,
		Volume = 0.34,
	}, scr)
end

local grades = {
	on = { 1.08, 0.4 },
	off = { 0.86, 0.34 },
	tab = { 1, 0.32 },
	flip = { 1.18, 0.22 },
	open = { 0.8, 0.42 },
	close = { 1.32, 0.3 },
	tap = { 1.22, 0.26 },
}

function visualsui:chime(kind)
	if not visualsui.sound or visualsui.quiet then
		return
	end

	local g = grades[kind] or grades.tap

	turnbell = turnbell % #bells + 1

	local s = bells[turnbell]

	s.PlaybackSpeed = g[1]
	s.Volume = g[2]
	s.TimePosition = 0

	pcall(s.Play, s)
end

local function stock(id)
	for _, s in next, bells do
		if s.SoundId ~= id then
			s.SoundId = id
		end
	end
end

function visualsui:settone(name)
	if not reel[name] then
		return
	end

	visualsui.tone = name

	local set = visualsui.tones[name]

	if set then
		stock(set)

		return
	end

	task.spawn(function()
		local got = seek(name)

		if visualsui.tone ~= name then
			return
		end

		visualsui.tones[name] = got or spare

		stock(visualsui.tones[name])
	end)
end

function visualsui:setsound(v)
	visualsui.sound = v and true or false
end

visualsui.cursors = {}
visualsui.cursorlist = {}
visualsui.style = nil
visualsui.cursor = false
-- also over the game with the menu closed, not only over the menu
visualsui.cursorgame = false

for _, entry in next, type(ASSETS) == "table" and {} or pulllist("cursors/") do
	local nm = string.match(entry, "([^/]+)%.png$")

	if nm and not visualsui.cursors[nm] then
		local got = pullasset(entry)

		if got then
			visualsui.cursors[nm] = got

			table.insert(visualsui.cursorlist, nm)
		end
	end
end

for _, dir in next, { "visualsui/cursors", "cursors" } do
	if slap(isfolder, dir) and type(listfiles) == "function" and type(getcustomasset) == "function" then
		for _, f in next, slap(listfiles, dir) or {} do
			local nm = string.match(string.gsub(tostring(f), "\\", "/"), "([^/]+)%.png$")

			if nm and not visualsui.cursors[nm] then
				local asset = slap(getcustomasset, dir .. "/" .. nm .. ".png")

				if type(asset) == "string" and asset ~= "" then
					visualsui.cursors[nm] = asset

					table.insert(visualsui.cursorlist, nm)
				end
			end
		end
	end
end

table.sort(visualsui.cursorlist, function(a, b)
	return string.lower(a) < string.lower(b)
end)

visualsui.style = visualsui.cursorlist[1]

local claw = new("ImageLabel", {
	Name = rnd(),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(64, 64),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Image = "",
	ScaleType = Enum.ScaleType.Stretch,
	Visible = false,
	ZIndex = 2147483647,
}, scr)

pcall(function()
	claw.ResampleMode = Enum.ResamplerMode.Pixelated
end)

-- The pixel of a 64x64 cursor that clicks. Arrows are drawn with their tip
-- on the centre; the rest click with their top-left edge or their crossing,
-- so the picture never sits over what you point at.
local HOTSPOT = {
	ChromeHearts = { 33, 40 },
	CodeGeass = { 1, 5 },
	FlowerBear = { 11, 22 },
	FlowerBearSmall = { 15, 24 },
	HelloKitty = { 15, 17 },
	SakuraFawn = { 6, 11 },
	SakuraFawnSmall = { 14, 19 },
	UnicornPusheen = { 13, 18 },
	UnicornPusheenSmall = { 18, 19 },
	WhiteAlicornPusheen = { 15, 20 },
}

local function dress(art)
	local spot = HOTSPOT[visualsui.style]

	claw.Image = art
	claw.AnchorPoint = spot and Vector2.new(spot[1] / 64, spot[2] / 64) or Vector2.new(0.5, 0.5)
end

local leash = nil
local kept = nil

local function trace()
	local p = uis:GetMouseLocation()

	claw.Position = UDim2.fromOffset(p.X, p.Y)

	-- in game, a mouse the game has locked to the centre (first person,
	-- shift lock) keeps the game's own crosshair: aiming stays as it was
	local locked = not visualsui.shown and uis.MouseBehavior == Enum.MouseBehavior.LockCenter

	if claw.Visible == locked then
		claw.Visible = not locked
	end

	-- the system arrow only where ours steps aside
	if uis.MouseIconEnabled ~= locked then
		uis.MouseIconEnabled = locked
	end
end

local function rouse()
	local art = visualsui.cursors[visualsui.style]
	local go = visualsui.cursor and (visualsui.shown or visualsui.cursorgame) and not visualsui.mobile and art ~= nil

	if go == (leash ~= nil) then
		if go then
			dress(art)
		end

		return
	end

	if go then
		kept = uis.MouseIconEnabled
		dress(art)

		trace()

		claw.Visible = true
		leash = rs.RenderStepped:Connect(trace)

		return
	end

	leash:Disconnect()
	leash = nil

	claw.Visible = false

	if kept ~= nil then
		uis.MouseIconEnabled = kept
		kept = nil
	end
end

function visualsui:setstyle(name)
	if not visualsui.cursors[name] then
		return
	end

	visualsui.style = name

	rouse()
end

function visualsui:setcursor(v)
	visualsui.cursor = v and true or false

	rouse()
end

function visualsui:setcursorgame(v)
	visualsui.cursorgame = v and true or false

	rouse()
end

function visualsui:wake()
	rouse()
end

local th = visualsui.theme

local ear, quit = nil, nil

local function capture(fn, off)
	if quit then
		local prev = quit

		quit = nil

		prev()
	end

	if ear then
		ear:Disconnect()
		ear = nil
	end

	if not fn then
		visualsui.capturing = false

		return
	end

	quit = off
	visualsui.capturing = true

	ear = uis.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.Keyboard or i.KeyCode == Enum.KeyCode.Unknown then
			return
		end

		local k = i.KeyCode

		quit = nil

		capture(nil)

		fn(k ~= Enum.KeyCode.Escape and k or nil)
	end)
end

visualsui.hotkeys = true

local hive = {}

local function hush(skip)
	for i = #hive, 1, -1 do
		local bd = hive[i]

		if bd ~= skip then
			bd:setopen(false)
		end
	end
end

local function gauge(txt, size)
	local ok, sz = pcall(function()
		return txs:GetTextSize(txt, size, Enum.Font.GothamBold, Vector2.new(9e9, 9e9))
	end)

	if ok and sz then
		return math.ceil(sz.X)
	end

	return math.ceil(#tostring(txt) * size * 0.6)
end

local deep = supports("UIShadow")

local hutch = new("CanvasGroup", {
	Name = rnd(),
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 8, 0.5, 0),
	Size = UDim2.fromOffset(0, 0),
	AutomaticSize = Enum.AutomaticSize.XY,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 900,
}, scr)

new("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 3),
}, hutch)

new("UIPadding", {
	PaddingTop = UDim.new(0, 10),
	PaddingBottom = UDim.new(0, 10),
	PaddingLeft = UDim.new(0, 10),
	PaddingRight = UDim.new(0, 10),
}, hutch)

hutch.Visible = false
hutch.GroupTransparency = 1

shrink(hutch)

local function plate(parent, order, pad, gap, lift)
	local card = new("Frame", {
		Name = rnd(),
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = th.panel,
		BackgroundTransparency = 0.16,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = order,
		ZIndex = 2,
	}, parent)

	round(card, 8)

	local edge = new("UIStroke", {
		Color = th.line,
		Thickness = 1,
		Transparency = 0.45,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	}, card)

	if lift and deep then
		new("UIShadow", {
			Color = th.bg,
			BlurRadius = UDim.new(0, lift),
			Offset = UDim2.fromOffset(0, 2),
			Spread = UDim2.fromOffset(-2, -2),
			Transparency = 0.6,
			ZIndex = -1,
		}, card)
	end

	local skin = new("Frame", {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = th.glow,
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, card)

	round(skin, 8)

	fade(skin, 90, {
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.6, 0.82),
		NumberSequenceKeypoint.new(1, 0.9),
	})

	local gloss = new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 1),
		Size = UDim2.new(1, -14, 0, 1),
		BackgroundColor3 = th.glow,
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, card)

	fade(gloss, 0, {
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})

	local hold = new("Frame", {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, card)

	if pad then
		new("UIPadding", {
			PaddingLeft = UDim.new(0, pad),
			PaddingRight = UDim.new(0, pad),
		}, hold)
	end

	if gap then
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, gap),
		}, hold)
	end

	return card, edge, skin, hold
end

local crown, _, _, crownhold = plate(hutch, 0, 14, 8, 10)

crown.Active = true

new("ImageLabel", {
	Name = rnd(),
	Size = UDim2.fromOffset(17, 17),
	BackgroundTransparency = 1,
	Image = icon("keyboard"),
	ImageColor3 = th.dim,
	ImageTransparency = 0,
	LayoutOrder = 1,
	ScaleType = Enum.ScaleType.Fit,
	ZIndex = 4,
}, crownhold)

new("TextLabel", {
	Name = rnd(),
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 20),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamMedium,
	Text = "hotkeys",
	TextColor3 = th.text,
	TextSize = 14,
	LayoutOrder = 2,
	ZIndex = 4,
}, crownhold)

local brief = 53 + gauge("hotkeys", 14)

drag(crown, hutch, 0.12)

local roost, ranks = {}, {}
local aired, span = false, nil

local function crest()
	local wide = brief

	for i = 1, #ranks do
		local p = roost[ranks[i]]

		if p and p.span and p.span > wide then
			wide = p.span
		end
	end

	if wide == span then
		return
	end

	if span == nil then
		span = wide
		crown.Size = UDim2.fromOffset(wide, 36)

		return
	end

	span = wide

	anim(crown, soft, { Size = UDim2.fromOffset(wide, 36) })
end

local function sort()
	table.sort(ranks, function(a, b)
		local pa, pb = roost[a], roost[b]

		if not pa or not pb then
			return false
		end

		if pa.tw ~= pb.tw then
			return pa.tw < pb.tw
		end

		return pa.name < pb.name
	end)

	for i = 1, #ranks do
		local p = roost[ranks[i]]

		if p then
			p.row.LayoutOrder = i
		end
	end
end

local function air()
	local want = visualsui.hotkeys and #ranks > 0

	if want == aired then
		return
	end

	aired = want

	crest()

	if want then
		hutch.Visible = true
	end

	local from = hutch.GroupTransparency
	local to = want and 0 or 1

	flow(hutch, want and 0.3 or 0.22, want and outq or inq, function(k)
		hutch.GroupTransparency = from + (to - from) * k

		if k >= 1 and not aired then
			hutch.Visible = false
		end
	end)
end

local function knob(p, on)
	on = on and true or false

	if not p.rail or p.on == on then
		return
	end

	p.on = on

	anim(p.rail, soft, { BackgroundColor3 = on and th.accent or th.bg })
	anim(p.bead, soft, {
		Position = UDim2.new(on and 0.68 or 0.32, 0, 0.5, 0),
		BackgroundColor3 = on and th.bg or Color3.new(1, 1, 1),
		BackgroundTransparency = on and 0 or 0.45,
	})
end

local function tally(p)
	local wide = 28 + p.tw

	if p.worth then
		wide = wide + p.vw + 10
	end

	local slim = math.max(24 + p.kw, 32)

	if wide == p.iw and slim == p.kwide then
		return
	end

	p.iw = wide
	p.kwide = slim
	p.span = wide + 5 + slim + (p.tumb and 37 or 0) + 4

	if p.born then
		anim(p.info, soft, { Size = UDim2.fromOffset(wide, 32) })
		anim(p.cue, soft, { Size = UDim2.fromOffset(slim, 32) })
		anim(p.row, soft, { Size = UDim2.fromOffset(p.span, 36) })
	else
		p.info.Size = UDim2.fromOffset(wide, 32)
		p.cue.Size = UDim2.fromOffset(slim, 32)
		p.row.Size = UDim2.fromOffset(p.span, 36)
	end
end

local function dawn(p)
	if p.gone or p.open then
		return
	end

	p.open = true

	p.row.Visible = true

	local from = p.row.GroupTransparency

	flow(p.row, 0.28, outq, function(k)
		p.row.GroupTransparency = from * (1 - k)
	end)
end

local function dusk(p, kill)
	if p.gone or (not p.open and not kill) then
		return
	end

	p.gone = kill and true or false
	p.open = false

	local from = p.row.GroupTransparency

	flow(p.row, 0.22, inq, function(k)
		p.row.GroupTransparency = from + (1 - from) * k

		if k < 1 then
			return
		end

		if p.gone then
			if p.row and p.row.Parent then
				p.row:Destroy()
			end

			return
		end

		p.row.Visible = false
	end)
end

local function perch(id, spec)
	local p = roost[id]

	if p then
		p.name = spec.name
		p.tw = gauge(spec.name, 14)
		p.kw = gauge(spec.key, 14)

		p.tag.Text = spec.name
		p.keyl.Text = spec.key

		if p.worth then
			p.worth.Text = spec.worth or ""
			p.vw = gauge(p.worth.Text, 14)
		end

		tally(p)
		knob(p, spec.lit)
		sort()
		crest()
		dawn(p)

		return
	end

	p = { name = spec.name, tw = gauge(spec.name, 14), kw = gauge(spec.key, 14), vw = 0 }

	p.row = new("CanvasGroup", {
		Name = rnd(),
		Size = UDim2.fromOffset(0, 36),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Visible = false,
		ZIndex = 2,
	}, hutch)

	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 5),
	}, p.row)

	new("UIPadding", {
		PaddingTop = UDim.new(0, 2),
		PaddingBottom = UDim.new(0, 2),
		PaddingLeft = UDim.new(0, 2),
		PaddingRight = UDim.new(0, 2),
	}, p.row)

	if spec.art then
		p.tumb, p.tumbedge, p.tumbskin = plate(p.row, 1)

		p.tumb.Size = UDim2.fromOffset(32, 32)

		p.rail = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(24, 13),
			BackgroundColor3 = th.bg,
			BorderSizePixel = 0,
			ZIndex = 4,
		}, p.tumb)

		new("UICorner", { CornerRadius = UDim.new(1, 0) }, p.rail)

		p.bead = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.3, 0, 0.5, 0),
			Size = UDim2.fromOffset(9, 9),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			ZIndex = 5,
		}, p.rail)

		new("UICorner", { CornerRadius = UDim.new(1, 0) }, p.bead)

		if spec.press then
			p.hit = new("ImageButton", {
				Name = rnd(),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ImageTransparency = 1,
				ZIndex = 6,
			}, p.tumb)

			conn(p.hit.MouseButton1Click, function()
				spec.press()
			end)
		end
	end

	local hold

	p.info, p.infoedge, p.infoskin, hold = plate(p.row, 2, 14, 10)

	p.tag = new("TextLabel", {
		Name = rnd(),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = spec.name,
		TextColor3 = th.text,
		TextSize = 14,
		TextTransparency = 0.05,
		LayoutOrder = 1,
		ZIndex = 4,
	}, hold)

	if spec.worth then
		p.worth = new("TextLabel", {
			Name = rnd(),
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = spec.worth,
			TextColor3 = th.dim,
			TextSize = 14,
			TextTransparency = 0.25,
			LayoutOrder = 2,
			ZIndex = 4,
		}, hold)

		p.vw = gauge(spec.worth, 14)
	end

	local perchhold

	p.cue, p.cueedge, p.cueskin, perchhold = plate(p.row, 3, 12, 0)

	p.keyl = new("TextLabel", {
		Name = rnd(),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = spec.key,
		TextColor3 = th.accent,
		TextSize = 14,
		TextTransparency = 0.1,
		LayoutOrder = 1,
		ZIndex = 4,
	}, perchhold)

	roost[id] = p

	table.insert(ranks, id)

	tally(p)
	knob(p, spec.lit)
	sort()
	air()
	crest()

	p.born = true

	task.spawn(function()
		rs.Heartbeat:Wait()

		if p.row.Parent then
			dawn(p)
		end
	end)
end

local function unperch(id)
	local p = roost[id]

	if not p then
		return
	end

	roost[id] = nil

	local at = table.find(ranks, id)

	if at then
		table.remove(ranks, at)
	end

	sort()
	air()
	crest()
	dusk(p, true)
end

local function relight(id, lit)
	local p = roost[id]

	if p then
		knob(p, lit)
	end
end

function overkeys()
	return inside(hutch, 6)
end

function visualsui:sethotkeys(v)
	visualsui.hotkeys = v and true or false

	air()
end

function visualsui:hotkeyspot(v)
	if typeof(v) == "UDim2" then
		hutch.Position = v
	end
end

crest()

visualsui.watermark = true

local function spotof(v)
	return string.format(
		"%.4f,%d,%.4f,%d",
		v.X.Scale,
		math.floor(v.X.Offset + 0.5),
		v.Y.Scale,
		math.floor(v.Y.Offset + 0.5)
	)
end

local function readspot(v)
	if type(v) ~= "string" then
		return nil
	end

	local xs, xo, ys, yo = string.match(v, "^(-?[%d%.]+),(-?%d+),(-?[%d%.]+),(-?%d+)$")

	if not xs then
		return nil
	end

	return UDim2.new(tonumber(xs), tonumber(xo), tonumber(ys), tonumber(yo))
end

local nest = new("CanvasGroup", {
	Name = rnd(),
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -8, 0, 8),
	Size = UDim2.fromOffset(0, 0),
	AutomaticSize = Enum.AutomaticSize.XY,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 900,
}, scr)

new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 8),
}, nest)

new("UIPadding", {
	PaddingTop = UDim.new(0, 10),
	PaddingBottom = UDim.new(0, 10),
	PaddingLeft = UDim.new(0, 10),
	PaddingRight = UDim.new(0, 10),
}, nest)

nest.Visible = false
nest.GroupTransparency = 1

shrink(nest)

-- The watermark: one card rather than two pills. Who you are and whose
-- script this is on the top line, the numbers that keep changing on the one
-- below, split by hairlines that fade out at both ends.
local sign = new("Frame", {
	Name = rnd(),
	Active = true,
	Size = UDim2.fromOffset(0, 0),
	AutomaticSize = Enum.AutomaticSize.XY,
	BackgroundColor3 = th.panel,
	BackgroundTransparency = 0.14,
	BorderSizePixel = 0,
	LayoutOrder = 1,
	ZIndex = 2,
}, nest)

round(sign, 13)

new("UIStroke", {
	Color = th.line,
	Thickness = 1,
	Transparency = 0.4,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	LineJoinMode = Enum.LineJoinMode.Round,
}, sign)

if deep then
	new("UIShadow", {
		Color = th.bg,
		BlurRadius = UDim.new(0, 16),
		Offset = UDim2.fromOffset(0, 3),
		Spread = UDim2.fromOffset(-3, -3),
		Transparency = 0.5,
		ZIndex = -1,
	}, sign)
end

-- the wash and the rim light, the same material as every other surface
local wash = new("Frame", {
	Name = rnd(),
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = th.glow,
	BackgroundTransparency = 0.88,
	BorderSizePixel = 0,
	ZIndex = 2,
}, sign)

round(wash, 13)

fade(wash, 90, {
	NumberSequenceKeypoint.new(0, 0.34),
	NumberSequenceKeypoint.new(0.55, 0.82),
	NumberSequenceKeypoint.new(1, 0.95),
})

local rim = new("Frame", {
	Name = rnd(),
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 1),
	Size = UDim2.new(1, -26, 0, 1),
	BackgroundColor3 = th.glow,
	BackgroundTransparency = 0.52,
	BorderSizePixel = 0,
	ZIndex = 3,
}, sign)

fade(rim, 0, {
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 0.05),
	NumberSequenceKeypoint.new(1, 1),
})

-- The content lives in its own frame. The wash above is sized to fill the
-- card, and a list layout on the card itself would take it for a row, which
-- makes an auto-sized card chase its own child until it covers the screen.
local body = new("Frame", {
	Name = rnd(),
	Size = UDim2.fromOffset(0, 0),
	AutomaticSize = Enum.AutomaticSize.XY,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 4,
}, sign)

new("UIPadding", {
	PaddingTop = UDim.new(0, 9),
	PaddingBottom = UDim.new(0, 9),
	PaddingLeft = UDim.new(0, 12),
	PaddingRight = UDim.new(0, 12),
}, body)

new("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 7),
}, body)

local function strip(order, height, gap)
	local row = new("Frame", {
		Name = rnd(),
		Size = UDim2.fromOffset(0, height),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = order,
		ZIndex = 4,
	}, body)

	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, gap),
	}, row)

	return row
end

local function hairline(parent, order, height)
	local rail = new("Frame", {
		Name = rnd(),
		Size = UDim2.fromOffset(1, height),
		BackgroundColor3 = th.glow,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		LayoutOrder = order,
		ZIndex = 4,
	}, parent)

	fade(rail, 90, {
		NumberSequenceKeypoint.new(0, 0.95),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 0.95),
	})

	return rail
end

-- ------------------------------------------------------------- who you are
local top = strip(1, 24, 9)

local face = new("ImageLabel", {
	Name = rnd(),
	Size = UDim2.fromOffset(24, 24),
	BackgroundColor3 = th.bg,
	BackgroundTransparency = 0.25,
	BorderSizePixel = 0,
	Image = visualsui.logo ~= "" and visualsui.logo
		or string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", lp.UserId),
	ImageTransparency = 0.02,
	LayoutOrder = 1,
	ScaleType = Enum.ScaleType.Crop,
	ZIndex = 5,
}, top)

new("UICorner", { CornerRadius = UDim.new(1, 0) }, face)

new("UIStroke", {
	Color = th.line,
	Thickness = 1,
	Transparency = 0.3,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, face)

local whotag = new("TextLabel", {
	Name = rnd(),
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 20),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = lp.Name,
	TextColor3 = th.text,
	TextSize = 14,
	LayoutOrder = 2,
	ZIndex = 5,
}, top)

hairline(top, 3, 16)

new("ImageLabel", {
	Name = rnd(),
	Size = UDim2.fromOffset(14, 14),
	BackgroundTransparency = 1,
	Image = icon("code"),
	ImageColor3 = th.dim,
	LayoutOrder = 4,
	ScaleType = Enum.ScaleType.Fit,
	ZIndex = 5,
}, top)

local brandtag = new("TextLabel", {
	Name = rnd(),
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 18),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamMedium,
	Text = "inertiahub.xyz",
	TextColor3 = th.dim,
	TextSize = 12,
	LayoutOrder = 5,
	ZIndex = 5,
}, top)

function visualsui:setwatermarktext(text)
	brandtag.Text = tostring(text or "")
end

-- ------------------------------------------------------- what keeps moving
local bottom = strip(2, 18, 8)

local function readout(order, art, txt, room)
	new("ImageLabel", {
		Name = rnd(),
		Size = UDim2.fromOffset(13, 13),
		BackgroundTransparency = 1,
		Image = icon(art),
		ImageColor3 = th.dim,
		LayoutOrder = order,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 5,
	}, bottom)

	return new("TextLabel", {
		Name = rnd(),
		Size = UDim2.fromOffset(room, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = txt,
		TextColor3 = th.text,
		TextSize = 13,
		TextTransparency = 0.1,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = order + 1,
		ZIndex = 5,
	}, bottom)
end

local ratetag = readout(1, "layers", "0", gauge("999", 13))

hairline(bottom, 3, 12)

local lagtag = readout(4, "wifi", "0ms", gauge("999ms", 13))

hairline(bottom, 6, 12)

local timetag = readout(7, "clock", "00:00", gauge("00:00", 13))

drag(sign, nest, 0.12)

local keyszone = overkeys

function overkeys()
	return (keyszone and keyszone()) or inside(nest, 6)
end

local marked = false

local function flare()
	local want = visualsui.watermark and true or false

	if want == marked then
		return
	end

	marked = want

	if want then
		nest.Visible = true
	end

	local from = nest.GroupTransparency
	local to = want and 0 or 1

	flow(nest, want and 0.3 or 0.22, want and outq or inq, function(k)
		nest.GroupTransparency = from + (to - from) * k

		if k >= 1 and not marked then
			nest.Visible = false
		end
	end)
end

local meter = nil

pcall(function()
	meter = cloneref(game:GetService("Stats"))
end)

local function lagof()
	if not meter then
		return 0
	end

	local ok, v = pcall(function()
		return meter.Network.ServerStatsItem["Data Ping"]:GetValue()
	end)

	if not ok or type(v) ~= "number" then
		return 0
	end

	return math.floor(v + 0.5)
end

local beats, drift = 0, 0

conn(rs.RenderStepped, function(dt)
	beats += 1
	drift += dt

	if drift < 0.5 then
		return
	end

	local rate = math.floor(beats / drift + 0.5)

	beats, drift = 0, 0

	if not nest.Visible then
		return
	end

	if whotag.Text ~= lp.Name then
		whotag.Text = lp.Name
	end

	ratetag.Text = tostring(rate)
	lagtag.Text = tostring(lagof()) .. "ms"
	timetag.Text = os.date("%H:%M")
end)

visualsui:hook("menu|hotkeyspot", "string", function()
	return spotof(hutch.Position)
end, function(v)
	local p = readspot(v)

	if p then
		hutch.Position = p
	end
end)

visualsui:hook("menu|markspot2", "string", function()
	return spotof(nest.Position)
end, function(v)
	local p = readspot(v)

	if p then
		nest.Position = p
	end
end)

function visualsui:setwatermark(v)
	visualsui.watermark = v and true or false

	flare()
end

function visualsui:watermarkspot(v)
	if typeof(v) == "UDim2" then
		nest.Position = v
	end
end

timetag.Text = os.date("%H:%M")

flare()

visualsui.opener = visualsui.mobile

local knock = new("ImageButton", {
	Name = rnd(),
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -10, 0.5, 0),
	Size = UDim2.fromOffset(54, 54),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", lp.UserId),
	ImageColor3 = Color3.new(1, 1, 1),
	ScaleType = Enum.ScaleType.Fit,
	Visible = visualsui.opener,
	Active = true,
	ZIndex = 950,
}, scr)

drag(knock, knock, 0.1)

local rap, rapt = nil, 0

conn(knock.InputBegan, function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		rap, rapt = i.Position, os.clock()
	end
end)

conn(knock.InputEnded, function(i)
	if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local from = rap

	rap = nil

	if not from or locks > 0 then
		return
	end

	if (i.Position - from).Magnitude > 8 or os.clock() - rapt > 0.7 then
		return
	end

	for _, w in next, visualsui.wins do
		pcall(function()
			w:toggle()
		end)
	end
end)

visualsui:hook("menu|openerspot", "string", function()
	return spotof(knock.Position)
end, function(v)
	local p = readspot(v)

	if p then
		knock.Position = p
	end
end)

function visualsui:setopener(v)
	visualsui.opener = v and true or false

	knock.Visible = visualsui.opener
end

function visualsui:openerspot(v)
	if typeof(v) == "UDim2" then
		knock.Position = v
	end
end

function visualsui:openericon(v)
	knock.Image = tostring(v)
end

local shelf = new("Frame", {
	Name = rnd(),
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.new(0, 18, 0, 18),
	Size = UDim2.fromOffset(252, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	ZIndex = 400,
}, scr)

shrink(shelf)

local puffs = {}
local puffn = 0

local function stack(fresh)
	local y = 0

	for i = 1, #puffs do
		local p = puffs[i]
		local card = p.husk

		if card and card.Parent then
			local at = UDim2.fromOffset(0, y)

			if p == fresh or p.spot == nil then
				card.Position = at
			elseif p.spot ~= y then
				anim(card, soft, { Position = at })
			end

			p.spot = y

			y += (p.tall or card.Size.Y.Offset) + 8
		end
	end
end

visualsui.notices = true
visualsui.noticecap = 5

function visualsui:setnotices(v)
	visualsui.notices = v and true or false
end

function visualsui:notify(cfg)
	if not visualsui.alive or not visualsui.notices then
		return
	end

	cfg = params(cfg, {
		title = "visuals",
		text = "",
		icon = "info",
		life = 5,
		tone = nil,
	})

	local th = visualsui.theme
	local wide = 252
	local head = tostring(cfg.title or "")
	local body = tostring(cfg.text or "")
	-- monochrome unless a caller asks for a tone, and then only the glyph wears it
	local tint = (typeof(cfg.tone) == "Color3") and cfg.tone or th.text
	local rows = 0

	if body ~= "" then
		rows = math.clamp(math.ceil(gauge(body, 11) / (wide - 58)), 1, 4)
	end

	local tall = (rows > 0) and (38 + rows * 13 + 4) or 38

	puffn += 1

	local husk = new("CanvasGroup", {
		Name = rnd(),
		Size = UDim2.fromOffset(wide, tall),
		BackgroundColor3 = th.panel,
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		LayoutOrder = puffn,
		ZIndex = 400,
	}, shelf)

	round(husk, math.min(14, tall / 2))

	new("UIStroke", {
		Color = th.line,
		Thickness = 1,
		Transparency = 0.4,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	}, husk)

	visualsui.glass(husk, math.min(14, tall / 2), { lift = 16, shade = th.bg, washTransparency = 0.9, z = 400 })

	-- the glyph sits on a small glass disc, centred on the first line
	local disc = new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0, 19),
		Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = th.glow,
		BackgroundTransparency = 0.84,
		BorderSizePixel = 0,
		ZIndex = 402,
	}, husk)

	new("UICorner", { CornerRadius = UDim.new(1, 0) }, disc)

	new("UIStroke", {
		Color = th.glow,
		Thickness = 1,
		Transparency = 0.7,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, disc)

	new("ImageLabel", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1,
		Image = icon(cfg.icon),
		ImageColor3 = tint,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 403,
	}, disc)

	new("TextLabel", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromOffset(42, 10),
		Size = UDim2.new(1, -54, 0, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = head,
		TextColor3 = th.text,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 402,
	}, husk)

	if rows > 0 then
		new("TextLabel", {
			Name = rnd(),
			Position = UDim2.fromOffset(42, 28),
			Size = UDim2.new(1, -54, 0, rows * 13),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = body,
			TextColor3 = th.dim,
			TextSize = 11,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			ZIndex = 402,
		}, husk)
	end

	-- time left, as a hairline under the card that runs down to nothing
	local fuse = new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -4),
		Size = UDim2.new(1, -28, 0, 1),
		BackgroundColor3 = th.glow,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		ZIndex = 403,
	}, husk)

	local shut = new("ImageButton", {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ImageTransparency = 1,
		ZIndex = 404,
	}, husk)

	local push = new("UIScale", { Scale = 0.96 }, husk)

	local function drift(inn, done)
		local a0 = husk.GroupTransparency
		local a1 = inn and 0 or 1
		local s0 = push.Scale
		local s1 = inn and 1 or 0.97

		flow(husk, inn and 0.30 or 0.16, inn and outq or inq, function(k)
			husk.GroupTransparency = a0 + (a1 - a0) * k
			push.Scale = s0 + (s1 - s0) * k

			if k >= 1 and done then
				done()
			end
		end)
	end

	local puff = { husk = husk, tall = tall, dead = false }

	function puff:close()
		if puff.dead then
			return
		end

		puff.dead = true

		drift(false, function()
			local at = table.find(puffs, puff)

			if at then
				table.remove(puffs, at)
			end

			husk:Destroy()

			stack()
		end)
	end

	table.insert(puffs, puff)

	stack(puff)

	local seen = 0
	local cap = math.max(visualsui.noticecap, 1)

	for i = #puffs, 1, -1 do
		local p = puffs[i]

		if not p.dead then
			seen += 1

			if seen > cap then
				p:close()
			end
		end
	end

	conn(shut.MouseButton1Click, function()
		visualsui:chime("tap")

		puff:close()
	end)

	conn(shut.MouseEnter, function()
		anim(disc, soft, { BackgroundTransparency = 0.7 })
	end)

	conn(shut.MouseLeave, function()
		anim(disc, soft, { BackgroundTransparency = 0.84 })
	end)

	drift(true)

	local life = math.max(tonumber(cfg.life) or 5, 0.4)

	anim(fuse, TweenInfo.new(life, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 1) })

	task.delay(life, function()
		puff:close()
	end)

	return puff
end

-- The link buttons in the window header: one per entry, laid out right to
-- left from the close button. Entries are
-- { image = content id, tip = text, callback = fn }.
visualsui.linklist = {}

function visualsui.linkhead(head)
	for _, b in next, head.links do
		b:Destroy()
	end

	table.clear(head.links)

	for n, l in next, visualsui.linklist do
		-- the artwork is drawn centred on its own canvas at one optical size, so
		-- every glyph takes the same box and none needs an offset
		local b, art = head.button(head.quest, 28, l.image or "", 17)

		b.Position = UDim2.new(1, -((n - 1) * 32), 0, 14)
		art.ImageColor3 = visualsui.theme.text
		art.ImageTransparency = 0.18

		conn(b.MouseEnter, function()
			anim(art, soft, { ImageTransparency = 0 })
		end)

		conn(b.MouseLeave, function()
			anim(art, soft, { ImageTransparency = 0.18 })
		end)

		conn(b.MouseButton1Click, function()
			visualsui:chime("tap")

			if type(l.callback) == "function" then
				task.spawn(l.callback)
			end
		end)

		head.links[n] = b
	end
end

function visualsui:setlinks(list)
	visualsui.linklist = type(list) == "table" and list or {}

	for _, head in next, visualsui.heads or {} do
		visualsui.linkhead(head)
	end
end

-- Everything the window draws with hangs off one table: the chunk was at
-- Luau's two-hundred-local ceiling, and a file-scope local each would put
-- it over.
local ui = {}

-- ============================================================= deport ui ====
-- The menu itself: a single rounded window with a people-bar at the bottom
-- for the feature groups, a capsule of sub-pages under the title, and cards
-- in one or two columns under that. Everything above this line is the
-- machinery the window sits on - theme, fonts, config pool, assets, sounds,
-- cursor, watermark, hotkey list, notifications - and is untouched by it.

ui.sheet = visualsui.sheet

function ui.palette()
	return visualsui.theme
end

-- A row is the one shape every control shares: a ui.caption on the left, the
-- control itself hugging the right edge. Height is the only thing that
-- varies, so it is the only thing a caller passes.
-- Every row keeps the same inset, so captions and controls share one left and
-- one right edge down a card.
ui.INSET = 10

function ui.rowframe(parent, height, order, flush)
	local row = new("Frame", {
		Name = rnd(),
		Size = UDim2.new(1, 0, 0, height or 26),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = order or 1,
	}, parent)

	if not flush then
		new("UIPadding", {
			PaddingLeft = UDim.new(0, ui.INSET),
			PaddingRight = UDim.new(0, ui.INSET),
		}, row)
	end

	return row
end

function ui.caption(row, text, width)
	local th = ui.palette()

	return new("TextLabel", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = width or UDim2.new(1, -96, 0, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = tostring(text or ""),
		TextColor3 = th.text,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
end

-- the small dark rounded field every value sits in
function ui.pill(parent, props)
	local th = ui.palette()
	local p = {
		Name = rnd(),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(80, 22),
		BackgroundColor3 = th.head,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
	}

	for k, v in next, props or {} do
		p[k] = v
	end

	local f = new("Frame", p, parent)

	round(f, 7)

	return f
end

function ui.hitbox(parent, props)
	local p = {
		Name = rnd(),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		ZIndex = 6,
	}

	for k, v in next, props or {} do
		p[k] = v
	end

	return new("TextButton", p, parent)
end

-- hover that reads as a press target without moving anything
function ui.warmth(button, target, rest, lit)
	conn(button.MouseEnter, function()
		anim(target, glide, { BackgroundColor3 = lit })
	end)

	conn(button.MouseLeave, function()
		anim(target, glide, { BackgroundColor3 = rest })
	end)
end

-- The watermark plate's recipe, reusable: a translucent body, a soft
-- top-down wash, a one-pixel gloss along the top rim, and a shadow where the
-- client can draw one. Roblox cannot blur what is behind a frame, so this is
-- as close to liquid glass as the engine gets - and it keeps every surface
-- (window, cards, dropdowns) reading as the same material.
function ui.glass(panel, radius, opts)
	opts = opts or {}

	local corner = tonumber(radius) or 12
	local wash = typeof(opts.wash) == "Color3" and opts.wash or th.glow
	local shade = typeof(opts.shade) == "Color3" and opts.shade or th.bg
	local z = tonumber(opts.z) or 1

	local skin = new("Frame", {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = wash,
		BackgroundTransparency = tonumber(opts.washTransparency) or 0.86,
		BorderSizePixel = 0,
		ZIndex = z,
	}, panel)

	round(skin, corner)

	fade(skin, 90, {
		NumberSequenceKeypoint.new(0, 0.32),
		NumberSequenceKeypoint.new(0.55, 0.8),
		NumberSequenceKeypoint.new(1, 0.94),
	})

	local gloss = new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 1),
		Size = UDim2.new(1, -math.max(corner * 2, 14), 0, 1),
		BackgroundColor3 = wash,
		BackgroundTransparency = tonumber(opts.glossTransparency) or 0.58,
		BorderSizePixel = 0,
		ZIndex = z,
	}, panel)

	fade(gloss, 0, {
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.05),
		NumberSequenceKeypoint.new(1, 1),
	})

	if (tonumber(opts.lift) or 0) > 0 and deep then
		new("UIShadow", {
			Color = shade,
			BlurRadius = UDim.new(0, tonumber(opts.lift)),
			Offset = UDim2.fromOffset(0, 2),
			Spread = UDim2.fromOffset(-2, -2),
			Transparency = tonumber(opts.shadow) or 0.55,
			ZIndex = -1,
		}, panel)
	end

	local sheen

	if opts.sheen then
		sheen = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(-0.4, 0.5),
			Size = UDim2.new(0.32, 0, 2, 0),
			Rotation = 18,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = z,
		}, panel)

		fade(sheen, 0, {
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.84),
			NumberSequenceKeypoint.new(1, 1),
		})
	end

	return { skin = skin, gloss = gloss, sheen = sheen }
end

-- One pass of light across a glass surface, the way an iOS sheet catches the
-- room as it comes up. Called on open only; it stops itself.
function ui.sheen(glass, dur)
	local sheen = glass and glass.sheen

	if not sheen or not sheen.Parent then
		return
	end

	sheen.Visible = true
	sheen.Position = UDim2.fromScale(-0.4, 0.5)

	flow(sheen, dur or 0.7, outq, function(k)
		sheen.Position = UDim2.fromScale(-0.4 + k * 1.8, 0.5)

		if k >= 1 then
			sheen.Visible = false
		end
	end)
end

-- A floating layer: the dropdown lists, the colour panels, the context
-- menus. One is open at a time and a click anywhere else shuts it, which is
-- what sky/skyzone above already arrange.
-- A glass highlight that slides to whichever item is selected, so a change of
-- tab reads as one object moving instead of two things swapping.
function ui.glider(parent, radius, z)
	local th = ui.palette()

	local frame = new("Frame", {
		Name = rnd(),
		BackgroundColor3 = th.glow,
		BackgroundTransparency = 0.78,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = z or 1,
	}, parent)

	round(frame, radius)

	new("UIStroke", {
		Color = th.glow,
		Thickness = 1,
		Transparency = 0.6,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, frame)

	fade(frame, 90, {
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 0.55),
	})

	local rim = new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 1),
		Size = UDim2.new(1, -radius * 1.6, 0, 1),
		BackgroundColor3 = th.text,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		ZIndex = (z or 1) + 1,
	}, frame)

	fade(rim, 0, {
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1),
	})

	local api = { frame = frame, placed = false }

	function api.to(position, size)
		if not api.placed then
			-- the first placement is a cut, not a slide in from nowhere
			frame.Position = position
			frame.Size = size
			frame.Visible = true
			api.placed = true

			return
		end

		anim(frame, follow, { Position = position, Size = size })
	end

	function api.hide()
		frame.Visible = false
		api.placed = false
	end

	return api
end

-- Put every open picker away: drop-downs, colour panels, key panels, menus.
function ui.closeall()
	hush()
	sink()
end

function ui.floater(width, height)
	local th = ui.palette()

	local hull = new("CanvasGroup", {
		Name = rnd(),
		Size = UDim2.fromOffset(width, height),
		BackgroundColor3 = ui.sheet.bg,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Visible = false,
		ZIndex = 400,
	}, scr)

	round(hull, 12)

	new("UIStroke", {
		Color = th.line,
		Thickness = 1,
		Transparency = 0.2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, hull)

	ui.glass(hull, 12, { z = 0 })

	shrink(hull)
	visualsui.floating[hull] = true

	return hull
end

local function liveview()
	return workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
end

-- The last word on where a panel lands: never closer than 8 to the top or the
-- left, never past the viewport on the other side. A trigger sitting on the
-- right edge would otherwise keep its list hanging off the screen even after
-- the flip.
local function settle(hull, x, y, want)
	local view = liveview()
	local maxx = math.max(8, (view.X - 12) / sc - want.X)
	local maxy = math.max(8, (view.Y - 12) / sc - want.Y)

	-- Everything above works in absolute screen coordinates, but a Position is
	-- relative to the ScreenGui, whose own AbsolutePosition is not zero (it
	-- sits 58 px up when it ignores the top bar). Without this the panel
	-- lands that far above whatever it was opened from.
	local origin = scr.AbsolutePosition

	hull.Position = UDim2.fromOffset(
		math.clamp(math.floor(x), 8, math.floor(maxx)) - origin.X,
		math.clamp(math.floor(y), 8, math.floor(maxy)) - origin.Y
	)
end

-- Put a ui.floater at a point, flipped when it would run off the bottom or the
-- right edge. The panel is laid out at height zero and grown by ui.reveal, so
-- its measured height is nothing at this point: the caller says how tall it is
-- going to be, otherwise the vertical flip never fires and the panel opens off
-- the bottom of the screen.
function ui.place(hull, x, y, wide, tall)
	local view = liveview()
	local want = Vector2.new(wide or hull.AbsoluteSize.X / sc, tall or hull.AbsoluteSize.Y / sc)

	if (y + want.Y) * sc > view.Y - 12 then
		y -= want.Y
	end

	if (x + want.X) * sc > view.X - 12 then
		x -= want.X
	end

	settle(hull, x, y, want)
end

-- Put a ui.floater on screen next to the control that opened it, flipped when
-- there is no room below or to the right. `tall` is the height the panel is
-- about to be revealed at, for the same reason as in ui.place.
function ui.anchor(hull, at, size, gap, tall)
	local view = liveview()
	local want = Vector2.new(hull.AbsoluteSize.X / sc, tall or hull.AbsoluteSize.Y / sc)
	local x = at.X
	local y = at.Y + size.Y + (gap or 6)

	if (y + want.Y) * sc > view.Y - 12 then
		y = at.Y - want.Y - (gap or 6)
	end

	if (x + want.X) * sc > view.X - 12 then
		x = at.X + size.X - want.X
	end

	settle(hull, x, y, want)
end

function ui.reveal(hull, tall)
	-- The panel is laid out at its final size at once and only fades and
	-- slides in. Growing its height made the engine re-lay out the list inside
	-- it on every frame, which is what made opening a drop-down stutter.
	hull.Size = UDim2.new(hull.Size.X.Scale, hull.Size.X.Offset, 0, tall)

	local home = hull.Position

	hull.Position = UDim2.new(home.X.Scale, home.X.Offset, home.Y.Scale, home.Y.Offset - 6)
	hull.GroupTransparency = 1
	hull.Visible = true

	hull:SetAttribute("home", nil)

	anim(hull, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 })
	anim(hull, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = home })
end

function ui.conceal(hull, done)
	anim(hull, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { GroupTransparency = 1 })

	task.delay(0.13, function()
		if hull.Parent then
			hull.Visible = false
		end

		if done then
			done()
		end
	end)
end

-- A scrolling list with the library's own wheel handling and no visible bar.
function ui.scroller(parent, props)
	local p = {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ClipsDescendants = true,
		ScrollingEnabled = true,
		ElasticBehavior = Enum.ElasticBehavior.Never,
	}

	for k, v in next, props or {} do
		p[k] = v
	end

	local sf = new("ScrollingFrame", p, parent)

	return sf
end

-- -------------------------------------------------------------- window ----
-- Display names come from the script in caps ("VISUALS"); the bar wants them
-- the way the design draws them.
function ui.titlecase(s)
	s = tostring(s or "")

	-- short names are acronyms (ESP, FX, UI): title-casing would make "Esp"
	if s ~= string.upper(s) or #s <= 3 then
		return s
	end

	return (string.gsub(string.lower(s), "(%a)([%w']*)", function(a, b)
		return string.upper(a) .. b
	end))
end


function visualsui:window(cfg)
	cfg = params(cfg, {
		size = UDim2.fromOffset(860, 600),
		bind = "Delete",
		title = "Deport",
		build = "",
	})

	local th = ui.palette()
	local win = {
		list = {},
		subs = {},
		open = true,
		size = cfg.size,
		bind = typeof(cfg.bind) == "EnumItem" and cfg.bind or Enum.KeyCode[tostring(cfg.bind)] or Enum.KeyCode.Delete,
	}

	table.insert(visualsui.wins, win)

	-- The shell is a CanvasGroup so the whole menu fades as one surface; at
	-- rest its children move to a plain twin, so text keeps its edges.
	local shell = new("CanvasGroup", {
		Name = rnd(),
		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = win.size,
		BackgroundColor3 = th.bg,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		GroupTransparency = 1,
		Visible = false,
		ZIndex = 50,
	}, scr)

	round(shell, 16)

	new("UIStroke", {
		Color = th.line,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	}, shell)

	-- The shell wears the same glass as the watermark: a wash over the deep
	-- navy body and one gloss line under the header.
	local shellglass = ui.glass(shell, 16, { lift = 30, shade = th.bg, washTransparency = 0.9, sheen = true, z = 0 })

	shrink(shell)

	-- On a phone the shell is drawn through a UIScale below one, and a canvas
	-- texture softens text there; the plain twin keeps it sharp. On a desktop
	-- the scale is one, nothing is soft, and shuffling the window's children
	-- between two parents on every open and close is what made it stutter.
	local twin = (sc ~= 1) and crisp(shell) or nil

	win.shell = shell
	win.root = shell
	visualsui.themeroots[shell] = true
	maskadd(shell)

	if twin then
		visualsui.themeroots[twin] = true
		maskadd(twin)
	end

	-- --------------------------------------------------------- header ----
	local header = new("Frame", {
		Name = rnd(),
		Active = true,
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, shell)

	new("Frame", {
		Name = rnd(),
		Position = UDim2.fromOffset(0, 55),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = th.line,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, shell)

	-- Snow, drifting down the header and thinning out as it reaches the line.
	-- One RenderStepped pass over sixteen flakes: no tweens, no per-flake
	-- connections, and nothing runs while the menu is shut. Each flake fades
	-- in over its first few pixels and out over its last few, so nothing pops
	-- into existence and nothing lands hard on the line.
	do
		local sky = new("Frame", {
			Name = rnd(),
			Size = UDim2.new(1, 0, 0, 55),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 3,
		}, shell)

		local FLAKES, FLOOR = 16, 55
		local flakes = {}

		local function respawn(f, fresh)
			f.x = math.random()
			f.y = fresh and math.random() * FLOOR or -math.random(2, 14)
			f.speed = 10 + math.random() * 12
			f.sway = 2.5 + math.random() * 5.5
			f.phase = math.random() * 6.28
			f.size = math.random(2, 3)
			f.base = 0.3 + math.random() * 0.4

			f.frame.Size = UDim2.fromOffset(f.size, f.size)
		end

		for i = 1, FLAKES do
			local f = {}

			f.frame = new("Frame", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = th.text,
				BorderSizePixel = 0,
				ZIndex = 3,
			}, sky)

			new("UICorner", { CornerRadius = UDim.new(1, 0) }, f.frame)

			respawn(f, true)
			flakes[i] = f
		end

		local clock = 0

		conn(rs.RenderStepped, function(dt)
			if not win.open or not shell.Visible then
				return
			end

			-- a hitch must not teleport the flakes; a long frame is simply a
			-- long frame, the drift keeps its speed afterwards
			dt = math.min(dt, 0.05)
			clock += dt

			for _, f in next, flakes do
				f.y += f.speed * dt

				if f.y >= FLOOR then
					respawn(f, false)
				end

				local rise = math.clamp(f.y / 7, 0, 1)
				local fall = math.clamp((FLOOR - f.y) / 5, 0, 1)
				local alpha = rise * fall

				-- two slow sine waves instead of one: a single wave reads as a
				-- metronome, two make the drift look like air
				local drift = math.sin(clock * 0.8 + f.phase) * f.sway
					+ math.sin(clock * 0.31 + f.phase * 1.7) * f.sway * 0.35

				f.frame.Position = UDim2.new(f.x, drift, 0, f.y)
				f.frame.BackgroundTransparency = math.clamp(1 - alpha * (1 - f.base), 0, 1)
			end
		end)
	end

	local avatar = new("ImageLabel", {
		Name = rnd(),
		Position = UDim2.fromOffset(16, 12),
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = th.head,
		BorderSizePixel = 0,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 5,
	}, header)

	new("UICorner", { CornerRadius = UDim.new(1, 0) }, avatar)

	new("UIStroke", {
		Color = th.line,
		Thickness = 1,
		Transparency = 0.35,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, avatar)

	task.spawn(function()
		local ok, image = pcall(function()
			return plrs:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)

		if ok and avatar.Parent then
			avatar.Image = image
		end
	end)

	-- the online badge sits on the avatar's lower-right edge, not inside the
	-- face; the ring is the header's own colour so it cuts a clean hole
	local dot = new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(46, 42),
		Size = UDim2.fromOffset(9, 9),
		BackgroundColor3 = th.accent,
		BorderSizePixel = 0,
		ZIndex = 6,
	}, header)

	new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)

	new("UIStroke", { Color = th.bg, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, dot)

	new("TextLabel", {
		Name = rnd(),
		Position = UDim2.fromOffset(60, 10),
		Size = UDim2.fromOffset(220, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = lp.Name,
		TextColor3 = th.text,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 5,
	}, header)

	new("ImageLabel", {
		Name = rnd(),
		Position = UDim2.fromOffset(60, 30),
		Size = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1,
		Image = icon("box"),
		ImageColor3 = th.dim,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 5,
	}, header)

	local buildtag = new("TextLabel", {
		Name = rnd(),
		Position = UDim2.fromOffset(76, 28),
		Size = UDim2.fromOffset(220, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = tostring(cfg.build or ""),
		TextColor3 = th.dim,
		TextSize = 11,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 5,
	}, header)

	function win:setbuild(text)
		buildtag.Text = tostring(text or "")
	end

	-- the brand: a figure stepping through a door, then the name
	local brand = new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 15),
		Size = UDim2.fromOffset(112, 24),
		BackgroundTransparency = 1,
		ZIndex = 5,
	}, header)

	new("TextLabel", {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = tostring(cfg.title),
		TextColor3 = th.text,
		TextSize = 17,
		ZIndex = 5,
	}, brand)

	-- the right-hand cluster: the link buttons the script fills in, then close
	local quest = new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 0),
		Size = UDim2.new(0, 400, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 6,
	}, header)

	-- A bare glyph with nothing behind it; a round glass disc fades in under
	-- the pointer. Every header button is made here so they all behave alike.
	local function headbutton(parent, width, glyph, size)
		local b = new("TextButton", {
			Name = rnd(),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 14),
			Size = UDim2.fromOffset(width, width),
			BackgroundColor3 = th.glow,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			ZIndex = 6,
		}, parent)

		round(b, width)

		local edge = new("UIStroke", {
			Color = th.glow,
			Thickness = 1,
			Transparency = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, b)

		local art = new("ImageLabel", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(size or 14, size or 14),
			BackgroundTransparency = 1,
			Image = glyph or "",
			ImageColor3 = th.dim,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 7,
		}, b)

		conn(b.MouseEnter, function()
			anim(b, soft, { BackgroundTransparency = 0.86 })
			anim(edge, soft, { Transparency = 0.6 })
			anim(art, soft, { ImageColor3 = th.text })
		end)

		conn(b.MouseLeave, function()
			anim(b, soft, { BackgroundTransparency = 1 })
			anim(edge, soft, { Transparency = 1 })
			anim(art, soft, { ImageColor3 = th.dim })
		end)

		return b, art
	end

	local head = { quest = quest, links = {}, button = headbutton }

	visualsui.heads = visualsui.heads or {}
	table.insert(visualsui.heads, head)
	visualsui.linkhead(head)

	-- -------------------------------------------------- sub-page capsule ----
	local capsule = new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 68),
		Size = UDim2.fromOffset(0, 34),
		BackgroundColor3 = th.panel,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 4,
	}, shell)

	round(capsule, 11)

	new("UIStroke", {
		Color = th.line,
		Thickness = 1,
		Transparency = 0.35,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, capsule)

	ui.glass(capsule, 11, { lift = 10, washTransparency = 0.9, z = 1 })

	local capglider = ui.glider(capsule, 8, 2)

	-- --------------------------------------------------------- content ----
	local board = new("Frame", {
		Name = rnd(),
		Position = UDim2.fromOffset(18, 116),
		Size = UDim2.new(1, -36, 1, -190),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, shell)

	-- --------------------------------------------------------- backdrop ----
	-- The space behind the cards is a surface of its own: a faint blue wash
	-- from the header down, a hairline grid, and a soft floor above the dock.
	-- Everything here is static, so a page change never re-lays it out.
	do
		local backdrop = new("Frame", {
			Name = rnd(),
			Position = UDim2.fromOffset(0, 56),
			Size = UDim2.new(1, 0, 1, -118),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 2,
		}, shell)

		local air = new("Frame", {
			Name = rnd(),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = th.glow,
			BackgroundTransparency = 0.9,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, backdrop)

		new("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.55),
				NumberSequenceKeypoint.new(0.5, 0.94),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}, air)

		-- a hairline grid, thin enough to read as texture and not as furniture
		local cols, rows = 16, 10

		for i = 1, cols - 1 do
			new("Frame", {
				Name = rnd(),
				Position = UDim2.fromScale(i / cols, 0),
				Size = UDim2.new(0, 1, 1, 0),
				BackgroundColor3 = th.line,
				BackgroundTransparency = 0.94,
				BorderSizePixel = 0,
				ZIndex = 2,
			}, backdrop)
		end

		for i = 1, rows - 1 do
			new("Frame", {
				Name = rnd(),
				Position = UDim2.fromScale(0, i / rows),
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = th.line,
				BackgroundTransparency = 0.94,
				BorderSizePixel = 0,
				ZIndex = 2,
			}, backdrop)
		end

		-- a soft floor, so the cards do not float over the dock
		local floor = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 46),
			BackgroundColor3 = th.bg,
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, backdrop)

		new("UIGradient", {
			Rotation = 270,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0.2),
			}),
		}, floor)
	end

	-- ------------------------------------------------------ bottom bar ----
	-- The groups sit on one glass dock; a highlight slides to the open one.
	local bar = new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundTransparency = 1,
		ZIndex = 4,
	}, shell)

	local dock = new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, -2),
		Size = UDim2.fromOffset(8, 42),
		BackgroundColor3 = th.panel,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, bar)

	round(dock, 15)

	new("UIStroke", {
		Color = th.line,
		Thickness = 1,
		Transparency = 0.45,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	}, dock)

	ui.glass(dock, 15, { washTransparency = 0.92, z = 4 })

	local dockglider = ui.glider(dock, 11, 5)

	local TAB_W, TAB_H, TAB_GAP, TAB_PAD = 104, 34, 2, 4

	-- ----------------------------------------------------- page plumbing ----
	-- A page is a scrolling board with a full-width lane on top and a pair of
	-- columns under it. A card picks its lane when it is made.
	local function newpage()
		local page = new("CanvasGroup", {
			Name = rnd(),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			GroupTransparency = 0,
			Visible = false,
		}, board)

		local list = ui.scroller(page)

		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 12),
		}, list)

		new("UIPadding", { PaddingBottom = UDim.new(0, 8), PaddingRight = UDim.new(0, 2) }, list)

		local wide = new("Frame", {
			Name = rnd(),
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = 1,
			Visible = false,
		}, list)

		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 12),
		}, wide)

		local pair = new("Frame", {
			Name = rnd(),
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = 2,
		}, list)

		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 14),
		}, pair)

		local function column(order)
			local col = new("Frame", {
				Name = rnd(),
				Size = UDim2.new(0.5, -7, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = order,
			}, pair)

			new("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 12),
			}, col)

			return col
		end

		local lanes = { left = column(1), right = column(2), full = wide }

		return page, lanes, wide, pair
	end

	-- Cards arrive one at a time while the script loads; a lane that gets
	-- nothing must not hold half the page open.
	local function balance(lanes, wide, pair)
		wide.Visible = #wide:GetChildren() > 1
		local l, r = #lanes.left:GetChildren() > 1, #lanes.right:GetChildren() > 1

		pair.Visible = l or r
		lanes.left.Visible = l
		lanes.right.Visible = r
		lanes.left.Size = UDim2.new((l and r) and 0.5 or 1, (l and r) and -7 or 0, 0, 0)
		lanes.right.Size = UDim2.new((l and r) and 0.5 or 1, (l and r) and -7 or 0, 0, 0)
	end

	local function pageof(node)
		if not node.page then
			node.page, node.lanes, node.wide, node.pair = newpage()
		end

		return node.page, node.lanes
	end

	-- Only one page is on screen. A change of page is a crossfade: the page
	-- being left fades out while the new one fades in and settles up from a
	-- few pixels below. Both are a group fade and a position, nothing that
	-- re-lays a page out, so the switch stays cheap however many cards it has.
	local shown = nil
	local switch = 0

	local function show(node)
		if shown == node then
			return
		end

		local was = shown

		shown = node
		switch += 1

		local mine = switch

		if was and was.page then
			local old = was.page

			-- The page being left is left on screen for the length of the
			-- fade. If the menu moves again first, the timer below sees a
			-- newer switch and leaves whatever is now open alone.
			old.Visible = true

			anim(old, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { GroupTransparency = 1 })

			task.delay(0.15, function()
				if mine ~= switch then
					return
				end

				if old ~= (shown and shown.page) then
					old.Visible = false
					old.GroupTransparency = 0
					old.Position = UDim2.new()
				end
			end)

			if was.hit then
				was.hit(false)
			end
		end

		if not node then
			return
		end

		local page = pageof(node)

		page.GroupTransparency = 1
		page.Position = UDim2.fromOffset(0, 10)
		page.Visible = true

		anim(page, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 })
		anim(page, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new() })

		if node.hit then
			node.hit(true)
		end
	end

	-- --------------------------------------------------------- capsule ----
	local function paintcapsule()
		local tab = win.group

		if not tab then
			capsule.Visible = false

			return
		end

		local count = #tab.subs

		capsule.Visible = count > 1
		capsule.Size = UDim2.fromOffset(math.max(count, 1) * 106, 34)

		-- Every group's pages are parented to the one capsule, so the ones
		-- belonging to the groups you are not on have to be put away; left
		-- visible they all draw on top of each other.
		for _, other in next, win.subs do
			other.slot.Visible = other.owner == tab
		end

		for n, sub in next, tab.subs do
			sub.slot.Parent = capsule
			sub.slot.Position = UDim2.new((n - 1) / count, 0, 0, 0)
			sub.slot.Size = UDim2.new(1 / count, 0, 1, 0)

			local on = win.active == sub

			anim(sub.art, glide, { ImageColor3 = on and th.accent or th.dim })
			anim(sub.tag, glide, { TextColor3 = on and th.text or th.dim })

			sub.tag.Font = on and Enum.Font.GothamBold or Enum.Font.GothamMedium

			if on then
				capglider.to(UDim2.new((n - 1) / count, 3, 0, 3), UDim2.new(1 / count, -6, 1, -6))
			end
		end
	end

	-- Tabs are placed by hand, in LayoutOrder order, so the dock knows its own
	-- width and the highlight knows exactly where to go.
	local function relayout()
		local order = table.clone(win.list)

		table.sort(order, function(a, b)
			return a.head.LayoutOrder < b.head.LayoutOrder
		end)

		for n, tab in next, order do
			tab.slotpos = UDim2.fromOffset(TAB_PAD + (n - 1) * (TAB_W + TAB_GAP), TAB_PAD)
			tab.head.Position = tab.slotpos
		end

		dock.Size = UDim2.fromOffset(TAB_PAD * 2 + #order * TAB_W + math.max(#order - 1, 0) * TAB_GAP, 42)
	end

	local function paintbar()
		for _, tab in next, win.list do
			local on = win.group == tab

			anim(tab.art, glide, { ImageColor3 = on and th.accent or th.dim })
			anim(tab.tag, glide, { TextColor3 = on and th.text or th.dim })

			tab.tag.Font = on and Enum.Font.GothamBold or Enum.Font.GothamMedium

			if on and tab.slotpos then
				dockglider.to(tab.slotpos, UDim2.fromOffset(TAB_W, TAB_H))
			end
		end
	end

	-- Picking a group shows the sub-page it was left on; picking a sub-page
	-- shows that one and marks its group.
	local function pick(node)
		if node.subs then
			win.group = node
			win.active = node.last or node.subs[1] or node
		else
			win.group = node.owner
			win.active = node
			node.owner.last = node
		end

		ui.closeall()
		show(win.active)
		paintbar()
		paintcapsule()
	end

	win.pick = pick

	-- ------------------------------------------------------ cards on a page ----
	local function laneof(node, side)
		local _, lanes = pageof(node)

		return lanes[side] or lanes.left
	end

	local function settle(node)
		if node.lanes then
			balance(node.lanes, node.wide, node.pair)
		end
	end

	local function cardmaker(build)
		return function(node, c)
			c = params(c or {}, { name = "section", side = "left" })

			local made = build(win, laneof(node, c.side), c)

			settle(node)

			return made
		end
	end

	local addsection = cardmaker(function(...) return ui.section(...) end)
	local addgallery = cardmaker(function(...) return ui.gallery(...) end)
	local addconfigs = cardmaker(function(...) return ui.configs(...) end)
	local addcolorcard = cardmaker(function(...) return ui.colorcard(...) end)

	local function wire(node)
		node.section = function(_, c) return addsection(node, c) end
		node.gallery = function(_, c) return addgallery(node, c) end
		node.configs = function(_, c) return addconfigs(node, c) end
		node.color = function(_, c) return addcolorcard(node, c) end

		return node
	end

	-- ---------------------------------------------------------- groups ----
	function win:tab(c)
		c = params(c, { name = "Tab", icon = "" })

		local tab = { name = c.name, subs = {}, owner = nil, open = true }

		local btn = new("TextButton", {
			Name = rnd(),
			Size = UDim2.fromOffset(TAB_W, TAB_H),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			LayoutOrder = #win.list + 1,
			ZIndex = 6,
		}, dock)

		local strip = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -16, 0, 20),
			BackgroundTransparency = 1,
			ZIndex = 6,
		}, btn)

		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 7),
		}, strip)

		tab.art = new("ImageLabel", {
			Name = rnd(),
			Size = UDim2.fromOffset(15, 15),
			BackgroundTransparency = 1,
			Image = icon(c.icon),
			ImageColor3 = th.dim,
			ScaleType = Enum.ScaleType.Fit,
			LayoutOrder = 1,
			ZIndex = 6,
		}, strip)

		tab.tag = new("TextLabel", {
			Name = rnd(),
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = ui.titlecase(c.name),
			TextColor3 = th.dim,
			TextSize = 13,
			LayoutOrder = 2,
			ZIndex = 6,
		}, strip)

		tab.head = btn
		tab.button = btn

		conn(btn:GetPropertyChangedSignal("LayoutOrder"), function()
			relayout()
			paintbar()
		end)

		conn(btn.MouseButton1Click, function()
			visualsui:chime("tap")
			pick(tab)
		end)

		function tab.select()
			pick(tab)
		end

		function tab:setopen() end

		function tab:sub(sc)
			sc = params(sc, { name = "Page", icon = "" })

			local sub = { name = sc.name, owner = tab }

			local slot = new("TextButton", {
				Name = rnd(),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				Visible = false,
				ZIndex = 5,
			}, capsule)

			sub.slot = slot

			local strip = new("Frame", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -14, 0, 20),
				BackgroundTransparency = 1,
				ZIndex = 6,
			}, slot)

			new("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 7),
			}, strip)

			sub.art = new("ImageLabel", {
				Name = rnd(),
				Size = UDim2.fromOffset(14, 14),
				BackgroundTransparency = 1,
				Image = icon(sc.icon),
				ImageColor3 = th.dim,
				ScaleType = Enum.ScaleType.Fit,
				LayoutOrder = 1,
				ZIndex = 6,
			}, strip)

			sub.tag = new("TextLabel", {
				Name = rnd(),
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromOffset(0, 20),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamMedium,
				Text = ui.titlecase(sc.name),
				TextColor3 = th.dim,
				TextSize = 13,
				LayoutOrder = 2,
				ZIndex = 6,
			}, strip)

			conn(slot.MouseButton1Click, function()
				visualsui:chime("tap")
				pick(sub)
			end)

			function sub.select()
				pick(sub)
			end

			wire(sub)

			table.insert(tab.subs, sub)
			table.insert(win.subs, sub)

			if win.group == tab then
				paintcapsule()
			end

			-- The first group is picked before it has any pages, so what is on
			-- screen is the group's own empty board. The moment it gets one,
			-- move to it; a group never has a page of its own once it has subs.
			if not win.active or win.active == tab then
				pick(sub)
			end

			return sub
		end

		wire(tab)

		table.insert(win.list, tab)

		relayout()

		if not win.active then
			pick(tab)
		end

		return tab
	end

	-- ---------------------------------------------------- open and close ----
	local renders = 0

	-- Fade and a short slide. Not a scale: a UIScale on the shell makes the
	-- engine re-lay out every descendant on every frame of the tween, which
	-- measured at a 39 ms frame; a fade costs 7 ms and a slide 10.
	function win:render(value)
		local want = value and true or false

		if want == win.open and shell.Visible == want then
			return
		end

		local was = win.open

		win.open = want
		visualsui.shown = want

		-- an open drop-down belongs to the page it was opened on
		ui.closeall()

		renders += 1

		local mine = renders

		-- Where the window rests is wherever it was last left, since it can be
		-- dragged. Closing in the middle of the opening slide would read a
		-- position 10 px off, so only a window that has settled is believed.
		if was and os.clock() - (win.openedAt or 0) > 0.4 then
			win.home = shell.Position
		end

		local base = win.home or shell.Position

		win.home = base

		if want then
			win.openedAt = os.clock()
		end

		if want then
			shell.Position = UDim2.new(base.X.Scale, base.X.Offset, base.Y.Scale, base.Y.Offset + 10)
			shell.Visible = true

			anim(shell, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 })
			anim(shell, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = base })

			return
		end

		anim(shell, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { GroupTransparency = 1 })
		anim(shell, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(base.X.Scale, base.X.Offset, base.Y.Scale, base.Y.Offset + 6),
		})

		task.delay(0.17, function()
			-- opened again before the fade finished: leave it be
			if mine == renders and not win.open and shell.Parent then
				shell.Visible = false
				shell.Position = base
			end
		end)
	end

	function win:toggle()
		win:render(not win.open)
	end

	function win:setsize(size)
		if typeof(size) ~= "UDim2" then
			return
		end

		win.size = size
		shell.Size = size
	end

	function win:setbind(value)
		local key = value

		if type(key) == "string" then
			key = Enum.KeyCode[key]
		end

		if typeof(key) == "EnumItem" then
			win.bind = key
		end
	end

	drag(header, shell, 0.12)

	-- The menu key works even when the game marks the press as handled: only a
	-- focused text box should keep it from firing, which is the one place a
	-- Delete press belongs to typing. A key that is being rebound is left
	-- alone, so binding Delete to a control does not also shut the menu.
	conn(uis.InputBegan, function(i)
		if not visualsui.alive or i.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		if i.KeyCode ~= win.bind then
			return
		end

		if ui.waiting or uis:GetFocusedTextBox() then
			return
		end

		win:toggle()
	end)

	win:render(true)

	return win
end

-- ============================================================== widgets ====
-- Every control is built by the same factory, so a toggle's own options
-- panel offers exactly what a card does. `host` is the frame the rows go in.

ui.KINDS = { toggle = "toggle", number = "number", list = "list", color = "color", key = "key", string = "string" }

function ui.register(flag, kind, get, set, schema)
	if type(flag) == "string" and flag ~= "" then
		visualsui:hook(flag, ui.KINDS[kind] or kind, get, set, schema)
	end
end

-- A key on a control. Right-click the row and a small panel offers the key
-- and how it should behave; the badge list on screen reads from here.
ui.MODES = { "Toggle", "Hold" }

-- Every bound control is driven from one pair of input handlers. With a
-- handler each, eighty toggles meant eighty calls on every key press.
ui.bound = {}
ui.waiting = nil

conn(uis.InputBegan, function(i, typing)
	if typing or not visualsui.alive or i.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end

	local catching = ui.waiting

	if catching then
		ui.waiting = nil
		catching.listening = false
		catching.key = (i.KeyCode ~= Enum.KeyCode.Escape) and i.KeyCode or nil

		catching.paint()

		return
	end

	for _, bd in next, ui.bound do
		if bd.key == i.KeyCode then
			if bd.mode == "Hold" then
				bd.fire(true)
			else
				bd.fire(not (bd.state and bd.state()))
			end
		end
	end
end)

conn(uis.InputEnded, function(i)
	if i.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end

	for _, bd in next, ui.bound do
		if bd.mode == "Hold" and bd.key == i.KeyCode then
			bd.fire(false)
		end
	end
end)

function ui.bindfor(win, row, title, opt)
	local th = ui.palette()
	local bd = { key = nil, mode = "Toggle", id = opt.id, listening = false }
	local hull, shown = nil, false

	local function label()
		return bd.key and keyname(bd.key) or "None"
	end

	local function perched()
		if bd.key and visualsui.alive then
			perch(bd.id, { name = tostring(title or ""), key = label(), lit = opt.state and opt.state() or false })
		else
			unperch(bd.id)
		end
	end

	function bd:lit(v)
		if bd.key then
			relight(bd.id, v and true or false)
		end
	end

	function bd:setopen(v)
		if not hull or v or not shown then
			return
		end

		shown = false

		ui.conceal(hull)

		if sky == bd.shut then
			sky = nil
			skyzone = nil
		end
	end

	bd.shut = function()
		bd:setopen(false)
	end

	local keybtn, modetag

	local function paint()
		if keybtn then
			keybtn.Text = bd.listening and "..." or label()
			keybtn.TextColor3 = (bd.listening or bd.key) and th.text or th.dim
		end

		if modetag then
			modetag.Text = bd.mode
		end

		perched()
	end

	local function build()
		if hull then
			return
		end

		hull = ui.floater(176, 0)

		local box = new("Frame", {
			Name = rnd(),
			Size = UDim2.new(1, -16, 1, -16),
			Position = UDim2.fromOffset(8, 8),
			BackgroundTransparency = 1,
		}, hull)

		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}, box)

		new("TextLabel", {
			Name = rnd(),
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = tostring(title or ""),
			TextColor3 = th.text,
			TextSize = 11,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 1,
			ZIndex = 402,
		}, box)

		local keyrow = new("Frame", {
			Name = rnd(),
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = ui.sheet.row,
			BorderSizePixel = 0,
			LayoutOrder = 2,
			ZIndex = 402,
		}, box)

		round(keyrow, 7)

		new("TextLabel", {
			Name = rnd(),
			Position = UDim2.fromOffset(9, 0),
			Size = UDim2.new(0.5, -9, 1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = "Key",
			TextColor3 = th.dim,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 403,
		}, keyrow)

		keybtn = new("TextButton", {
			Name = rnd(),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.new(0.5, -8, 1, -6),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = label(),
			TextColor3 = th.dim,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 403,
		}, keyrow)

		conn(keybtn.MouseButton1Click, function()
			if ui.waiting and ui.waiting ~= bd then
				ui.waiting.listening = false
				ui.waiting.paint()
			end

			bd.listening = true
			ui.waiting = bd

			paint()
		end)

		local moderow = new("Frame", {
			Name = rnd(),
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = ui.sheet.row,
			BorderSizePixel = 0,
			LayoutOrder = 3,
			ZIndex = 402,
		}, box)

		round(moderow, 7)

		new("TextLabel", {
			Name = rnd(),
			Position = UDim2.fromOffset(9, 0),
			Size = UDim2.new(0.5, -9, 1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = "Mode",
			TextColor3 = th.dim,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 403,
		}, moderow)

		modetag = new("TextLabel", {
			Name = rnd(),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.new(0.5, -8, 1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = bd.mode,
			TextColor3 = th.text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 403,
		}, moderow)

		conn(ui.hitbox(moderow, { ZIndex = 404 }).MouseButton1Click, function()
			local at = table.find(ui.MODES, bd.mode) or 1

			bd.mode = ui.MODES[at % #ui.MODES + 1]
			paint()
		end)

		local clear = new("TextButton", {
			Name = rnd(),
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundColor3 = ui.sheet.row,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			Text = "Clear",
			TextColor3 = th.dim,
			TextSize = 12,
			LayoutOrder = 4,
			ZIndex = 402,
		}, box)

		round(clear, 7)

		conn(clear.MouseButton1Click, function()
			bd.key = nil
			bd.listening = false

			if ui.waiting == bd then
				ui.waiting = nil
			end

			paint()
			bd:setopen(false)
		end)
	end

	conn(row.InputBegan, function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton2 then
			return
		end

		build()
		hush(bd)
		sink()

		shown = true
		visualsui:chime("tap")
		paint()

		ui.anchor(hull, apos(row), asz(row), 4, 134)
		ui.reveal(hull, 134)

		sky = bd.shut
		skyzone = hull
	end)

	bd.fire = opt.fire
	bd.state = opt.state
	bd.paint = paint

	table.insert(ui.bound, bd)

	-- the key and the mode are settings like any other
	ui.register(bd.id .. "|key", "key",
		function() return bd.key and bd.key.Name or "Unknown" end,
		function(v)
			bd.key = (v ~= "Unknown") and Enum.KeyCode[v] or nil
			paint()
		end)

	ui.register(bd.id .. "|mode", "list",
		function() return bd.mode end,
		function(v)
			if table.find(ui.MODES, v) then
				bd.mode = v
				paint()
			end
		end,
		{ validate = function(v) return table.find(ui.MODES, v) ~= nil end })

	table.insert(hive, bd)

	return bd
end

function ui.attach(win, host)
	local th = ui.palette()
	local api = {}
	local seq = 0

	-- Every caption made here, so a toggle can dim its own settings while the
	-- feature is off and bring them back up when it is on.
	local captions = {}

	local function caption(row, text, width)
		local label = ui.caption(row, text, width)

		captions[#captions + 1] = label

		return label
	end

	api.lit = true

	function api.setlit(on)
		on = on and true or false

		if on == api.lit then
			return
		end

		api.lit = on

		for _, label in next, captions do
			if label.Parent then
				anim(label, glide, { TextColor3 = on and th.text or th.dim })
			end
		end
	end

	local function order()
		seq += 1

		return seq
	end

	-- ------------------------------------------------------------ label ----
	function api:label(c)
		c = params(c, { name = "", wrap = false })

		local row = ui.rowframe(host, c.wrap and 0 or 18, order())

		if c.wrap then
			row.AutomaticSize = Enum.AutomaticSize.Y
		end

		local text = new("TextLabel", {
			Name = rnd(),
			Size = c.wrap and UDim2.new(1, 0, 0, 0) or UDim2.fromScale(1, 1),
			AutomaticSize = c.wrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = tostring(c.name or ""),
			TextColor3 = th.dim,
			TextSize = 12,
			TextWrapped = c.wrap and true or false,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		}, row)

		local el = { row = row }

		function el:set(v)
			text.Text = tostring(v or "")
		end

		function el:get()
			return text.Text
		end

		return el
	end

	-- ----------------------------------------------------------- button ----
	function api:button(c)
		c = params(c, { name = "Button", icon = nil, callback = nil })

		-- Flush with the card's content edge: an action spans the card the way
		-- a bar does, rather than floating in the same inset as a control row.
		local row = ui.rowframe(host, 32, order(), true)

		local face = new("Frame", {
			Name = rnd(),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = th.head,
			BorderSizePixel = 0,
		}, row)

		round(face, 10)

		-- a faint blue tint over the body, so the action reads as part of the
		-- palette instead of a neutral slab
		local tint = new("Frame", {
			Name = rnd(),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = th.accent,
			BackgroundTransparency = 0.93,
			BorderSizePixel = 0,
		}, face)

		round(tint, 10)

		local edge = new("UIStroke", {
			Color = th.line,
			Thickness = 1,
			Transparency = 0.35,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Round,
		}, face)

		-- light from above: a sheen falling off and a rim along the top edge
		local sheen = new("Frame", {
			Name = rnd(),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = th.glow,
			BackgroundTransparency = 0.88,
			BorderSizePixel = 0,
		}, face)

		round(sheen, 10)

		fade(sheen, 90, {
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.6, 0.85),
			NumberSequenceKeypoint.new(1, 1),
		})

		local rim = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 1),
			Size = UDim2.new(1, -20, 0, 1),
			BackgroundColor3 = th.text,
			BackgroundTransparency = 0.7,
			BorderSizePixel = 0,
		}, face)

		fade(rim, 0, {
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 1),
		})

		local hold = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -16, 1, 0),
			BackgroundTransparency = 1,
			ZIndex = 2,
		}, face)

		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 7),
		}, hold)

		local art

		if c.icon then
			art = new("ImageLabel", {
				Name = rnd(),
				Size = UDim2.fromOffset(14, 14),
				BackgroundTransparency = 1,
				Image = icon(c.icon),
				ImageColor3 = th.dim,
				ScaleType = Enum.ScaleType.Fit,
				LayoutOrder = 1,
				ZIndex = 2,
			}, hold)
		end

		local label = new("TextLabel", {
			Name = rnd(),
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 16),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = tostring(c.name),
			TextColor3 = th.text,
			TextSize = 12,
			LayoutOrder = 2,
			ZIndex = 2,
		}, hold)

		local hit = ui.hitbox(row)

		conn(hit.MouseEnter, function()
			anim(face, soft, { BackgroundColor3 = th.line })
			anim(tint, soft, { BackgroundTransparency = 0.86 })
			anim(edge, soft, { Color = th.glow, Transparency = 0.1 })

			if art then
				anim(art, soft, { ImageColor3 = th.text })
			end
		end)

		conn(hit.MouseLeave, function()
			anim(face, soft, { BackgroundColor3 = th.head })
			anim(tint, soft, { BackgroundTransparency = 0.93 })
			anim(edge, soft, { Color = th.line, Transparency = 0.35 })

			if art then
				anim(art, soft, { ImageColor3 = th.dim })
			end
		end)

		conn(hit.MouseButton1Down, function()
			anim(face, quick, { BackgroundColor3 = th.panel })
			anim(tint, quick, { BackgroundTransparency = 0.8 })
		end)

		conn(hit.MouseButton1Up, function()
			anim(face, soft, { BackgroundColor3 = th.line })
			anim(tint, soft, { BackgroundTransparency = 0.86 })
		end)

		conn(hit.MouseButton1Click, function()
			visualsui:chime("tap")
			callback(c.callback)
		end)

		return { row = row, face = face, label = label }
	end

	-- ----------------------------------------------------------- toggle ----
	function api:toggle(c)
		c = params(c, { name = "Toggle", default = false, options = false, flag = nil, callback = nil })

		local row = ui.rowframe(host, 28, order())
		local on = c.default and true or false

		-- a function's name is the loudest thing on its row
		local cap = caption(row, c.name, UDim2.new(1, c.options and -100 or -70, 0, 18))

		cap.Font = Enum.Font.GothamMedium
		cap.TextSize = 13
		cap.TextColor3 = on and th.text or th.dim
		semi(cap)

		local track = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(38, 20),
			BackgroundColor3 = on and th.accent or th.head,
			BorderSizePixel = 0,
		}, row)

		local trackEdge = new("UIStroke", {
			Color = on and th.text or th.line,
			Thickness = 1,
			Transparency = on and 0.55 or 0.3,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, track)

		new("UICorner", { CornerRadius = UDim.new(1, 0) }, track)

		-- a sheen across the track, so it reads as a glass pill and not a flat bar
		local trackSheen = new("Frame", {
			Name = rnd(),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = th.text,
			BackgroundTransparency = on and 0.8 or 0.94,
			BorderSizePixel = 0,
		}, track)

		new("UICorner", { CornerRadius = UDim.new(1, 0) }, trackSheen)

		fade(trackSheen, 90, {
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.55, 0.8),
			NumberSequenceKeypoint.new(1, 1),
		})

		local knob = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, on and 20 or 2, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = on and th.bg or th.dim,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, track)

		new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

		local el = { row = row, name = c.name }
		local panel, dots

		local function paint()
			anim(track, soft, { BackgroundColor3 = on and th.accent or th.head })
			anim(trackEdge, soft, { Transparency = on and 0.55 or 0.3, Color = on and th.text or th.line })
			anim(trackSheen, soft, { BackgroundTransparency = on and 0.8 or 0.94 })
			anim(knob, soft, {
				Position = UDim2.new(0, on and 20 or 2, 0.5, 0),
				BackgroundColor3 = on and th.bg or th.dim,
			})
			anim(cap, glide, { TextColor3 = on and th.text or th.dim })

			-- rawget: reading el.options would build the panel, and most
			-- toggles never have one
			local panel = rawget(el, "options")

			if panel and panel.setlit then
				panel.setlit(on)
			end
		end

		function el:get()
			return on
		end

		function el:set(v, quiet)
			local want = v and true or false

			if want == on then
				return
			end

			on = want
			paint()

			if not quiet then
				callback(c.callback, on)
			end
		end

		local hit = ui.hitbox(row)

		-- A second target exactly over the switch, above the row target, so a
		-- click on the track or its knob can never be swallowed by anything
		-- else in the row. The two share one handler; only the topmost sees
		-- the click, so it still flips once.
		local trackHit = ui.hitbox(row, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(46, 26),
			ZIndex = 7,
		})

		local function flip()
			visualsui:chime("tap")
			el:set(not on)
		end

		conn(hit.MouseButton1Click, flip)
		conn(trackHit.MouseButton1Click, flip)

		-- The extra controls a feature hangs off its toggle live in a strip
		-- that folds out under the row. Most toggles never get any, so none of
		-- it exists until something asks for the panel; the row's place in the
		-- list is reserved up front so it lands directly underneath.
		if c.options then
			local foldorder = order()

			local function build()
				local fold = new("Frame", {
					Name = rnd(),
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					LayoutOrder = foldorder,
					Visible = false,
				}, host)

				local inner = new("CanvasGroup", {
					Name = rnd(),
					Size = UDim2.new(1, -10, 0, 0),
					Position = UDim2.fromOffset(10, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					GroupTransparency = 1,
				}, fold)

				new("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
				}, inner)

				new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 2) }, inner)

				new("Frame", {
					Name = rnd(),
					Size = UDim2.new(0, 1, 1, -8),
					Position = UDim2.fromOffset(2, 4),
					BackgroundColor3 = th.line,
					BackgroundTransparency = 0.4,
					BorderSizePixel = 0,
				}, fold)

				local dots = new("ImageButton", {
					Name = rnd(),
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -48, 0.5, 0),
					Size = UDim2.fromOffset(18, 18),
					BackgroundColor3 = th.head,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Image = icon("ellipsis"),
					ImageColor3 = th.dim,
					ScaleType = Enum.ScaleType.Fit,
					Visible = false,
					ZIndex = 7,
				}, row)

				round(dots, 5)

				-- The click area is the whole row, switch included. The options
				-- button sits above it (higher ZIndex) and takes its own clicks.

				local shown = false

				conn(dots.MouseButton1Click, function()
					shown = not shown

					visualsui:chime("tap")
					anim(dots, glide, { ImageColor3 = shown and th.text or th.dim, Rotation = shown and 90 or 0 })

					-- The strip sits inside five nested auto-sized frames, so every
					-- height written to it re-lays the whole page out. Animating
					-- the height did that once per frame, which is the stutter it
					-- had. Now the height changes once, and the content slides in
					-- under the clip, which costs a position write and no layout.
					if shown then
						fold.Size = UDim2.new(1, 0, 0, asz(inner).Y)
						fold.Visible = true
						inner.Position = UDim2.fromOffset(10, -10)
						inner.GroupTransparency = 1

						anim(inner, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 })
						anim(inner, arrive, { Position = UDim2.fromOffset(10, 0) })
					else
						-- fade first, then take the height away once: no frame in
						-- between asks the page to lay itself out
						anim(inner, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { GroupTransparency = 1 })

						task.delay(0.13, function()
							if not shown and fold.Parent then
								fold.Visible = false
								fold.Size = UDim2.new(1, 0, 0, 0)
							end
						end)
					end
				end)

				conn(inner:GetPropertyChangedSignal("AbsoluteSize"), function()
					if shown then
						fold.Size = UDim2.new(1, 0, 0, asz(inner).Y)
					end
				end)

				local panel = ui.attach(win, inner)

				panel.setlit(on)

				panel.reveal = function()
					dots.Visible = true
				end

				return panel
			end

			setmetatable(el, {
				__index = function(t, key)
					if key ~= "options" then
						return nil
					end

					local panel = build()

					rawset(t, "options", panel)

					return panel
				end,
			})
		end

		ui.register(c.flag, "toggle", function() return on end, function(v) el:set(v) end)

		-- Right-click binds a key to the toggle; the badge list on screen is
		-- fed from there.
		el.bind = ui.bindfor(win, row, c.name, {
			id = c.flag or (rnd() .. "|" .. tostring(c.name)),
			fire = function(v) el:set(v) end,
			state = function() return on end,
		})

		el.bind:lit(on)

		local lit = el.set

		function el:set(v, quiet)
			lit(self, v, quiet)
			el.bind:lit(on)
		end

		return el
	end

	-- ----------------------------------------------------------- slider ----
	function api:slider(c)
		c = params(c, {
			name = "Slider",
			min = 0,
			max = 100,
			default = nil,
			step = 1,
			suffix = "",
			flag = nil,
			callback = nil,
		})

		local lo, hi = tonumber(c.min) or 0, tonumber(c.max) or 100

		if hi < lo then
			lo, hi = hi, lo
		end

		local step = math.abs(tonumber(c.step) or 1)

		if step <= 0 then
			step = 1
		end

		local digits = (step < 1) and math.max(0, math.ceil(-math.log10(step))) or 0
		local value = math.clamp(tonumber(c.default) or lo, lo, hi)

		local row = ui.rowframe(host, 40, order())
		local cap = caption(row, c.name, UDim2.new(1, -74, 0, 14))

		cap.AnchorPoint = Vector2.new()
		cap.Position = UDim2.fromOffset(0, 2)

		local readout = new("TextBox", {
			Name = rnd(),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(68, 18),
			BackgroundColor3 = th.head,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			Text = "",
			TextColor3 = th.text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
			ClearTextOnFocus = false,
			ZIndex = 7,
		}, row)

		round(readout, 5)

		local track = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, -8),
			Size = UDim2.new(1, 0, 0, 4),
			BackgroundColor3 = th.head,
			BorderSizePixel = 0,
		}, row)

		round(track, 2)

		local fill = new("Frame", {
			Name = rnd(),
			Size = UDim2.fromScale(0, 1),
			BackgroundColor3 = th.accent,
			BorderSizePixel = 0,
		}, track)

		round(fill, 2)

		local knob = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromOffset(11, 11),
			BackgroundColor3 = th.text,
			BorderSizePixel = 0,
			ZIndex = 6,
		}, track)

		new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

		local el = { row = row, name = c.name }

		local function text()
			return string.format("%." .. digits .. "f", value) .. tostring(c.suffix or "")
		end

		local function paint(smooth)
			local k = (hi > lo) and (value - lo) / (hi - lo) or 0

			if smooth then
				anim(fill, quick, { Size = UDim2.fromScale(k, 1) })
				anim(knob, quick, { Position = UDim2.fromScale(k, 0.5) })
			else
				fill.Size = UDim2.fromScale(k, 1)
				knob.Position = UDim2.fromScale(k, 0.5)
			end

			if not readout:IsFocused() then
				readout.Text = text()
			end
		end

		function el:get()
			return value
		end

		function el:set(v, quiet)
			v = tonumber(v)

			if not v or v ~= v then
				return
			end

			v = math.clamp(math.floor(v / step + 0.5) * step, lo, hi)

			if math.abs(v - value) < step / 1000 then
				paint(true)

				return
			end

			value = v
			paint(true)

			if not quiet then
				callback(c.callback, value)
			end
		end

		paint()

		-- Dragging the bar, and typing the number for the values a drag can
		-- never land on exactly.
		local function fromx(x)
			local a = apos(track)
			local w = asz(track).X

			el:set(lo + (hi - lo) * math.clamp((x - a.X) / math.max(w, 1), 0, 1))
		end

		local grip = ui.hitbox(row, {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 20),
			ZIndex = 5,
		})

		conn(grip.InputBegan, function(i)
			if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			latch(1)
			anim(knob, quick, { Size = UDim2.fromOffset(13, 13) })
			fromx(pointer(i).X)

			local move = conn(uis.InputChanged, function(j)
				if j.UserInputType == Enum.UserInputType.MouseMovement or j == i then
					fromx(pointer(j).X)
				end
			end)

			untilReleased(i, function()
				move:Disconnect()
				latch(-1)
				anim(knob, quick, { Size = UDim2.fromOffset(11, 11) })
			end)
		end)

		conn(readout.Focused, function()
			readout.BackgroundTransparency = 0.1
			readout.Text = string.format("%." .. digits .. "f", value)
		end)

		conn(readout.FocusLost, function()
			readout.BackgroundTransparency = 1

			local typed = tonumber(string.match(readout.Text or "", "-?%d+%.?%d*"))

			if typed then
				el:set(typed)
			end

			readout.Text = text()
		end)

		ui.register(c.flag, "number", function() return value end, function(v) el:set(v) end, { min = lo, max = hi })

		return el
	end

	-- --------------------------------------------------------- dropdown ----
	function api:combo(c)
		c = params(c, {
			name = "Dropdown",
			list = {},
			default = nil,
			multi = false,
			flag = nil,
			callback = nil,
		})

		local list = {}

		for _, v in next, c.list do
			list[#list + 1] = tostring(v)
		end

		local picked = {}
		local single = nil

		if c.multi then
			for _, v in next, (type(c.default) == "table" and c.default or {}) do
				picked[tostring(v)] = true
			end
		else
			single = (c.default ~= nil) and tostring(c.default) or list[1]
		end

		local row = ui.rowframe(host, 26, order())
		local wide = tostring(c.name or "") == ""
		local cap = caption(row, c.name, UDim2.new(0.44, -6, 0, 16))

		cap.Visible = not wide

		local field = ui.pill(row, { Size = wide and UDim2.new(1, 0, 0, 22) or UDim2.new(0.56, 0, 0, 22) })

		-- The field reads as a glass well: a hairline that comes up when the
		-- pointer is on it and turns accent while its list is open.
		local fieldEdge = new("UIStroke", {
			Color = th.line,
			Thickness = 1,
			Transparency = 0.45,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, field)

		local tag = new("TextLabel", {
			Name = rnd(),
			Position = UDim2.fromOffset(9, 0),
			Size = UDim2.new(1, -28, 1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = "",
			TextColor3 = th.text,
			TextSize = 12,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 6,
		}, field)

		local chev = new("ImageLabel", {
			Name = rnd(),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -7, 0.5, 0),
			Size = UDim2.fromOffset(12, 12),
			BackgroundTransparency = 1,
			Image = icon("chevron-down"),
			ImageColor3 = th.dim,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 6,
		}, field)

		local el = { row = row, name = c.name }
		local hull, rows, shown, body = nil, {}, false, nil
		local drawn, version = -1, 0

		local function shownvalue()
			if not c.multi then
				return single or "None"
			end

			local out = {}

			for _, v in next, list do
				if picked[v] then
					out[#out + 1] = v
				end
			end

			if #out == 0 then
				return "None"
			end

			if #out <= 2 then
				return table.concat(out, ", ")
			end

			return #out .. " selected"
		end

		local function paintrows()
			for _, r in next, rows do
				local on = c.multi and picked[r.value] or (single == r.value)

				-- the chosen row is plated like a lit pill: a lighter body, a
				-- rim, a short accent bar on the left, bolder text and a tick
				r.on = on and true or false
				r.row:SetAttribute("on", r.on)

				anim(r.row, soft, { BackgroundTransparency = on and 0.86 or 1 })
				anim(r.edge, soft, { Transparency = on and 0.55 or 1 })
				anim(r.bar, soft, { BackgroundTransparency = on and 0 or 1 })
				anim(r.dot, soft, { ImageTransparency = on and 0 or 1 })
				anim(r.text, soft, { TextColor3 = on and th.text or th.dim })

				if on then
					semi(r.text)
				else
					plain(r.text)
				end
			end
		end

		local function paint()
			tag.Text = shownvalue()
			tag.TextColor3 = (tag.Text == "None") and th.dim or th.text

			paintrows()
		end

		function el:get()
			if not c.multi then
				return single
			end

			local out = {}

			for _, v in next, list do
				if picked[v] then
					out[#out + 1] = v
				end
			end

			return table.concat(out, ", ")
		end

		function el:set(v, quiet)
			if c.multi then
				table.clear(picked)

				local src = v

				if type(v) == "string" then
					src = {}

					for part in string.gmatch(v, "[^,]+") do
						src[#src + 1] = string.match(part, "^%s*(.-)%s*$")
					end
				end

				for _, name in next, (type(src) == "table" and src or {}) do
					if table.find(list, tostring(name)) then
						picked[tostring(name)] = true
					end
				end
			else
				local name = tostring(v)

				if not table.find(list, name) then
					return
				end

				single = name
			end

			paint()

			if not quiet then
				callback(c.callback, el:get())
			end
		end

		local function close()
			if not shown then
				return
			end

			shown = false

			anim(chev, glide, { Rotation = 0 })
			anim(fieldEdge, glide, { Color = th.line, Transparency = 0.45 })
			ui.conceal(hull)

			if sky == el.shut then
				sky = nil
				skyzone = nil
			end
		end

		el.shut = close

		function el:setopen(v)
			if not v then
				close()
			end
		end

		local function build()
			if hull then
				return
			end

			hull = ui.floater(1, 0)

			body = ui.scroller(hull, {
				Size = UDim2.new(1, -8, 1, -8),
				Position = UDim2.fromOffset(4, 4),
			})

			new("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			}, body)
		end

		local function fillrows()
			build()

			-- Opening the list again used to destroy and rebuild every row.
			-- The rows are only stale when the value list changed; otherwise
			-- just repaint the ticks and keep what is already there.
			if drawn == version then
				paintrows()

				return
			end

			drawn = version

			for _, r in next, rows do
				r.row:Destroy()
			end

			table.clear(rows)

			for n, value in next, list do
				local line = new("TextButton", {
					Name = rnd(),
					Size = UDim2.new(1, 0, 0, 28),
					BackgroundColor3 = th.glow,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Text = "",
					LayoutOrder = n,
					ZIndex = 402,
				}, body)

				round(line, 8)

				local lineEdge = new("UIStroke", {
					Color = th.glow,
					Thickness = 1,
					Transparency = 1,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}, line)

				local text = new("TextLabel", {
					Name = rnd(),
					Position = UDim2.fromOffset(12, 0),
					Size = UDim2.new(1, -36, 1, 0),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamMedium,
					Text = value,
					TextColor3 = th.dim,
					TextSize = 12,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 403,
				}, line)

				-- a short accent bar on the chosen row, the way a selected
				-- item is marked in a native list
				local bar = new("Frame", {
					Name = rnd(),
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 5, 0.5, 0),
					Size = UDim2.new(0, 2, 1, -14),
					BackgroundColor3 = th.accent,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 403,
				}, line)

				new("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)

				-- the tick is an icon, not a bare dot: it says "this one" at a
				-- glance and matches the check used elsewhere in the menu
				local dot = new("ImageLabel", {
					Name = rnd(),
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -10, 0.5, 0),
					Size = UDim2.fromOffset(12, 12),
					BackgroundTransparency = 1,
					Image = icon("check"),
					ImageColor3 = th.accent,
					ImageTransparency = 1,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 403,
				}, line)

				conn(line.MouseEnter, function()
					anim(line, quick, { BackgroundTransparency = line:GetAttribute("on") and 0.8 or 0.93 })
				end)

				conn(line.MouseLeave, function()
					anim(line, soft, { BackgroundTransparency = line:GetAttribute("on") and 0.86 or 1 })
				end)

				conn(line.MouseButton1Click, function()
					visualsui:chime("tap")

					if c.multi then
						picked[value] = (not picked[value]) or nil
						paint()
						callback(c.callback, el:get())
					else
						single = value
						paint()
						callback(c.callback, value)
						close()
					end
				end)

				rows[#rows + 1] = { row = line, value = value, text = text, dot = dot, bar = bar, edge = lineEdge }
			end

			paintrows()
		end

		local function open()
			fillrows()

			shown = true

			local width = math.max(asz(field).X, 132)
			local tall = math.min(#list * 28 + 8, 228)

			hull.Size = UDim2.fromOffset(width, tall)

			hush(el)
			sink()
			ui.anchor(hull, apos(field), asz(field), 5, tall)
			ui.reveal(hull, tall)
			anim(chev, glide, { Rotation = 180 })
			anim(fieldEdge, glide, { Color = th.accent, Transparency = 0.2 })

			sky = close
			skyzone = hull
		end

		local press = ui.hitbox(row)

		conn(press.MouseEnter, function()
			if not shown then
				anim(fieldEdge, glide, { Color = th.glow, Transparency = 0.2 })
			end
		end)

		conn(press.MouseLeave, function()
			if not shown then
				anim(fieldEdge, glide, { Color = th.line, Transparency = 0.45 })
			end
		end)

		conn(press.MouseButton1Click, function()
			visualsui:chime("tap")

			if shown then
				close()
			else
				open()
			end
		end)

		function el:setlist(values)
			table.clear(list)
			version += 1

			for _, v in next, values or {} do
				list[#list + 1] = tostring(v)
			end

			if not c.multi and not table.find(list, single) then
				single = list[1]
			end

			if c.multi then
				for name in next, picked do
					if not table.find(list, name) then
						picked[name] = nil
					end
				end
			end

			if hull then
				fillrows()
			end

			paint()
		end

		paint()

		ui.register(c.flag, c.multi and "string" or "list",
			function() return el:get() end,
			function(v) el:set(v) end,
			{ validate = function(v)
				if c.multi then
					return type(v) == "string"
				end

				return table.find(list, tostring(v)) ~= nil
			end })

		table.insert(hive, el)

		return el
	end

	-- ----------------------------------------------------------- colour ----
	function api:color(c)
		c = params(c, { name = "Color", default = nil, key = nil, flag = nil, callback = nil })

		-- A card colour (key) edits the ui.palette itself; everything else keeps
		-- its own value.
		local value = (typeof(c.default) == "Color3" and c.default)
			or (c.key and ui.palette()[c.key])
			or Color3.new(1, 1, 1)

		local row = ui.rowframe(host, 26, order())
		local cap = caption(row, c.name, UDim2.new(1, -52, 0, 16))

		local chip = ui.pill(row, { Size = UDim2.fromOffset(40, 20), BackgroundColor3 = value })

		new("UIStroke", {
			Color = th.line,
			Thickness = 1,
			Transparency = 0.2,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, chip)

		local el = { row = row, name = c.name }
		local hull, shown = nil, false
		local hue, sat, val = 0, 0, 1
		local field, square, hueknob, satknob, base

		local function sync()
			hue, sat, val = value:ToHSV()
		end

		sync()

		local function paintpanel()
			if not hull then
				return
			end

			base.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
			satknob.Position = UDim2.fromScale(sat, 1 - val)
			hueknob.Position = UDim2.new(0.5, 0, hue, 0)

			if not field:IsFocused() then
				field.Text = hexof(value)
			end
		end

		local function paint(quiet)
			chip.BackgroundColor3 = value
			paintpanel()

			if c.key then
				visualsui:recolor(c.key, value)
			end

			if not quiet then
				callback(c.callback, value)
			end
		end

		function el:get()
			return value
		end

		function el:set(v, quiet)
			local colour = (typeof(v) == "Color3") and v or fromhex(tostring(v))

			if not colour then
				return
			end

			value = colour
			sync()
			paint(quiet)
		end

		local function close()
			if not shown then
				return
			end

			shown = false

			ui.conceal(hull)

			if sky == el.shut then
				sky = nil
				skyzone = nil
			end
		end

		el.shut = close

		function el:setopen(v)
			if not v then
				close()
			end
		end

		local function grab(frame, onmove)
			conn(frame.InputBegan, function(i)
				if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then
					return
				end

				latch(1)
				onmove(pointer(i))

				local move = conn(uis.InputChanged, function(j)
					if j.UserInputType == Enum.UserInputType.MouseMovement or j == i then
						onmove(pointer(j))
					end
				end)

				untilReleased(i, function()
					move:Disconnect()
					latch(-1)
				end)
			end)
		end

		local function build()
			if hull then
				return
			end

			hull = ui.floater(206, 0)

			local pad = new("Frame", {
				Name = rnd(),
				Position = UDim2.fromOffset(10, 10),
				Size = UDim2.new(1, -20, 1, -20),
				BackgroundTransparency = 1,
				ZIndex = 402,
			}, hull)

			base = new("Frame", {
				Name = rnd(),
				Size = UDim2.fromOffset(152, 112),
				BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
				BorderSizePixel = 0,
				ZIndex = 402,
			}, pad)

			round(base, 8)

			local white = new("Frame", {
				Name = rnd(),
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				ZIndex = 403,
			}, base)

			round(white, 8)

			new("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}, white)

			local black = new("Frame", {
				Name = rnd(),
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(),
				BorderSizePixel = 0,
				ZIndex = 404,
			}, base)

			round(black, 8)

			new("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(1, 0),
				}),
			}, black)

			satknob = new("Frame", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(11, 11),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 406,
			}, base)

			new("UICorner", { CornerRadius = UDim.new(1, 0) }, satknob)

			new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }, satknob)

			local strip = new("Frame", {
				Name = rnd(),
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.fromOffset(18, 112),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				ZIndex = 402,
			}, pad)

			round(strip, 6)

			new("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
					ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
					ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
					ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
					ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
					ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
				}),
			}, strip)

			hueknob = new("Frame", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.new(1, 6, 0, 4),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				ZIndex = 406,
			}, strip)

			round(hueknob, 2)

			new("UIStroke", { Color = Color3.new(), Thickness = 1, Transparency = 0.5 }, hueknob)

			field = new("TextBox", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 0, 1, 0),
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundColor3 = ui.sheet.row,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamBold,
				Text = hexof(value),
				TextColor3 = th.text,
				TextSize = 12,
				ClearTextOnFocus = false,
				ZIndex = 402,
			}, pad)

			round(field, 7)

			conn(field.FocusLost, function()
				local colour = fromhex(field.Text)

				if colour then
					el:set(colour)
				else
					field.Text = hexof(value)
				end
			end)

			grab(base, function(at)
				local a, z = apos(base), asz(base)

				sat = math.clamp((at.X - a.X) / math.max(z.X, 1), 0, 1)
				val = 1 - math.clamp((at.Y - a.Y) / math.max(z.Y, 1), 0, 1)
				value = Color3.fromHSV(hue, sat, val)
				paint()
			end)

			grab(strip, function(at)
				local a, z = apos(strip), asz(strip)

				hue = math.clamp((at.Y - a.Y) / math.max(z.Y, 1), 0, 1)
				value = Color3.fromHSV(hue, sat, val)
				paint()
			end)
		end

		conn(ui.hitbox(row).MouseButton1Click, function()
			visualsui:chime("tap")

			if shown then
				close()

				return
			end

			build()
			paintpanel()

			shown = true

			hush(el)
			sink()
			ui.anchor(hull, apos(chip), asz(chip), 5, 180)
			ui.reveal(hull, 180)

			sky = close
			skyzone = hull
		end)

		paint(true)

		ui.register(c.flag or (c.key and ("theme|" .. c.key)), "color",
			function() return value end,
			function(v) el:set(v) end)

		table.insert(hive, el)

		return el
	end

	-- ---------------------------------------------------------- keybind ----
	function api:keybind(c)
		c = params(c, { name = "Keybind", default = nil, flag = nil, callback = nil })

		local key = (typeof(c.default) == "EnumItem" and c.default)
			or (type(c.default) == "string" and Enum.KeyCode[c.default])
			or nil

		local row = ui.rowframe(host, 26, order())
		local cap = caption(row, c.name, UDim2.new(1, -78, 0, 16))

		local field = ui.pill(row, { Size = UDim2.fromOffset(70, 22) })

		local tag = new("TextLabel", {
			Name = rnd(),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = keyname(key),
			TextColor3 = key and th.text or th.dim,
			TextSize = 12,
			ZIndex = 6,
		}, field)

		local el = { row = row, name = c.name }
		local listening = false

		local function paint()
			tag.Text = listening and "..." or keyname(key)
			tag.TextColor3 = (listening or key) and th.text or th.dim
		end

		function el:get()
			return key and key.Name or "Unknown"
		end

		function el:set(v, quiet)
			local want = (typeof(v) == "EnumItem" and v)
				or (type(v) == "string" and v ~= "Unknown" and Enum.KeyCode[v])
				or nil

			key = want
			listening = false
			paint()

			if not quiet then
				callback(c.callback, key)
			end
		end

		conn(ui.hitbox(row).MouseButton1Click, function()
			visualsui:chime("tap")

			listening = true
			paint()
		end)

		conn(uis.InputBegan, function(i, typing)
			if not listening or typing then
				return
			end

			if i.UserInputType == Enum.UserInputType.Keyboard then
				el:set(i.KeyCode ~= Enum.KeyCode.Escape and i.KeyCode or nil)
			end
		end)

		ui.register(c.flag, "key", function() return el:get() end, function(v) el:set(v) end)

		return el
	end

	-- ------------------------------------------------------- text field ----
	function api:input(c)
		c = params(c, { name = "", placeholder = "", default = "", flag = nil, callback = nil })

		local row = ui.rowframe(host, 26, order())

		local box = new("TextBox", {
			Name = rnd(),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = th.head,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			Text = tostring(c.default or ""),
			TextColor3 = th.text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			PlaceholderText = tostring(c.placeholder ~= "" and c.placeholder or c.name or ""),
			PlaceholderColor3 = th.dim,
			ClearTextOnFocus = false,
			ZIndex = 6,
		}, row)

		round(box, 7)

		new("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9) }, box)

		local el = { row = row, box = box, name = c.name }
		local applying = false

		function el:get()
			return box.Text
		end

		function el:set(v, quiet)
			applying = true
			box.Text = tostring(v or "")
			applying = false

			if not quiet and not (visualsui.secrets and visualsui.secrets[c.flag]) then
				callback(c.callback, box.Text)
			end
		end

		conn(box:GetPropertyChangedSignal("Text"), function()
			if not applying then
				callback(c.callback, box.Text)
			end
		end)

		ui.register(c.flag, "string", function() return box.Text end, function(v) el:set(v, true) end)

		return el
	end

	return api
end

-- ================================================================ cards ====
-- One card shape for everything on a page: a title you can fold away and a
-- body that grows with what is put in it.

function ui.cardshell(win, lane, c)
	local th = ui.palette()

	local slot = new("Frame", {
		Name = rnd(),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = #lane:GetChildren(),
	}, lane)

	local glass = ui.glass(slot, 12, { lift = 12, shade = th.bg, washTransparency = 0.84, z = 1 })

	local panel = new("Frame", {
		Name = rnd(),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = th.panel,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, slot)

	round(panel, 12)

	new("UIStroke", {
		Color = th.line,
		Thickness = 1,
		Transparency = 0.45,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	}, panel)

	new("UIPadding", {
		PaddingTop = UDim.new(0, 11),
		PaddingBottom = UDim.new(0, 11),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}, panel)

	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	}, panel)

	local head = new("Frame", {
		Name = rnd(),
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		ZIndex = 3,
	}, panel)

	local title = new("TextLabel", {
		Name = rnd(),
		Size = UDim2.new(1, -40, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = tostring(c.name or ""),
		TextColor3 = th.text,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	}, head)

	local fold = new("ImageLabel", {
		Name = rnd(),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(13, 13),
		BackgroundTransparency = 1,
		Image = icon("chevron-down"),
		ImageColor3 = th.dim,
		ImageTransparency = 0.3,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 3,
	}, head)

	local body = new("Frame", {
		Name = rnd(),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = 2,
	}, panel)

	local items = new("CanvasGroup", {
		Name = rnd(),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, body)

	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
	}, items)

	-- Folding fades the items and then changes the body's height once. A
	-- height animated through the nested auto-sized frames re-laid the whole
	-- page out every frame.
	local shut = false
	local folds = 0

	conn(ui.hitbox(head, { ZIndex = 4 }).MouseButton1Click, function()
		shut = not shut
		folds += 1

		local mine = folds

		visualsui:chime("tap")
		anim(fold, glide, { Rotation = shut and -90 or 0 })

		if shut then
			anim(items, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { GroupTransparency = 1 })

			task.delay(0.13, function()
				if mine == folds and shut then
					body.AutomaticSize = Enum.AutomaticSize.None
					body.Size = UDim2.new(1, 0, 0, 0)
					items.Visible = false
				end
			end)
		else
			items.Visible = true
			body.AutomaticSize = Enum.AutomaticSize.Y
			items.GroupTransparency = 1

			anim(items, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 })
		end
	end)

	return { slot = slot, panel = panel, head = head, title = title, body = body, items = items }
end

function ui.cardapi(sec, shell)
	sec.slot = shell.slot
	sec.panel = shell.panel
	sec.items = shell.items
	sec.head = shell.head

	function sec:setvisible(state)
		shell.slot.Visible = state and true or false
	end

	function sec:settitle(text)
		shell.title.Text = tostring(text or "")
	end

	return sec
end

function ui.section(win, lane, c)
	local shell = ui.cardshell(win, lane, c)

	return ui.cardapi(ui.attach(win, shell.items), shell)
end

-- Every ui.palette colour in one card rather than one card per colour.
ui.palettecards = setmetatable({}, { __mode = "k" })

function ui.colorcard(win, lane, c)
	if not ui.palettecards[lane] then
		local shell = ui.cardshell(win, lane, { name = "Palette" })

		ui.palettecards[lane] = ui.cardapi(ui.attach(win, shell.items), shell)
	end

	return ui.palettecards[lane]:color({ name = c.name, key = c.key })
end

-- ---------------------------------------------------------------- configs ----
function ui.configs(win, lane, c)
	local th = ui.palette()
	local shell = ui.cardshell(win, lane, { name = c.name or "Configs" })
	local sec = ui.cardapi(ui.attach(win, shell.items), shell)
	local chosen = nil
	local rows = {}

	local list = new("Frame", {
		Name = rnd(),
		Size = UDim2.new(1, 0, 0, 132),
		BackgroundColor3 = th.bg,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		LayoutOrder = 1,
	}, shell.items)

	round(list, 8)

	local body = ui.scroller(list, {
		Size = UDim2.new(1, -8, 1, -8),
		Position = UDim2.fromOffset(4, 4),
	})

	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2),
	}, body)

	local empty = new("TextLabel", {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = "no saved configs",
		TextColor3 = th.dim,
		TextSize = 12,
		Visible = false,
	}, list)

	local function toast(text, bad)
		visualsui:notify({ title = text, icon = bad and "x" or "check", life = 3 })
	end

	local refresh

	local function rowfor(name, n)
		local line = new("TextButton", {
			Name = rnd(),
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = th.head,
			BackgroundTransparency = (chosen == name) and 0 or 1,
			BorderSizePixel = 0,
			Text = "",
			LayoutOrder = n,
		}, body)

		round(line, 7)

		local tag = new("TextLabel", {
			Name = rnd(),
			Position = UDim2.fromOffset(9, 0),
			Size = UDim2.new(1, -42, 1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = name,
			TextColor3 = (chosen == name) and th.text or th.dim,
			TextSize = 12,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 2,
		}, line)

		if visualsui:autoload() == name then
			new("ImageLabel", {
				Name = rnd(),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.fromOffset(12, 12),
				BackgroundTransparency = 1,
				Image = icon("power"),
				ImageColor3 = th.accent,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 2,
			}, line)
		end

		conn(line.MouseButton1Click, function()
			chosen = name
			visualsui:chime("tap")
			refresh()
		end)

		rows[#rows + 1] = line
	end

	function refresh()
		for _, r in next, rows do
			r:Destroy()
		end

		table.clear(rows)

		local names = visualsui:roster()

		empty.Visible = #names == 0

		if chosen and not table.find(names, chosen) then
			chosen = nil
		end

		for n, name in next, names do
			rowfor(name, n)
		end
	end

	local field = sec:input({ placeholder = "config name" })

	local function named()
		local text = string.match(field:get() or "", "^%s*(.-)%s*$")

		return (text ~= "" and text) or chosen
	end

	sec:button({
		name = "Save",
		icon = "save",
		callback = function()
			local name = named()

			if not name then
				toast("Name it first", true)

				return
			end

			if visualsui:store(name) then
				chosen = name
				field:set("", true)
				refresh()
				toast("Saved " .. name)
			else
				toast("Could not save", true)
			end
		end,
	})

	sec:button({
		name = "Load",
		icon = "refresh-cw",
		callback = function()
			if not chosen then
				toast("Pick a config", true)

				return
			end

			if visualsui:fetch(chosen) then
				toast("Loaded " .. chosen)
			else
				local why = visualsui.configResult and visualsui.configResult.errors and visualsui.configResult.errors[1]

				toast(tostring(why or "Could not load"), true)
			end
		end,
	})

	sec:button({
		name = "Delete",
		icon = "trash-2",
		callback = function()
			if not chosen then
				toast("Pick a config", true)

				return
			end

			local name = chosen

			visualsui:ask({
				title = "delete " .. name,
				icon = "trash-2",
				accept = "delete",
				deny = "keep",
				confirm = true,
				callback = function()
					if visualsui:erase(name) then
						chosen = nil
						refresh()
						toast("Deleted " .. name)
					else
						toast("Could not delete", true)
					end
				end,
			})
		end,
	})

	sec:button({
		name = "Autoload",
		icon = "power",
		callback = function()
			if visualsui:autoload() == chosen then
				visualsui:setautoload(nil)
				toast("Autoload off")
			elseif chosen then
				visualsui:setautoload(chosen)
				toast("Autoload " .. chosen)
			else
				toast("Pick a config", true)

				return
			end

			refresh()
		end,
	})

	refresh()

	sec.refresh = refresh

	return sec
end

-- ---------------------------------------------------------------- gallery ----
-- A picture grid. The cells are pooled and only the ones on screen exist, so
-- a thousand cosmetics cost the same as a dozen.
function ui.gallery(win, lane, cfg)
	cfg = params(cfg, {
		name = "gallery",
		icon = "image",
		height = 260,
		list = {},
		default = nil,
		multi = false,
		reset = false,
		thumb = "Asset",
		blank = "image",
		cell = 76,
		search = true,
		tools = false,
		buttons = nil,
		action = nil,
		context = nil,
		empty = "nothing here",
		flag = nil,
		callback = nil,
	})

	local th = ui.palette()
	local shape = shots[string.lower(tostring(cfg.thumb))]
	local shell = ui.cardshell(win, lane, { name = cfg.name })
	local data, view, pool = {}, {}, {}
	local bag, pick, query = {}, nil, ""
	local gap = 6
	local span = math.max(tonumber(cfg.cell) or 76, 40)
	-- the width a cell actually has: the list is divided between the columns
	local cellw = span

	-- the count sits in the card header, right of the title
	shell.title.Size = UDim2.new(1, -70, 1, 0)

	local count = new("TextLabel", {
		Name = rnd(),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -20, 0.5, 0),
		Size = UDim2.fromOffset(46, 14),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = "0",
		TextColor3 = th.dim,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 3,
	}, shell.head)

	local field

	if cfg.search then
		local hunt = new("Frame", {
			Name = rnd(),
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundColor3 = th.head,
			BorderSizePixel = 0,
			LayoutOrder = 1,
		}, shell.items)

		round(hunt, 10)

		new("UIStroke", {
			Color = th.line,
			Thickness = 1,
			Transparency = 0.4,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, hunt)

		new("ImageLabel", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 9, 0.5, 0),
			Size = UDim2.fromOffset(13, 13),
			BackgroundTransparency = 1,
			Image = icon("search"),
			ImageColor3 = th.dim,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 2,
		}, hunt)

		field = new("TextBox", {
			Name = rnd(),
			Position = UDim2.fromOffset(28, 0),
			Size = UDim2.new(1, -36, 1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = "",
			TextColor3 = th.text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			PlaceholderText = "search",
			PlaceholderColor3 = th.dim,
			ClearTextOnFocus = false,
			ZIndex = 2,
		}, hunt)
	end

	local frame = new("Frame", {
		Name = rnd(),
		Size = UDim2.new(1, 0, 0, math.max(tonumber(cfg.height) or 260, 90)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 2,
	}, shell.items)

	local list = ui.scroller(frame, {
		Size = UDim2.fromScale(1, 1),
		AutomaticCanvasSize = Enum.AutomaticSize.None,
	})

	local empty = new("TextLabel", {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = tostring(cfg.empty),
		TextColor3 = th.dim,
		TextSize = 12,
		TextWrapped = true,
		Visible = false,
	}, frame)

	local function melt(v)
		if type(v) == "string" then
			return v ~= "" and { name = v, label = v } or nil
		end

		if type(v) ~= "table" then
			return nil
		end

		local nm = v.name or v.Name or v.label or v.Label or v.id or v.Id

		if nm == nil then
			return nil
		end

		local id = tonumber(v.id or v.Id or v.ID or v.asset or v.Asset or v.assetid or v.AssetId or v.userid or v.UserId)
		local art = v.image or v.Image or v.icon or v.Icon or v.art or v.thumb or v.Thumb

		return {
			name = tostring(nm),
			label = tostring(v.display or v.Display or v.label or v.Label or nm),
			id = id,
			art = (type(art) == "string" or type(art) == "number") and art or nil,
			rect = typeof(v.rect) == "Vector2" and v.rect or nil,
			rectsize = typeof(v.rectsize) == "Vector2" and v.rectsize or nil,
		}
	end

	local function picture(e)
		if not e then
			return ""
		end

		if e.art then
			return icon(e.art)
		end

		if shape and e.id and e.id > 0 then
			return string.format(shape, e.id)
		end

		return ""
	end

	-- A cell with no art still has to say what it is. Two initials on the
	-- gradient beat an empty box, and they cost nothing.
	local function initials(text)
		local out = ""

		for word in string.gmatch(tostring(text or ""), "%a+") do
			out = out .. string.upper(string.sub(word, 1, 1))

			if #out >= 2 then
				break
			end
		end

		return out
	end

	local function value()
		if not cfg.multi then
			return pick
		end

		local out = {}

		for i = 1, #data do
			if bag[data[i].name] then
				out[#out + 1] = data[i].name
			end
		end

		return out
	end

	local function chosen(name)
		if name == nil then
			return false
		end

		return cfg.multi and bag[name] == true or pick == name
	end

	local function total()
		local n = 0

		for _ in next, bag do
			n += 1
		end

		return n
	end

	local function tag()
		local n, all = #view, #data

		if n == all then
			count.Text = (cfg.multi and (total() .. "/" .. all)) or tostring(all)
		else
			count.Text = n .. "/" .. all
		end

		empty.Visible = all == 0 or n == 0
	end

	local function shout()
		if cfg.callback and not visualsui.quiet then
			callback(cfg.callback, value())
		end
	end

	-- ------------------------------------------------------------- cells ----
	local function dress(slot, e)
		if not e then
			if slot.frame.Visible then
				slot.frame.Visible = false
			end

			slot.entry = nil

			return
		end

		if not slot.frame.Visible then
			slot.frame.Visible = true
		end

		-- Scrolling re-dresses the same cells over and over. The picture and
		-- its crop only change when the record under the cell changes; the
		-- selection edge is cheap and still repaints every time.
		if slot.entry ~= e then
			slot.entry = e
			slot.tag.Text = e.label

			local art = picture(e)

			if slot.art.Image ~= art then
				slot.art.Image = art
			end

			slot.art.Visible = art ~= ""
			slot.blank.Visible = art == ""

			if art == "" then
				local letters = initials(e.label)

				slot.initials.Text = letters
				slot.initials.Visible = letters ~= ""
				slot.glyph.Visible = letters == ""
			end

			if e.rect and e.rectsize then
				slot.art.ImageRectOffset = e.rect
				slot.art.ImageRectSize = e.rectsize
			else
				slot.art.ImageRectOffset = Vector2.zero
				slot.art.ImageRectSize = Vector2.zero
			end
		end

		-- A picked cell is lighter, rimmed in brighter glass, and its name reads
		-- at full strength. Nothing is added to it: no badge, no tick.
		local on = chosen(e.name)

		if slot.on ~= on then
			slot.on = on

			anim(slot.frame, soft, { BackgroundColor3 = on and th.line or th.head })
			anim(slot.edge, soft, { Transparency = on and 0.05 or 0.55 })
			anim(slot.tag, soft, { TextColor3 = on and th.text or th.dim })

			slot.edge.Color = on and th.text or th.line
		end
	end

	local function hitcell(slot)
		local e = slot.entry

		if not e then
			return
		end

		visualsui:chime("tap")

		if cfg.multi then
			bag[e.name] = (not bag[e.name]) or nil
		else
			pick = (pick ~= e.name) and e.name or (cfg.reset and nil or e.name)
		end

		for _, s in next, pool do
			dress(s, s.entry)
		end

		tag()
		shout()
	end

	local function makecell()
		local box = new("Frame", {
			Name = rnd(),
			Size = UDim2.fromOffset(cellw, cellw + 16),
			BackgroundColor3 = th.head,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Visible = false,
		}, list)

		round(box, 12)

		local edge = new("UIStroke", {
			Color = th.line,
			Thickness = 1,
			Transparency = 0.55,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Round,
		}, box)

		-- The picture sits in a rounded well of its own, so a square image
		-- never pokes its corners out of the cell and every cell has the same
		-- inner shape whatever is drawn in it.
		local well = new("Frame", {
			Name = rnd(),
			Position = UDim2.fromOffset(5, 5),
			Size = UDim2.new(1, -10, 0, cellw - 12),
			BackgroundColor3 = th.panel,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 2,
		}, box)

		round(well, 8)

		local art = new("ImageLabel", {
			Name = rnd(),
			Position = UDim2.fromOffset(3, 3),
			Size = UDim2.new(1, -6, 1, -6),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 2,
		}, well)

		local blank = new("Frame", {
			Name = rnd(),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = th.head,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, well)

		new("UIGradient", {
			Color = ColorSequence.new(th.glow, th.panel),
			Rotation = 135,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.45),
				NumberSequenceKeypoint.new(1, 0.78),
			}),
		}, blank)

		local glyph = new("ImageLabel", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.45),
			Size = UDim2.fromOffset(span * 0.34, span * 0.34),
			BackgroundTransparency = 1,
			Image = icon(cfg.blank),
			ImageColor3 = th.text,
			ImageTransparency = 0.35,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 2,
		}, blank)

		local initials = new("TextLabel", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.45),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = "",
			TextColor3 = th.text,
			TextTransparency = 0.15,
			TextSize = math.max(12, math.floor(span * 0.26)),
			ZIndex = 2,
		}, blank)

		local tag = new("TextLabel", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -3),
			Size = UDim2.new(1, -8, 0, 13),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = "",
			TextColor3 = th.dim,
			TextSize = 10,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 3,
		}, box)

		local slot = { frame = box, well = well, art = art, blank = blank, glyph = glyph, initials = initials, tag = tag, edge = edge }

		local hit = ui.hitbox(box, { ZIndex = 5 })

		conn(hit.MouseButton1Click, function()
			hitcell(slot)
		end)

		-- the per-cell menu, on the ellipsis and on a right click
		local function openmenu()
			local e = slot.entry

			if not e then
				return
			end

			local a, z = apos(box), asz(box)
			local hook = cfg.action and (cfg.action.callback or cfg.action.Callback)

			if hook then
				callback(hook, e.name, e, a.X + z.X - 8, a.Y + 20, box)
			elseif type(cfg.context) == "function" then
				callback(cfg.context, e.name, e, a.X + z.X - 8, a.Y + 20, box)
			end
		end

		if cfg.action or cfg.context then
			local more = new("ImageButton", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0, 0),
				Position = UDim2.fromOffset(4, 4),
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = th.bg,
				BackgroundTransparency = 0.25,
				BorderSizePixel = 0,
				Image = icon((cfg.action and (cfg.action.icon or cfg.action.Icon)) or "ellipsis"),
				ImageColor3 = th.text,
				ScaleType = Enum.ScaleType.Fit,
				Visible = false,
				ZIndex = 6,
			}, box)

			round(more, 5)

			conn(more.MouseButton1Click, openmenu)

			conn(hit.MouseEnter, function()
				more.Visible = true
			end)

			conn(hit.MouseLeave, function()
				more.Visible = false
			end)
		end

		conn(hit.MouseButton2Click, openmenu)

		return slot
	end

	-- ------------------------------------------------------ virtual rows ----
	local cols, rows = 1, 0
	local pass = 0
	local last = { cols = -1, rows = -1, need = -1, first = -1, pass = -1, margin = -1, cellw = -1 }

	local function reflow()
		local width = asz(list).X
		local tall = asz(list).Y

		cols = math.max(math.floor((width - 6 + gap) / (span + gap)), 1)

		-- Cells stretch to use the whole list, so there is no dead strip down
		-- either side whatever the window width happens to be.
		local fit = math.max(math.floor((width - 6 - (cols - 1) * gap) / cols), 40)

		if fit ~= cellw then
			cellw = fit

			for _, slot in next, pool do
				slot.frame.Size = UDim2.fromOffset(cellw, cellw + 16)
				slot.well.Size = UDim2.new(1, -10, 0, cellw - 12)
			end
		end

		local pitch = cellw + 16 + gap

		rows = math.ceil(#view / cols)

		-- centred, never closer than 3 to the edge: a stroke is drawn outside
		-- its frame and the list clips at its own bounds
		local margin = math.max(math.floor((width - (cols * cellw + (cols - 1) * gap)) / 2), 3)

		-- Shrinking the canvas has to happen before the first row is read:
		-- the engine clamps CanvasPosition while the canvas shrinks, and a
		-- search from the bottom would otherwise keep the old scroll.
		if rows ~= last.rows then
			list.CanvasSize = UDim2.fromOffset(0, rows * pitch + 6)
		end

		local need = cols * (math.ceil(tall / pitch) + 2)
		local top = math.max(math.floor(list.CanvasPosition.Y / pitch), 0)
		local first = top * cols

		-- Scrolling inside one row moves the canvas, not the pool. Bail out
		-- before touching a single cell unless the row or the data changed.
		if cols == last.cols and rows == last.rows and need == last.need
			and first == last.first and pass == last.pass and margin == last.margin and cellw == last.cellw then
			return
		end

		last.cols, last.rows, last.need, last.first, last.pass, last.margin, last.cellw = cols, rows, need, first, pass, margin, cellw

		while #pool < need do
			pool[#pool + 1] = makecell()
		end

		for i = need + 1, #pool do
			pool[i].frame.Visible = false
			pool[i].entry = nil
		end

		for i = 1, need do
			local slot = pool[i]
			local index = first + i
			local e = view[index]

			if e then
				local r = math.floor((index - 1) / cols)
				local col = (index - 1) % cols
				local pos = UDim2.fromOffset(margin + col * (cellw + gap), 3 + r * pitch)

				if slot.frame.Position ~= pos then
					slot.frame.Position = pos
				end
			end

			dress(slot, e)
		end
	end

	local function sieve()
		pass += 1
		table.clear(view)

		if query == "" then
			for i = 1, #data do
				view[i] = data[i]
			end
		else
			for i = 1, #data do
				local e = data[i]

				if string.find(string.lower(e.label), query, 1, true) or string.find(string.lower(e.name), query, 1, true) then
					view[#view + 1] = e
				end
			end
		end

		tag()
		reflow()
	end

	local function soak(ls)
		table.clear(data)

		local seen = {}

		for _, v in next, (type(ls) == "table" and ls or {}) do
			local e = melt(v)

			if e and not seen[e.name] then
				seen[e.name] = true
				data[#data + 1] = e
			end
		end

		if cfg.multi then
			for nm in next, bag do
				if not seen[nm] then
					bag[nm] = nil
				end
			end
		elseif pick and not seen[pick] then
			pick = nil
		end

		sieve()
	end

	conn(list:GetPropertyChangedSignal("CanvasPosition"), reflow)
	conn(list:GetPropertyChangedSignal("AbsoluteSize"), reflow)

	if field then
		conn(field:GetPropertyChangedSignal("Text"), function()
			local q = string.lower(string.match(field.Text, "^%s*(.-)%s*$") or "")

			if q ~= query then
				query = q

				sieve()
			end
		end)
	end

	local item = ui.cardapi({}, shell)

	item.list = list
	item.data = data

	function item:get()
		return value()
	end

	function item:set(v, quiet)
		if cfg.multi then
			table.clear(bag)

			if type(v) == "table" then
				for k, s in next, v do
					if s == true and type(k) == "string" then
						bag[k] = true
					elseif type(s) == "string" and s ~= "" then
						bag[s] = true
					end
				end
			elseif type(v) == "string" and v ~= "" then
				for s in string.gmatch(v, "[^,]+") do
					local nm = string.match(s, "^%s*(.-)%s*$")

					if nm ~= "" then
						bag[nm] = true
					end
				end
			end
		else
			if type(v) == "table" then
				v = v.name or v.Name
			end

			pick = (type(v) == "string" and v ~= "") and v or nil
		end

		for _, s in next, pool do
			dress(s, s.entry)
		end

		tag()

		if not quiet then
			shout()
		end
	end

	function item:setdata(ls)
		soak(ls)
	end

	function item:setdefault(v)
		item:set(v, true)
	end

	function item:clear()
		table.clear(bag)

		pick = nil

		for _, s in next, pool do
			dress(s, s.entry)
		end

		tag()
		shout()
	end

	function item:all()
		if not cfg.multi then
			return
		end

		for i = 1, #view do
			bag[view[i].name] = true
		end

		for _, s in next, pool do
			dress(s, s.entry)
		end

		tag()
		shout()
	end

	function item:refresh()
		sieve()
	end

	function item:values()
		local out = {}

		for i = 1, #data do
			out[i] = data[i].name
		end

		return out
	end

	function item:search(q)
		if field then
			field.Text = tostring(q or "")
		end
	end

	-- the tool row: select all, clear, reload, plus whatever the caller adds
	local extra = (type(cfg.buttons) == "table") and cfg.buttons or {}

	if cfg.tools or #extra > 0 then
		local slots = {}

		if cfg.tools then
			slots[#slots + 1] = { icon = "refresh-cw", callback = function() sieve() end }
		end

		for _, b in next, extra do
			if type(b) == "table" then
				slots[#slots + 1] = b
			end
		end

		local strip = new("Frame", {
			Name = rnd(),
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 1,
			LayoutOrder = 3,
		}, shell.items)

		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, gap),
		}, strip)

		local wide = math.max(#slots, 1)

		for n, b in next, slots do
			local hit = new("ImageButton", {
				Name = rnd(),
				Size = UDim2.new(1 / wide, -(gap * (wide - 1)) / wide, 1, 0),
				BackgroundColor3 = th.head,
				BorderSizePixel = 0,
				Image = icon(b.icon or b.Icon or "circle-dot"),
				ImageColor3 = th.dim,
				ScaleType = Enum.ScaleType.Fit,
				LayoutOrder = n,
			}, strip)

			round(hit, 7)

			new("UIPadding", {
				PaddingTop = UDim.new(0, 7),
				PaddingBottom = UDim.new(0, 7),
			}, hit)

			ui.warmth(hit, hit, th.head, th.line)

			conn(hit.MouseButton1Click, function()
				visualsui:chime("tap")
				callback(b.callback or b.Callback)
			end)
		end
	end

	soak(cfg.list)

	if cfg.default ~= nil then
		item:set(cfg.default, true)
	end

	visualsui:hook(cfg.flag or (rnd() .. "|" .. tostring(cfg.name)), cfg.multi and "list" or "string",
		function()
			if cfg.multi then
				return table.concat(value(), ", ")
			end

			return pick or ""
		end,
		function(v)
			item:set(v, true)

			if cfg.callback then
				callback(cfg.callback, value())
			end
		end,
		{ validate = function(v)
			local function known(name)
				for i = 1, #data do
					if data[i].name == name then
						return true
					end
				end

				return false
			end

			if not cfg.multi then
				return v == "" or known(v)
			end

			for name in string.gmatch(tostring(v), "[^,]+") do
				if not known(string.match(name, "^%s*(.-)%s*$")) then
					return false
				end
			end

			return true
		end })

	task.defer(reflow)

	return item
end

-- ============================================================== dialogs ====
-- The little menu a grid cell opens: a few actions and, where a feature
-- wants them, sliders for the thing that was clicked.
ui.livepopup = nil

function visualsui:closepopup()
	if ui.livepopup then
		local hull = ui.livepopup

		ui.livepopup = nil

		ui.conceal(hull, function()
			if hull.Parent then
				hull:Destroy()
			end
		end)
	end
end

function visualsui:popup(cfg)
	cfg = params(cfg or {}, {
		title = "",
		icon = nil,
		x = 0,
		y = 0,
		width = 194,
		items = nil,
		sliders = nil,
		follow = nil,
	})

	visualsui:closepopup()

	local th = ui.palette()
	local items = type(cfg.items) == "table" and cfg.items or {}
	local sliders = type(cfg.sliders) == "table" and cfg.sliders or {}
	local hull = ui.floater(math.max(tonumber(cfg.width) or 194, 140), 0)

	local box = new("Frame", {
		Name = rnd(),
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.new(1, -20, 1, -20),
		BackgroundTransparency = 1,
		ZIndex = 402,
	}, hull)

	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
	}, box)

	local head = new("Frame", {
		Name = rnd(),
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		ZIndex = 402,
	}, box)

	if cfg.icon then
		new("ImageLabel", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(13, 13),
			BackgroundTransparency = 1,
			Image = icon(cfg.icon),
			ImageColor3 = th.dim,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 403,
		}, head)
	end

	new("TextLabel", {
		Name = rnd(),
		Position = UDim2.fromOffset(cfg.icon and 19 or 0, 0),
		Size = UDim2.new(1, cfg.icon and -19 or 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = tostring(cfg.title or ""),
		TextColor3 = th.text,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 403,
	}, head)

	local tall = 20 + 16 + 6
	local api = ui.attach(nil, box)

	for _, s in next, sliders do
		if type(s) == "table" then
			api:slider({
				name = s.name or s.Name or "",
				min = s.min or s.Min or 0,
				max = s.max or s.Max or 100,
				default = s.value or s.Value or s.default,
				step = s.step or s.Step or (s.precision and 10 ^ -s.precision) or 1,
				suffix = s.suffix or s.Suffix or "",
				callback = s.callback or s.Callback,
			})

			tall += 46
		end
	end

	for _, it in next, items do
		if type(it) == "table" then
			api:button({
				name = it.name or it.Name or "",
				icon = it.icon or it.Icon,
				callback = function()
					visualsui:closepopup()
					callback(it.callback or it.Callback)
				end,
			})

			tall += 34
		end
	end

	ui.livepopup = hull

	local function shut()
		visualsui:closepopup()
	end

	hush()
	sink()

	local at = Vector2.new(tonumber(cfg.x) or 0, tonumber(cfg.y) or 0)

	ui.place(hull, at.X, at.Y, nil, math.min(tall, 320))
	ui.reveal(hull, math.min(tall, 320))

	sky = shut
	skyzone = hull

	return hull
end

-- A prompt: a line of text, or just a yes and a no.
ui.liveask = nil

function visualsui:closeask()
	if ui.liveask then
		local hull = ui.liveask

		ui.liveask = nil
		latch(-1)

		ui.conceal(hull, function()
			if hull.Parent then
				hull:Destroy()
			end
		end)
	end
end

function visualsui:ask(cfg)
	cfg = params(cfg or {}, {
		title = "",
		icon = nil,
		hint = "",
		accept = "ok",
		deny = "cancel",
		confirm = false,
		callback = nil,
	})

	visualsui:closeask()

	local th = ui.palette()
	local hull = ui.floater(300, 0)

	hull.AnchorPoint = Vector2.new(0.5, 0.5)
	hull.Position = UDim2.fromScale(0.5, 0.5)
	hull.ZIndex = 600

	local box = new("Frame", {
		Name = rnd(),
		Position = UDim2.fromOffset(14, 14),
		Size = UDim2.new(1, -28, 1, -28),
		BackgroundTransparency = 1,
		ZIndex = 602,
	}, hull)

	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
	}, box)

	local head = new("Frame", {
		Name = rnd(),
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		ZIndex = 602,
	}, box)

	new("ImageLabel", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(15, 15),
		BackgroundTransparency = 1,
		Image = icon(cfg.icon or "info"),
		ImageColor3 = th.accent,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 603,
	}, head)

	new("TextLabel", {
		Name = rnd(),
		Position = UDim2.fromOffset(22, 0),
		Size = UDim2.new(1, -22, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = tostring(cfg.title or ""),
		TextColor3 = th.text,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 603,
	}, head)

	local field

	if not cfg.confirm then
		field = new("TextBox", {
			Name = rnd(),
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundColor3 = ui.sheet.row,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			Text = "",
			TextColor3 = th.text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			PlaceholderText = tostring(cfg.hint or ""),
			PlaceholderColor3 = th.dim,
			ClearTextOnFocus = false,
			LayoutOrder = 2,
			ZIndex = 602,
		}, box)

		round(field, 8)

		new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, field)
	end

	local foot = new("Frame", {
		Name = rnd(),
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		ZIndex = 602,
	}, box)

	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	}, foot)

	local function leaf(text, order, strong)
		local b = new("TextButton", {
			Name = rnd(),
			Size = UDim2.new(0.5, -4, 1, 0),
			BackgroundColor3 = strong and th.accent or ui.sheet.row,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			Text = tostring(text),
			TextColor3 = strong and th.bg or th.text,
			TextSize = 12,
			LayoutOrder = order,
			ZIndex = 603,
		}, foot)

		round(b, 8)

		return b
	end

	local no = leaf(cfg.deny, 1, false)
	local yes = leaf(cfg.accept, 2, true)

	conn(no.MouseButton1Click, function()
		visualsui:chime("close")
		visualsui:closeask()
	end)

	conn(yes.MouseButton1Click, function()
		local text = field and field.Text or ""

		visualsui:chime("tap")
		visualsui:closeask()
		callback(cfg.callback, text)
	end)

	if field then
		conn(field.FocusLost, function(enter)
			if enter then
				local text = field.Text

				visualsui:closeask()
				callback(cfg.callback, text)
			end
		end)
	end

	ui.liveask = hull
	latch(1)

	ui.reveal(hull, cfg.confirm and 92 or 132)

	if field then
		task.defer(function()
			pcall(function()
				field:CaptureFocus()
			end)
		end)
	end

	return hull
end

-- =============================================================== unload ====
function visualsui:unload()
	if scr then
		pcall(function()
			scr.Enabled = false
		end)
	end

	pcall(visualsui.closeask, visualsui)
	pcall(visualsui.closepopup, visualsui)

	visualsui.alive = false
	visualsui.applyEpoch = (visualsui.applyEpoch or 0) + 1
	visualsui.quiet = false
	visualsui.configApplying = false
	locks = 0
	visualsui.cursor = false
	visualsui.shown = false

	pcall(rouse)
	pcall(capture, nil)
	pcall(hush)

	table.clear(eyes)
	table.clear(hive)
	table.clear(visualsui.pool)
	table.clear(visualsui.order)
	table.clear(visualsui.heads or {})

	for _, c in next, visualsui.conns do
		pcall(function()
			c:Disconnect()
		end)
	end

	table.clear(visualsui.conns)
	table.clear(visualsui.wins)

	if scr then
		pcall(function()
			scr:Destroy()
		end)
	end
end

getgenv().visualsui = visualsui

-- Glass is part of the surface hosts can reuse: the music HUD and the
-- watermark draw with the same material as the menu.
visualsui.glass = ui.glass
visualsui.sheen = ui.sheen

return visualsui
