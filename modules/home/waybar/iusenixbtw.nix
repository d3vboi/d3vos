{ pkgs, lib, host, config, ... }:
let
  inherit (import ../../../hosts/${host}/variables.nix) clock24h;
in
with lib; {
  programs.waybar = {
    enable = true;
    package = pkgs.waybar;

    settings = [
      {
        layer = "bottom";
        position = "top";
        height = 30;

        modules-left = [
          "hyprland/workspaces"
          "hyprland/mode"
        ];

        modules-center = [
          "hyprland/window"
        ];

        modules-right = [
          "tray"
          "custom/spotify"
          "custom/weather"
          "custom/storage"
          "backlight"
          "pulseaudio"
          "network"
          "idle_inhibitor"
          "battery"
          "clock"
        ];

        "hyprland/mode" = {
          format = " {}";
        };

        "hyprland/workspaces" = {
          format = "{name}";
          disable-scroll = true;
        };

        "hyprland/window" = {
          max-length = 80;
          tooltip = false;
        };

        "clock" = {
          format = if clock24h == true then "{:%a %d %b %H:%M}" else "{:%a %d %b %I:%M %p}";
          tooltip = false;
        };

        "battery" = {
          format = "{capacity}% {icon}";
          format-alt = "{time} {icon}";
          format-icons = [ "" "" "" "" "" ];
          format-charging = "{capacity}% ";
          interval = 30;
          states = { warning = 25; critical = 10; };
          tooltip = false;
        };

        "network" = {
          format = "{icon}";
          format-alt = "{ipaddr}/{cidr} {icon}";
          format-alt-click = "click-right";
          format-icons = {
            wifi = [ "" "" "" ];
            ethernet = [ "" ];
            disconnected = [ "" ];
          };
          on-click = "termite -e nmtui";
          tooltip = false;
        };

        "pulseaudio" = {
          format = "{icon}";
          format-alt = "{volume} {icon}";
          format-alt-click = "click-right";
          format-muted = "";
          format-icons = {
            phone = [ " " " " " " " " ];
            default = [ "" "" "" "" ];
          };
          scroll-step = 10;
          on-click = "pavucontrol";
          tooltip = false;
        };

        "custom/spotify" = {
          interval = 1;
          return-type = "json";
          exec = "~/.config/waybar/modules/spotify.sh";
          exec-if = "pgrep spotify";
          escape = true;
        };

        "custom/storage" = {
          format = "{} ";
          format-alt = "{percentage}% ";
          format-alt-click = "click-right";
          return-type = "json";
          interval = 60;
          exec = "~/.config/waybar/modules/storage.sh";
        };

        "backlight" = {
          format = "{icon}";
          format-alt = "{percent}% {icon}";
          format-alt-click = "click-right";
          format-icons = [ "" "" ];
          on-scroll-down = "light -A 1";
          on-scroll-up = "light -U 1";
        };

        "custom/weather" = {
          format = "{}";
          format-alt = "{alt}: {}";
          format-alt-click = "click-right";
          interval = 1800;
          return-type = "json";
          exec = "~/.config/waybar/modules/weather.sh";
          exec-if = "ping wttr.in -c1";
        };

        "idle_inhibitor" = {
          format = "{icon}";
          format-icons = { activated = ""; deactivated = ""; };
          tooltip = false;
        };

        "tray" = {
          icon-size = 18;
        };
      }
    ];

    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: JetBrainsMono Nerd Font Mono;
        font-size: 14px;
        box-shadow: none;
        text-shadow: none;
        transition-duration: 0s;
        min-height: 0px;
      }

      window#waybar {
        background: #${config.lib.stylix.colors.base00};
        color: #${config.lib.stylix.colors.base05};
      }

      window#waybar.solo {
        background: #${config.lib.stylix.colors.base00};
        color: #${config.lib.stylix.colors.base05};
      }

      #workspaces {
        margin: 0 5px;
      }

      #workspaces button {
        padding: 0 5px;
        background: transparent;
        color: #${config.lib.stylix.colors.base04};
      }

      #workspaces button.visible,
      #workspaces button.focused {
        color: #${config.lib.stylix.colors.base08};
      }

      #workspaces button.focused {
        border-top: 3px solid #${config.lib.stylix.colors.base08};
        border-bottom: 3px solid transparent;
      }

      #workspaces button.urgent {
        color: #${config.lib.stylix.colors.base09};
      }

      #mode, #battery, #cpu, #memory, #network, #pulseaudio, #idle_inhibitor,
      #backlight, #custom-storage, #custom-spotify, #custom-weather, #custom-mail {
        margin: 0px 6px 0px 10px;
        min-width: 25px;
      }

      #clock {
        margin: 0px 16px 0px 10px;
        min-width: 140px;
        font-weight: bold;
        background: #${config.lib.stylix.colors.base0E};
        color: #${config.lib.stylix.colors.base00};
      }

      #battery.warning {
        color: #${config.lib.stylix.colors.base0A};
      }

      #battery.critical {
        color: #${config.lib.stylix.colors.base08};
      }

      #battery.charging {
        color: #${config.lib.stylix.colors.base05};
      }

      #custom-storage.warning {
        color: #${config.lib.stylix.colors.base0A};
      }

      #custom-storage.critical {
        color: #${config.lib.stylix.colors.base08};
      }

      #tray {
        background: #${config.lib.stylix.colors.base02};
        color: #${config.lib.stylix.colors.base00};
        padding: 0px 10px;
      }
    '';
  };
}
