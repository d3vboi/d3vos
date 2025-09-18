{ profile, ... }: {
  programs.bash = {
    enable = false;
    enableCompletion = true;
    initExtra = ''
      fastfetch
      if [ -f $HOME/.bashrc-personal ]; then
        source $HOME/.bashrc-personal
      fi
    '';
    shellAliases = {
      sv = "sudo nvim";
      fr = "nh os switch --hostname ${profile}";
      fu = "nh os switch --hostname ${profile} --update";
      zu = "sh <(curl -L https://gitlab.com/D3vboi/d3vos/-/releases/latest/download/install-d3vos.sh)";
      ncg = "nix-collect-garbage --delete-old && sudo nix-collect-garbage -d && sudo /run/current-system/bin/switch-to-configuration boot";
      v = "nvim";
      cat = "bat";
      ".." = "cd ..";
    };
  };
}
