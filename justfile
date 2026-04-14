# Install plugins and dev tools needed for check/test
install:
    @echo "Installing dev tools…"
    brew install stylua selene
    @echo "Installing plugins…"
    nvim --headless -c "lua vim.pack.update()" -c "quitall"
    @echo "Done."

# Format all Lua files with stylua
format:
    stylua .

# Lint all Lua files with selene
lint:
    selene .
    selene --config tests/selene.toml tests/

# Run plenary tests
test:
    nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

# Run lint, format, and tests
check: lint format test
