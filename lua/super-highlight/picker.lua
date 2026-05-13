local state = require "super-highlight.state"

local M = {}

local function notify_warn(message)
  vim.notify(message, vim.log.levels.WARN, { title = "Super Highlight" })
end

local function has_ui()
  return #vim.api.nvim_list_uis() > 0
end

local function get_snacks_picker()
  local ok, snacks = pcall(require, "snacks")
  if not ok or type(snacks) ~= "table" then return nil end

  local picker = snacks.picker
  if type(picker) ~= "table" or type(picker.pick) ~= "function" then return nil end

  return picker
end

local function item_count(item)
  return #(item.positions or {})
end

local function palette_name(opts, item)
  local entry = opts.palette and opts.palette[item.palette]
  if type(entry) == "table" and type(entry.name) == "string" and entry.name ~= "" then return entry.name end
  return tostring(item.palette or "-")
end

local function item_label(item)
  local label = type(item.label) == "string" and item.label or "highlight"
  return label:gsub("\n", "\\n")
end

local function count_label(item)
  local count = item_count(item)
  local noun = item.kind == "word" and "occurrence" or "span"
  return ("%d %s%s"):format(count, noun, count == 1 and "" or "s")
end

local function first_position(item)
  local pos = item.positions and item.positions[1]
  if not pos then return nil end
  return { pos.start_row + 1, pos.start_col }
end

local function build_items(bufnr, opts)
  local items = {}
  local state_items = state.get(bufnr).items

  for _, item in ipairs(state_items) do
    local label = item_label(item)
    local kind_label = item.kind == "word" and "word" or "range"

    table.insert(items, {
      buf = bufnr,
      pos = first_position(item),
      text = table.concat({ label, kind_label, palette_name(opts, item), count_label(item) }, " "),
      label = label,
      kind = kind_label,
      palette_name = palette_name(opts, item),
      count_label = count_label(item),
      item_group = item.group,
    })
  end

  return items
end

local function format_item(item)
  return {
    { "  ", item.item_group or "Normal" },
    { " " },
    { item.label, "SnacksPickerFile" },
    { "  " },
    { item.kind, "SnacksPickerComment" },
    { "  " },
    { item.palette_name, "SnacksPickerLabel" },
    { "  " },
    { item.count_label, "SnacksPickerDelim" },
  }
end

function M.open(args)
  args = args or {}

  local picker = get_snacks_picker()
  if not picker then
    notify_warn("snacks.nvim picker is unavailable")
    return nil
  end

  local bufnr = args.bufnr or vim.api.nvim_get_current_buf()
  local opts = args.opts or {}
  local items = build_items(bufnr, opts)
  if #items == 0 or not has_ui() then return nil end

  return picker.pick({
    title = "Highlights",
    items = items,
    format = format_item,
    layout = {
      preset = "select",
      hidden = { "preview" },
    },
    jump = { reuse_win = true },
  })
end

return M
