local logger = hs.logger.new('init.lua', 'debug')

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

-- Activate cmd-T in Arc
hs.hotkey.bind(key.hyper, "q", function()
    activate_app_and_send_key("Arc", { "cmd" }, "t")
end)


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
hs.hotkey.bind({}, key.both_shift, rotateKeyboarLayout)

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

local function screensChanged()
    logger.df("Screens changed")
    local laptop, primary, secondary = detect_screens(false, false)
    if primary ~= nil then
        if primary:name() == "LG HDR 4K" then
            logger.df("Location is home")
        elseif primary:name() == "DELL U2720Q (1)" and secondary ~= nil then
            logger.df("Location is work")
        else
            logger.df("Location is unknown")
        end
    end
end

hs.screen.watcher.new(screensChanged):start()
screensChanged()


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

local function ksheet_toggle()
    spoon.KSheet:toggle()
end

local function reload_config()
    hs.console.clearConsole()
    hs.openConsole()
    hs.reload()
end

----------------------------------------------------------------------------------------------------
--- Menubar
local function createMenubar()
    -- The process here to setup the menu is to ensure that it works with Ice
    -- Always delete existing menubar first
    if MyHammerspoonMenu then
        MyHammerspoonMenu:delete()
    end

    -- Small delay to let macOS process the deletion
    hs.timer.doAfter(0.1, function()
        MyHammerspoonMenu = hs.menubar.new(true, "myhammerspoonmenubar")
        MyHammerspoonMenu:setTitle("🔨🥄")
        -- menubar:setIcon(hs.image.imageFromName("NSHandCursor"))
        MyHammerspoonMenu:setMenu({
            { title = "Work Layout",        fn = work_layout },
            { title = "Home Work Layout",   fn = home_work_layout, },
            { title = "Home Layout",        fn = home_layout, },
            { title = "-" },
            { title = "Toggle KSheet",      fn = ksheet_toggle },
            { title = "Reload Config",      fn = reload_config },
            -- paste by emitting fake keyboard events. This is a workaround for pasting to (password) fields that blocks pasting.
            { title = "Paste by Keystroke", fn = function() hs.eventtap.keyStrokes(hs.pasteboard.getContents()) end },
            { title = "Toggle Caps Lock",   fn = hs.hid.capslock.toggle },
            { title = "Sleep",              fn = function() hs.caffeinate.systemSleep() end },
        })
    end)
end

createMenubar()

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
