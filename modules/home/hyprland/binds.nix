{ host, ... }:
let
  inherit
    (import ../../../hosts/${host}/variables.nix)
    browser
    terminal
    ;
in
{
  wayland.windowManager.hyprland.settings = {
    bind = [
      "$modifier,Return,exec,${terminal}"               # Terminal
      "$modifier,K,exec,list-keybinds"                  # Keybinds
      "$modifier ,R,exec,rofi-launcher"                 # Launcher
      "$modifier SHIFT,Return,exec,rofi-launcher"       # Launcher
      "$modifier SHIFT,W,exec,web-search"               # Web search
      "$modifier ALT,W,exec,wallsetter"                 # Wallpaper setter
      "$modifier SHIFT,N,exec,swaync-client -rs"        # Swaync client
      "$modifier,B,exec,${browser}"                     # Browser
      "$modifier,Y,exec,kitty -e yazi"                  # Yazi (Terminal file explorer)
      "$modifier,E,exec,emopicker9000"                  # Emoji picker
      "$modifier,S,exec,screenshootin"                  # Screenshot
      #"$modifier,D,exec,discord"                        # Discord
      #"$modifier,O,exec,obs"                            # OBS
      "$modifier,Escape,exec,hyprlock"                  # Hyprlock (Lock screen) 
      "$modifier,C,exec,hyprpicker -a"                  # Hyprpicker (Colour picker)
      "$modifier,G,exec,gimp"                           # Gimp
      "$modifier control,return,exec,pypr toggle term"  # Pypr (Popup terminal)
      "$modifier,T,exec, thunar"                        # Thunar
      "$modifier,M,exec,pavucontrol"                    # Pavucontrol (Audio config)
      "$modifier,Q,killactive,"                         # Kill current window (Alt+F4)
      "$modifier,P,pseudo,"                             # Toggle Pseudo tiling
      "$modifier,V,exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy" # Clipboard history
      "$modifier SHIFT,I,togglesplit,"                  # Toggle horizontal/vertial split
      "$modifier,F,fullscreen,"                         # Fullscreen
      "$modifier SHIFT,F,togglefloating,"               # Toggle floating
      "$modifier ALT,F,workspaceopt, allfloat"          # Float all windows on workspace
      "$modifier SHIFT,C,exit,"                         # Exit hyprland
      "$modifier SHIFT,left,movewindow,l"               # Move window left
      "$modifier SHIFT,right,movewindow,r"              # Move window right
      "$modifier SHIFT,up,movewindow,u"                 # Move window up
      "$modifier SHIFT,down,movewindow,d"               # Move window down
      "$modifier SHIFT,h,movewindow,l"                  # Move window left
      "$modifier SHIFT,l,movewindow,r"                  # Move window right
      "$modifier SHIFT,k,movewindow,u"                  # Move window up
      "$modifier SHIFT,j,movewindow,d"                  # Move window down
      "$modifier ALT, left, swapwindow,l"               # Swap window left
      "$modifier ALT, right, swapwindow,r"              # Swap window right
      "$modifier ALT, up, swapwindow,u"                 # Swap window up
      "$modifier ALT, down, swapwindow,d"               # Swap window down
      "$modifier ALT, 43, swapwindow,l"                 # Swap window left
      "$modifier ALT, 46, swapwindow,r"                 # Swap window right
      "$modifier ALT, 45, swapwindow,u"                 # Swap window up
      "$modifier ALT, 44, swapwindow,d"                 # Swap window down
      "$modifier,left,movefocus,l"                      # Move focus left
      "$modifier,right,movefocus,r"                     # Move focus right
      "$modifier,up,movefocus,u"                        # Move focus up
      "$modifier,down,movefocus,d"                      # Move focus down
      "$modifier,h,movefocus,l"                         # Move focus left
      "$modifier,l,movefocus,r"                         # Move focus right
      "$modifier,k,movefocus,u"                         # Move focus up
      "$modifier,j,movefocus,d"                         # Move focus down
      "$modifier,1,workspace,1"                         # 
      "$modifier,2,workspace,2"                         #
      "$modifier,3,workspace,3"                         #
      "$modifier,4,workspace,4"                         #
      "$modifier,5,workspace,5"                         # Move to workspace
      "$modifier,6,workspace,6"                         #
      "$modifier,7,workspace,7"                         #
      "$modifier,8,workspace,8"                         #
      "$modifier,9,workspace,9"                         #
      "$modifier,0,workspace,10"                        #
      "$modifier SHIFT,SPACE,movetoworkspace,special"
      "$modifier,SPACE,togglespecialworkspace"
      "$modifier SHIFT,1,movetoworkspace,1"             #
      "$modifier SHIFT,2,movetoworkspace,2"             #
      "$modifier SHIFT,3,movetoworkspace,3"             #
      "$modifier SHIFT,4,movetoworkspace,4"             #
      "$modifier SHIFT,5,movetoworkspace,5"             # Move window to workspace
      "$modifier SHIFT,6,movetoworkspace,6"             #
      "$modifier SHIFT,7,movetoworkspace,7"             #
      "$modifier SHIFT,8,movetoworkspace,8"             #
      "$modifier SHIFT,9,movetoworkspace,9"             #
      "$modifier SHIFT,0,movetoworkspace,10"            #
      "$modifier CONTROL,right,workspace,e+1"           # Next workspace
      "$modifier CONTROL,left,workspace,e-1"            # Previous workspace
      "$modifier,Tab,workspace,e+1"                     # Next workspace
      "$modifier Shift,Tab,workspace,e-1"               # Previous workspace
      "$modifier,mouse_down,workspace, e+1"             # Drag window
      "$modifier,mouse_up,workspace, e-1"               # Drag window
      "ALT,Tab,cyclenext"                               # Next window
      "ALT SHIFT,Tab,cyclenext,prev"                    # Previous window
      "ALT,Tab,bringactivetotop"
      ",XF86AudioRaiseVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
      ",XF86AudioLowerVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      " ,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ",XF86AudioPlay, exec, playerctl play-pause"
      ",XF86AudioPause, exec, playerctl play-pause"
      ",XF86AudioNext, exec, playerctl next"
      ",XF86AudioPrev, exec, playerctl previous"
      ",XF86MonBrightnessDown,exec,brightnessctl set 5%-"
      ",XF86MonBrightnessUp,exec,brightnessctl set +5%"
    ];

    bindm = [
      "$modifier, mouse:272, movewindow"
      "$modifier, mouse:273, resizewindow"
    ];
  };
}
