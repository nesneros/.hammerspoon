local logger = hs.logger.new('init.lua', 'debug')

hs.allowAppleScript(true)

require('hs.ipc')

hs.loadSpoon("SpoonInstall")
Install = spoon.SpoonInstall
Install.use_syncinstall = true

Install:andUse("EmmyLua", {})
Install:andUse("KSheet", {})

local key = {
    -- Keys bound with Karabiner
    caps_lock_tap = 'F13',
    left_alt = 'F16',
    left_command = 'F17',
    right_shift_double_tab = 'F18',
    right_alt = 'F19',
    both_shift = 'F20',

    hyper = { 'shift', 'ctrl', 'alt', 'cmd' },
}

----------------------------------------------------------------------------------------------------
--- Global hotkeys
local function activateAppAandSsendKkey(app_name, mods, key)
    hs.application.launchOrFocus(app_name)
    local app = hs.appfinder.appFromName(app_name)
    if app then
        app:activate()
        hs.eventtap.keyStroke(mods, key, 10000, app)
    else
        hs.alert.show(string.format("%s not found", app_name))
    end
end


----------------------------------------------------------------------------------------------------
--- Keyboard layouts
local function rotateKeyboarLayout()
    local allLayouts = hs.keycodes.layouts()

    local currentLayout = hs.keycodes.currentLayout()
    local newIndex = 1
    for i = 1, #allLayouts - 1 do
        if allLayouts[i] == currentLayout then
            newIndex = i + 1
            break
        end
    end
    hs.keycodes.setLayout(allLayouts[newIndex])
end

local function mute(flag)
    local output = hs.audiodevice.defaultOutputDevice()
    logger.df("mute: %s: %s", flag, output)
    output:setMuted(flag)
    if flag then
        local input = hs.audiodevice.defaultInputDevice()
        logger.df("mute: %s: %s", flag, input)
        input:setMuted(flag)
    end
end

local function detectScreens(primary_required, secondary_required)
    local laptop, primary, secondary = nil, nil, nil
    for k, v in pairs(hs.screen.allScreens()) do
        local name = v:name()
        logger.df("Screen %s: %s", k, name)
        if name == "Built-in Retina Display" then
            logger.df("Laptop screen: %s", name)
            laptop = v
        elseif name == "DELL U2720Q (1)" or name == "LG HDR 4K" then
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


----------------------------------------------------------------------------------------------------
--- Location-based actions
local function atWork()
    -- mute(true)
    local laptop, primary, secondary = detectScreens(true, true)

    if laptop == nil then
        return
    end
end

local function atHome(laptop, screen)
    -- mute(false)
    local laptop, primary, secondary = detectScreens(true, false)

    if laptop == nil then
        return
    end
end

local function atHomeWorking()
    mute(false)
    local laptop, primary, secondary = detectScreens(true, false)

    if laptop == nil then
        return
    end
end


----------------------------------------------------------------------------------------------------
--- Watch WiFi access point

-- Hammerspoon might need location services permission for wifi callback to work. Uncomment the following lines to enable it.
-- hs.location.start()

local function wifiChanged(watcher, message, interface, ...)
    if message == "SSIDChange" then
        local ssid = hs.wifi.currentNetwork()
        hs.alert.show("WiFi changed to: " .. (ssid or "none"))
        if ssid == "Reden" then
            mute(false)
        elseif ssid == "Sepior" then
            mute(true)
        end
    end
end

local wifiWatcher = hs.wifi.watcher.new(wifiChanged)
wifiWatcher:start()

local function screensChanged()
    logger.df("Screens changed")
    local laptop, primary, secondary = detectScreens(false, false)
    if primary ~= nil then
        if primary:name() == "LG HDR 4K" then
            logger.df("Location is home")
            atHome()
        elseif primary:name() == "DELL U2720Q (1)" and secondary ~= nil then
            logger.df("Location is work")
            atWork()
        else
            logger.df("Location is unknown")
        end
    end
end

