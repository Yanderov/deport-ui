# Deport UI

The menu library Salad Visuals draws itself with: one rounded window, a bar of
groups along the bottom, a capsule of sub-pages under the title, and cards in
one or two columns under that.

| File | What it is |
|---|---|
| `deport.luau` | The library. Window, pages, cards, every control, plus the config engine, asset loader, fonts, sounds, cursor, watermark, hotkey badges and notifications. |
| `adapter.luau` | A NeverLose-shaped API over it, so `main.lua` keeps its twenty-six thousand lines of `AddTab`/`AddSection`/`AddToggle` calls untouched. |

`Tools/build_clean.py` reads both, strips the comments and folds them into
`dist/main.lua`; nothing is fetched at run time.

## Using the library directly

```lua
local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Yanderov/deport-ui/main/deport.luau"))()

local win = lib:window({ title = "Deport", build = "build: 1.0", size = UDim2.fromOffset(860, 600), bind = "RightShift" })

local tab = win:tab({ name = "Visuals", icon = "eye" })
local page = tab:sub({ name = "ESP", icon = "user" })
local card = page:section({ name = "Players", side = "left" })

card:toggle({ name = "Enabled", flag = "esp_on", callback = function(on) print(on) end })
card:slider({ name = "Distance", min = 0, max = 500, default = 200, suffix = "m", flag = "esp_range" })
card:combo({ name = "Target", list = { "All", "Enemies" }, default = "All", flag = "esp_target" })
card:color({ name = "Box", default = Color3.new(1, 1, 1), flag = "esp_box" })
card:keybind({ name = "Panic", default = "RightAlt", flag = "esp_panic" })
card:input({ name = "Note", placeholder = "anything", flag = "esp_note" })
card:button({ name = "Reset", icon = "refresh-cw", callback = function() end })
card:label({ name = "a line of text", wrap = true })
```

### Window

```lua
win:tab({ name, icon })          -- an entry in the bottom bar
tab:sub({ name, icon })          -- a page in the capsule under the title
tab:section({ name, side })      -- a card; side is "left", "right" or "full"
sub:gallery({ ... })             -- a virtualised picture grid
sub:configs({ name, side })      -- the saved-profile card
sub:color({ name, key, side })   -- a palette colour, by theme key

win:render(true)                 -- show or hide
win:toggle()
win:setsize(UDim2.fromOffset(900, 620))
win:setbind("Insert")
win:setbuild("build: 1.1")
```

### Controls

Every control returns an element with `:get()` and `:set(value, quiet)`. A
`flag` registers it with the config engine; a toggle also gets a right-click
keybind, which shows up in the badge list on screen.

A toggle carries a fold-out panel for the controls that belong to it:

```lua
local esp = card:toggle({ name = "Box", options = true, flag = "box" })

esp.options.reveal()
esp.options:slider({ name = "Thickness", min = 1, max = 5, default = 1, flag = "box_width" })
```

### Configs

```lua
lib:hook(id, kind, get, set, schema)  -- register anything else as a setting
lib:freeze()                          -- the whole menu as one string
lib:thaw(blob)                        -- read one back
lib:apply(data)                       -- put it on
lib:store(name) / :fetch(name) / :erase(name) / :roster()
lib:setautoload(name) / :autoload()
```

### Theme

Nine roles — `bg`, `side`, `panel`, `head`, `line`, `glow`, `text`, `dim`,
`accent` — plus a fixed sheet palette for the floating panels.

```lua
lib:retheme({ accent = Color3.fromRGB(96, 156, 255) })
lib:recolor("accent", Color3.new(1, 1, 1))
lib:setfont("Montserrat")   -- lib:fontnames() lists them
```

### HUD

```lua
lib:setwatermark(true)
lib:setwatermarktext("inertiahub.xyz")
lib:sethotkeys(true)
lib:setlinks({ { image = "rbxassetid://1", callback = function() end } })
lib:notify({ title = "done", text = "all good", icon = "check", life = 3 })
lib:ask({ title = "add model", hint = "id", accept = "add", deny = "cancel", callback = print })
lib:popup({ title = "Item", x = 100, y = 100, items = { ... }, sliders = { ... } })
lib:unload()
```

## Testing it

`python Tools/test_ui.py` builds the whole menu outside Roblox against
`Tools/robloxstub.luau` and drives every control, the config round trip, the
dialogs, the navigation and the unload. `python Tools/test_performance.py`
runs it as part of the wider suite.
