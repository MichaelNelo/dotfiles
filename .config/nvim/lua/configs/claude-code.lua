return {
  window = {
    split_ratio = 0.4,
    position = "vertical",
  },
  git = {
    use_git_root = true,
  },
  command = "claude",
  command_variants = {
    continue = "--continue", -- Resume the most recent conversation
    resume = "--resume",     -- Display an interactive conversation picker
   	verbose = "--verbose",   -- Enable verbose logging with full turn-by-turn output
  },
  keymaps = {
  	toggle = {
  		normal = "<C-n>",
  		terminal = "<C-n>",
  		variants = {
		  continue = "<leader>cC", -- Normal mode keymap for Claude Code with continue flag
		  verbose = "<leader>cV",  -- Normal mode keymap for Claude Code with verbose flag
		},	
  	},
  	scrolling = true,
	window_navigation = true,
  }
}
