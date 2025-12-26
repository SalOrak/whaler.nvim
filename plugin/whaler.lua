vim.api.nvim_create_user_command("Whaler", function(ctx)
    require("whaler").whaler()
  end, {})

vim.api.nvim_create_user_command("WhalerSwitch", function(ctx)
    local bufnr = vim.api.nvim_get_current_buf()
    local filename =  vim.api.nvim_buf_get_name(bufnr)
    local clean = string.gsub(filename,".*://", "")
    local path = vim.fs.abspath(clean)
    local parent = vim.fs.dirname(path)
    require("whaler").switch(parent)
  end,
  { desc = "Whaler: Changes project to current buffer path"})
