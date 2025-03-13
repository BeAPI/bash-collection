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
- Allows specific IP addresses to bypass authentication
- Compatible with both Apache 2.2 and 2.4 syntax

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
- Use Apache 2.4 syntax (default)

### Command-line Options

```
Usage: ./add_http_auth.sh [options]
Options:
  -f, --file      Path to the .htaccess file (default: ./.htaccess)
  -p, --passwd    Path to the .htpasswd file (default: ./.htpasswd)
  -u, --user      Username (default: 'admin')
  -s, --password  Password (if not specified, it will be asked interactively)
  -e, --encrypt   Encryption method: md5, bcrypt, sha1 (default: 'bcrypt')
  -i, --ip        Comma-separated list of IP addresses allowed without authentication
  -a, --apache    Apache version: 2.2 or 2.4 (default: '2.4')
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

#### Allow specific IP addresses to bypass authentication:

```bash
./add_http_auth.sh -i "192.168.1.100,10.0.0.5"
```

#### Specify Apache version (for older servers):

```bash
./add_http_auth.sh -a 2.2
```

#### Full example with all options:

```bash
./add_http_auth.sh -f /var/www/html/.htaccess -p /etc/apache2/.htpasswd -u webmaster -s "my_secure_password" -e bcrypt -i "192.168.1.100,10.0.0.5" -a 2.4
```

## How It Works

1. The script first checks if the specified directories exist
2. It then checks if the .htaccess file already exists and if authentication is already configured
3. If a password is not provided as an argument, it prompts the user to enter one
4. It creates or updates the .htpasswd file with the username and hashed password
5. If IP addresses are specified, it adds rules to allow those IPs to bypass authentication
6. Finally, it adds the necessary authentication directives to the .htaccess file

## Encryption Methods

The script supports three encryption methods:

1. **bcrypt** (default): The most secure option, requires the `htpasswd` command
2. **md5**: Compatible with most servers, requires the `openssl` command
3. **sha1**: Stronger than md5 but less secure than bcrypt, requires the `openssl` command

## IP-Based Access

When you specify IP addresses with the `-i` option, the script adds rules to the .htaccess file that allow those IPs to access the protected content without authentication. This is useful for:

- Office networks where you want to allow access without prompting for credentials
- Development or staging environments where you want to restrict access but allow certain IPs
- Monitoring services that need to access the site without authentication

The IP addresses should be provided as a comma-separated list without spaces, for example: `192.168.1.100,10.0.0.5`

## Apache Version Compatibility

The script supports both Apache 2.2 and Apache 2.4 syntax for access control:

### Apache 2.2 Syntax

```apache
SetEnvIf Remote_Addr "^(192\.168\.1\.100|10\.0\.0\.5)$" ALLOW_ACCESS
Order deny,allow
Deny from all
Allow from env=ALLOW_ACCESS
Satisfy any
```

### Apache 2.4 Syntax

```apache
<RequireAny>
    Require ip 192.168.1.100 10.0.0.5
    Require valid-user
</RequireAny>
```

By default, the script uses Apache 2.4 syntax. If you're using an older Apache server (version 2.2), specify `-a 2.2` when running the script.

## Security Considerations

- When using the `-s` option to specify a password on the command line, be aware that the password may be visible in the process list or command history
- For production environments, it's recommended to use the interactive password prompt
- Make sure the .htpasswd file is stored in a location not accessible from the web
- Ensure proper file permissions are set on both .htaccess and .htpasswd files
- Use bcrypt encryption when possible for better security
- Be careful when allowing IP addresses to bypass authentication, as IP addresses can be spoofed

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

5. **IP-based access not working**
   - Make sure your Apache server has the required modules enabled:
     - For Apache 2.2: `mod_setenvif`, `mod_authz_host`
     - For Apache 2.4: `mod_authz_core`, `mod_authz_host`
   - Check that you're using the correct IP address format
   - Verify that your server is properly detecting the client's IP address
   - Ensure you're using the correct Apache version syntax (`-a 2.2` or `-a 2.4`)

## License

This script is released under the MIT License. See the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

BeAPI - [https://beapi.fr](https://beapi.fr) 