# BeAPI Bash Collection

A collection of useful bash scripts for various tasks.

## Available Scripts

This repository contains a collection of bash scripts organized by category:

### HTTP Authentication

Scripts for managing HTTP authentication in web servers.

- [add_http_auth.sh](http-auth/add_http_auth.sh) - Add HTTP Basic authentication to an .htaccess file with support for IP-based access control and compatibility with both Apache 2.2 and 2.4

### WordPress

Scripts for managing WordPress installations.

- [wp-cron.sh](wp-cron-sentry/wp-cron.sh) - Execute WordPress cron tasks via WP-CLI with support for multisite installations and Sentry monitoring via HTTP API (supports both Sentry.io and self-hosted instances with customizable API paths)
- [wp-cron.sh](wp-cron-healthchecks/wp-cron.sh) - Execute WordPress cron tasks via WP-CLI with support for multisite installations and Healthchecks.io monitoring (start/success/fail pings)

## Installation

Clone the repository:

```bash
git clone git@github.com:BeAPI/bash-collection.git
cd bash-collection
```

Make the scripts executable:

```bash
chmod +x */**.sh
```

## Usage

Each script is located in its own directory with specific documentation. Navigate to the script's directory and check its README.md file for detailed usage instructions.

For example:

```bash
cd http-auth
./add_http_auth.sh --help
```

Or:

```bash
cd wp-cron-sentry
./wp-cron.sh --help

cd wp-cron-healthchecks
./wp-cron.sh --help
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is released under the MIT License. See the LICENSE file for details.

## Author

BeAPI - [https://beapi.fr](https://beapi.fr)
