#!/bin/bash

# Script to run WordPress cron tasks via WP-CLI
# This script can be used in a cron job to ensure WordPress scheduled tasks are executed

# Function to display help
show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -p, --path      Path to WordPress installation (default: current directory)"
    echo "  -c, --cli       WP-CLI command to use (default: 'wp')"
    echo "  -u, --url       WordPress URL (optional, for multisite installations)"
    echo "  -q, --quiet     Suppress output except for errors"
    echo "  -s, --sentry    Send execution data to Sentry"
    echo "  -m, --monitor   Sentry monitor slug (required if using Sentry)"
    echo "  -k, --key       Sentry public key (required if using Sentry)"
    echo "  -e, --env       Sentry environment (default: 'production')"
    echo "  -i, --instance  Sentry instance URL (default: 'https://o0.ingest.sentry.io')"
    echo "  -o, --org-id    Sentry organization/project ID (default: '0')"
    echo "  -t, --timeout   Maximum execution time in seconds (default: 300)"
    echo "  -h, --help      Display this help"
    exit 0
}

# Function to log messages
log() {
    local level="$1"
    local message="$2"
    
    if [ "$QUIET_MODE" != "true" ] || [ "$level" = "ERROR" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
    fi
}

# Function to send check-in to Sentry
send_to_sentry() {
    local status="$1"
    local check_in_id="$2"
    
    if [ "$USE_SENTRY" = "true" ]; then
        if [ -z "$SENTRY_MONITOR" ] || [ -z "$SENTRY_KEY" ]; then
            log "ERROR" "Sentry monitor slug and public key are required for Sentry integration."
            return 1
        fi
        
        # Build Sentry URL
        local sentry_url="${SENTRY_INSTANCE}/api/${SENTRY_ORG_ID}/cron/${SENTRY_MONITOR}/${SENTRY_KEY}/"
        
        # Add parameters
        local params="?status=${status}"
        
        # Add environment if specified
        if [ -n "$SENTRY_ENV" ]; then
            params="${params}&environment=${SENTRY_ENV}"
        fi
        
        # Add check-in ID if provided
        if [ -n "$check_in_id" ]; then
            params="${params}&check_in_id=${check_in_id}"
        fi
        
        log "INFO" "Sending check-in to Sentry with status: ${status}"
        log "INFO" "Sentry URL: ${sentry_url}${params}"
        
        # Send the check-in to Sentry
        if curl -s -o /dev/null -w "%{http_code}" "${sentry_url}${params}" | grep -q "20[0-9]"; then
            log "INFO" "Check-in sent to Sentry successfully."
            return 0
        else
            log "ERROR" "Failed to send check-in to Sentry."
            return 1
        fi
    fi
    
    return 0
}

# Default values
WP_PATH="."
WP_CLI="wp"
WP_URL=""
QUIET_MODE="false"
USE_SENTRY="false"
SENTRY_MONITOR=""
SENTRY_KEY=""
SENTRY_ENV="production"
SENTRY_INSTANCE="https://o0.ingest.sentry.io"
SENTRY_ORG_ID="0"
TIMEOUT=300

# Process arguments
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
        -s|--sentry)
            USE_SENTRY="true"
            shift
            ;;
        -m|--monitor)
            SENTRY_MONITOR="$2"
            shift 2
            ;;
        --monitor=*)
            SENTRY_MONITOR="${1#*=}"
            shift
            ;;
        -k|--key)
            SENTRY_KEY="$2"
            shift 2
            ;;
        --key=*)
            SENTRY_KEY="${1#*=}"
            shift
            ;;
        -e|--env)
            SENTRY_ENV="$2"
            shift 2
            ;;
        --env=*)
            SENTRY_ENV="${1#*=}"
            shift
            ;;
        -i|--instance)
            SENTRY_INSTANCE="$2"
            shift 2
            ;;
        --instance=*)
            SENTRY_INSTANCE="${1#*=}"
            shift
            ;;
        -o|--org-id)
            SENTRY_ORG_ID="$2"
            shift 2
            ;;
        --org-id=*)
            SENTRY_ORG_ID="${1#*=}"
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

# Validate WordPress path
if [ ! -d "$WP_PATH" ]; then
    log "ERROR" "WordPress path '$WP_PATH' does not exist or is not a directory."
    exit 1
fi

