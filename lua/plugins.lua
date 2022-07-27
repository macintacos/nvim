---@diagnostic disable: undefined-global
local install_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"

if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    vim.api.nvim_command("!git clone https://github.com/wbthomason/packer.nvim " .. install_path)
    vim.api.nvim_command("packadd packer.nvim")
end

--
vim.cmd("autocmd BufWritePost plugins.lua PackerCompile")

-- Because: https://github.com/wbthomason/packer.nvim/issues/202
require("packer").init({ max_jobs = 50 })

local function scandir(directory)
    local i, t, popen = 0, {}, io.popen
    local pfile = popen("find " .. directory .. " -maxdepth 1 -iname '*.lua' -execdir basename -s '.lua' {} +")
    for filename in pfile:lines() do
        i = i + 1
        t[i] = filename
    end
    pfile:close()
    return t
end

local path_to_plugins = vim.fn.stdpath("config") .. "/lua/plugins"
local plugin_files = scandir(path_to_plugins)

-- Plugins specified here!
return require("packer").startup(function(use)
    -- Get Packer to manage itself
    use({
        "wbthomason/packer.nvim",
        config = {
            profile = {
                enable = true,
                threshold = 1,
            },
        },
    })

    for _, file in pairs(plugin_files) do
        use(require("plugins." .. file))
    end

    -- Completion / LSP
    -- use({ "williamboman/nvim-lsp-installer" })
    -- use({ "neovim/nvim-lspconfig" })
    use({ "folke/lsp-colors.nvim" })
    use({ "folke/lua-dev.nvim" })
    use({ "ray-x/lsp_signature.nvim" })
    use({ "ray-x/guihua.lua" })
    use({
        "jose-elias-alvarez/null-ls.nvim",
        requres = {
            "nvim-lua/plenary.nvim",
            "neovim/nvim-lspconfig",
        },
    })

    -- Language Features
    use({ "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" })
    use({ "nvim-treesitter/playground", run = ":TSInstall query" })
    use({ "SmiteshP/nvim-gps", requires = "nvim-tree-sitter/nvim-treesitter" })
    use({ "kkoomen/vim-doge", run = ":call doge#install()" })
    use({ "preservim/vim-lexical" })
    use({ "preservim/vim-pencil" })
    use({ "stevearc/aerial.nvim" })

    -- Languages
    use({ "fatih/vim-go", run = ":silent :GoUpdateBinaries" })
    use({ "MTDL9/vim-log-highlighting" })
    use({ "SidOfc/mkdx" })
    use({ "iamcco/markdown-preview.nvim", run = "cd app && yarn install" })

    -- Appearance
    use({ "stevearc/dressing.nvim" })
    use({ "kyazdani42/nvim-web-devicons" })
    use({ "norcalli/nvim-colorizer.lua" })
    use({ "lukas-reineke/indent-blankline.nvim" }) -- TODO: make a different highlight for Python, similar to indent rainbow?
    use({ "akinsho/bufferline.nvim", tag = "*", requires = "kyazdani42/nvim-web-devicons" })
    use({ "kyazdani42/nvim-tree.lua", requires = "kyazdani42/nvim-web-devicons" }) -- TODO: Why is this so slow?
    -- use({ "nvim-lualine/lualine.nvim" })
    use({ "Mofiqul/dracula.nvim" })
    use({ "onsails/lspkind-nvim" })

    -- Utilities
    use({ "pwntester/octo.nvim" })
    use({
        "stevearc/stickybuf.nvim",
        config = function()
            require("stickybuf").setup()
        end,
    })
    use({ "folke/which-key.nvim" })
    use({ "mrjones2014/legendary.nvim" }) -- TODO: Turn this on wh enwe're on 0.7.0+
    use({ "dhruvasagar/vim-prosession", requires = { "tpope/vim-obsession" } })
    use({ "nacro90/numb.nvim" })
    use({ "folke/trouble.nvim" })
    use({ "arthurxavierx/vim-caser" })
    use({ "kazhala/close-buffers.nvim" })
    use({
        "folke/zen-mode.nvim",
        config = function()
            require("zen-mode").setup({})
        end,
    })
    use({ "tpope/vim-repeat" })
    use({ "mtth/scratch.vim" })
    use({ "troydm/zoomwintab.vim" }) -- or: dhruvasagar/vim-zoom
    use({ "jeffkreeftmeijer/vim-numbertoggle" })
    use({ "folke/todo-comments.nvim" })
    use({ "dstein64/vim-startuptime" })
    use({ "marklcrns/vim-smartq" })
    use({ "fedepujol/move.nvim" })
    use({ "inkarkat/vim-visualrepeat", requires = { "inkarkat/vim-ingo-library" } })
    use({ "abecodes/tabout.nvim" })
    use({ "justinmk/vim-gtfo" })
    use({ "luukvbaal/stabilize.nvim" })
    use({ "edluffy/specs.nvim" })
    use({ "Mofiqul/trld.nvim" })

    -- Text Manipulation
    use({ "ervandew/supertab" })
    use({ "tpope/vim-endwise" })
    -- use({ "numToStr/Comment.nvim" })
    use({ "tpope/vim-eunuch" })
    use({ "windwp/nvim-spectre" })
    use({ "windwp/nvim-autopairs" })
    use({ "windwp/nvim-ts-autotag" })
    use({ "AndrewRadev/tagalong.vim" })
    use({
        "mizlan/iswap.nvim",
        config = function()
            require("iswap").setup({})
        end,
    })
    use({ "tpope/vim-surround" })
    use({ "junegunn/vim-easy-align" })
    use({ "AndrewRadev/splitjoin.vim" })
    use({ "andymass/vim-matchup" })
    use({ "mg979/vim-visual-multi", branch = "master" })
    use({ "ggandor/lightspeed.nvim" })
    use({ "svermeulen/vim-cutlass" })
    use({ "svermeulen/vim-yoink" })
    use({ "itchyny/vim-cursorword" })
    use({ "inkarkat/vim-LineJuggler" })
    use({ "ntpeters/vim-better-whitespace" })
    use({ "wellle/targets.vim" })
    use({ "kana/vim-textobj-user" })
    use({ "preservim/vim-textobj-quote" })
    use({ "preservim/vim-textobj-sentence" })
    use({ "gelguy/wilder.nvim", requires = { "romgrk/fzy-lua-native", run = "make" } })
    use({ "simnalamburt/vim-mundo" })

    -- Git
    use({
        "TimUntersberger/neogit",
        requires = {
            "nvim-lua/plenary.nvim",
            "sindrets/diffview.nvim",
        },
    })
    use({ "lewis6991/gitsigns.nvim" })
    use({ "tpope/vim-fugitive" })
    use({ "rhysd/committia.vim" })
end)
