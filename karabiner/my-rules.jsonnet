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
    {
      description: 'left_shift + right_shift at the same time -> f20',
      manipulators: [
        {
          from: {
            key_code: 'left_shift',
            modifiers: { mandatory: ['right_shift'] },
          },
          to: [{ key_code: 'f20' }],
          to_if_alone: [{ key_code: 'left_shift' }],
          type: 'basic',
        },
        {
          from: {
            key_code: 'right_shift',
            modifiers: {
              mandatory: ['left_shift'],
            },
          },
          to: [{ key_code: 'f20' }],
          to_if_alone: [{ key_code: 'right_shift' }],
          type: 'basic',
        },
      ],
    },
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
    {
      description: 'Change spacebar to hyper, if not pressed with other keys.',
      manipulators: [
        {
          from: {
            key_code: 'spacebar',
            modifiers: {},
          },
          to: [
            {
              key_code: 'left_shift',
              modifiers: ['left_control', 'left_alt', 'left_command'],
            },
          ],
          to_if_alone: [{ key_code: 'spacebar' }],
          type: 'basic',
        },
      ],
    },
  ],
}
