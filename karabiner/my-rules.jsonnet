local map_modifier(modifier, to_key) = {
  description: modifier + ' -> ' + to_key,
  manipulators: [
    {
      type: 'basic',
      from: {
        key_code: modifier,
        modifiers: {},
      },
      to: [
        {
          key_code: modifier,
        },
      ],
      to_if_alone: [
        {
          key_code: to_key,
        },
      ],
    },
  ],
};

local same_time_modifier(modifier1, modifier2, to_key) = {
  entry:: function(mod1, mod2) {
    from: {
      key_code: mod1,
      modifiers: { mandatory: [mod2] },
    },
    to: [{ key_code: to_key }],
    to_if_alone: [{ key_code: mod1 }],
    type: 'basic',
  },
  description: modifier1 + ' + ' + modifier2 + ' at the same time -> ' + to_key,
  manipulators: [
    self.entry(modifier1, modifier2),
    self.entry(modifier2, modifier1),
  ],
};

// hold a (for app) together with another key to open an app
local open_app(key, app) = {
  description: 'a & ' + key + ' (simultaneously) => Open ' + app,
  manipulators: [
    {
      type: 'basic',
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
local hyperKey = 'Space';
local map_hyper(from, to) = {
  description: hyperKey + ' ' + from + ' -> ' + to,
  manipulators: [
    {
      type: 'basic',
      from: {
        key_code: from,
        modifiers: { mandatory: hyper },
      },
      to: [
        {
          key_code: to,
        },
      ],
    },
  ],
};

local disable_hyper_on_key(key) = {
  type: 'basic',
  from: {
    key_code: key,
    modifiers: {
      optional: ['any'],
    },
  },
  to: [
    {
      key_code: key,
    },
    {
      set_variable: {
        name: 'disable_hyper_key',
        value: 1,
      },
    },
  ],
  to_after_key_up: [
    {
      set_variable: {
        name: 'disable_hyper_key',
        value: 0,
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
    {
      description: 'Change caps_lock to control if pressed with other keys, to escape if pressed alone.',
      manipulators: [
        {
          from: {
            key_code: 'caps_lock',
            modifiers: { optional: ['any'] },
          },
          to: [{ key_code: 'left_control' }],
          to_if_alone: [{ key_code: 'escape' }],
          type: 'basic',
        },
      ],
    },
    // hyper . and , flashes the screen. '.' also make a system diagnostic. Map these to F24.
    map_hyper('comma', 'f24'),
    map_hyper('period', 'f24'),
    map_hyper('w', 'f24'),
    {
      description: 'Change spacebar to hyper, if not pressed with other keys.',
      manipulators: [
        {
          conditions: [
            {
              name: 'disable_hyper_key',
              type: 'variable_if',
              value: 0,
            },
          ],
          from: {
            key_code: 'spacebar',
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
          to_if_alone: [{ key_code: 'spacebar' }],
          type: 'basic',
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

    // VIM navi with haper
    map_hyper('h', 'left_arrow'),
    map_hyper('j', 'down_arrow'),
    map_hyper('k', 'up_arrow'),
    map_hyper('l', 'right_arrow'),
  ],
}
