# Format all Lua files with stylua
format:
    stylua .

# Lint all Lua files with selene
lint:
    selene .

# Run both lint and format
check: lint format
