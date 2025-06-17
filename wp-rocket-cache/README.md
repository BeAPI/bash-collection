# WP-Rocket Cache Cleaner

A Bash script to clear WP-Rocket cache via WP-CLI. This script supports both single-site and multisite WordPress installations.

## Features

- Clear WP-Rocket cache for a single site or all sites in a multisite installation
- Automatic detection of multisite installations
- Checks if WP-Rocket is active before attempting to clear cache
- Detailed logging with timestamps
- Support for custom WP-CLI command paths
- Quiet mode for minimal output

## Requirements

- Bash shell
- WP-CLI installed and accessible
- WordPress installation with WP-Rocket plugin

## Usage

```bash
./wp-rocket-cache.sh [options]
```

### Options

- `-p, --path`      Path to WordPress installation (default: current directory)
- `-c, --cli`       WP-CLI command to use (default: 'wp')
- `-u, --url`       WordPress URL (optional, for multisite installations)
- `-q, --quiet`     Suppress output except for errors
- `-h, --help`      Display help message

### Examples

Clear cache for a single site:
```bash
./wp-rocket-cache.sh --path=/path/to/wordpress --url=https://example.com
```

Clear cache for all sites in a multisite installation:
```bash
./wp-rocket-cache.sh --path=/path/to/wordpress
```

Use a custom WP-CLI command:
```bash
./wp-rocket-cache.sh --path=/path/to/wordpress --cli=/usr/local/bin/wp-cli.phar
```

## Logging

The script provides detailed logging with timestamps. You can enable logging to a file by setting the `LOGFILE` environment variable:

```bash
LOGFILE=/path/to/logfile.log ./wp-rocket-cache.sh --path=/path/to/wordpress
```

## Exit Codes

- `0`: Success
- `1`: Error occurred during cache clearing
- `2`: Invalid arguments or configuration

## Notes

- The script automatically checks if WP-Rocket is active before attempting to clear the cache
- For multisite installations, sites where WP-Rocket is not active will be skipped
- All operations are logged with timestamps for better tracking 