local helpers = require('test.functional.helpers')(after_each)
local Screen = require('test.functional.ui.screen')
local clear = helpers.clear
local command = helpers.command
local feed = helpers.feed
local feed_command = helpers.feed_command
local exec = helpers.exec

describe('cmdline', function()
  before_each(clear)

  -- oldtest: Test_cmdlineclear_tabenter()
  it('is cleared when switching tabs', function()
    local screen = Screen.new(30, 10)
    screen:attach()
    screen:set_default_attr_ids {
      [1] = {underline = true, background = Screen.colors.LightGrey};
      [2] = {bold = true};
      [3] = {reverse = true};
      [4] = {bold = true, foreground = Screen.colors.Blue1};
    }
    -- TODO(bfredl): redraw with tabs is severly broken. fix it
    feed_command [[ set display-=msgsep ]]

    feed_command([[call setline(1, range(30))]])
    screen:expect([[
      ^0                             |
      1                             |
      2                             |
      3                             |
      4                             |
      5                             |
      6                             |
      7                             |
      8                             |
      :call setline(1, range(30))   |
    ]])

    feed [[:tabnew<cr>]]
    screen:expect{grid=[[
      {1: + [No Name] }{2: [No Name] }{3:     }{1:X}|
      ^                              |
      {4:~                             }|
      {4:~                             }|
      {4:~                             }|
      {4:~                             }|
      {4:~                             }|
      {4:~                             }|
      {4:~                             }|
      :tabnew                       |
    ]]}

    feed [[<C-w>-<C-w>-]]
    screen:expect{grid=[[
      {1: + [No Name] }{2: [No Name] }{3:     }{1:X}|
      ^                              |
      {4:~                             }|
      {4:~                             }|
      {4:~                             }|
      {4:~                             }|
      {4:~                             }|
                                    |
                                    |
      :tabnew                       |
    ]]}

    feed [[gt]]
    screen:expect{grid=[[
      {2: + [No Name] }{1: [No Name] }{3:     }{1:X}|
      ^0                             |
      1                             |
      2                             |
      3                             |
      4                             |
      5                             |
      6                             |
      7                             |
                                    |
    ]]}

    feed [[gt]]
    screen:expect([[
      {1: + [No Name] }{2: [No Name] }{3:     }{1:X}|
      ^                              |
      {4:~                             }|
      {4:~                             }|
      {4:~                             }|
      {4:~                             }|
      {4:~                             }|
                                    |
                                    |
                                    |
    ]])
  end)

  -- oldtest: Test_verbose_option()
  it('prints every executed Ex command if verbose >= 16', function()
    local screen = Screen.new(60, 12)
    screen:attach()
    exec([[
      command DoSomething echo 'hello' |set ts=4 |let v = '123' |echo v
      call feedkeys("\r", 't') " for the hit-enter prompt
      set verbose=20
    ]])
    feed_command('DoSomething')
    screen:expect([[
                                                                  |
      ~                                                           |
      ~                                                           |
                                                                  |
      Executing: DoSomething                                      |
      Executing: echo 'hello' |set ts=4 |let v = '123' |echo v    |
      hello                                                       |
      Executing: set ts=4 |let v = '123' |echo v                  |
      Executing: let v = '123' |echo v                            |
      Executing: echo v                                           |
      123                                                         |
      Press ENTER or type command to continue^                     |
    ]])
  end)

  -- oldtest: Test_cmdline_redraw_tabline()
  it('tabline is redrawn on entering cmdline', function()
    local screen = Screen.new(30, 6)
    screen:set_default_attr_ids({
      [0] = {bold = true, foreground = Screen.colors.Blue},  -- NonText
      [1] = {reverse = true},  -- TabLineFill
    })
    screen:attach()
    exec([[
      set showtabline=2
      autocmd CmdlineEnter * set tabline=foo
    ]])
    feed(':')
    screen:expect([[
      {1:foo                           }|
                                    |
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      :^                             |
    ]])
  end)
end)

describe('cmdwin', function()
  before_each(clear)

  -- oldtest: Test_cmdwin_interrupted()
  it('still uses a new buffer when interrupting more prompt on open', function()
    local screen = Screen.new(30, 16)
    screen:set_default_attr_ids({
      [0] = {bold = true, foreground = Screen.colors.Blue},  -- NonText
      [1] = {bold = true, reverse = true},  -- StatusLine
      [2] = {reverse = true},  -- StatusLineNC
      [3] = {bold = true, foreground = Screen.colors.SeaGreen},  -- MoreMsg
      [4] = {bold = true},  -- ModeMsg
    })
    screen:attach()
    command('set more')
    command('autocmd WinNew * highlight')
    feed('q:')
    screen:expect({any = '{3:%-%- More %-%-}^'})
    feed('q')
    screen:expect([[
                                    |
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {2:[No Name]                     }|
      {0::}^                             |
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {1:[Command Line]                }|
                                    |
    ]])
    feed([[aecho 'done']])
    screen:expect([[
                                    |
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {2:[No Name]                     }|
      {0::}echo 'done'^                  |
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {1:[Command Line]                }|
      {4:-- INSERT --}                  |
    ]])
    feed('<CR>')
    screen:expect([[
      ^                              |
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      {0:~                             }|
      done                          |
    ]])
  end)
end)
