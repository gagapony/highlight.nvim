local state = require "super-highlight.state"
local render = require "super-highlight.render"
local config = require "super-highlight.config"
local items = require "super-highlight.items"

local M = {}

M._resolved_palette_count = 0
M._debug = {
  word_refresh_runs = 0,
}

local pending_word_refresh = {}
local word_refresh_delay = 40

local command_names = {
  "SuperHighlightWord",
  "SuperHighlightVisual",
  "SuperHighlightClear",
  "SuperHighlightClearAll",
  "SuperHighlightNext",
  "SuperHighlightPrev",
  "SuperHighlightPicker",
}

local function current_buf()
  return vim.api.nvim_get_current_buf()
end

local function valid_loaded_buf(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr)
end

local function clear_pending_word_refresh(bufnr)
  pending_word_refresh[bufnr] = nil
end

local function current_word()
  local word = vim.fn.expand "<cword>"
  if type(word) ~= "string" or word == "" then return nil end
  return word
end

local function ordered_range(start_pos, end_pos)
  local start_row = start_pos[2] - 1
  local start_col = start_pos[3] - 1
  local end_row = end_pos[2] - 1
  local end_col = end_pos[3]

  if start_row > end_row or (start_row == end_row and start_col > end_col) then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col - 1, start_col + 1
  end

  if start_row < 0 or end_row < 0 then return nil end
  if start_row == end_row and start_col >= end_col then return nil end

  return {
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
  }
end

local function visual_range()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  return ordered_range(start_pos, end_pos)
end

local function range_label(bufnr, range)
  local lines = vim.api.nvim_buf_get_text(
    bufnr,
    range.start_row,
    range.start_col,
    range.end_row,
    range.end_col,
    {}
  )
  local text = table.concat(lines, "\\n")
  if text == "" then return "selection" end
  return text
end

local function jump_in_positions(positions, row, col, direction)
  if #positions == 0 then return nil end

  if direction > 0 then
    for _, pos in ipairs(positions) do
      if pos.start_row > row or (pos.start_row == row and pos.start_col > col) then return pos end
    end
    return positions[1]
  end

  for index = #positions, 1, -1 do
    local pos = positions[index]
    if pos.start_row < row or (pos.start_row == row and pos.start_col < col) then return pos end
  end

  return positions[#positions]
end

local function extmark_position(bufnr, mark_id)
  if type(mark_id) ~= "number" then return nil end

  local ok, mark = pcall(vim.api.nvim_buf_get_extmark_by_id, bufnr, render.ns, mark_id, { details = true })
  if not ok or type(mark) ~= "table" or mark[1] == nil or mark[2] == nil then return nil end

  local details = mark[3] or {}
  local end_row = details.end_row
  local end_col = details.end_col
  if type(end_row) ~= "number" or type(end_col) ~= "number" then return nil end

  return {
    start_row = mark[1],
    start_col = mark[2],
    end_row = end_row,
    end_col = end_col,
  }
end

local function sync_range_items(bufnr)
  if not valid_loaded_buf(bufnr) then return end

  local buffer_state = state.get(bufnr)
  for index = #buffer_state.items, 1, -1 do
    local item = buffer_state.items[index]
    if item.kind == "range" then
      local positions = {}
      for _, mark_id in ipairs(item.marks or {}) do
        local pos = extmark_position(bufnr, mark_id)
        if pos then positions[#positions + 1] = pos end
      end

      if #positions == 0 then
        table.remove(buffer_state.items, index)
      else
        item.positions = positions
        item.range = positions[1]
      end
    end
  end
end

local function refresh_word_items(bufnr)
  if not valid_loaded_buf(bufnr) then return end

  local buffer_state = state.get(bufnr)
  local changed = false

  sync_range_items(bufnr)

  for index = #buffer_state.items, 1, -1 do
    local item = buffer_state.items[index]
    if item.kind == "word" then
      local positions = scan_word_positions(bufnr, item.word)
      if #positions == 0 then
        table.remove(buffer_state.items, index)
        changed = true
      else
        item.positions = positions
        changed = true
      end
    end
  end

  if changed then render.redraw(bufnr, buffer_state) end
end

local function cleanup_buffer(args)
  local bufnr = args and args.buf or current_buf()
  clear_pending_word_refresh(bufnr)
  state.drop(bufnr)
end

local function queue_word_refresh(bufnr)
  if not valid_loaded_buf(bufnr) then return end

  local pending = pending_word_refresh[bufnr]
  if pending then
    pending.dirty = true
    return
  end

  pending = { dirty = false }
  pending_word_refresh[bufnr] = pending

  vim.defer_fn(function()
    if pending_word_refresh[bufnr] ~= pending then return end
    pending_word_refresh[bufnr] = nil
    if not valid_loaded_buf(bufnr) then return end

    refresh_word_items(bufnr)
    M._debug.word_refresh_runs = M._debug.word_refresh_runs + 1
  end, word_refresh_delay)
end

local function flush_word_refresh(bufnr)
  local pending = pending_word_refresh[bufnr]
  if not pending then return end

  pending_word_refresh[bufnr] = nil
  if not valid_loaded_buf(bufnr) then return end

  refresh_word_items(bufnr)
  M._debug.word_refresh_runs = M._debug.word_refresh_runs + 1
end

local function sync_positions(bufnr)
  flush_word_refresh(bufnr)
  sync_range_items(bufnr)
end

local function create_commands()
  for _, name in ipairs(command_names) do
    pcall(vim.api.nvim_del_user_command, name)
  end

  vim.api.nvim_create_user_command("SuperHighlightWord", function() M.toggle_word() end, {})
  vim.api.nvim_create_user_command("SuperHighlightVisual", function() M.toggle_visual() end, { range = true })
  vim.api.nvim_create_user_command("SuperHighlightClear", function() M.clear_at_cursor() end, {})
  vim.api.nvim_create_user_command("SuperHighlightClearAll", function() M.clear_buffer() end, {})
  vim.api.nvim_create_user_command("SuperHighlightNext", function() M.jump_next() end, {})
  vim.api.nvim_create_user_command("SuperHighlightPrev", function() M.jump_prev() end, {})
  vim.api.nvim_create_user_command("SuperHighlightPicker", function() M.open_picker() end, {})
end

local function apply_global_items(bufnr)
  if not valid_loaded_buf(bufnr) then return end
  items.apply_to_buffer(bufnr)
end

local function create_autocmds()
  local group = vim.api.nvim_create_augroup("SuperHighlight", { clear = true })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    callback = function(args)
      queue_word_refresh(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = cleanup_buffer,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(args)
      if valid_loaded_buf(args.buf) then
        apply_global_items(args.buf)
      end
    end,
  })
end

local function refresh_theme()
  local palette = require("super-highlight.theme").build_palette()
  M._resolved_palette_count = require("super-highlight.theme").create_hl_groups(palette)
  state.for_each(function(bufnr, buf_state)
    if valid_loaded_buf(bufnr) and #buf_state.items > 0 then
      render.redraw(bufnr, buf_state)
    end
  end)
end

local function create_theme_watcher()
  if not config.get("auto_theme") then return end

  local group = vim.api.nvim_create_augroup("SuperHighlightTheme", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      vim.schedule(refresh_theme)
    end,
  })
