# HTTP Authentication Script

A bash script to easily add HTTP Basic authentication to an .htaccess file.

## Overview

`add_http_auth.sh` is a utility script that simplifies the process of adding HTTP Basic authentication to a website or directory through an .htaccess file. The script handles the creation of both the .htaccess configuration and the .htpasswd password file.

## Features

- Adds HTTP Basic authentication to an .htaccess file
- Creates or updates the .htpasswd password file
- Checks if authentication is already configured before making changes
- Works on both Linux and macOS systems
- Supports custom paths for both .htaccess and .htpasswd files
- Allows customization of username
- Provides interactive or command-line password entry
- Supports multiple encryption methods (bcrypt, md5, sha1)

## Requirements

- Bash shell
- For bcrypt encryption (default): `htpasswd` command (from apache2-utils or httpd-tools)
- For md5/sha1 encryption: `openssl` command

## Installation

1. Clone the repository:

```bash
git clone git@github.com:BeAPI/bash-collection.git
cd bash-collection/http-auth
```

2. Make the script executable:

```bash
chmod +x add_http_auth.sh
```

Alternatively, you can download just the script:

```bash
curl -O https://raw.githubusercontent.com/BeAPI/bash-collection/main/http-auth/add_http_auth.sh
chmod +x add_http_auth.sh
```

## Usage

### Basic Usage

Run the script without any arguments to use default values:

```bash
./add_http_auth.sh
```

This will:
- Create or update a .htaccess file in the current directory
- Create or update a .htpasswd file in the current directory
- Set up authentication with default values (username: admin)
- Prompt you to enter a password
- Use bcrypt encryption (most secure)

### Command-line Options

```
Usage: ./add_http_auth.sh [options]
Options:
  -f, --file      Path to the .htaccess file (default: ./.htaccess)
  -p, --passwd    Path to the .htpasswd file (default: ./.htpasswd)
  -u, --user      Username (default: 'admin')
  -s, --password  Password (if not specified, it will be asked interactively)
  -e, --encrypt   Encryption method: md5, bcrypt, sha1 (default: 'bcrypt')
  -h, --help      Display this help
```

### Examples

#### Specify custom paths for files:

```bash
./add_http_auth.sh -f /var/www/html/.htaccess -p /etc/apache2/.htpasswd
```

#### Customize username:

```bash
./add_http_auth.sh -u webmaster
```

#### Provide password via command line (useful for scripts):

```bash
./add_http_auth.sh -s "my_secure_password"
```

#### Specify encryption method:

```bash
./add_http_auth.sh -e md5
```

#### Full example with all options:

```bash
./add_http_auth.sh -f /var/www/html/.htaccess -p /etc/apache2/.htpasswd -u webmaster -s "my_secure_password" -e bcrypt
```

## How It Works

1. The script first checks if the specified directories exist
2. It then checks if the .htaccess file already exists and if authentication is already configured
3. If a password is not provided as an argument, it prompts the user to enter one
4. It creates or updates the .htpasswd file with the username and hashed password
5. Finally, it adds the necessary authentication directives to the .htaccess file

## Encryption Methods

The script supports three encryption methods:

1. **bcrypt** (default): The most secure option, requires the `htpasswd` command
2. **md5**: Compatible with most servers, requires the `openssl` command
3. **sha1**: Stronger than md5 but less secure than bcrypt, requires the `openssl` command

## Security Considerations

- When using the `-s` option to specify a password on the command line, be aware that the password may be visible in the process list or command history
- For production environments, it's recommended to use the interactive password prompt
- Make sure the .htpasswd file is stored in a location not accessible from the web
- Ensure proper file permissions are set on both .htaccess and .htpasswd files
- Use bcrypt encryption when possible for better security

## Troubleshooting

### Common Issues

1. **"Error: The directory for the .htaccess file does not exist"**
   - Make sure the directory where you want to place the .htaccess file exists

2. **"Error: htpasswd command not found"**
   - Install apache2-utils (Debian/Ubuntu) or httpd-tools (CentOS/RHEL)
   - Alternatively, use `-e md5` or `-e sha1` if you have openssl installed

3. **"Error: openssl command not found"**
   - Install openssl or use `-e bcrypt` if you have htpasswd installed

4. **Authentication not working in browser**
   - Ensure your web server is configured to allow .htaccess overrides
   - Check that the path to the .htpasswd file in the .htaccess is correct and accessible by the web server

## License

This script is released under the MIT License. See the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

BeAPI - [https://beapi.fr](https://beapi.fr) 