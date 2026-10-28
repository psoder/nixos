{ pkgs, ... }:

{
  imports = [
    programs/git.nix
    programs/fish.nix
    programs/neovim.nix
  ];

  programs = {
    neovim.defaultEditor = true;

    atuin = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
      settings = {
        filter_mode = "directory";
        ctrl_n_shortcuts = true;
        keymap_mode = "vim-insert";
      };
    };
  };

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    git
    nixfmt
    nixfmt-tree
    sops
    age
    yazi
    zellij
    bottom
    fd
    ripgrep
    dust
    delta
    eza
    bat
    fzf
    zoxide
    fastfetch
    hdparm
  ];
}
