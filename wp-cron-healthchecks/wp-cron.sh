#!/bin/bash

# Script to run WordPress cron tasks via WP-CLI
# Compatible with healthchecks.io for monitoring

show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -p, --path      Path to WordPress installation (default: current directory)"
    echo "  -c, --cli       WP-CLI command to use (default: 'wp')"
    echo "  -u, --url       WordPress URL (optional, for multisite installations)"
    echo "  -q, --quiet     Suppress output except for errors"
    echo "  -H, --hc-url    Healthchecks.io ping URL (required)"
    echo "  -t, --timeout   Maximum execution time in seconds (default: 300)"
    echo "  -h, --help      Display this help"
    exit 0
}

log() {
    local level="$1"
    local message="$2"
    if [ "$QUIET_MODE" != "true" ] || [ "$level" = "ERROR" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
    fi
}

# Defaults
WP_PATH="."
WP_CLI="wp"
WP_URL=""
QUIET_MODE="false"
HC_URL=""
TIMEOUT=300

# Parse args
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -p|--path)
            WP_PATH="$2"
            shift 2
            ;;
        -c|--cli)
            WP_CLI="$2"
            shift 2
            ;;
        --cli=*)
            WP_CLI="${1#*=}"
            shift
            ;;
        -u|--url)
            WP_URL="$2"
            shift 2
            ;;
        --url=*)
            WP_URL="${1#*=}"
            shift
            ;;
        -q|--quiet)
            QUIET_MODE="true"
            shift
            ;;
        -H|--hc-url)
            HC_URL="$2"
            shift 2
            ;;
        --hc-url=*)
            HC_URL="${1#*=}"
            shift
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --timeout=*)
            TIMEOUT="${1#*=}"
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

if [ ! -d "$WP_PATH" ]; then
    log "ERROR" "WordPress path '$WP_PATH' does not exist or is not a directory."
    exit 1
fi

if ! command -v $WP_CLI &> /dev/null && [[ ! "$WP_CLI" == *" "* ]]; then
    log "ERROR" "WP-CLI command '$WP_CLI' not found. Please install WP-CLI or provide the correct command."
    exit 1
fi

if [ -z "$HC_URL" ]; then
    log "ERROR" "Healthchecks.io ping URL is required. Use -H or --hc-url."
    exit 1
fi

WP_COMMAND="$WP_CLI --path=$WP_PATH"
if [ -n "$WP_URL" ]; then
    WP_COMMAND="$WP_COMMAND --url=$WP_URL"
fi

log "INFO" "Starting WordPress cron execution..."
log "INFO" "Using WP-CLI command: $WP_COMMAND"
log "INFO" "WordPress path: $WP_PATH"

run_cron_for_site() {
    local site_url="$1"
    local start_time end_time duration exit_code
    log "INFO" "Running cron for site: $site_url"
    if [ -n "$site_url" ]; then
        local CMD="$WP_CLI --path=$WP_PATH --url=$site_url cron event run --due-now --no-color"
    else
        local CMD="$WP_CLI --path=$WP_PATH cron event run --due-now --no-color"
    fi
    start_time=$(date +%s)
    # Capture output and exit code
    local m
    m=$($CMD 2>&1)
    exit_code=$?
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    # Limit message to 10kb (healthchecks.io limit)
    local m_10k
    m_10k=$(echo "$m" | tail --bytes=10000)
    # Send log to healthchecks.io with exit code
    if [ -n "$HC_URL" ]; then
        local hc_url="${HC_URL}/${exit_code}"
        log "INFO" "Sending log to Healthchecks.io: $hc_url"
        curl -fsS -m 10 --retry 5 --data "$m_10k" -o /dev/null "$hc_url" || log "ERROR" "Failed to send log to $hc_url"
    fi
    # Save full log to file if LOGFILE is set
    if [ -n "$LOGFILE" ]; then
        echo "$m" >> "$LOGFILE"
    fi
    if [ $exit_code -eq 0 ]; then
        log "INFO" "WordPress cron executed successfully for $site_url in $duration seconds."
        return 0
    else
        if [ $exit_code -eq 124 ]; then
            log "ERROR" "WordPress cron execution timed out for $site_url after $TIMEOUT seconds."
        else
            log "ERROR" "WordPress cron execution failed for $site_url with exit code $exit_code after $duration seconds."
        fi
        return $exit_code
    fi
}

# Function to send check-in to Healthchecks.io
send_hc_ping() {
    local suffix="$1"
    local log_data="$2"
    if [ -n "$HC_URL" ]; then
        local url="$HC_URL$suffix"
        log "INFO" "Pinging Healthchecks.io: $url"
        if [ -n "$log_data" ]; then
            curl -fsS -m 10 --retry 5 --data "$log_data" -o /dev/null "$url" || log "ERROR" "Failed to send log to $url"
        else
            curl -fsS --retry 3 "$url" >/dev/null 2>&1 || log "ERROR" "Failed to ping $url"
        fi
    fi
}

# Main execution logic
send_hc_ping "/start"

if [ -n "$WP_URL" ]; then
    # Single site or specific site in multisite
    if run_cron_for_site "$WP_URL"; then
        send_hc_ping ""
        exit 0
    else
        send_hc_ping "/fail"
        exit 1
    fi
else
    # Detect if multisite
    IS_MULTISITE=$($WP_CLI --path=$WP_PATH eval 'echo is_multisite() ? "yes" : "no";' 2>/dev/null)
    if [ "$IS_MULTISITE" = "yes" ]; then
        log "INFO" "Multisite detected. Running cron for all sites."
        SITE_URLS=$($WP_CLI --path=$WP_PATH site list --field=url 2>/dev/null)
        EXIT_CODE=0
        COMBINED_LOG=""
        # Declare variables outside the loop
        site_log=""
        site_exit_code=0
        for site_url in $SITE_URLS; do
            # Capture output and exit code for each site
            site_log=$($WP_CLI --path=$WP_PATH --url=$site_url cron event run --due-now --no-color 2>&1)
            site_exit_code=$?
            if [ $site_exit_code -ne 0 ]; then
                EXIT_CODE=1
            fi
            COMBINED_LOG="${COMBINED_LOG}--- Site: $site_url ---\n$site_log\n"
        done
        # Limit combined log to 10kb
        COMBINED_LOG_10K=$(echo -e "$COMBINED_LOG" | tail --bytes=10000)
        # Send single ping with combined log
        if [ -n "$HC_URL" ]; then
            hc_url="${HC_URL}/${EXIT_CODE}"
            log "INFO" "Sending combined log to Healthchecks.io: $hc_url"
            send_hc_ping "/${EXIT_CODE}" "$COMBINED_LOG_10K"
        fi
        # Save full combined log if LOGFILE is set
        if [ -n "$LOGFILE" ]; then
            echo -e "$COMBINED_LOG" >> "$LOGFILE"
        fi
        if [ $EXIT_CODE -eq 0 ]; then
            exit 0
        else
            exit 1
        fi
    else
        # Single site
        if run_cron_for_site ""; then
            send_hc_ping ""
            exit 0
        else
            send_hc_ping "/fail"
            exit 1
        fi
    fi
fi 