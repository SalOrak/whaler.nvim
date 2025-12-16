vim.api.nvim_create_user_command("Whaler", function(ctx)
    require("whaler").whaler()
  end, {})

vim.api.nvim_create_user_command("WhalerSwitch", function(ctx)
    P(ctx.args)
    -- require("whaler").switch(ctx.fargs)
  end,
  {
      complete = "dir",
      nargs = "*",
})