# Check if WP-CLI is available
if ! command -v $WP_CLI &> /dev/null && [[ ! "$WP_CLI" == *" "* ]]; then
    log "ERROR" "WP-CLI command '$WP_CLI' not found. Please install WP-CLI or provide the correct command."
    exit 1
fi

# Check Sentry parameters if Sentry is enabled
if [ "$USE_SENTRY" = "true" ]; then
    if [ -z "$SENTRY_MONITOR" ] || [ -z "$SENTRY_KEY" ]; then
        log "ERROR" "Sentry monitor slug and public key are required when using Sentry integration."
        exit 1
    fi
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        log "ERROR" "curl command not found. It is required for Sentry integration."
        exit 1
    fi
    
    # Remove trailing slash from Sentry instance URL if present
    SENTRY_INSTANCE="${SENTRY_INSTANCE%/}"
    
    log "INFO" "Using Sentry instance: $SENTRY_INSTANCE"
    log "INFO" "Using Sentry organization/project ID: $SENTRY_ORG_ID"
fi

# Build the WP-CLI command
WP_COMMAND="$WP_CLI --path=$WP_PATH"

# Add URL if provided
if [ -n "$WP_URL" ]; then
    WP_COMMAND="$WP_COMMAND --url=$WP_URL"
fi

log "INFO" "Starting WordPress cron execution..."
log "INFO" "Using WP-CLI command: $WP_COMMAND"
log "INFO" "WordPress path: $WP_PATH"

# Multisite handling
run_cron_for_site() {
    local site_url="$1"
    local start_time end_time duration exit_code
    
    log "INFO" "Running cron for site: $site_url"
    if [ -n "$site_url" ]; then
        local CMD="$WP_CLI --path=$WP_PATH --url=$site_url cron event run --due-now"
    else
        local CMD="$WP_CLI --path=$WP_PATH cron event run --due-now"
    fi
    start_time=$(date +%s)
    if timeout $TIMEOUT $CMD; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        log "INFO" "WordPress cron executed successfully for $site_url in $duration seconds."
        return 0
    else
        exit_code=$?
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        if [ $exit_code -eq 124 ]; then
            log "ERROR" "WordPress cron execution timed out for $site_url after $TIMEOUT seconds."
        else
            log "ERROR" "WordPress cron execution failed for $site_url with exit code $exit_code after $duration seconds."
        fi
        return $exit_code
    fi
}

# Generate a check-in ID for Sentry
check_in_id=""
if [ "$USE_SENTRY" = "true" ]; then
    check_in_id=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "manual-$(date +%s)")
    log "INFO" "Generated check-in ID for Sentry: $check_in_id"
    # Send in_progress status to Sentry
    send_to_sentry "in_progress" "$check_in_id"
fi

# Main execution logic
if [ -n "$WP_URL" ]; then
    # Single site or specific site in multisite
    if run_cron_for_site "$WP_URL"; then
        [ "$USE_SENTRY" = "true" ] && send_to_sentry "ok" "$check_in_id"
        exit 0
    else
        [ "$USE_SENTRY" = "true" ] && send_to_sentry "error" "$check_in_id"
        exit 1
    fi
else
    # Detect if multisite
    IS_MULTISITE=$($WP_CLI --path=$WP_PATH eval 'echo is_multisite() ? "yes" : "no";' 2>/dev/null)
    if [ "$IS_MULTISITE" = "yes" ]; then
        log "INFO" "Multisite detected. Running cron for all sites."
        SITE_URLS=$($WP_CLI --path=$WP_PATH site list --field=url 2>/dev/null)
        EXIT_CODE=0
        for site_url in $SITE_URLS; do
            if ! run_cron_for_site "$site_url"; then
                EXIT_CODE=1
            fi
        done
        if [ $EXIT_CODE -eq 0 ]; then
            [ "$USE_SENTRY" = "true" ] && send_to_sentry "ok" "$check_in_id"
            exit 0
        else
            [ "$USE_SENTRY" = "true" ] && send_to_sentry "error" "$check_in_id"
            exit 1
        fi
    else
        # Single site
        if run_cron_for_site ""; then
            [ "$USE_SENTRY" = "true" ] && send_to_sentry "ok" "$check_in_id"
            exit 0
        else
            [ "$USE_SENTRY" = "true" ] && send_to_sentry "error" "$check_in_id"
            exit 1
        fi
    fi
fi 