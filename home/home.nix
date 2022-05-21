{ ... }:

{
  imports = [
    ./i3.nix
    ./steam-proton.nix
    ./ssh.nix
    ./direnv.nix
    ./git.nix
    ./github.nix
    ./bash.nix
    ./zsh.nix
    ./starship.nix
    ./zoxide.nix
    ./kitty.nix
    ./gpg-agent.nix
    ./fzf.nix
    ./easyeffects.nix
    ./htop.nix
    ./firefox.nix
  ];

  home.enableNixpkgsReleaseCheck = false;
}
