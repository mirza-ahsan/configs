-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Personal keymaps below override LazyVim's where they overlap.
-- LSP keymaps (K, gd, gr, <leader>ca, <leader>rn) live in lua/plugins/personal.lua.

local map = vim.keymap.set

-----------------------------------------------------------
-- General & Navigation
-----------------------------------------------------------

-- Yank to system clipboard
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to clipboard" })
map("n", "<leader>Y", [["+Y]], { desc = "Yank line to clipboard" })

-- File explorer: netrw in place, or as a toggled panel on the right (Zed: ctrl-shift-e)
map("n", "<leader>pv", vim.cmd.Ex, { desc = "Open Netrw Explorer" })
map("n", "<C-S-e>", function()
  vim.cmd("Lexplore! " .. vim.fn.fnameescape(LazyVim.root()))
end, { desc = "Toggle netrw panel" })

-- Move selected lines up/down in visual mode
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move block down", silent = true })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move block up", silent = true })

-- Keep cursor centered during navigation
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
map("n", "n", "nzzzv", { desc = "Next search match and center" })
map("n", "N", "Nzzzv", { desc = "Prev search match and center" })
map("n", "J", "mzJ`z", { desc = "Join lines and keep cursor position" })

-- Zed: "g o" jumps to the start of the document
map("n", "go", "gg0", { desc = "Start of document" })
map("o", "go", "gg", { desc = "Start of document" })

-- Utility
map({ "n", "v" }, "<C-_>", "<cmd>messages<CR>", { desc = "View message history" })
map("n", "Q", "<nop>", { desc = "Disable Ex mode" })

-- Window Management
map("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
map("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
map("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
map("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-----------------------------------------------------------
-- Finder (snacks picker, themed by Omarchy)
-----------------------------------------------------------

map("n", "<leader>pf", function() Snacks.picker.files() end, { desc = "Find files" })
map("n", "<leader>fg", function() Snacks.picker.grep() end, { desc = "Live grep" })
map("n", "<leader>fb", function() Snacks.picker.buffers() end, { desc = "Buffers" })
map("n", "<leader>fh", function() Snacks.picker.help() end, { desc = "Help tags" })

-----------------------------------------------------------
-- Diagnostics & Formatting
-----------------------------------------------------------

map("n", "gl", vim.diagnostic.open_float, { desc = "Show full error message" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Go to previous error" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Go to next error" })

map("n", "<leader>f", function() LazyVim.format({ force = true }) end, { desc = "Format file" })

-- Zed: "- -" opens code actions
map("n", "--", vim.lsp.buf.code_action, { desc = "Code Action" })

-----------------------------------------------------------
-- Compile & Run
-----------------------------------------------------------

-- Assemble a .asm file to a .com and open it in DOSBox, optionally under the AFD debugger
local function run_asm_in_dosbox(with_debugger)
  local asm_file = vim.fn.expand("%:p")
  local asm_dir = vim.fn.expand("%:p:h")
  local output_file = vim.fn.expand("%:t:r")

  local result = vim.fn.systemlist({ "nasm", asm_file, "-o", asm_dir .. "/" .. output_file .. ".com" })
  if vim.v.shell_error ~= 0 then
    for _, line in ipairs(result) do
      print(line)
    end
    print("Compilation Failed")
    return
  end
  print("Compilation Successful")

  local program = with_debugger and ("afd " .. output_file .. ".com") or (output_file .. ".com")
  local cmd = { "dosbox", "-c", "mount c: " .. asm_dir, "-c", "c:", "-c", program }
  if with_debugger then
    vim.list_extend(cmd, { "-c", "exit" })
  end
  table.insert(cmd, "-fullscreen")

  if vim.fn.jobstart(cmd, { detach = true }) <= 0 then
    print("Failed to start DOSBox!")
  end
end

map("n", "<leader>d", function()
  if vim.bo.filetype == "asm" then
    run_asm_in_dosbox(true)
  else
    print("This command works only for .asm files!")
  end
end, { desc = "Compile, mount in DOSBox, and run AFD for .asm files" })

map("n", "<leader>r", function()
  local filetype = vim.bo.filetype
  if filetype == "c" then
    local filepath = vim.fn.expand("%:r")
    local filename = vim.fn.expand("%:t:r")
    vim.fn.system({ "clang", filepath .. ".c", "-o", filename })
    vim.cmd("!./" .. filename)
  elseif filetype == "asm" then
    run_asm_in_dosbox(false)
  else
    print("This command works only for .c and .asm files!")
  end
end, { desc = "Compile and run C/ASM files" })
