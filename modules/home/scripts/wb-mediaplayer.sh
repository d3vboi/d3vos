# --- Configuration and Global Variables ---

LOG_FILE=""
VERBOSE_LEVEL=0 # 0=DEBUG, 1=INFO, 2=WARN, 3=ERROR, 4=CRITICAL
SELECTED_PLAYER=""
EXCLUDED_PLAYERS_RAW=""
declare -a EXCLUDED_PLAYERS_ARRAY # Array to hold excluded player names
LAST_OUTPUT="" # Stores the last JSON output to prevent redundant prints
POLLING_INTERVAL=1 # How often to poll for player status, in seconds

# --- Logging Functions ---
# Maps verbose levels to human-readable names.
# Python's default was WARNING (30), -v for INFO (20), -vv for DEBUG (10/0).
log_level_map=(DEBUG INFO WARN ERROR CRITICAL)

# Generic log function
log() {
    local level_num=$1
    local msg=$2
    # Only log if the message's level is higher or equal to the current VERBOSE_LEVEL
    if (( level_num >= VERBOSE_LEVEL )); then
        local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        local level_name="${log_level_map[$level_num]}"
        local log_msg="${timestamp} ${level_name}: ${msg}"
        if [[ -n "$LOG_FILE" ]]; then
            echo "$log_msg" >> "$LOG_FILE"
        else
            echo "$log_msg" >&2
        fi
    fi
}

# Specific logging levels for convenience
log_debug() { log 0 "$@"; }
log_info() { log 1 "$@"; }
log_warn() { log 2 "$@"; }
log_error() { log 3 "$@"; }

# --- Signal Handling ---
cleanup() {
    log_info "Received signal to stop, exiting"
    # Ensure a newline is printed to clean up terminal prompt
    echo ""
    exit 0
}
trap cleanup SIGINT SIGTERM

# --- Output Management ---

# Clears the output by printing an empty line, effectively hiding previous output
clear_output() {
    echo ""
    LAST_OUTPUT="" # Reset last output to ensure next actual output is printed
    log_debug "Output cleared."
}

# Writes the formatted JSON output to stdout.
# Only prints if the output has changed since the last call.
write_output() {
    local text="$1"
    local player_name="$2"

    # Construct JSON output using jq for robustness
    local output_json=$(jq -n \
                        --arg text "$text" \
                        --arg class "custom-$player_name" \
                        --arg alt "$player_name" \
                        '{text: $text, class: $class, alt: $alt}')

    if [[ "$output_json" != "$LAST_OUTPUT" ]]; then
        echo "$output_json"
        LAST_OUTPUT="$output_json"
        log_debug "Output written: $output_json"
    else
        log_debug "Output unchanged, skipping print."
    fi
}

# --- Playerctl Interaction Functions ---

# Fetches metadata for a specific player using playerctl --format to get JSON.
# Returns empty string on error or if player doesn't exist.
get_player_metadata() {
    local p_name=$1
    # Use --format to get specific fields as JSON
    playerctl --player="$p_name" metadata --format '{"artist": "{{artist}}", "title": "{{title}}", "status": "{{status}}", "player_name": "{{playerName}}", "trackid": "{{mpris:trackid}}"}' 2>/dev/null
}

# Fetches the playback status for a specific player.
# Returns empty string on error or if player doesn't exist.
get_player_status() {
    local p_name=$1
    playerctl --player="$p_name" status 2>/dev/null
}

# Extracts artist from JSON metadata. Handles '&' escaping.
get_artist() {
    local metadata_json="$1"
    jq -r '.artist | select(. != null)' <<< "$metadata_json" | sed 's/&/\&amp;/g'
}

# Extracts title from JSON metadata. Handles '&' escaping.
get_title() {
    local metadata_json="$1"
    jq -r '.title | select(. != null)' <<< "$metadata_json" | sed 's/&/\&amp;/g'
}

# Extracts mpris:trackid from JSON metadata.
get_trackid() {
    local metadata_json="$1"
    jq -r '.trackid | select(. != null)' <<< "$metadata_json"
}

# Determines the track information string based on metadata and status.
determine_track_info() {
    local player_name="$1"
    local metadata_json="$2"
    local status="$3"

    local artist=$(get_artist "$metadata_json")
    local title=$(get_title "$metadata_json")
    local trackid=$(get_trackid "$metadata_json")

    local track_info=""

    # Special handling for Spotify advertisements
    if [[ "$player_name" == "spotify" && "$trackid" == *":ad:"* ]]; then
        track_info="Advertisement"
    elif [[ -n "$artist" && -n "$title" ]]; then
        track_info="${artist} - ${title}"
    elif [[ -n "$title" ]]; then
        track_info="${title}"
    fi

    # Prepend play/pause icon if track info is available
    if [[ -n "$track_info" ]]; then
        if [[ "$status" == "Playing" ]]; then
            track_info=" ${track_info}" # Play icon
        else
            track_info=" ${track_info}" # Pause icon
        fi
    fi
    echo "$track_info"
}

# --- Main Player Management Logic ---

