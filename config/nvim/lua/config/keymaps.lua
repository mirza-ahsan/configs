-- ~/.config/nvim/lua/config/keymaps.lua

local keymap = vim.keymap

-----------------------------------------------------------
-- General & Navigation Remaps
-----------------------------------------------------------

-- Yanking
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- Open Netrw
keymap.set("n", "<leader>pv", vim.cmd.Ex, { desc = "Open Netrw Explorer" })

-- Move selected lines up/down in visual mode
keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move block down" })
keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move block up" })

-- Keep cursor centered during navigation
keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
keymap.set("n", "n", "nzzzv", { desc = "Next search match and center" })
keymap.set("n", "N", "Nzzzv", { desc = "Prev search match and center" })
keymap.set("n", "J", "mzJ`z", { desc = "Join lines and keep cursor position" })

-- Utility
keymap.set({ "n", "v" }, "<C-_>", ":message<CR>", { desc = "View message history" })
keymap.set("n", "Q", "<nop>", { desc = "Disable Ex mode" })

-- Window Management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-----------------------------------------------------------
-- Custom Compilers & Runners
-----------------------------------------------------------

-- Format file (Will hook up to LSP later)
keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "Format file via LSP" })

-- Compile, mount in DOSBox, and run AFD for .asm files
keymap.set("n", "<leader>d", function()
    if vim.bo.filetype == "asm" then
        local asm_file = vim.fn.expand("%:p")
        local asm_dir = vim.fn.expand("%:p:h")
        local output_file = vim.fn.expand("%:t:r")

        vim.fn.system("nasm " .. asm_file .. " -o " .. output_file .. ".com")

        if vim.v.shell_error ~= 0 then
            local result = vim.fn.systemlist("nasm " .. asm_file .. " -o " .. output_file .. ".com 2>&1")
            for _, line in ipairs(result) do
                print(line)
            end
            print("Compilation Failed")
            return
        end

        print("Compilation Successful")
        local dosbox_command = table.concat({
            "dosbox",
            "-c \"mount c: " .. asm_dir .. "\"",
            "-c \"c:\"",
            "-c \"afd " .. output_file .. ".com \"",
            "-c \"exit \""
        }, " ")

        local job_id = vim.fn.jobstart(
            "xdotool key alt+4 && xdotool key alt+Return && " .. dosbox_command .. " -fullscreen", {
                on_exit = function()
                    vim.fn.system("xdotool key ctrl+d && xdotool key alt+3")
                end
            })

        if job_id <= 0 then print("Failed to start DOSBox!") end
    else
        print("This command works only for .asm files!")
    end
end, { desc = "Compile, mount in DOSBox, and run AFD for .asm files" })

-- Compile and run C/ASM files
keymap.set("n", "<leader>r", function()
    local filetype = vim.bo.filetype

    if filetype == "c" then
        local filepath = vim.fn.expand("%:r")
        local filename = vim.fn.expand("%:t:r")
        vim.fn.system("gcc " .. filepath .. ".c -o " .. filename)
        vim.cmd("!./" .. filename)
    elseif filetype == "asm" then
        local asm_file = vim.fn.expand("%:p")
        local asm_dir = vim.fn.expand("%:p:h")
        local output_file = vim.fn.expand("%:t:r")

        local compile_cmd = "nasm " .. asm_file .. " -o " .. output_file .. ".com"
        local compile_result = vim.fn.systemlist(compile_cmd)

        if vim.v.shell_error ~= 0 then
            print("Compilation Failed")
            for _, line in ipairs(compile_result) do print(line) end
            return
        end
        print("Compilation Successful")

        local dosbox_command = table.concat({
            "dosbox",
            "-c \"mount c: " .. asm_dir .. "\"",
            "-c \"c:\"",
            "-c \"" .. output_file .. ".com\"",
        }, " ")

        local job_id = vim.fn.jobstart(
            "xdotool key alt+4 && xdotool key alt+Return && " .. dosbox_command .. " -fullscreen", {
                on_exit = function()
                    vim.fn.system("xdotool key ctrl+d && xdotool key alt+3")
                end
            })

        if job_id <= 0 then print("Failed to start DOSBox!") end
    else
        print("This command works only for .c and .asm files!")
    end
end, { desc = "Compile and run C/ASM files" })
