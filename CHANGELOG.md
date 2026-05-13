# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- Unified word and range highlighting with consistent API
- Cross-buffer persistence for range highlights
- Theme color extraction with saturation boost
- Configuration validation and defaults module
- Modular architecture (config, theme, items modules)
- MIT License
- Contributing guidelines

### Changed
- Refactored init.lua to use separate modules
- Improved code organization and maintainability
- Enhanced documentation

### Fixed
- Range highlights now persist across buffers
- Theme switching applies to all existing highlights

## [0.1.0] - 2026-05-13

### Added
- Initial release
- Word highlighting with cross-buffer persistence
- Range highlighting (buffer-local)
- Theme-adaptive color palette
- Snacks picker integration
- Navigation commands (]h/[h)
