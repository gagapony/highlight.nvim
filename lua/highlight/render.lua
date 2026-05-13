local M = {}

M.ns = vim.api.nvim_create_namespace("highlight")

local function normalize_bufnr(bufnr)
  if bufnr == nil or bufnr == 0 then return vim.api.nvim_get_current_buf() end
  return bufnr
end

local function get_loaded_bufnr(bufnr)
  bufnr = normalize_bufnr(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return nil end
  if not vim.api.nvim_buf_is_loaded(bufnr) then return nil end
  return bufnr
end

local function validate_position(pos, context, index)
  assert(type(pos) == "table", ("%s position %d must be a table"):format(context, index))

  local fields = { "start_row", "start_col", "end_row", "end_col" }
  for _, field in ipairs(fields) do
    local value = pos[field]
    assert(type(value) == "number", ("%s position %d %s must be a number"):format(context, index, field))
    assert(value >= 0, ("%s position %d %s must be non-negative"):format(context, index, field))
    assert(value == math.floor(value), ("%s position %d %s must be an integer"):format(context, index, field))
  end

  assert(pos.start_row <= pos.end_row, ("%s position %d start_row must not be after end_row"):format(context, index))
  if pos.start_row == pos.end_row then
    assert(pos.start_col < pos.end_col, ("%s position %d must have positive width"):format(context, index))
  end
end

local function validate_positions(positions, context)
  assert(type(positions) == "table", ("%s positions must be a list"):format(context))
  for index, pos in ipairs(positions) do
    validate_position(pos, context, index)
  end
end

local function line_length(bufnr, row)
  return #vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
end

local function clamp(value, minimum, maximum)
  if value < minimum then return minimum end
  if value > maximum then return maximum end
  return value
end

local function prepare_positions(bufnr, positions, context)
  validate_positions(positions, context)

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if line_count < 1 then return {} end

  local prepared = {}
  for _, pos in ipairs(positions) do
    if pos.start_row < line_count then
      local start_row = pos.start_row
      local end_row = clamp(pos.end_row, start_row, line_count - 1)
      local start_col = clamp(pos.start_col, 0, line_length(bufnr, start_row))
      local end_col = clamp(pos.end_col, 0, line_length(bufnr, end_row))

      if start_row == end_row then
        if start_col < end_col then
          prepared[#prepared + 1] = {
            start_row = start_row,
            start_col = start_col,
            end_row = end_row,
            end_col = end_col,
          }
        end
      else
        prepared[#prepared + 1] = {
          start_row = start_row,
          start_col = start_col,
          end_row = end_row,
          end_col = end_col,
        }
      end
    end
  end

  return prepared
end

local function render_positions(bufnr, ns, positions, group)
  local marks = {}

  for index, pos in ipairs(positions) do
    local ok, mark = pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, pos.start_row, pos.start_col, {
      end_row = pos.end_row,
      end_col = pos.end_col,
      hl_group = group,
      strict = false,
    })

    if ok then marks[#marks + 1] = mark end
  end

  return marks
end

local function reset_item_marks(item)
  if type(item) == "table" then item.marks = {} end
end

function M.clear_manual(bufnr)
  bufnr = get_loaded_bufnr(bufnr)
  if not bufnr then return end
  vim.api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)
end

function M.draw_item(bufnr, item)
  assert(type(item) == "table", "manual highlight item must be a table")
  assert(type(item.group) == "string" and item.group ~= "", "manual highlight item.group must be a non-empty string")
  reset_item_marks(item)
  bufnr = get_loaded_bufnr(bufnr)
  if not bufnr then return {} end

  local positions = prepare_positions(bufnr, item.positions, "manual highlight item")
  local marks = render_positions(bufnr, M.ns, positions, item.group)

  item.marks = marks
  return marks
end

function M.redraw(bufnr, state)
  assert(type(state) == "table", "manual highlight state must be a table")
  assert(type(state.items) == "table", "manual highlight state.items must be a list")

  for _, item in ipairs(state.items) do
    reset_item_marks(item)
  end

  bufnr = get_loaded_bufnr(bufnr)
  if not bufnr then return end

  local prepared = {}
  for _, item in ipairs(state.items) do
    if type(item) == "table" and type(item.group) == "string" and item.group ~= "" then
      local ok, positions = pcall(prepare_positions, bufnr, item.positions, "manual highlight item")
      if ok then
        prepared[#prepared + 1] = {
          item = item,
          positions = positions,
        }
      end
    end
  end

  M.clear_manual(bufnr)

  for _, entry in ipairs(prepared) do
    entry.item.marks = render_positions(bufnr, M.ns, entry.positions, entry.item.group)
  end
end

return M
