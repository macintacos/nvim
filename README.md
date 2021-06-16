# Lua-forward Neovim Config

I'm taking a second stab at trying a neovim config again, using Neovim nightly since 0.5.0 seems shiny. Some notable decisions that I might revisit later:

- I switched away from the native LSP because it was far too finnicky to set up for my tastes. [CoC.nvim](https://github.com/neoclide/coc.nvim) will do just fine until the LSP configuration stuff can get sorted out - ideally, I'm keeping an eye on projects like [nvim-lspinstall](https://github.com/kabouzeid/nvim-lspinstall)
- I couldn't find a great way to do this, but there's a lot of stuff in my previous configuration that I want to bring over to this config, so I'm still using an `init.vim`. Almost all new configuration takes place in the `lua/` folder, and where it's relatively straightforward, I'm converting old configurations over to Lua.

I'll attach a screenshot at.... some point.

