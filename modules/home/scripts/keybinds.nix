{ pkgs }:
pkgs.writeShellScriptBin "list-keybinds" ''
  # check if rofi is already running
  if pidof rofi > /dev/null; then
    pkill rofi
  fi

  keybinds=$(cat ~/.config/hypr/hyprland.conf | grep -E '^bind')
  
  # replace #modifier with SUPER in the displayed keybinds for rofi
  display_keybinds=$(echo "$keybinds" | sed 's/\$modifier/SUPER/g' | sed 's/^[^=]*=//')

  # use rofi to display the keybinds with the modified content
  echo "$display_keybinds" | rofi -dmenu -i -config ~/.config/rofi/config-long.rasi -mesg "$msg"

''
