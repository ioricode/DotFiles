-- vim.opt.guicursor = "n-v-i-c:block-Cursor"
vim.g.mapleader = " "

vim.o.guicursor = "n-v-c-sm-i-ci-ve:block,r-cr-o:hor20,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor"

vim.opt.nu = true

vim.opt.relativenumber = true

vim.opt.tabstop = 8
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

print("This file Running GOOD")

vim.opt.wrap = true

vim.opt.swapfile = false
vim.opt.backup = false

vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.scrolloff = 8

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"

vim.keymap.set("x", "<leader>p", '"_dP')

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- greatest remap ever
vim.keymap.set("x", "<leader>p", [["_dP]])

--
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d')

vim.keymap.set("n", "<c-k", ":wincmd k<CR>")
vim.keymap.set("n", "<c-j", ":wincmd j<CR>")
vim.keymap.set("n", "<c-h", ":wincmd h<CR>")
vim.keymap.set("n", "<c-l", ":wincmd l<CR>")

--ALL LINE SHOULF BE WRITEN SAME)
--PRESS CTRL V THEN J(OR SELECT LINE WANT TO MARK
--THEN TYPE WHAT U WANT AND THEN ENTER AND
--<leader>cm MASON
--<leader>f
