local M = {}

local buffers = {}

local function current_buf()
  return vim.api.nvim_get_current_buf()
end

local function normalize_bufnr(bufnr)
  if bufnr == nil or bufnr == 0 then return current_buf() end
  return bufnr
end

local function new_state(bufnr)
  return {
    bufnr = bufnr,
    items = {},
    next_id = 1,
    next_color_index = 1,
  }
end

local function validate_endpoint(value, field)
  assert(type(value) == "number", ("highlight %s must be a number"):format(field))
  assert(value >= 0, ("highlight %s must be non-negative"):format(field))
  assert(value == math.floor(value), ("highlight %s must be an integer"):format(field))
end

local function is_valid_coordinate(value)
  return type(value) == "number" and value >= 0 and value == math.floor(value)
end

local function copy_item(item)
  local copy = {}
  for key, value in pairs(item) do
    copy[key] = value
  end
  -- Support new fields
  copy.text = item.text
  return copy
end

local function copy_list(list)
  local copy = {}
  for index, value in ipairs(list or {}) do
    copy[index] = value
  end
  return copy
end

local function normalize_position(pos)
  assert(type(pos) == "table", "highlight position must be a table")

  validate_endpoint(pos.start_row, "start_row")
  validate_endpoint(pos.start_col, "start_col")
  validate_endpoint(pos.end_row, "end_row")
  validate_endpoint(pos.end_col, "end_col")

  local starts_after_end = pos.start_row > pos.end_row
  local zero_or_negative_width = pos.start_row == pos.end_row and pos.start_col >= pos.end_col
  assert(not starts_after_end, "highlight position start_row must not be after end_row")
  assert(not zero_or_negative_width, "highlight position must have positive width")

  return {
    start_row = pos.start_row,
    start_col = pos.start_col,
    end_row = pos.end_row,
    end_col = pos.end_col,
  }
end

local function normalize_positions(positions)
  assert(positions == nil or type(positions) == "table", "highlight positions must be a list")

  local normalized = {}
  for index, pos in ipairs(positions or {}) do
    normalized[index] = normalize_position(pos)
  end
  return normalized
end

local function normalize_range(range)
  if range == nil then return nil end
  return normalize_position(range)
end

local function range_contains(pos, row, col)
  local row_in_range = row >= pos.start_row and row <= pos.end_row
  local after_start = row ~= pos.start_row or col >= pos.start_col
  local before_end = row ~= pos.end_row or col < pos.end_col
  return row_in_range and after_start and before_end
end

function M.get(bufnr)
  bufnr = normalize_bufnr(bufnr)
  if not buffers[bufnr] then buffers[bufnr] = new_state(bufnr) end
  return buffers[bufnr]
end

function M.reset(bufnr)
  bufnr = normalize_bufnr(bufnr)
  buffers[bufnr] = new_state(bufnr)
  return buffers[bufnr]
end

function M.drop(bufnr)
  bufnr = normalize_bufnr(bufnr)
  local state = buffers[bufnr]
  buffers[bufnr] = nil
  return state
end

function M.add_item(bufnr, item)
  local state = M.get(bufnr)
  assert(type(item) == "table", "highlight item must be a table")

  local positions = normalize_positions(item.positions)
  local range = normalize_range(item.range)
  local stored_item = copy_item(item)

  stored_item.id = state.next_id
  stored_item.range = range
  stored_item.positions = positions
  stored_item.marks = copy_list(item.marks)
  state.next_id = state.next_id + 1
  table.insert(state.items, stored_item)
  return stored_item
end

function M.remove_item(bufnr, item_id)
  local state = M.get(bufnr)
  for index, item in ipairs(state.items) do
    if item.id == item_id then
      table.remove(state.items, index)
      return item
    end
  end
end

function M.find_word(bufnr, word)
  for _, item in ipairs(M.get(bufnr).items) do
    if item.kind == "word" and item.word == word then return item end
  end
end

function M.find_item_by_text(bufnr, text)
  for _, item in ipairs(M.get(bufnr).items) do
    if item.kind == "range" and item.text == text then return item end
  end
end

function M.find_range(bufnr, range)
  local normalized = normalize_range(range)
  for _, item in ipairs(M.get(bufnr).items) do
    if item.kind == "range" and vim.deep_equal(item.range, normalized) then return item end
  end
end

function M.get_item_by_id(bufnr, item_id)
  for _, item in ipairs(M.get(bufnr).items) do
    if item.id == item_id then return item end
  end
end

function M.item_at_position(bufnr, row, col)
  if not is_valid_coordinate(row) or not is_valid_coordinate(col) then return nil end

  local items = M.get(bufnr).items
  for index = #items, 1, -1 do
    local item = items[index]
    for _, pos in ipairs(item.positions or {}) do
      if range_contains(pos, row, col) then return item end
    end
  end
end

function M.flatten_positions(bufnr)
  local positions = {}
  for item_index, item in ipairs(M.get(bufnr).items) do
    for position_index, pos in ipairs(item.positions or {}) do
      positions[#positions + 1] = {
        item = item,
        item_id = item.id,
        item_index = item_index,
        position_index = position_index,
        start_row = pos.start_row,
        start_col = pos.start_col,
        end_row = pos.end_row,
        end_col = pos.end_col,
      }
    end
  end

  table.sort(positions, function(left, right)
    if left.start_row == right.start_row then
      if left.start_col == right.start_col then
        if left.item_index == right.item_index then return left.position_index < right.position_index end
        return left.item_index < right.item_index
      end
      return left.start_col < right.start_col
    end
    return left.start_row < right.start_row
  end)

  return positions
end

function M.for_each(fn)
  for bufnr, buf_state in pairs(buffers) do
    fn(bufnr, buf_state)
  end
end

return M
