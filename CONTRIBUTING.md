# Contributing to Super Highlight

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## How to Contribute

### Reporting Bugs
1. Check existing issues to avoid duplicates
2. Use the bug report template
3. Include Neovim version, plugin version, reproduction steps

### Suggesting Features
1. Check existing feature requests
2. Use the "enhancement" label
3. Describe the use case clearly

### Submitting Pull Requests
1. Fork the repository
2. Create a feature branch
3. Make your changes with clear commit messages
4. Submit a pull request

## Development Setup

Clone your fork and test with:
```bash
git clone https://github.com/gagapony/highlight.nvim.git
cd highlight.nvim
nvim --headless -c "lua require('highlight').setup({})" -c "qa"
```

## Code Style

- Use 2 spaces for indentation
- Follow Lua style guide
- Add comments for complex logic
- Keep functions focused and small

## Testing

Test your changes thoroughly before submitting.
