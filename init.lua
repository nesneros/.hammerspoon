hs.loadSpoon("SpoonInstall")

-- For VSCode extension
spoon.SpoonInstall:andUse("EmmyLua", {})
spoon.SpoonInstall:andUse("RecursiveBinder", {})

spoon.RecursiveBinder.escapeKey = { {}, 'escape' } -- Press escape to abort

local singleKey = spoon.RecursiveBinder.singleKey

local keyMap = {
    [singleKey('b', 'browser')] = function() hs.application.launchOrFocus("Arc") end,
    [singleKey('t', 'kitty')] = function() hs.application.launchOrFocus("Kitty") end,
    [singleKey('h', 'hammerspoon+')] = {
        [singleKey('h', 'reload config')] = function() hs.reload() end,
        [singleKey('c', 'toggle console')] = function() hs.toggleConsole() end
    },
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
    activate_app_and_send_key("Arc", { "cmd" }, "t")
end)

