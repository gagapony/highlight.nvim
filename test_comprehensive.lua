#!/usr/bin/env nvim -l

-- Comprehensive Integration Test Suite for Super Highlight
-- Tests all core functionality: word highlighting, range highlighting,
-- cross-buffer persistence, theme switching, clear operations, and navigation

package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'

-- Test utilities
local test_results = {}
local test_count = 0
local passed_count = 0
local failed_count = 0

local function assert(condition, test_name, error_msg)
  test_count = test_count + 1
  if condition then
    passed_count = passed_count + 1
    table.insert(test_results, { name = test_name, status = "PASSED", msg = error_msg })
    print("✅ PASSED: " .. test_name)
    return true
  else
    failed_count = failed_count + 1
    table.insert(test_results, { name = test_name, status = "FAILED", msg = error_msg })
    print("❌ FAILED: " .. test_name .. " - " .. (error_msg or "Unknown error"))
    return false
  end
end

local function cleanup_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end

-- Initialize
print("=== Super Highlight Comprehensive Integration Tests ===\n")
print("Initializing plugin...\n")

local super_highlight = require('super-highlight.init')
local state = require('super-highlight.state')
local items = require('super-highlight.items')
local render = require('super-highlight.render')

-- Setup with default config
super_highlight.setup({})

print("Starting tests...\n")

-- ============================================================================
-- TEST 1: Word Highlighting
-- ============================================================================
print("TEST 1: Word Highlighting")
print("-------------------------------------------")

-- Create test buffer
local buf1 = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf1, 0, -1, false, {
  "test test test",
  "another line",
  "test word here",
})

vim.api.nvim_set_current_buf(buf1)

-- Add word highlight for "test"
local test_word = "test"
local item = items.add_global_item(buf1, {
  kind = "word",
  word = test_word,
  label = test_word,
})

assert(item ~= nil, "1.1 - Add word highlight", "Item should be created")
assert(item.word == test_word, "1.2 - Word matches", "Item word should be 'test'")
assert(item.kind == "word", "1.3 - Kind matches", "Item kind should be 'word'")

-- Check buffer state
local buf_state = state.get(buf1)
assert(#buf_state.items > 0, "1.4 - Buffer has items", "Buffer should have highlight items")

-- Check positions were found
local total_positions = 0
for _, buf_item in ipairs(buf_state.items) do
  total_positions = total_positions + #buf_item.positions
end
assert(total_positions >= 3, "1.5 - Positions found", "Should find at least 3 occurrences of 'test'")

print()

-- ============================================================================
-- TEST 2: Range Highlighting
-- ============================================================================
print("TEST 2: Range Highlighting")
print("-------------------------------------------")

local buf2 = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf2, 0, -1, false, {
  "abc->def abc->def",
  "another abc->def here",
})

vim.api.nvim_set_current_buf(buf2)

-- Add range highlight for "abc->def"
local test_range_text = "abc->def"
local range_item = items.add_global_item(buf2, {
  kind = "range",
  text = test_range_text,
  label = test_range_text,
})

assert(range_item ~= nil, "2.1 - Add range highlight", "Range item should be created")
assert(range_item.text == test_range_text, "2.2 - Text matches", "Item text should be 'abc->def'")
assert(range_item.kind == "range", "2.3 - Kind matches", "Item kind should be 'range'")

-- Check buffer state
local buf2_state = state.get(buf2)
assert(#buf2_state.items > 0, "2.4 - Buffer has range items", "Buffer should have range highlight items")

print()

-- ============================================================================
-- TEST 3: Cross-Buffer Persistence
-- ============================================================================
print("TEST 3: Cross-Buffer Persistence")
print("-------------------------------------------")

-- Create highlight in buf3
local buf3 = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf3, 0, -1, false, {"persistent word"})

vim.api.nvim_set_current_buf(buf3)

local persistent_word = "word"
items.clear_all()  -- Clear previous items
state.reset(buf3)

local persistent_item = items.add_global_item(buf3, {
  kind = "word",
  word = persistent_word,
  label = persistent_word,
})

assert(persistent_item ~= nil, "3.1 - Create persistent item", "Item should be created in buf3")

-- Create another buffer with same word
local buf4 = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf4, 0, -1, false, {"word appears here"})

vim.api.nvim_set_current_buf(buf4)

-- Apply global items to buf4
items.apply_to_buffer(buf4)

local buf4_state = state.get(buf4)
assert(#buf4_state.items > 0, "3.2 - Item appears in new buffer", "Global item should apply to buf4")

-- Find the specific item
local found_in_buf4 = false
for _, buf_item in ipairs(buf4_state.items) do
  if buf_item.id == persistent_item.id and buf_item.word == persistent_word then
    found_in_buf4 = true
    break
  end
end
assert(found_in_buf4, "3.3 - Same item ID in new buffer", "Item should have same ID in buf4")

print()

-- ============================================================================
-- TEST 4: Theme Switching
-- ============================================================================
print("TEST 4: Theme Switching")
print("-------------------------------------------")

local buf5 = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf5, 0, -1, false, {"theme test"})

