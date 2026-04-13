# Format all Lua files with stylua
format:
    stylua .

# Lint all Lua files with selene
lint:
    selene .

# Run plenary tests
test:
    nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

# Run lint, format, and tests
check: lint format test