end

function M.setup(opts)
  config.setup(opts)
  local palette = require("super-highlight.theme").build_palette()
  M._resolved_palette_count = require("super-highlight.theme").create_hl_groups(palette)
  create_commands()
  create_autocmds()
  create_theme_watcher()
end

function M.toggle_word()
  local bufnr = current_buf()
  local word = current_word()
  if not word then return end

  local existing = items.find_global_item(word, nil)
  if existing then
    items.remove_global_item(existing.id)
    state.remove_item(bufnr, existing.id)
    render.redraw(bufnr, state.get(bufnr))
    return
  end

  local item = items.add_global_item(bufnr, {
    kind = "word",
    word = word,
    label = word,
  })

  if not item then
    vim.notify("Failed to add word highlight", vim.log.levels.ERROR, { title = "Super Highlight" })
  end
end

function M.toggle_visual()
  local bufnr = current_buf()
  local range = visual_range()
  if not range then return end

  local text = range_label(bufnr, range)

  local existing = items.find_global_item(nil, text)
  if existing then
    items.remove_global_item(existing.id)
    state.remove_item(bufnr, existing.id)
    render.redraw(bufnr, state.get(bufnr))
    return
  end

  local item = items.add_global_item(bufnr, {
    kind = "range",
    text = text,
    label = text,
    range = range,
  })

  if not item then
    vim.notify("Failed to add range highlight", vim.log.levels.ERROR, { title = "Super Highlight" })
  end
end

function M.clear_at_cursor()
  local bufnr = current_buf()
  sync_positions(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local item = state.item_at_position(bufnr, cursor[1] - 1, cursor[2])

  if item then
    items.remove_global_item(item.id)
    state.remove_item(bufnr, item.id)
    render.redraw(bufnr, state.get(bufnr))
  end
end

function M.clear_buffer()
  local bufnr = current_buf()
  state.reset(bufnr)
  render.clear_manual(bufnr)
  items.clear_all()
end

function M.jump_next()
  local bufnr = current_buf()
  sync_positions(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]
  local positions = state.flatten_positions(bufnr)
  if #positions == 0 then return end

  local item = state.item_at_position(bufnr, row, col)
  local scope = positions

  if item then
    scope = {}
    for _, pos in ipairs(positions) do
      if pos.item_id == item.id then scope[#scope + 1] = pos end
    end
    if #scope == 0 then scope = positions end
  end

  local target = jump_in_positions(scope, row, col, 1)
  if target then vim.api.nvim_win_set_cursor(0, { target.start_row + 1, target.start_col }) end
end

function M.jump_prev()
  local bufnr = current_buf()
  sync_positions(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]
  local positions = state.flatten_positions(bufnr)
  if #positions == 0 then return end

  local item = state.item_at_position(bufnr, row, col)
  local scope = positions

  if item then
    scope = {}
    for _, pos in ipairs(positions) do
      if pos.item_id == item.id then scope[#scope + 1] = pos end
    end
    if #scope == 0 then scope = positions end
  end

  local target = jump_in_positions(scope, row, col, -1)
  if target then vim.api.nvim_win_set_cursor(0, { target.start_row + 1, target.start_col }) end
end

function M.open_picker()
  if not config.get("picker") then return nil end
  local bufnr = current_buf()
  sync_positions(bufnr)
  local ok, picker = pcall(require, "super-highlight.picker")
  if not ok then
    local missing = type(picker) == "string" and picker:match("module 'super%-highlight%.picker' not found", 1, true)
    if missing then return nil end
    vim.notify(picker, vim.log.levels.ERROR, { title = "Super Highlight" })
    return nil
  end
  if ok and type(picker.open) == "function" then return picker.open { bufnr = bufnr, opts = config.opts } end
end

return M