vim.api.nvim_set_current_buf(buf5)

-- Create highlight
local theme_item = items.add_global_item(buf5, {
  kind = "word",
  word = "theme",
  label = "theme",
})

assert(theme_item ~= nil, "4.1 - Create highlight before theme switch", "Highlight should be created")

-- Get original palette count
local original_count = super_highlight._resolved_palette_count
assert(original_count > 0, "4.2 - Has highlight groups", "Should have highlight groups")

-- Simulate theme switch by calling refresh
local theme = require('super-highlight.theme')
local new_palette = theme.build_palette()
local new_count = theme.create_hl_groups(new_palette)

assert(new_count > 0, "4.3 - New highlight groups created", "Should create new highlight groups")

-- Redraw should work without errors
local buf5_state = state.get(buf5)
local success, err = pcall(render.redraw, buf5, buf5_state)
assert(success, "4.4 - Redraw with new theme", "Redraw should succeed: " .. tostring(err))

print()

-- ============================================================================
-- TEST 5: Clear Operations
-- ============================================================================
print("TEST 5: Clear Operations")
print("-------------------------------------------")

local buf6 = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf6, 0, -1, false, {"clear test clear"})

vim.api.nvim_set_current_buf(buf6)

items.clear_all()
state.reset(buf6)

-- Add multiple highlights
local item1 = items.add_global_item(buf6, {
  kind = "word",
  word = "clear",
  label = "clear",
})

local item2 = items.add_global_item(buf6, {
  kind = "word",
  word = "test",
  label = "test",
})

assert(item1 ~= nil and item2 ~= nil, "5.1 - Create multiple highlights", "Should create 2 highlights")

-- Test clear_at_cursor (remove single item)
state.remove_item(buf6, item1.id)
items.remove_global_item(item1.id)

local buf6_state = state.get(buf6)
local remaining_count = #buf6_state.items
assert(remaining_count == 1, "5.2 - Remove single item", "Should have 1 item remaining")

-- Verify correct item remains
local remaining = buf6_state.items[1]
assert(remaining.word == "test", "5.3 - Correct item remains", "Remaining item should be 'test'")

-- Test clear_buffer (remove all)
super_highlight.clear_buffer()
local buf6_after_clear = state.get(buf6)
assert(#buf6_after_clear.items == 0, "5.4 - Clear all items", "Should have 0 items after clear_buffer")

print()

-- ============================================================================
-- TEST 6: Navigation
-- ============================================================================
print("TEST 6: Navigation")
print("-------------------------------------------")

local buf7 = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf7, 0, -1, false, {
  "line one with nav",
  "line two with nav",
  "line three",
})

vim.api.nvim_set_current_buf(buf7)

items.clear_all()
state.reset(buf7)

-- Create highlight for navigation
local nav_item = items.add_global_item(buf7, {
  kind = "word",
  word = "nav",
  label = "nav",
})

assert(nav_item ~= nil, "6.1 - Create highlight for navigation", "Highlight should be created")

-- Get all positions
local buf7_state = state.get(buf7)
local positions = state.flatten_positions(buf7)
assert(#positions >= 2, "6.2 - Multiple positions to navigate", "Should have at least 2 positions")

-- Test jump_next
vim.api.nvim_win_set_cursor(0, {1, 0})
local cursor_before = vim.api.nvim_win_get_cursor(0)

super_highlight.jump_next()
local cursor_after = vim.api.nvim_win_get_cursor(0)

assert(cursor_after[1] > cursor_before[1] or cursor_after[2] > cursor_before[2],
       "6.3 - Jump next moves cursor", "Cursor should move forward")

-- Test jump_prev
super_highlight.jump_prev()
local cursor_prev = vim.api.nvim_win_get_cursor(0)

-- Should move back or stay at first occurrence
assert(cursor_prev[1] <= cursor_after[1] or cursor_prev[2] <= cursor_after[2],
       "6.4 - Jump prev moves cursor", "Cursor should move backward")

print()

-- ============================================================================
-- TEST 7: Toggle Word Functionality
-- ============================================================================
print("TEST 7: Toggle Word Functionality")
print("-------------------------------------------")

local buf8 = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf8, 0, -1, false, {"toggle toggle toggle"})

vim.api.nvim_set_current_buf(buf8)
items.clear_all()
state.reset(buf8)

-- Place cursor on "toggle"
vim.api.nvim_win_set_cursor(0, {1, 0})

-- First toggle - should add
local toggle_word = vim.fn.expand("<cword>")
assert(toggle_word == "toggle", "7.1 - Cursor on correct word", "Cursor should be on 'toggle'")

-- Simulate toggle_word
local toggle_item = items.add_global_item(buf8, {
  kind = "word",
  word = toggle_word,
  label = toggle_word,
})

assert(toggle_item ~= nil, "7.2 - First toggle adds item", "First toggle should add highlight")

-- Second toggle - should remove (check if item exists)
local found_before = items.find_global_item(toggle_word, nil)
assert(found_before ~= nil, "7.3 - Item exists before second toggle", "Item should exist")

