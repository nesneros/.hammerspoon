local logger = hs.logger.new('MyApp', 'debug')

hs.loadSpoon("SpoonInstall")
Install = spoon.SpoonInstall
Install.use_syncinstall = true

Install:andUse("EmmyLua", {})
Install:andUse("KSheet", {})
Install:andUse("RecursiveBinder", {})

spoon.RecursiveBinder.escapeKey = { {}, 'escape' } -- Press escape to abort
spoon.RecursiveBinder.helperEntryEachLine = 4
spoon.RecursiveBinder.helperEntryLengthInChar = 30
local singleKey = spoon.RecursiveBinder.singleKey

logger.i(hs.keycodes.currentLayout())

local keyMap = {
    [singleKey('b', 'browser')] = function() hs.application.launchOrFocus("Arc") end,
    [singleKey('t', 'kitty')] = function() hs.application.launchOrFocus("Kitty") end,
    [singleKey('s', 'keybindings')] = function() spoon.KSheet:toggle() end,
    [singleKey('h', 'HS console & reload')] = function()
        hs.toggleConsole(); hs.reload()
    end,
    [singleKey('f', 'finder+')] = {
        [singleKey('h', 'home')] = function() hs.execute("open ~") end,
        [singleKey('d', 'Documents')] = function() hs.execute("open ~/Documents") end
    }
}
hs.hotkey.bind({ 'alt' }, 'space', spoon.RecursiveBinder.recursiveBind(keyMap))

----------------------------------------------------------------------------------------------------
-- paste by emitting fake kweyboard events. This is a workaround for pasting to (password) fields that blocks pasting.
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "V", function() hs.eventtap.keyStrokes(hs.pasteboard.getContents()) end)

----------------------------------------------------------------------------------------------------
--- Global hotkeys
local function activate_app_and_send_key(app_name, mods, key)
    hs.application.launchOrFocus(app_name)
    local app = hs.appfinder.appFromName(app_name)
    if app then
        app:activate()
        hs.eventtap.keyStroke(mods, key, 10000, app)
    else
        hs.alert.show(string.format("%s not found", app_name))
    end
end

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "T", function()
    -- hs.hotkey.bind({ "cmd" }, "tab", function()
    activate_app_and_send_key("Arc", { "cmd" }, "t")
end)


local function caffeinate(on)
    -- hs.caffeinate.
end

----------------------------------------------------------------------------------------------------
--- Keyboard layouts
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "I", function()
    local allLayouts = { 'U.S.', 'Danish' }

    local currentLayout = hs.keycodes.currentLayout()
    local newIndex = 1
    for i = 1, #allLayouts - 1 do
        if allLayouts[i] == currentLayout then
            newIndex = i + 1
            break
        end
    end
    hs.keycodes.setLayout(allLayouts[newIndex])
end)


----------------------------------------------------------------------------------------------------
--- Window management

local function detect_screens(primary_required, secondary_required)
    local laptop, primary, secondary = nil, nil, nil
    for k, v in pairs(hs.screen.allScreens()) do
        local name = v:name()
        logger.df("Screen %s: %s", k, name)
        if name == "Built-in Retina Display" then
            logger.df("Laptop screen: %s", name)
            laptop = v
        elseif name == "DELL U2720Q (1)" then
            logger.df("Primary screen: %s", name)
            primary = v
        elseif name == "DELL U2720Q (2)" then
            logger.df("Secondary screen: %s", name)
            secondary = v
        else
            logger.ef("Unknown screen: %s", name)
        end
    end

    if laptop == nil then
        hs.alert.show("Laptop screen not found")
        return
    end

    if primary_required and primary == nil then
        hs.alert.show("Primary screen not found")
        return
    end
    if secondary_required and secondary == nil then
        hs.alert.show("Secondary screen not found")
        return
    end
    return laptop, primary, secondary
end

local function work_layout()
    local laptop, primary, secondary = detect_screens(true, true)

    if laptop == nil then
        return
    end
end

local function home_layout()
    local laptop, primary, secondary = detect_screens(true, false)

    if laptop == nil then
        return
    end
end

local function home_work_layout()
    local laptop, primary, secondary = detect_screens(true, false)

    if laptop == nil then
        return
    end
end

----------------------------------------------------------------------------------------------------
--- Menubar
local menubar = hs.menubar.new(true, "myhammerspoonmenubar")
if menubar then
    menubar:setIcon(hs.image.imageFromName("NSHandCursor"))
    menubar:setMenu({
        { title = "Sleep",            fn = function() hs.caffeinate.systemSleep() end },
        {
            title = "Caffeinate",
            checked = true,
            fn = function()
                hs.reload()
            end
        },
        { title = "-" },
        { title = "Work Layout",      fn = work_layout },
        { title = "Home Work Layout", fn = home_work_layout, },
        { title = "Home Layout",      fn = home_layout, },
    })
end
