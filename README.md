# highlight.nvim

<div align="center">

A modern, intelligent highlighter for Neovim that keeps your important code visible across files.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Neovim](https://img.shields.io/badge/Neovim-0.10%2B-blue.svg)](https://neovim.io)

</div>

## ✨ Features

- 🎯 **Word Highlighting** - Mark important words that persist across all files
- 🔍 **Range Highlighting** - Highlight code snippets (like `obj->property`) that appear anywhere in your project
- 🌈 **Theme Adaptive** - Automatically extracts colors from your colorscheme for perfect visual harmony
- 🔄 **Cross-Buffer Persistence** - Highlights automatically appear in every file you open
- 🎨 **Saturation Boost** - Enhances visibility with intelligent color adjustment
- 📋 **Picker Integration** - List and jump to all highlights with Snacks picker
- ⚡ **Zero Configuration** - Works out of the box with sensible defaults
- 🚀 **Performance Optimized** - Efficient scanning and rendering with extmarks

## 📸 Quick Preview

```lua
-- Mark this variable name
local function calculateTotal(items)
  local total = 0
  for _, item in ipairs(items) do
    total = total + item.value  -- Press <Leader>hm here
  end
  return total
end

-- "total" is now highlighted in EVERY file in your project
-- Switch to another file and all "total" occurrences are highlighted!
```

## 🚀 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "gagapony/highlight.nvim",
  event = "VeryLazy",  -- Load when needed
  opts = {
    -- Configuration here (optional)
  }
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'gagapony/highlight.nvim'
lua << EOF
require("highlight").setup({})
EOF
```

### Manual Installation

1. Clone this repository to your Neovim config directory:
```bash
git clone https://github.com/gagapony/highlight.nvim.git \
  ~/.config/nvim/lua/highlight
```

2. Add to your `init.lua`:
```lua
require("highlight").setup({})
```

## 🎮 Usage

### Basic Keymaps

All keymaps use `<Leader>h` prefix (default leader is `\`).

| Mode | Key | Action | Example |
|------|-----|--------|---------|
| Normal | `<Leader>hm` | Mark word under cursor | Cursor on `myVar` → press `<Leader>hm` |
| Visual | `<Leader>hm` | Mark selected range | Select `obj->property` → press `<Leader>hm` |
| Normal | `<Leader>hd` | Remove highlight at cursor | Cursor on highlight → press `<Leader>hd` |
| Normal | `<Leader>hD` | Clear all in current buffer | Press `<Leader>hD` |
| Normal | `<Leader>hn` / `]h` | Jump to next highlight | Navigate through highlights |
| Normal | `<Leader>hp` / `[h` | Jump to previous highlight | Navigate backwards |
| Normal | `<Leader>hl` | Open highlight list | Show all highlights in picker |

### Commands

You can also use commands (great for keymap customization):

```vim
:SuperHighlightWord      " Mark word under cursor
:SuperHighlightVisual    " Mark visual selection
:SuperHighlightClear     " Remove highlight at cursor
:SuperHighlightClearAll  " Clear all in buffer
:SuperHighlightNext      " Jump to next highlight
:SuperHighlightPrev      " Jump to previous highlight
:SuperHighlightPicker    " Open highlight list
```

### Real-World Examples

#### Example 1: Track Variable Usage

```lua
-- In controller.lua
function UserController:create(user)
  self.user = user  -- Press <Leader>hm on "user"
end

-- Switch to model.lua - "user" is automatically highlighted!
function User:validate()
  if self.user == nil then
    error("Invalid user")
  end
end
```

#### Example 2: Mark Function Calls

```javascript
// In api.js
export const fetchData = async () => {  -- Mark "fetchData"
  const response = await fetch('/api/data');
  return response.json();
};

// In component.jsx - "fetchData" is highlighted
useEffect(() => {
  fetchData().then(setData);
}, []);
```

#### Example 3: Highlight Code Patterns

```cpp
// Select and mark: ptr->value
auto result = ptr->value;  -- After marking, this appears in all files

// In another file:
auto x = object->value;  -- "ptr->value" is NOT highlighted (different text)
auto y = ptr->value;     -- "ptr->value" IS highlighted (exact match)
```

## ⚙️ Configuration

### Default Configuration

```lua
{
  auto_theme = true,      -- Auto-extract colors from colorscheme
  saturation = 0.35,      -- Color vividness (0.0 ~ 1.0)
  lightness = 0.45,       -- Brightness level (0.0 ~ 1.0)
  palette = {             -- Manual colors (when auto_theme = false)
    { name = "green", bg = "#82c65a", fg = "#001737" },
    { name = "gold",  bg = "#e4ac58", fg = "#500000" },
    { name = "violet", bg = "#8f2f8f", fg = "#f8dff6" },
    { name = "blue",  bg = "#5783c7", fg = "#dffcfc" },
  },
  picker = true,          -- Enable Snacks picker integration
}
```

### Configuration Options

#### `auto_theme` (boolean, default: `true`)

When `true`, automatically extracts colors from your current colorscheme.

**Sources**: Diff colors, Search, Todo, Warning/Error messages, and more

When `false`, uses the manual `palette` configuration.

#### `saturation` (number, default: `0.35`)

Boosts color saturation for better visibility.

- `0.0` = No boost (use original colors)
- `0.5` = Medium boost (recommended)
- `1.0` = Maximum vividness

#### `lightness` (number, default: `0.45`)

Adjusts brightness to ensure highlights stand out.

- `0.3` = Darker highlights (for light themes)
- `0.5` = Medium brightness (balanced)
- `0.7` = Brighter highlights (for dark themes)

#### `palette` (table, default: 4 colors)

Manual color palette when `auto_theme = false`.

Each color needs:
- `name` - Color identifier (for debugging)
- `bg` - Background color (hex format: `#RRGGBB`)
- `fg` - Foreground/text color (hex format: `#RRGGBB`)

#### `picker` (boolean, default: `true`)

Enables/disables Snacks picker integration. Requires `folke/snacks.nvim`.

### Example Configurations

#### For Dark Themes

```lua
require("highlight").setup({
  saturation = 0.40,   -- More vivid for dark backgrounds
  lightness = 0.50,    -- Brighter highlights
})
```

#### For Light Themes

```lua
require("highlight").setup({
  saturation = 0.25,   -- Less saturation to avoid glare
  lightness = 0.35,    -- Darker highlights for contrast
})
```

#### Custom Color Palette

```lua
require("highlight").setup({
  auto_theme = false,
  palette = {
    { name = "red",    bg = "#ff6b6b", fg = "#1a1a1a" },
    { name = "yellow", bg = "#ffd93d", fg = "#1a1a1a" },
    { name = "cyan",   bg = "#6bcbff", fg = "#1a1a1a" },
    { name = "purple", bg = "#c8a1ff", fg = "#1a1a1a" },
    { name = "green",  bg = "#51cf66", fg = "#1a1a1a" },
  },
})
```

## 🎨 How It Works

### Word Highlighting

1. Press `<Leader>hm` on a word (e.g., `myVariable`)
2. The plugin marks this word globally
3. When you switch to ANY buffer, all occurrences of `myVariable` are highlighted
4. Uses **whole-word matching** (exact word boundaries)

### Range Highlighting

1. Visually select text (e.g., `obj->property`)
2. Press `<Leader>hm`
3. The plugin marks this exact text globally
4. When you switch buffers, exact text matches are highlighted
5. Uses **exact text matching** (character-for-character)

### Theme Adaptation

When `auto_theme = true`:
1. Extracts colors from your colorscheme's built-in highlights
2. Boosts saturation for better visibility
3. Adjusts lightness for optimal contrast
4. Creates 16 highlight groups (or fewer if colorscheme has limited colors)

When you change colorscheme (`:colorscheme gruvbox`), all highlights automatically adapt!

## 🧹 Troubleshooting

### Highlights Not Appearing

**Problem**: Marked words don't show in other files.

**Solutions**:
1. Make sure the file is saved (highlights scan buffer content)
2. Check if the word/range exactly matches (case-sensitive)
3. For ranges: verify exact character match (spaces matter)

### Colors Don't Match Theme

**Problem**: Highlight colors clash with your colorscheme.

**Solutions**:
1. Set `auto_theme = true` to extract from current theme
2. Adjust `saturation` and `lightness` values
3. Provide custom `palette` for complete control

### Performance Issues

**Problem**: Lag when typing or switching buffers.

**Solutions**:
1. Reduce number of marked items (clear unused with `<Leader>hD`)
2. The plugin uses debounced scanning (40ms delay)
3. Consider marking fewer common words (like `end`, `function`)

### Picker Not Working

**Problem**: `<Leader>hl` does nothing or shows error.

**Solutions**:
1. Install `folke/snacks.nvim`: `{: "folke/snacks.nvim"}`
2. Set `picker = true` in config
3. Check `:checkhealth snacks` for picker availability

## 🆚 Comparison with vim-highlighter

| Feature | vim-highlighter | highlight.nvim |
|---------|----------------|----------------|
| **Language** | VimScript | Lua (modern) |
| **Rendering** | `matchadd()` | Extmarks (faster) |
| **Persistence** | Buffer-local | Cross-buffer ✨ |
| **Theme Adaptation** | Manual | Auto-extraction ✨ |
| **Range Highlighting** | No | Yes ✨ |
| **Performance** | Slower with many highlights | Optimized ✨ |

## 📋 Requirements

- **Neovim** 0.10 or higher (for extmark API)
- **Optional**: `folke/snacks.nvim` (for picker integration)

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📝 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- Inspired by [vim-highlighter](https://github.com/adelarsq/vim-highlighter)
- Built with [Neovim](https://neovim.io)'s extmark API
- Picker integration via [folke/snacks.nvim](https://github.com/folke/snacks.nvim)

## 📮 Feedback

- 🐛 **Bug Reports**: Open an issue on GitHub
- 💡 **Feature Requests**: Open an issue with the "enhancement" label
- 📖 **Questions**: Use GitHub Discussions

---

<div align="center">

Made with ❤️ for the Neovim community

</div>