items.remove_global_item(toggle_item.id)
state.remove_item(buf8, toggle_item.id)
render.redraw(buf8, state.get(buf8))

local found_after = items.find_global_item(toggle_word, nil)
assert(found_after == nil, "7.4 - Item removed after second toggle", "Item should be removed")

print()

-- ============================================================================
-- TEST 8: Toggle Visual Functionality
-- ============================================================================
print("TEST 8: Toggle Visual (Range) Functionality")
print("-------------------------------------------")

local buf9 = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf9, 0, -1, false, {"visual selection test"})

vim.api.nvim_set_current_buf(buf9)
items.clear_all()
state.reset(buf9)

-- Simulate visual selection of "selection"
local range_text = "selection"
local range_item_test = items.add_global_item(buf9, {
  kind = "range",
  text = range_text,
  label = range_text,
})

assert(range_item_test ~= nil, "8.1 - Add range highlight", "Range highlight should be added")
assert(range_item_test.kind == "range", "8.2 - Correct kind", "Item should be range type")

-- Toggle off
items.remove_global_item(range_item_test.id)
state.remove_item(buf9, range_item_test.id)
render.redraw(buf9, state.get(buf9))

local found_range = items.find_global_item(nil, range_text)
assert(found_range == nil, "8.3 - Range removed", "Range should be removed after toggle")

print()

-- ============================================================================
-- TEST 9: Global Items Management
-- ============================================================================
print("TEST 9: Global Items Management")
print("-------------------------------------------")

local buf10 = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf10, 0, -1, false, {"global test"})

vim.api.nvim_set_current_buf(buf10)

items.clear_all()

-- Add multiple global items
local g1 = items.add_global_item(buf10, { kind = "word", word = "global", label = "global" })
local g2 = items.add_global_item(buf10, { kind = "word", word = "test", label = "test" })

local global_items = items.get_global_items()
assert(#global_items == 2, "9.1 - Get global items", "Should have 2 global items")

-- Find specific items
local found_g1 = items.find_global_item("global", nil)
assert(found_g1 ~= nil and found_g1.id == g1.id, "9.2 - Find global item", "Should find 'global' item")

local found_g2 = items.find_global_item("test", nil)
assert(found_g2 ~= nil and found_g2.id == g2.id, "9.3 - Find another global item", "Should find 'test' item")

-- Clear all
items.clear_all()
local global_items_after = items.get_global_items()
assert(#global_items_after == 0, "9.4 - Clear all global items", "Should have 0 global items after clear")

print()

-- ============================================================================
-- TEST 10: Color Index Management
-- ============================================================================
print("TEST 10: Color Index Management")
print("-------------------------------------------")

local buf11 = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf11, 0, -1, false, {"color1 color2 color3"})

vim.api.nvim_set_current_buf(buf11)
items.clear_all()
state.reset(buf11)

-- Add items and check they get different colors
local c1 = items.add_global_item(buf11, { kind = "word", word = "color1", label = "c1" })
local c2 = items.add_global_item(buf11, { kind = "word", word = "color2", label = "c2" })
local c3 = items.add_global_item(buf11, { kind = "word", word = "color3", label = "c3" })

assert(c1 ~= nil and c2 ~= nil and c3 ~= nil, "10.1 - Create colored items", "Should create 3 items")

-- Each should have a palette index
assert(c1.palette ~= nil, "10.2 - Item 1 has color", "Item 1 should have palette index")
assert(c2.palette ~= nil, "10.3 - Item 2 has color", "Item 2 should have palette index")
assert(c3.palette ~= nil, "10.4 - Item 3 has color", "Item 3 should have palette index")

-- Colors should cycle (if palette has limited size)
local global_items_color = items.get_global_items()
assert(#global_items_color == 3, "10.5 - All items exist", "All 3 items should exist")

print()

-- ============================================================================
-- CLEANUP AND SUMMARY
-- ============================================================================
print("==========================================")
print("CLEANUP")
print("==========================================")

-- Clean up all test buffers
cleanup_buffers()

print("All test buffers cleaned up\n")

-- ============================================================================
-- TEST SUMMARY
-- ============================================================================
print("==========================================")
print("TEST SUMMARY")
print("==========================================")
print(string.format("Total Tests: %d", test_count))
print(string.format("Passed: %d", passed_count))
print(string.format("Failed: %d", failed_count))
print(string.format("Success Rate: %.1f%%", (passed_count / test_count) * 100))
print()

if failed_count > 0 then
  print("FAILED TESTS:")
  print("-------------------------------------------")
  for _, result in ipairs(test_results) do
    if result.status == "FAILED" then
      print(string.format("❌ %s: %s", result.name, result.msg or "Unknown error"))
    end
  end
  print()
end

print("==========================================")
if failed_count == 0 then
  print("✅ ALL TESTS PASSED!")
else
  print(string.format("❌ %d TEST(S) FAILED", failed_count))
end
print("==========================================")

-- Exit with appropriate code
if failed_count > 0 then
  os.exit(1)
else
  os.exit(0)
end
