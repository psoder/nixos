{ ... }:

{
  programs.nixvim = {
    enable = true;
    colorschemes.catppuccin.enable = true;
    plugins.lualine.enable = true;

    opts = {
      number = true;
      relativenumber = true;
    };

    lsp = {
      servers = {
        nixd.enable = true;
      };
    };

    plugins = {
      lsp-format.enable = true;
    };
  };
}