# Finds the most important player (playing > paused > first available)
# and displays its information. Clears output if no player is found.
show_most_important_player() {
    log_debug "Evaluating players for display."

    local all_player_names=$(playerctl -l 2>/dev/null | tr '\n' ' ')
    declare -a filtered_players=()

    # Filter players based on --player and --exclude arguments
    for p_name in $all_player_names; do
        local skip=0
        # Check exclusion list
        for excluded in "${EXCLUDED_PLAYERS_ARRAY[@]}"; do
            if [[ "$p_name" == "$excluded" ]]; then
                skip=1
                log_debug "Player '$p_name' is in excluded list, skipping."
                break
            fi
        done
        if [[ "$skip" -eq 1 ]]; then
            continue
        fi

        # Check selected player filter
        if [[ -n "$SELECTED_PLAYER" && "$p_name" != "$SELECTED_PLAYER" ]]; then
            log_debug "Player '$p_name' is not the selected player ('$SELECTED_PLAYER'), skipping."
            continue
        fi
        filtered_players+=("$p_name")
    done

    log_debug "Filtered players: ${filtered_players[*]}"

    local current_playing_player=""
    local first_available_player=""

    # Iterate through filtered players (reverse order for priority, though -l is usually stable)
    # to find a playing player, or just the first one if none are playing.
    for (( i=${#filtered_players[@]}-1; i>=0; i-- )); do
        local p_name=${filtered_players[$i]}
        local p_status=$(get_player_status "$p_name")

        if [[ -z "$first_available_player" ]]; then
            first_available_player="$p_name" # Keep the first one found as a fallback
        fi

        if [[ "$p_status" == "Playing" ]]; then
            current_playing_player="$p_name"
            log_debug "Found playing player: $current_playing_player"
            break # Found a playing player, this is our priority
        fi
    done

    local player_to_display=""
    if [[ -n "$current_playing_player" ]]; then
        player_to_display="$current_playing_player"
    elif [[ -n "$first_available_player" ]]; then
        player_to_display="$first_available_player"
        log_debug "No playing player, falling back to first available: $player_to_display"
    fi

    if [[ -n "$player_to_display" ]]; then
        local p_name="$player_to_display"
        local p_status=$(get_player_status "$p_name") # Re-fetch status just in case
        local p_metadata=$(get_player_metadata "$p_name") # Re-fetch metadata

        # Check if another player started playing *just before* this one was processed
        # This mirrors the Python script's logic "only print output if no other player is playing"
        local latest_playing_player=""
        for (( i=${#filtered_players[@]}-1; i>=0; i-- )); do
            local check_p_name=${filtered_players[$i]}
            local check_p_status=$(get_player_status "$check_p_name")
            if [[ "$check_p_status" == "Playing" ]]; then
                latest_playing_player="$check_p_name"
                break
            fi
        done
        
        if [[ -z "$latest_playing_player" || "$latest_playing_player" == "$p_name" ]]; then
            local track_info=$(determine_track_info "$p_name" "$p_metadata" "$p_status")
            log_debug "Displaying info for player '$p_name': Status='$p_status', Metadata='${p_metadata}'"
            write_output "$track_info" "$p_name"
        else
            log_debug "Another player '$latest_playing_player' is now playing, skipping output for '$p_name'."
        fi
    else
        log_debug "No suitable player found to display output."
        clear_output
    fi
}

# --- Argument Parsing ---

parse_args() {
    while (( "$#" )); do
        case "$1" in
            -v|--verbose)
                (( VERBOSE_LEVEL++ ))
                shift
                ;;
            -x|--exclude)
                EXCLUDED_PLAYERS_RAW="$2"
                shift 2
                ;;
            --player)
                SELECTED_PLAYER="$2"
                shift 2
                ;;
            --enable-logging)
                # Resolve script path to make logfile path absolute
                local script_dir="$(dirname "$(readlink -f "$0")")"
                LOG_FILE="${script_dir}/media-player.log"
                shift
                ;;
            *)
                echo "Unknown argument: $1" >&2
                exit 1
                ;;
        esac
    done

    # Map the Bash VERBOSE_LEVEL (0=DEBUG, 1=INFO, 2=WARN) to match Python's logic
    # Python: default WARN, -v INFO, -vv DEBUG
    case "$VERBOSE_LEVEL" in
        0) VERBOSE_LEVEL=2 ;; # Default: WARN
        1) VERBOSE_LEVEL=1 ;; # -v: INFO
        *) VERBOSE_LEVEL=0 ;; # -vv or more: DEBUG
    esac

    if [[ -n "$EXCLUDED_PLAYERS_RAW" ]]; then
        IFS=',' read -r -a EXCLUDED_PLAYERS_ARRAY <<< "$EXCLUDED_PLAYERS_RAW"
        log_info "Excluded players set: ${EXCLUDED_PLAYERS_ARRAY[*]}"
    fi
    if [[ -n "$SELECTED_PLAYER" ]]; then
        log_info "Monitoring only player: $SELECTED_PLAYER"
    fi
    if [[ -n "$LOG_FILE" ]]; then
        log_info "Logging output to: $LOG_FILE"
    fi
}

# --- Main Execution Loop ---

main() {
    parse_args "$@"

    log_info "Starting media player monitor."

    # Initial check and display
    show_most_important_player

    # Enter the continuous polling loop
    log_info "Entering continuous polling loop (interval: ${POLLING_INTERVAL}s)."
    while true; do
        show_most_important_player
        sleep "$POLLING_INTERVAL"
    done
}

# Execute main function with all command-line arguments
main "$@"
