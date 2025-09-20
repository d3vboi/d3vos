{ pkgs, ... }:
pkgs.writeShellScriptBin "remind" ''
  #!/usr/bin/env bash

  # Colors
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  WHITE='\033[1;37m'
  GRAY='\033[0;37m'
  BOLD='\033[1m'
  NC='\033[0m'

  REMIND_DIR="$HOME/.local/share/reminders"
  REMIND_FILE="$REMIND_DIR/reminders.txt"
  mkdir -p "$REMIND_DIR"
  touch "$REMIND_FILE"

  show_usage() {
    echo -e "''${BOLD}''${BLUE}⏰ Reminder Manager''${NC}"
    echo -e "''${GRAY}Usage:''${NC}"
    echo -e "  ''${CYAN}remind''${NC} ''${YELLOW}<time>''${NC} ''${WHITE}<message>''${NC} [-u urgency]"
    echo -e "  ''${CYAN}remind list''${NC}              - Show active reminders"
    echo -e "  ''${CYAN}remind cancel <id>''${NC}       - Cancel reminder by ID"
    echo -e "  ''${CYAN}remind help''${NC}              - Show this help"
    echo ""
    echo -e "''${GRAY}Examples:''${NC}"
    echo -e "  ''${GREEN}remind 10m 'Take a break''${NC}"
    echo -e "  ''${GREEN}remind -u critical 23:00 'Shutdown!''${NC}"
    echo -e "  ''${GREEN}remind 2h 'Nap' -u low''${NC}"
  }

  parse_time() {
    local input="$1" seconds=0
    if [[ "$input" =~ ^[0-9]+$ ]]; then
      if (( ''${#input} == 4 )); then
        target=$(date -d "''${input:0:2}:''${input:2:2}" +%s)
        now=$(date +%s)
        (( seconds = target - now ))
        [[ $seconds -lt 0 ]] && (( seconds += 86400 ))
      else
        seconds="$input"
      fi
    elif [[ "$input" =~ ^([0-9]+)([smhd])$ ]]; then
      num="''${BASH_REMATCH[1]}"
      unit="''${BASH_REMATCH[2]}"
      case $unit in
        s) seconds=$((num)) ;;
        m) seconds=$((num*60)) ;;
        h) seconds=$((num*3600)) ;;
        d) seconds=$((num*86400)) ;;
      esac
    else
      target=$(date -d "$input" +%s 2>/dev/null)
      [[ -z "$target" ]] && return 1
      now=$(date +%s)
      (( seconds = target - now ))
      [[ $seconds -lt 0 ]] && (( seconds += 86400 ))
    fi
    echo "$seconds"
  }

  add_reminder() {
    local time_input="$1" ; shift
    local urgency="normal" message=""

    # Parse args for urgency no matter position
    local args=("$@")
    local cleaned=()
    for ((i=0; i<''${#args[@]}; i++)); do
      if [[ "''${args[i]}" == "-u" || "''${args[i]}" == "--urgency" ]]; then
        urgency="''${args[i+1]}"
        ((i++))
      else
        cleaned+=("''${args[i]}")
      fi
    done
    message="''${cleaned[*]}"

    local seconds
    seconds=$(parse_time "$time_input") || { echo -e "''${RED}✗ Invalid time format''${NC}"; exit 1; }

    local id=$(( $(date +%s%N) % 100000 ))
    local when=$(date -d "+$seconds seconds" '+%Y-%m-%d %H:%M:%S')

    echo "$id|$when|$urgency|$message" >> "$REMIND_FILE"

    echo -e "''${GREEN}✓''${NC} Reminder #$id set for ''${YELLOW}$when''${NC} (''${CYAN}$urgency''${NC})"

    (
      sleep "$seconds"
      notify-send -u "$urgency" "Reminder" "$message"
      grep -v "^$id|" "$REMIND_FILE" > "$REMIND_FILE.tmp" && mv "$REMIND_FILE.tmp" "$REMIND_FILE"
    ) >/dev/null 2>&1 &
    disown
  }

  list_reminders() {
    if ! [ -s "$REMIND_FILE" ]; then
      echo -e "''${YELLOW}⏰ No active reminders''${NC}"
      return
    fi
    echo -e "''${BOLD}''${BLUE}Active Reminders''${NC}"
    echo -e "''${GRAY}$(printf '%.0s─' {1..50})''${NC}"
    while IFS='|' read -r id when urgency message; do
      color=$WHITE
      [[ "$urgency" == "low" ]] && color=$GREEN
      [[ "$urgency" == "normal" ]] && color=$YELLOW
      [[ "$urgency" == "critical" ]] && color=$RED
      echo -e "''${CYAN}#$id''${NC} [''${YELLOW}$when''${NC}] ''${color}($urgency)''${NC} → $message"
    done < "$REMIND_FILE"
  }

  cancel_reminder() {
    local id="$1"
    if grep -q "^$id|" "$REMIND_FILE"; then
      grep -v "^$id|" "$REMIND_FILE" > "$REMIND_FILE.tmp" && mv "$REMIND_FILE.tmp" "$REMIND_FILE"
      echo -e "''${GREEN}✓''${NC} Reminder #$id cancelled"
    else
      echo -e "''${RED}✗''${NC} Reminder #$id not found"
    fi
  }

  main() {
    case "$1" in
      ""|"help"|"-h"|"--help") show_usage ;;
      "list") list_reminders ;;
      "cancel") shift; cancel_reminder "$1" ;;
      *) add_reminder "$@" ;;
    esac
  }

  main "$@"
''
