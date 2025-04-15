return {
    {
        "quarto-dev/quarto-nvim",
        dependencies = {
            "jmbuhr/otter.nvim",
            "nvim-treesitter/nvim-treesitter",
        },
        debug = false,
        closePreviewOnExit = true,
        lspFeatures = {
            enabled = true,
            chunks = "curly",
            languages = { "r", "python", "bash", "html" },
            diagnostics = {
                enabled = true,
                triggers = { "BufWritePost" },
            },
            completion = {
                enabled = true,
            },
        },
        codeRunner = {
            enabled = true,
            default_method = "molten", -- "molten", "slime", "iron" or <function>
            ft_runners = {}, -- filetype to runner, ie. `{ python = "molten" }`.
            -- Takes precedence over `default_method`
            never_run = { "yaml" }, -- filetypes which are never sent to a code runner
        },
    },
    { -- directly open ipynb files as quarto docuements
        -- and convert back behind the scenes
        "GCBallesteros/jupytext.nvim",
        opts = {
            custom_language_formatting = {
                python = {
                    extension = "qmd",
                    style = "quarto",
                    force_ft = "quarto",
                },
                r = {
                    extension = "qmd",
                    style = "quarto",
                    force_ft = "quarto",
                },
            },
        },
    },
    { -- send code from python/r/qmd documets to a terminal or REPL
        -- like ipython, R, bash
        "jpalardy/vim-slime",
        dev = false,
        init = function()
            vim.b["quarto_is_python_chunk"] = false
            Quarto_is_in_python_chunk = function()
                require("otter.tools.functions").is_otter_language_context("python")
            end

            vim.cmd([[
      let g:slime_dispatch_ipython_pause = 100
      function SlimeOverride_EscapeText_quarto(text)
      call v:lua.Quarto_is_in_python_chunk()
      if exists('g:slime_python_ipython') && len(split(a:text,"\n")) > 1 && b:quarto_is_python_chunk && !(exists('b:quarto_is_r_mode') && b:quarto_is_r_mode)
      return ["%cpaste -q\n", g:slime_dispatch_ipython_pause, a:text, "--", "\n"]
      else
      if exists('b:quarto_is_r_mode') && b:quarto_is_r_mode && b:quarto_is_python_chunk
      return [a:text, "\n"]
      else
      return [a:text]
      end
      end
      endfunction
      ]])

            vim.g.slime_target = "neovim"
            vim.g.slime_no_mappings = true
            vim.g.slime_python_ipython = 1
        end,
        config = function()
            vim.g.slime_input_pid = false
            vim.g.slime_suggest_default = true
            vim.g.slime_menu_config = false
            vim.g.slime_neovim_ignore_unlisted = true

            local function mark_terminal()
                local job_id = vim.b.terminal_job_id
                vim.print("job_id: " .. job_id)
            end

            local function set_terminal()
                vim.fn.call("slime#config", {})
            end
            vim.keymap.set("n", "<leader>cm", mark_terminal, { desc = "[m]ark terminal" })
            vim.keymap.set("n", "<leader>cs", set_terminal, { desc = "[s]et terminal" })
        end,
    },
    { -- preview equations
        "jbyuki/nabla.nvim",
        keys = {
            { "<leader>qm", ':lua require"nabla".toggle_virt()<cr>', desc = "toggle [m]ath equations" },
        },
    },

    {
        "benlubas/molten-nvim",
        dev = false,
        enabled = true,
        version = "^1.0.0", -- use version <2.0.0 to avoid breaking changes
        build = ":UpdateRemotePlugins",
        init = function()
            vim.g.molten_image_provider = "image.nvim"
            -- vim.g.molten_output_win_max_height = 20
            vim.g.molten_auto_open_output = true
            vim.g.molten_auto_open_html_in_browser = true
            vim.g.molten_tick_rate = 200
        end,
        config = function()
            local init = function()
                local quarto_cfg = require("quarto.config").config
                quarto_cfg.codeRunner.default_method = "molten"
                vim.cmd([[MoltenInit]])
            end
            local deinit = function()
                local quarto_cfg = require("quarto.config").config
                quarto_cfg.codeRunner.default_method = "slime"
                vim.cmd([[MoltenDeinit]])
            end
            vim.keymap.set("n", "<localleader>mi", init, { silent = true, desc = "Initialize molten" })
            vim.keymap.set("n", "<localleader>md", deinit, { silent = true, desc = "Stop molten" })
            vim.keymap.set(
                "n",
                "<localleader>mp",
                ":MoltenImagePopup<CR>",
                { silent = true, desc = "molten image popup" }
            )
            vim.keymap.set(
                "n",
                "<localleader>mb",
                ":MoltenOpenInBrowser<CR>",
                { silent = true, desc = "molten open in browser" }
            )
            vim.keymap.set("n", "<localleader>mh", ":MoltenHideOutput<CR>", { silent = true, desc = "hide output" })
            vim.keymap.set(
                "n",
                "<localleader>ms",
                ":noautocmd MoltenEnterOutput<CR>",
                { silent = true, desc = "show/enter output" }
            )
        end,
    },
    {
        "3rd/image.nvim",
        event = "VeryLazy",
        opts = {
            backend = "kitty",
            processor = "magick_cli",
            integrations = {
                markdown = {
                    enabled = true,
                    clear_in_insert_mode = false,
                    download_remote_images = true,
                    only_render_image_at_cursor = false,
                    floating_windows = false,
                    filetypes = { "markdown", "vimwiki", "quarto" },
                },
                neorg = {
                    enabled = true,
                    filetypes = { "norg" },
                },
                typst = {
                    enabled = true,
                    filetypes = { "typst" },
                },
                html = {
                    enabled = false,
                },
                css = {
                    enabled = false,
                },
            },
            max_width = nil,
            max_height = nil,
            max_width_window_percentage = nil,
            max_height_window_percentage = 50,
            window_overlap_clear_enabled = false,
            window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "snacks_notif", "scrollview", "scrollview_sign" },
            editor_only_render_when_focused = false,
            tmux_show_only_in_active_window = false,
            hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
        },
    },
}
