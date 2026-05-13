#!/usr/bin/env nvim -l

-- Test script for refactored init.lua
package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'

print("=== Testing Super Highlight Refactored Module ===\n")

-- Test 1: Module loading
print("Test 1: Loading module...")
local ok, super_highlight = pcall(require, 'super-highlight.init')
if not ok then
  print("❌ FAILED: Could not load module")
  os.exit(1)
end
print("✅ PASSED: Module loaded successfully\n")

-- Test 2: Setup function
print("Test 2: Testing setup()...")
local setup_ok, setup_err = pcall(super_highlight.setup, {})
if not setup_ok then
  print("❌ FAILED: setup() failed with error:", setup_err)
  os.exit(1)
end
print("✅ PASSED: setup() completed\n")

-- Test 3: Check that modules are integrated
print("Test 3: Verifying module integration...")
local config_ok, config = pcall(require, 'super-highlight.config')
local items_ok, items = pcall(require, 'super-highlight.items')
local theme_ok, theme = pcall(require, 'super-highlight.theme')

if not config_ok or not items_ok or not theme_ok then
  print("❌ FAILED: Could not load required modules")
  os.exit(1)
end
print("✅ PASSED: All modules loaded\n")

-- Test 4: Verify config
print("Test 4: Verifying config integration...")
local auto_theme = config.get('auto_theme')
local palette = config.get('palette')
if type(auto_theme) ~= 'boolean' or type(palette) ~= 'table' then
  print("❌ FAILED: Config not properly initialized")
  os.exit(1)
end
print("✅ PASSED: Config properly initialized\n")

-- Test 5: Verify items module
print("Test 5: Verifying items module...")
if type(items.add_global_item) ~= 'function' or
   type(items.remove_global_item) ~= 'function' or
   type(items.find_global_item) ~= 'function' then
  print("❌ FAILED: Items module missing required functions")
  os.exit(1)
end
print("✅ PASSED: Items module has required functions\n")

-- Test 6: Verify theme module
print("Test 6: Verifying theme module...")
if type(theme.build_palette) ~= 'function' or
   type(theme.create_hl_groups) ~= 'function' then
  print("❌ FAILED: Theme module missing required functions")
  os.exit(1)
end
print("✅ PASSED: Theme module has required functions\n")

-- Test 7: Verify public API
print("Test 7: Verifying public API...")
local public_functions = {
  'setup', 'toggle_word', 'toggle_visual', 'clear_at_cursor',
  'clear_buffer', 'jump_next', 'jump_prev', 'open_picker'
}

for _, func_name in ipairs(public_functions) do
  if type(super_highlight[func_name]) ~= 'function' then
    print("❌ FAILED: Missing public function:", func_name)
    os.exit(1)
  end
end
print("✅ PASSED: All public API functions available\n")

print("=== All Tests Passed! ===")
