<p align="center">
  <h1 align="center">veil.nvim</h1>
</p>

<p align="center">
  <strong>Hide your secrets. Stream with confidence.</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#contributing">Contributing</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Neovim-0.9+-blueviolet.svg?style=for-the-badge&logo=neovim" alt="Neovim" />
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License" />
  <img src="https://img.shields.io/github/stars/Gentleman-Programming/veil.nvim?style=for-the-badge" alt="Stars" />
</p>

---

## Demo

https://github.com/user-attachments/assets/9583b667-2e98-41b7-990f-298eed37e402

---

## Why veil.nvim?

Ever been streaming or screen sharing and accidentally exposed your API keys? **veil.nvim** automatically conceals sensitive values in your config files, so you can code without worry.

Unlike other plugins that rely on complex regex patterns, **veil.nvim** uses simple, predictable patterns that just work with standard configuration file formats.

---

## Features

| Feature | Description |
|---------|-------------|
| **Auto-conceal** | Automatically hides sensitive values when you open `.env`, `.npmrc`, and other config files |
| **Smart patterns** | Works with `KEY=value` and `key: value` formats out of the box |
| **Peek mode** | Quickly reveal the value on the current line with `<leader>sp` |
| **Theme-aware** | Uses your colorscheme's Comment color by default |
| **Fully customizable** | Add your own files, patterns, and keybindings |
| **Zero config** | Works immediately with sensible defaults |

---

## Installation

### lazy.nvim

```lua
{
  "Gentleman-Programming/veil.nvim",
  event = "VeryLazy",
  config = function()
    require("veil").setup()
  end,
}
```

### packer.nvim

```lua
use {
  "Gentleman-Programming/veil.nvim",
  config = function()
    require("veil").setup()
  end,
}
```

---

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `:Veil` | Toggle veil on/off |
| `:VeilEnable` | Enable veil |
| `:VeilDisable` | Disable veil |
| `:VeilPeek` | Reveal value on current line (auto-hides when you leave) |

### Default Keybindings

| Keymap | Action |
|--------|--------|
| `<leader>sv` | Toggle veil on/off |
| `<leader>sp` | Peek at value on current line |

---

## Configuration

### Quick Start

Just call setup with no arguments for sensible defaults:

```lua
require("veil").setup()
```

### Adding Custom Files & Patterns

```lua
require("veil").setup({
  -- Add extra files (merged with defaults)
  extra_files = {
    "config.secret.json",
    "*.credentials",
  },

  -- Add extra patterns - simple keywords or full patterns
  extra_patterns = {
    "MY_CUSTOM_VAR",      -- Simple keyword
    "COMPANY_API_KEY",    -- Another keyword
  },
})
```

### Full Options

<details>
<summary>Click to expand all options</summary>

```lua
require("veil").setup({
  -- Files where veil is automatically enabled
  files = {
    ".env",
    ".env.*",
    ".npmrc",
    ".pypirc",
    "credentials.json",
    "secrets.yaml",
    "secrets.yml",
    ".secrets",
  },

  -- Patterns to match (VALUE part will be concealed)
  patterns = {
    { pattern = "(%w+_KEY%s*[=:]%s*[\"']?)([^\"'\n]+)", group = 2 },
    { pattern = "(%w+_SECRET%s*[=:]%s*[\"']?)([^\"'\n]+)", group = 2 },
    { pattern = "(%w+_TOKEN%s*[=:]%s*[\"']?)([^\"'\n]+)", group = 2 },
    { pattern = "(%w+_PASSWORD%s*[=:]%s*[\"']?)([^\"'\n]+)", group = 2 },
  },

  -- Character used to conceal
  conceal_char = "*",

  -- Auto enable on matching files
  auto_enable = true,

  -- Extra files (merged with defaults)
  extra_files = {},

  -- Extra patterns (merged with defaults)
  extra_patterns = {},

  -- Use ONLY your files, ignore defaults
  exclude_default_files = false,

  -- Use ONLY your patterns, ignore defaults
  exclude_default_patterns = false,

  -- Customize conceal color (nil = theme's Comment color)
  highlight = nil, -- or { fg = "#ff0000" }

  -- Reveal values in insert mode on current line
  reveal_on_insert = false,

  -- Keybindings (false to disable)
  keymaps = {
    toggle = "<leader>sv",
    peek = "<leader>sp",
  },
})
```

</details>

---

## How It Works

```
# What's in your file:
API_KEY="sk_live_super_secret_123"
DATABASE_URL="postgresql://user:password@localhost/db"

# What you see with veil.nvim:
API_KEY="**************************"
DATABASE_URL="*************************************"
```

Veil uses Neovim's built-in `conceal` feature to hide sensitive values while keeping keys visible. The peek feature (`<leader>sp`) lets you quickly reveal individual values when you need them.

---

## Supported Files (Default)

- `.env`, `.env.*` (environment files)
- `.npmrc` (npm config)
- `.pypirc` (Python package index)
- `credentials.json`
- `secrets.yaml`, `secrets.yml`
- `.secrets`

---

## Contributing

Issues and PRs welcome! Check out the [GitHub repo](https://github.com/Gentleman-Programming/veil.nvim).

---

<p align="center">
  Made with care by <a href="https://github.com/Gentleman-Programming">Gentleman Programming</a>
</p>
