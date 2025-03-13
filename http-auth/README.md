# HTTP Authentication Script

A bash script to easily add HTTP Digest authentication to an .htaccess file.

## Overview

`add_http_auth.sh` is a utility script that simplifies the process of adding HTTP Digest authentication to a website or directory through an .htaccess file. The script handles the creation of both the .htaccess configuration and the .htdigest password file.

## Features

- Adds HTTP Digest authentication to an .htaccess file
- Creates or updates the .htdigest password file
- Checks if authentication is already configured before making changes
- Works on both Linux and macOS systems
- Supports custom paths for both .htaccess and .htdigest files
- Allows customization of realm name and username
- Provides interactive or command-line password entry

## Requirements

- Bash shell
- MD5 hashing utility (either `md5sum` on Linux or `md5` on macOS)

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
- Create or update a .htdigest file in the current directory
- Set up authentication with default values (username: admin, realm: "Restricted Area")
- Prompt you to enter a password

### Command-line Options

```
Usage: ./add_http_auth.sh [options]
Options:
  -f, --file      Path to the .htaccess file (default: ./.htaccess)
  -d, --digest    Path to the .htdigest file (default: ./.htdigest)
  -r, --realm     Realm name (default: 'Restricted Area')
  -u, --user      Username (default: 'admin')
  -p, --password  Password (if not specified, it will be asked interactively)
  -h, --help      Display this help
```

### Examples

#### Specify custom paths for files:

```bash
./add_http_auth.sh -f /var/www/html/.htaccess -d /etc/apache2/.htdigest
```

#### Customize username and realm:

```bash
./add_http_auth.sh -u webmaster -r "My Website Admin Area"
```

#### Provide password via command line (useful for scripts):

```bash
./add_http_auth.sh -p "my_secure_password"
```

#### Full example with all options:

```bash
./add_http_auth.sh -f /var/www/html/.htaccess -d /etc/apache2/.htdigest -u webmaster -r "My Website Admin Area" -p "my_secure_password"
```

## How It Works

1. The script first checks if the specified directories exist
2. It then checks if the .htaccess file already exists and if authentication is already configured
3. If a password is not provided as an argument, it prompts the user to enter one
4. It creates or updates the .htdigest file with the username, realm, and hashed password
5. Finally, it adds the necessary authentication directives to the .htaccess file

## Security Considerations

- When using the `-p` option to specify a password on the command line, be aware that the password may be visible in the process list or command history
- For production environments, it's recommended to use the interactive password prompt
- Make sure the .htdigest file is stored in a location not accessible from the web
- Ensure proper file permissions are set on both .htaccess and .htdigest files

## Troubleshooting

### Common Issues

1. **"Error: The directory for the .htaccess file does not exist"**
   - Make sure the directory where you want to place the .htaccess file exists

2. **"Error: No MD5 hashing command found"**
   - Install either `md5sum` (Linux) or ensure `md5` is available (macOS)

3. **Authentication not working in browser**
   - Ensure your web server is configured to allow .htaccess overrides
   - Check that the path to the .htdigest file in the .htaccess is correct and accessible by the web server

## License

This script is released under the MIT License. See the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

BeAPI - [https://beapi.fr](https://beapi.fr) 