-- Move the currently focused window to a specific screen by name
local function move_window_to_screen(win, screenName)
    -- local win = hs.window.focusedWindow()
    -- if not win then
    --     hs.alert("No focused window")
    --     return
    -- end

    local targetScreen = nil
    for _, screen in ipairs(hs.screen.allScreens()) do
        if screen:name() == screenName then
            targetScreen = screen
            break
        end
    end

    if not targetScreen then
        hs.alert("Screen '" .. screenName .. "' not found")
        return
    end

    win:moveToScreen(targetScreen)
    hs.alert("Moved to " .. screenName)
end


ScreenWatcher = hs.screen.watcher.new(screensChanged)
ScreenWatcher:start()
screensChanged()

local function identifyScreens()
    -- loop through all screens and print out their names
    for i, screen in ipairs(hs.screen.allScreens()) do
        hs.alert("Screen " .. i .. ": " .. screen:name(), screen)
    end
end

local function ksheetToggle()
    spoon.KSheet:toggle()
end

local function reloadConfig()
    hs.console.clearConsole()
    hs.openConsole()
    hs.reload()
end

----------------------------------------------------------------------------------------------------
--- Menubar
-- Always delete existing menubar first
if MyHammerspoonMenu then
    MyHammerspoonMenu:delete()
end

-- Small delay to let macOS process the deletion
-- Store time in variable to avoid it being garbage collected
TheTimer = hs.timer.doAfter(0.1, function()
    MyHammerspoonMenu = hs.menubar.new(true, "myhammerspoonmenubar")
    MyHammerspoonMenu:setTitle("🔨🥄")
    -- menubar:setIcon(hs.image.imageFromName("NSHandCursor"))
    MyHammerspoonMenu:setMenu({
        { title = "Work Layout",        fn = atWork },
        { title = "Home Work Layout",   fn = atHomeWorking, },
        { title = "Home Layout",        fn = atHome, },
        { title = "-" },
        { title = "Toggle KSheet",      fn = ksheetToggle },
        { title = "Reload Config",      fn = reloadConfig },
        { title = "Identify Screens",   fn = identifyScreens },
        -- paste by emitting fake keyboard events. This is a workaround for pasting to (password) fields that blocks pasting.
        { title = "Paste by Keystroke", fn = function() hs.eventtap.keyStrokes(hs.pasteboard.getContents()) end },
        { title = "Toggle Caps Lock",   fn = hs.hid.capslock.toggle },
        { title = "Sleep",              fn = function() hs.caffeinate.systemSleep() end },
    })
    TheTimer = nil
end)

------------------------------------------------------------------------------------------------------------
--- Hammerflow
hs.loadSpoon("Hammerflow")
spoon.Hammerflow.loadFirstValidTomlFile({
    "hammerflow.toml"
})

-- optionally respect auto_reload setting in the toml config.
if spoon.Hammerflow.auto_reload then
    hs.loadSpoon("ReloadConfiguration")
    -- set any paths for auto reload
    -- spoon.ReloadConfiguration.watch_paths = {hs.configDir, "~/path/to/my/configs/"}
    spoon.ReloadConfiguration:start()
end

--------------------------------------------------------------------------------------------------------------------
--- Key bindings
hs.hotkey.bind({}, key.both_shift, rotateKeyboarLayout)

-- Activate Cmd-T in Arc
hs.hotkey.bind(key.hyper, "q", function()
    activateAppAandSsendKkey("Arc", { "cmd" }, "t")
end)

function UpdateAllSpoons()
    local spoonDir = os.getenv("HOME") .. "/.hammerspoon/Spoons/"
    local handle = io.popen('ls "' .. spoonDir .. '"')
    local result = handle:read("*a")
    handle:close()

    local spoons = {}
    for spoonFolder in result:gmatch("([^\n]+)%.spoon/?") do
        table.insert(spoons, spoonFolder)
    end

    print("Installed Spoons:")
    for _, name in ipairs(spoons) do
        print("  " .. name)
    end


    spoon.SpoonInstall:updateAllRepos()
    for _, name in ipairs(spoons) do
        print("Updating " .. name)
        spoon.SpoonInstall:installSpoonFromRepo(name)
    end
    print("All Spoons updated.")
end
