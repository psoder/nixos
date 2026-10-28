{ ... }:

{
  programs.git = {
    enable = true;
    config = {
      core = {
        editor = "nvim";
        pager = "delta";
      };
      init.defaultBranch = "main";

      user = {
        name = "Pontus Söderlund";
        email = "52171526+psoder@users.noreply.github.com";
      };

      alias = {
        lg = "log --oneline --graph --abbrev-commit --date=relative";
        df = "diff";
        dfs = "diff --stat";
      };
    };
  };
}
