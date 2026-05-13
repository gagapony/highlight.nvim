local config = require "super-highlight.config"

local M = {}

local theme_palette_sources = {
  { hl = "DiffAdd", field = "bg", name = "diff-green" },
  { hl = "DiffChange", field = "bg", name = "diff-yellow" },
  { hl = "DiffText", field = "bg", name = "diff-cyan" },
  { hl = "DiffDelete", field = "bg", name = "diff-red" },
  { hl = "IncSearch", field = "bg", name = "inc-search" },
  { hl = "Search", field = "bg", name = "search" },
  { hl = "MatchParen", field = "bg", name = "match-paren" },
  { hl = "Todo", field = "fg", name = "todo" },
  { hl = "WarningMsg", field = "fg", name = "warning" },
  { hl = "ErrorMsg", field = "fg", name = "error" },
  { hl = "ModeMsg", field = "fg", name = "mode" },
  { hl = "MoreMsg", field = "fg", name = "more" },
  { hl = "Question", field = "fg", name = "question" },
  { hl = "Directory", field = "fg", name = "directory" },
  { hl = "Title", field = "fg", name = "title" },
  { hl = "SpecialChar", field = "fg", name = "special" },
  { hl = "Tag", field = "fg", name = "tag" },
  { hl = "Underlined", field = "fg", name = "underlined" },
}

local function hex_to_hsl(hex)
  hex = hex:gsub("^#", "")
  local r = tonumber(hex:sub(1, 2), 16) / 255
  local g = tonumber(hex:sub(3, 4), 16) / 255
  local b = tonumber(hex:sub(5, 6), 16) / 255
  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local h, s, l = 0, 0, (max + min) / 2
  if max ~= min then
    local d = max - min
    if l > 0.5 then s = d / (2 - max - min) else s = d / (max + min) end
    if max == r then h = (g - b) / d + (g < b and 6 or 0)
    elseif max == g then h = (b - r) / d + 2
    else h = (r - g) / d + 4 end
    h = h / 6
  end
  return h, s, l
end

local function hsl_to_hex(h, s, l)
  local function hue_to_rgb(p, q, t)
    if t < 0 then t = t + 1 end
    if t > 1 then t = t - 1 end
    if t < 1 / 6 then return p + (q - p) * 6 * t end
    if t < 1 / 2 then return q end
    if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
    return p
  end
  local r, g, b
  if s == 0 then r, g, b = l, l, l
  else
    local q = l < 0.5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q
    r = hue_to_rgb(p, q, h + 1 / 3)
    g = hue_to_rgb(p, q, h)
    b = hue_to_rgb(p, q, h - 1 / 3)
  end
  return ("#%02x%02x%02x"):format(
    math.floor(r * 255 + 0.5),
    math.floor(g * 255 + 0.5),
    math.floor(b * 255 + 0.5)
  )
end

local function boost_saturation(hex, boost, target_lightness)
  boost = boost or 0.35
  target_lightness = target_lightness or 0.50
  local h, s, l = hex_to_hsl(hex)
  s = math.min(1, math.max(s, 0.3) + boost)
  l = math.min(0.65, math.max(0.30, l * 0.5 + target_lightness * 0.5))
  return hsl_to_hex(h, s, l)
end

function M.build_palette()
  local opts = config.opts
  local saturation = opts.saturation or 0.35
  local lightness = opts.lightness or 0.45

  if not opts.auto_theme then
    return opts.palette
  end

  local normal_bg_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
  local is_dark = not normal_bg_hl or not normal_bg_hl.bg or normal_bg_hl.bg < 0x800000
  local target_lightness = lightness
  local resolved = {}

  for _, source in ipairs(theme_palette_sources) do
    local hl = vim.api.nvim_get_hl(0, { name = source.hl })
    if hl then
      local raw = hl[source.field]
      if raw then
        local hex = ("#%06x"):format(raw)
        local boosted = boost_saturation(hex, saturation, target_lightness)
        local fg = is_dark and "#ffffff" or "#000000"
        table.insert(resolved, { name = source.name, bg = boosted, fg = fg })
      end
    end
  end

  if #resolved == 0 then
    return opts.palette
  end

  return resolved
end

function M.create_hl_groups(palette)
  for index, color in ipairs(palette) do
    vim.api.nvim_set_hl(0, ("SuperHighlight%d"):format(index), {
      fg = color.fg,
      bg = color.bg,
    })
  end

  return #palette
end

return M
