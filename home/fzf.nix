{ ... }:

{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
     defaultOptions = [
      "--height=60%"
      "--layout=reverse"
      "--border=rounded"
    ];
    fileWidget.options = [
      "--preview 'bat --color=always --style=numbers --line-range=:300 {}'"
    ];
    changeDirWidget.options = [
      "--preview 'tree -C {} | head -200'"
    ];
    historyWidget.options = [ "--sort" "--exact" ];
  };
}
