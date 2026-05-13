local state = require "super-highlight.state"
local render = require "super-highlight.render"
local theme = require "super-highlight.theme"

local M = {}

-- Global item registry (session-scoped)
local global_items = {}
local next_global_id = 1

-- Color index management
local function next_color_index()
  local palette = theme.build_palette()
  local count = #palette
  if count == 0 then return nil end

  -- Use first unused color index, or wrap around
  local used_indices = {}
  for _, item in ipairs(global_items) do
    used_indices[item.palette] = true
  end

  for i = 1, count do
    if not used_indices[i] then
      return i
    end
  end

  -- All colors used, start from 1
  return 1
end

local function scan_word_positions(bufnr, word)
  local positions = {}
  local escaped = vim.fn.escape(word, "\\")
  local pattern = ("\\V\\<%s\\>"):format(escaped)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for row, line in ipairs(lines) do
    local start_col = 0
    while true do
      local match = vim.fn.matchstrpos(line, pattern, start_col)
      local from = tonumber(match[2])
      local to = tonumber(match[3])

      if from == nil or from < 0 or to == nil then break end

      table.insert(positions, {
        start_row = row - 1,
        start_col = from,
        end_row = row - 1,
        end_col = to,
      })

      if to <= from then break end
      start_col = to
    end
  end

  return positions
end

local function scan_text_positions(bufnr, text)
  local positions = {}
  local escaped = vim.fn.escape(text, "\\")
  local pattern = ("\\V%s"):format(escaped)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for row, line in ipairs(lines) do
    local start_col = 0
    while true do
      local match = vim.fn.matchstrpos(line, pattern, start_col)
      local from = tonumber(match[2])
      local to = tonumber(match[3])

      if from == nil or from < 0 or to == nil then break end

      table.insert(positions, {
        start_row = row - 1,
        start_col = from,
        end_row = row - 1,
        end_col = to,
      })

      if to <= from then break end
      start_col = to
    end
  end

  return positions
end

function M.add_global_item(bufnr, item_spec)
  local color_index = next_color_index()
  if not color_index then
    vim.notify("No colors available for highlighting", vim.log.levels.WARN, { title = "Super Highlight" })
    return nil
  end

  local item = {
    id = ("global_%d"):format(next_global_id),
    kind = item_spec.kind,
    word = item_spec.word,
    text = item_spec.text,
    label = item_spec.label,
    palette = color_index,
    group = ("SuperHighlight%d"):format(color_index),
  }

  next_global_id = next_global_id + 1
  table.insert(global_items, item)

  -- Create highlight group
  local palette = theme.build_palette()
  theme.create_hl_groups(palette)

  -- Apply to current buffer
  M.apply_item_to_buffer(bufnr, item)

  return item
end

function M.remove_global_item(item_id)
  for i, item in ipairs(global_items) do
    if item.id == item_id then
      table.remove(global_items, i)
      return item
    end
  end
  return nil
end

function M.find_global_item(word, text)
  for _, item in ipairs(global_items) do
    if item.kind == "word" and item.word == word then
      return item
    end
    if item.kind == "range" and item.text == text then
      return item
    end
  end
  return nil
end

function M.apply_item_to_buffer(bufnr, global_item)
  local positions = {}

  if global_item.kind == "word" then
    positions = scan_word_positions(bufnr, global_item.word)
  elseif global_item.kind == "range" then
    positions = scan_text_positions(bufnr, global_item.text)
  end

  if #positions == 0 then
    return nil
  end

  -- Check if already exists in buffer
  local buf_state = state.get(bufnr)
  for _, buf_item in ipairs(buf_state.items) do
    if buf_item.id == global_item.id then
      return buf_item
    end
  end

  -- Add to buffer state
  local buf_item = state.add_item(bufnr, {
    id = global_item.id,
    kind = global_item.kind,
    word = global_item.word,
    text = global_item.text,
    label = global_item.label,
    palette = global_item.palette,
    group = global_item.group,
    positions = positions,
  })

  -- Render
  render.draw_item(bufnr, buf_item)

  return buf_item
end

function M.apply_to_buffer(bufnr)
  local buf_state = state.get(bufnr)

  for _, global_item in ipairs(global_items) do
    -- Check if already applied
    local already_applied = false
    for _, buf_item in ipairs(buf_state.items) do
      if buf_item.id == global_item.id then
        already_applied = true
        break
      end
    end

    if not already_applied then
      M.apply_item_to_buffer(bufnr, global_item)
    end
  end

  render.redraw(bufnr, buf_state)
end

function M.get_global_items()
  return global_items
end

function M.clear_all()
  global_items = {}
  next_global_id = 1
end

return M
