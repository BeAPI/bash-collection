#!/bin/bash

# Script to clear WP-Rocket cache via WP-CLI

show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -p, --path      Path to WordPress installation (default: current directory)"
    echo "  -c, --cli       WP-CLI command to use (default: 'wp')"
    echo "  -u, --url       WordPress URL (optional, for multisite installations)"
    echo "  -q, --quiet     Suppress output except for errors"
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

WP_COMMAND="$WP_CLI --path=$WP_PATH"
if [ -n "$WP_URL" ]; then
    WP_COMMAND="$WP_COMMAND --url=$WP_URL"
fi

log "INFO" "Starting WP-Rocket cache clearing..."
log "INFO" "Using WP-CLI command: $WP_COMMAND"
log "INFO" "WordPress path: $WP_PATH"

check_wp_rocket_active() {
    local site_url="$1"
    local exit_code
    
    if [ -n "$site_url" ]; then
        $WP_CLI --path=$WP_PATH --url=$site_url plugin is-active wp-rocket >/dev/null 2>&1
        exit_code=$?
    else
        $WP_CLI --path=$WP_PATH plugin is-active wp-rocket >/dev/null 2>&1
        exit_code=$?
    fi
    
    return $exit_code
}

clear_cache_for_site() {
    local site_url="$1"
    local start_time end_time duration exit_code
    
    # Check if WP-Rocket is active
    if ! check_wp_rocket_active "$site_url"; then
        log "WARNING" "WP-Rocket is not active for site: $site_url"
        return 0
    fi
    
    log "INFO" "Clearing cache for site: $site_url"
    
    if [ -n "$site_url" ]; then
        local CMD="$WP_CLI --path=$WP_PATH --url=$site_url rocket clean --confirm --no-color"
    else
        local CMD="$WP_CLI --path=$WP_PATH rocket clean --confirm --no-color"
    fi
    
    start_time=$(date +%s)
    # Capture output and exit code
    local m
    m=$($CMD 2>&1)
    exit_code=$?
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    # Save log to file if LOGFILE is set
    if [ -n "$LOGFILE" ]; then
        echo "$m" >> "$LOGFILE"
    fi
    
    if [ $exit_code -eq 0 ]; then
        log "INFO" "WP-Rocket cache cleared successfully for $site_url in $duration seconds."
        log "INFO" "Cache purge completed successfully - Plugin is active and command executed successfully"
        return 0
    else
        log "ERROR" "WP-Rocket cache clearing failed for $site_url with exit code $exit_code after $duration seconds."
        return $exit_code
    fi
}

if [ -n "$WP_URL" ]; then
    # Single site or specific site in multisite
    if clear_cache_for_site "$WP_URL"; then
        exit 0
    else
        exit 1
    fi
else
    # Detect if multisite
    IS_MULTISITE=$($WP_CLI --path=$WP_PATH eval 'echo is_multisite() ? "yes" : "no";' 2>/dev/null)
    if [ "$IS_MULTISITE" = "yes" ]; then
        log "INFO" "Multisite detected. Clearing cache for all sites."
        SITE_URLS=$($WP_CLI --path=$WP_PATH site list --field=url 2>/dev/null)
        EXIT_CODE=0
        
        for site_url in $SITE_URLS; do
            # Skip if WP-Rocket is not active
            if ! check_wp_rocket_active "$site_url"; then
                log "WARNING" "Skipping site $site_url - WP-Rocket is not active"
                continue
            fi
            
            # Capture output and exit code for each site
            site_log=$($WP_CLI --path=$WP_PATH --url=$site_url rocket clean --confirm --no-color 2>&1)
            site_exit_code=$?
            if [ $site_exit_code -ne 0 ]; then
                EXIT_CODE=1
            else
                log "INFO" "Cache purge completed successfully for $site_url - Plugin is active and command executed successfully"
            fi
            if [ -n "$LOGFILE" ]; then
                echo "--- Site: $site_url ---" >> "$LOGFILE"
                echo "$site_log" >> "$LOGFILE"
            fi
        done
        
        if [ $EXIT_CODE -eq 0 ]; then
            exit 0
        else
            exit 1
        fi
    else
        # Single site
        if clear_cache_for_site ""; then
            exit 0
        else
            exit 1
        fi
    fi
fi 