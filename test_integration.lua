#!/usr/bin/env nvim -l

-- Integration test for refactored init.lua functionality
package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'

print("=== Integration Test: Super Highlight Functionality ===\n")

local super_highlight = require('super-highlight.init')
local state = require('super-highlight.state')
local items = require('super-highlight.items')

-- Initialize the plugin
super_highlight.setup({})

-- Create a mock buffer for testing
local test_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, {
  "Hello world, this is a test",
  "Another line with more text",
  "Test line three with test word",
})

-- Test 1: Word highlighting
print("Test 1: Testing word highlight...")
vim.api.nvim_set_current_buf(test_buf)
vim.api.nvim_win_set_cursor(0, {1, 0}) -- Move to first line

-- Manually trigger toggle_word logic
local word = "test"
local bufnr = test_buf

-- Add a global item
local item = items.add_global_item(bufnr, {
  kind = "word",
  word = word,
  label = word,
})

if not item then
  print("❌ FAILED: Could not add word highlight")
  os.exit(1)
end

-- Verify item was added
local buf_state = state.get(bufnr)
if #buf_state.items == 0 then
  print("❌ FAILED: No items in buffer state")
  os.exit(1)
end

print("✅ PASSED: Word highlight added\n")

-- Test 2: Find existing item
print("Test 2: Testing find_global_item...")
local found = items.find_global_item(word, nil)
if not found or found.word ~= word then
  print("❌ FAILED: Could not find global item")
  os.exit(1)
end
print("✅ PASSED: Found global item\n")

-- Test 3: Remove item
print("Test 3: Testing remove_global_item...")
items.remove_global_item(found.id)
state.remove_item(bufnr, found.id)

-- Verify item was removed
local found_again = items.find_global_item(word, nil)
if found_again then
  print("❌ FAILED: Item was not removed")
  os.exit(1)
end
print("✅ PASSED: Item removed successfully\n")

-- Test 4: Clear all
print("Test 4: Testing clear_all...")
items.add_global_item(bufnr, { kind = "word", word = "hello", label = "hello" })
items.add_global_item(bufnr, { kind = "word", word = "world", label = "world" })
items.clear_all()

local global_items = items.get_global_items()
if #global_items > 0 then
  print("❌ FAILED: Items were not cleared")
  os.exit(1)
end
print("✅ PASSED: All items cleared\n")

-- Test 5: Apply to buffer
print("Test 5: Testing apply_to_buffer...")
items.add_global_item(bufnr, { kind = "word", word = "line", label = "line" })
state.reset(bufnr) -- Clear buffer state

items.apply_to_buffer(bufnr)
local buf_state_after = state.get(bufnr)
if #buf_state_after.items == 0 then
  print("❌ FAILED: Items were not applied to buffer")
  os.exit(1)
end
print("✅ PASSED: Items applied to buffer\n")

-- Test 6: Theme integration
print("Test 6: Testing theme integration...")
local theme = require('super-highlight.theme')
local palette = theme.build_palette()
if type(palette) ~= 'table' or #palette == 0 then
  print("❌ FAILED: Could not build palette")
  os.exit(1)
end

local count = theme.create_hl_groups(palette)
if type(count) ~= 'number' or count == 0 then
  print("❌ FAILED: Could not create highlight groups")
  os.exit(1)
end
print("✅ PASSED: Theme integration works\n")

-- Clean up
vim.api.nvim_buf_delete(test_buf, { force = true })

print("=== All Integration Tests Passed! ===")
