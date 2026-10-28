{ ... }:

{
  programs.fish = {
    enable = true;
    shellAliases = {
      ls = "eza";
      cat = "bat";
      gs = "git status";
      gdf = "git diff";
      gds = "git diff --status";
    };
    loginShellInit = ''
      function fish_greeting
        fastfetch
      end
    '';
    interactiveShellInit = ''
      zoxide init fish --cmd cd | source

      function fish_user_key_bindings
        fish_default_key_bindings -M insert
        fish_vi_key_bindings --no-erase insert
      end
    '';
  };
}
