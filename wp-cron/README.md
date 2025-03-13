# WordPress Cron Execution Script

This script allows you to execute WordPress cron tasks via WP-CLI. It's designed to be used in a cron job to ensure WordPress scheduled tasks are executed reliably, which is especially useful for WordPress multisite installations.

## Features

- Execute WordPress cron tasks via WP-CLI
- Specify custom WP-CLI command (useful for installations where WP-CLI is not in PATH)
- Support for WordPress multisite installations via URL parameter
- Timeout control to prevent hanging processes
- Quiet mode to suppress non-error output
- Sentry integration for monitoring and error tracking via HTTP API
- Support for self-hosted Sentry instances
- Detailed logging with timestamps

## Requirements

- Bash shell
- WordPress installation
- WP-CLI (installed or accessible via a custom command)
- `timeout` command (usually pre-installed on most Linux distributions)
- `curl` command (required for Sentry integration)

## Installation

1. Copy the `wp-cron.sh` script to your server
2. Make it executable:
   ```bash
   chmod +x wp-cron.sh
   ```

## Usage

Basic usage:

```bash
./wp-cron.sh -p /path/to/wordpress
```

With all options:

```bash
./wp-cron.sh --path=/path/to/wordpress --cli="php /path/to/wp-cli.phar" --url=example.com --timeout=600 --sentry --monitor="your-monitor-slug" --key="your-public-key" --env="production" --instance="https://sentry.example.com" --org-id="123456" --quiet
```

### Options

- `-p, --path`: Path to WordPress installation (default: current directory)
- `-c, --cli`: WP-CLI command to use (default: 'wp')
- `-u, --url`: WordPress URL (optional, for multisite installations)
- `-q, --quiet`: Suppress output except for errors
- `-s, --sentry`: Send execution data to Sentry
- `-m, --monitor`: Sentry monitor slug (required if using Sentry)
- `-k, --key`: Sentry public key (required if using Sentry)
- `-e, --env`: Sentry environment (default: 'production')
- `-i, --instance`: Sentry instance URL (default: 'https://o0.ingest.sentry.io')
- `-o, --org-id`: Sentry organization/project ID (default: '0')
- `-t, --timeout`: Maximum execution time in seconds (default: 300)
- `-h, --help`: Display help information

## Examples

### Basic WordPress Installation

```bash
./wp-cron.sh -p /var/www/html/wordpress
```

### WordPress Multisite with Custom WP-CLI Path

```bash
./wp-cron.sh -p /var/www/html/wordpress -c "php /usr/local/bin/wp-cli.phar" -u site1.example.com
```

### With Sentry Integration and Extended Timeout

```bash
./wp-cron.sh -p /var/www/html/wordpress -s -m "wordpress-cron" -k "abcdef123456" -e "staging" -t 600
```

### With Self-hosted Sentry Instance

```bash
./wp-cron.sh -p /var/www/html/wordpress -s -m "wordpress-cron" -k "abcdef123456" -i "https://sentry.example.com" -o "123456"
```

## Setting Up as a Cron Job

To run the script every 15 minutes:

```bash
# Edit crontab
crontab -e

# Add the following line
*/15 * * * * /path/to/wp-cron.sh -p /path/to/wordpress -q
```

## Sentry Integration

The script uses Sentry's HTTP API for cron monitoring. To use this integration:

1. Create a cron monitor in your Sentry project:
   - Go to your Sentry project
   - Navigate to Crons > Create Monitor
   - Configure your monitor and save it
   - Note the monitor slug and public key

2. Run the script with the Sentry options:
   ```bash
   ./wp-cron.sh -p /path/to/wordpress -s -m "your-monitor-slug" -k "your-public-key"
   ```

The script will send check-ins to Sentry with the following statuses:
- `in_progress`: When the cron job starts
- `ok`: When the cron job completes successfully
- `error`: When the cron job fails or times out

You can also specify an environment with the `-e` or `--env` option (defaults to "production").

### Self-hosted Sentry

If you're using a self-hosted Sentry instance, you can specify the instance URL with the `-i` or `--instance` option:

```bash
./wp-cron.sh -p /path/to/wordpress -s -m "your-monitor-slug" -k "your-public-key" -i "https://sentry.example.com"
```
Make sure to provide the base URL of your Sentry instance without any trailing slashes.

### Sentry API Path

The Sentry API URL is constructed as follows:
```
{instance-url}/api/{org-id}/cron/{monitor-slug}/{public-key}/
```

By default, the `org-id` is set to "0", which works for Sentry.io. If you're using a self-hosted Sentry instance or need to specify a different organization/project ID, you can use the `-o` or `--org-id` option:

```bash
./wp-cron.sh -p /path/to/wordpress -s -m "your-monitor-slug" -k "your-public-key" -o "123456"
```

## Troubleshooting

### WP-CLI Not Found

If you get an error about WP-CLI not being found, you can specify the full path to the WP-CLI executable:

```bash
./wp-cron.sh -p /path/to/wordpress -c "php /path/to/wp-cli.phar"
```

### Timeout Issues

If your WordPress site has many scheduled tasks that take a long time to complete, you may need to increase the timeout:

```bash
./wp-cron.sh -p /path/to/wordpress -t 900  # 15 minutes timeout
```

### WordPress Path Validation

The script checks for the existence of `wp-config.php` in the specified WordPress path. Make sure you're providing the correct path to your WordPress installation.

### Sentry Integration Issues

If you're having issues with the Sentry integration:

1. Ensure that `curl` is installed on your system
2. Verify that your monitor slug and public key are correct
3. Check that your server can reach the Sentry API (no firewall blocking outbound connections)
4. If using a self-hosted Sentry instance, make sure the URL is correct
5. Verify that the organization/project ID is correct for your Sentry instance
6. Run the script without the quiet mode to see detailed logs, including the full Sentry URL

## Security Considerations

- The script should be run by a user with appropriate permissions to access the WordPress files
- Consider using the quiet mode (`-q`) when running as a cron job to prevent unnecessary emails
- Store the script in a location not accessible via the web server
- Keep your Sentry public key secure, although it's designed to be used in client-side applications 