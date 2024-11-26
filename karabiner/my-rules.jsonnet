local basic = { type: 'basic' };

local to(key) = { to: [{ key_code: key }] };
local to_if_alone(key) = { to_if_alone: [{ key_code: key }] };

local from_with_mods(from_key, mods) = {
  from: {
    key_code: from_key,
    modifiers: { mandatory: mods },
  },
};

local from_with_any_mods(from_key) = {
  from: {
    key_code: from_key,
    modifiers: { optional: ['any'] },
  },
};

local from_simul(key1, key2) = {
  from: {
    simultaneous: [
      { key_code: key1 },
      { key_code: key2 },
    ],
  },
};

local set_var(var, value) = {
  set_variable: {
    name: var,
    value: value,
  },
};

// Map a modifier key to another key (e.g. f-key) if pressed allone. If pressed with other keys, it will work as normal modifier.
local map_modifier(modifier, to_key) = {
  description: modifier + ' -> ' + to_key,
  manipulators: [
    basic + to(modifier) + to_if_alone(to_key) + from_with_mods(modifier, []),
  ],
};

local same_time_modifier(modifier1, modifier2, to_key) = {
  entry:: function(mod1, mod2) basic + to(to_key) + to_if_alone(mod1) + from_with_mods(mod1, [mod2]) {},
  description: modifier1 + ' + ' + modifier2 + ' at the same time -> ' + to_key,
  manipulators: [
    self.entry(modifier1, modifier2),
    self.entry(modifier2, modifier1),
  ],
};

local map_simultaneous(key1, key2, to_key) = {
  description: key1 + ' + ' + key2 + ' (simultaneously) -> ' + to_key,
  manipulators: [
    basic + to(to_key) + from_simul(key1, key2),
  ],
};

// hold a (for app) together with another key to open an app
local open_app(key, app) = {
  description: 'a & ' + key + ' (simultaneously) => Open ' + app,
  manipulators: [
    basic {
      from: {
        simultaneous: [
          {
            key_code: 'a',
          },
          {
            key_code: key,
          },
        ],
      },
      to_if_held_down: [
        {
          shell_command: 'open -a "' + app + '"',
        },
      ],
      parameters: {
        'basic.simultaneous_threshold_milliseconds': 50,
        'basic.to_if_held_down_threshold_milliseconds': 175,
      },
    },
  ],
};

local hyper = ['left_shift', 'left_command', 'left_control', 'left_alt'];
local hyperKey = 'tab';

local map_hyper(from, to_key) = {
  description: hyperKey + ' ' + from + ' -> ' + to_key,
  manipulators: [
    basic + to(to_key) + from_with_mods(from, hyper),
  ],
};

local disable_hyper_on_key(key) = basic + from_with_any_mods(key) {
  to: [
    { key_code: key },
    set_var('disable_hyper_key', 1),
  ],
  to_after_key_up: [set_var('disable_hyper_key', 0)],
};

local double_tap(key, to) = {
  setv:: function(value) set_var(key + ' pressed', value),
  description: 'double-tap ' + key + ' -> ' + to,
  manipulators: [
    basic + from_with_any_mods(key) {
      conditions: [
        {
          name: key + ' pressed',
          type: 'variable_if',
          value: 1,
        },
      ],
      to: [
        $.setv(0),
        { key_code: to },
      ],
    },
    basic + from_with_any_mods(key) {
      to: [
        $.setv(1),
        { key_code: key },
      ],
      to_delayed_action: {
        to_if_canceled: [$.setv(0)],
        to_if_invoked: [$.setv(0)],
      },
    },
  ],
};

{
  // F20 seems to be the highest possible function key
  title: 'Personal',
  rules: [
    // map_modifier('left_shift', 'f13'),
    // Note that F14 and F15 controls brightness. Seems not possible to disable them.
    // map_modifier('fn', 'f16'),
    // map_modifier('left_control', 'f17'),
    map_modifier('left_alt', 'f16'),
    map_modifier('left_command', 'f17'),
    // map_modifier('right_command', 'f18'),
    map_modifier('right_alt', 'f19'),
    // map_modifier('right_control', 'f19'),
    // map_modifier('right_shift', 'f19'),
    same_time_modifier('left_shift', 'right_shift', 'f20'),
    double_tap('right_shift', 'f18'),
    {
      description: 'Change caps_lock to control if pressed with other keys, to escape if pressed alone.',
      manipulators: [
        basic + to('left_control') + to_if_alone('escape') + from_with_any_mods('caps_lock'),
      ],
    },
    // hyper . and , flashes the screen. '.' also make a system diagnostic. Map these to F24.
    map_hyper('comma', 'f24'),
    map_hyper('period', 'f24'),
    map_hyper('w', 'f24'),
    {
      description: 'Change ' + hyperKey + ' to hyper if pressed with other keys.',
      manipulators: [
        basic + to_if_alone(hyperKey) {
          conditions: [
            {
              name: 'disable_hyper_key',
              type: 'variable_if',
              value: 0,
            },
          ],
          from: {
            key_code: hyperKey,
            modifiers: {},
          },
          to_if_held_down: [
            {
              key_code: hyper[0],
              modifiers: std.slice(hyper, 1, std.length(hyper), 1),
            },
          ],
          parameters: {
            'basic.to_if_alone_timeout_milliseconds': 150,
            'basic.to_if_held_down_threshold_milliseconds': 150,
          },
        },
        // disale hyper key when pressing '.' and ',' because that will trigger a system diagnostic.
        disable_hyper_on_key('period'),
        disable_hyper_on_key('comma'),
      ],
    },

    // open_app('b', 'Arc'),
    // open_app('s', 'Slack'),
    // open_app('t', 'Kitty'),
    // open_app('v', 'Visual Studio Code'),

    map_simultaneous('delete_or_backspace', 'equal_sign', 'delete_forward'),
    // VIM navi with haper
    map_hyper('h', 'left_arrow'),
    map_hyper('j', 'down_arrow'),
    map_hyper('k', 'up_arrow'),
    map_hyper('l', 'right_arrow'),
  ],
}
