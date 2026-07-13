local wezterm = require 'wezterm'

local config = wezterm.config_builder()

config.color_scheme = 'AdventureTime'

-- config.font = wezterm.font 'HackGen Console NF'

-- config.default_prog = { 'C:\\.cargo\\bin\\nu.exe' }

config.default_prog = { 'C:\\Users\\eda3\\AppData\\Local\\Programs\\nu\\bin\\nu.exe' }

set_environment_variables = {
  MISE_PWSH_CHPWD_WARNING = "0",
}

return config
