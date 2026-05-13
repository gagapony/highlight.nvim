local M = {}

local defaults = {
  auto_theme = true,
  saturation = 0.35,
  lightness = 0.45,
  palette = {
    { name = "green", bg = "#82c65a", fg = "#001737" },
    { name = "gold",  bg = "#e4ac58", fg = "#500000" },
    { name = "violet", bg = "#8f2f8f", fg = "#f8dff6" },
    { name = "blue",  bg = "#5783c7", fg = "#dffcfc" },
  },
  picker = true,
}

M.opts = {}

function M.setup(opts)
  opts = opts or {}

  -- Validate auto_theme
  if opts.auto_theme ~= nil then
    assert(type(opts.auto_theme) == "boolean", "auto_theme must be a boolean")
  end

  -- Validate saturation
  if opts.saturation ~= nil then
    assert(type(opts.saturation) == "number", "saturation must be a number")
    assert(opts.saturation >= 0 and opts.saturation <= 1, "saturation must be between 0 and 1")
  end

  -- Validate lightness
  if opts.lightness ~= nil then
    assert(type(opts.lightness) == "number", "lightness must be a number")
    assert(opts.lightness >= 0 and opts.lightness <= 1, "lightness must be between 0 and 1")
  end

  -- Validate palette
  if opts.palette ~= nil then
    assert(type(opts.palette) == "table", "palette must be a table")
    for i, color in ipairs(opts.palette) do
      assert(type(color) == "table", ("palette[%d] must be a table"):format(i))
      assert(type(color.name) == "string", ("palette[%d].name must be a string"):format(i))
      assert(type(color.bg) == "string", ("palette[%d].bg must be a string"):format(i))
      assert(type(color.fg) == "string", ("palette[%d].fg must be a string"):format(i))
      assert(color.bg:match("^#%x%x%x%x%x%x$"), ("palette[%d].bg must be hex color #RRGGBB"):format(i))
      assert(color.fg:match("^#%x%x%x%x%x%x$"), ("palette[%d].fg must be hex color #RRGGBB"):format(i))
    end
  end

  -- Validate picker
  if opts.picker ~= nil then
    assert(type(opts.picker) == "boolean", "picker must be a boolean")
  end

  M.opts = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts)
  return M.opts
end

function M.get(key)
  return M.opts[key]
end

return M
