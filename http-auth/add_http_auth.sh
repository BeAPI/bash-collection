#!/bin/bash

# Script to add HTTP Basic authentication to an .htaccess file
# The password is stored in an .htpasswd file

# Function to display help
show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -f, --file      Path to the .htaccess file (default: ./.htaccess)"
    echo "  -p, --passwd    Path to the .htpasswd file (default: ./.htpasswd)"
    echo "  -u, --user      Username (default: 'admin')"
    echo "  -s, --password  Password (if not specified, it will be asked interactively)"
    echo "  -e, --encrypt   Encryption method: md5, bcrypt, sha1 (default: 'bcrypt')"
    echo "  -i, --ip        Comma-separated list of IP addresses allowed without authentication"
    echo "  -a, --apache    Apache version: 2.2 or 2.4 (default: '2.4')"
    echo "  -h, --help      Display this help"
    exit 0
}

# Function to get absolute path without relying on realpath
get_absolute_path() {
    local path="$1"
    
    # If the path is already absolute, return it as is
    if [[ "$path" = /* ]]; then
        echo "$path"
        return
    fi
    
    # Otherwise, build the absolute path
    echo "$(cd "$(dirname "$path")" 2>/dev/null && pwd)/$(basename "$path")"
}

# Function to generate an htpasswd entry
generate_htpasswd_entry() {
    local username="$1"
    local password="$2"
    local encrypt_method="$3"
    
    case "$encrypt_method" in
        md5)
            if command -v openssl &> /dev/null; then
                # Generate MD5 hash with openssl
                local hash=$(echo -n "$password" | openssl passwd -apr1 -stdin)
                echo "$username:$hash"
            else
                echo "Error: openssl command not found. Cannot generate MD5 hash."
                exit 1
            fi
            ;;
        bcrypt)
            if command -v htpasswd &> /dev/null; then
                # Use htpasswd to generate bcrypt hash
                htpasswd -bnBC 10 "$username" "$password" 2>/dev/null
            else
                echo "Error: htpasswd command not found. Cannot generate bcrypt hash."
                echo "Please install apache2-utils (Debian/Ubuntu) or httpd-tools (CentOS/RHEL)."
                exit 1
            fi
            ;;
        sha1)
            if command -v openssl &> /dev/null; then
                # Generate SHA1 hash with openssl
                local hash=$(echo -n "$password" | openssl passwd -5 -stdin)
                echo "$username:$hash"
            else
                echo "Error: openssl command not found. Cannot generate SHA1 hash."
                exit 1
            fi
            ;;
        *)
            echo "Error: Unknown encryption method: $encrypt_method"
            exit 1
            ;;
    esac
}

# Function to generate IP-based access rules
generate_ip_rules() {
    local ip_list="$1"
    local apache_version="$2"
    local rules=""
    
    # If IP list is empty, return empty rules
    if [ -z "$ip_list" ]; then
        echo ""
        return
    fi
    
    # Format the IP list for use in the rules
    # Replace commas with spaces for Apache 2.4 Require ip directive
    local formatted_ip_list=${ip_list//,/ }
    
    # Start the rules block
    rules="# Allow access from specific IP addresses without authentication\n"
    
    if [ "$apache_version" = "2.2" ]; then
        # Apache 2.2 syntax
        # Replace spaces with | for regex OR
        local regex_ip_list=${ip_list//,/|}
        rules="${rules}SetEnvIf Remote_Addr \"^(${regex_ip_list})$\" ALLOW_ACCESS\n"
        rules="${rules}Order deny,allow\n"
        rules="${rules}Deny from all\n"
        rules="${rules}Allow from env=ALLOW_ACCESS\n"
        rules="${rules}Satisfy any\n\n"
    else
        # Apache 2.4 syntax using RequireAny
        rules="${rules}<RequireAny>\n"
        rules="${rules}    Require ip ${formatted_ip_list}\n"
        rules="${rules}    Require valid-user\n"
        rules="${rules}</RequireAny>\n\n"
    fi
    
    echo -e "$rules"
}

# Default values
HTACCESS_FILE="./.htaccess"
HTPASSWD_FILE="./.htpasswd"
USERNAME="admin"
PASSWORD=""
ENCRYPT_METHOD="bcrypt"
ALLOWED_IPS=""
APACHE_VERSION="2.4"

# Process arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            HTACCESS_FILE="$2"
            shift 2
            ;;
        -p|--passwd)
            HTPASSWD_FILE="$2"
            shift 2
            ;;
        -u|--user)
            USERNAME="$2"
            shift 2
            ;;
        -s|--password)
            PASSWORD="$2"
            shift 2
            ;;
        -e|--encrypt)
            ENCRYPT_METHOD="$2"
            shift 2
            ;;
        -i|--ip)
            ALLOWED_IPS="$2"
            shift 2
            ;;
        -a|--apache)
            APACHE_VERSION="$2"
            shift 2
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

# Validate encryption method
if [[ ! "$ENCRYPT_METHOD" =~ ^(md5|bcrypt|sha1)$ ]]; then
    echo "Error: Invalid encryption method. Valid options are: md5, bcrypt, sha1"
    exit 1
fi

# Validate Apache version
if [[ ! "$APACHE_VERSION" =~ ^(2.2|2.4)$ ]]; then
    echo "Error: Invalid Apache version. Valid options are: 2.2, 2.4"
    exit 1
fi

# Convert to absolute paths without using realpath
HTACCESS_PATH=$(get_absolute_path "$HTACCESS_FILE")
HTPASSWD_PATH=$(get_absolute_path "$HTPASSWD_FILE")

# Check if directories exist
HTACCESS_DIR=$(dirname "$HTACCESS_PATH")
if [ ! -d "$HTACCESS_DIR" ]; then
    echo "Error: The directory for the .htaccess file '$HTACCESS_DIR' does not exist."
    exit 1
fi

HTPASSWD_DIR=$(dirname "$HTPASSWD_PATH")
if [ ! -d "$HTPASSWD_DIR" ]; then
    echo "Error: The directory for the .htpasswd file '$HTPASSWD_DIR' does not exist."
    exit 1
fi

# Check if the .htaccess file already exists
if [ -f "$HTACCESS_PATH" ]; then
    echo "The .htaccess file already exists at '$HTACCESS_PATH'."
    
    # Check if authentication is already configured
    if grep -q "AuthType Basic" "$HTACCESS_PATH"; then
        echo "HTTP Basic authentication is already configured in the .htaccess file."
        exit 0
    fi
else
    echo "Creating a new .htaccess file at '$HTACCESS_PATH'."
    touch "$HTACCESS_PATH"
fi

# Ask for password if not specified as an argument
if [ -z "$PASSWORD" ]; then
    echo -n "Please enter the password for user '$USERNAME': "
    read -s PASSWORD
    echo ""
    
    # Check that the password is not empty
    if [ -z "$PASSWORD" ]; then
        echo "Error: Password cannot be empty."
        exit 1
    fi
else
    echo "Using password provided as argument."
fi

# Create or update the .htpasswd file
if [ ! -f "$HTPASSWD_PATH" ]; then
    echo "Creating .htpasswd file at '$HTPASSWD_PATH'."
    touch "$HTPASSWD_PATH"
fi

# Generate the entry in the .htpasswd file using our function
echo "Generating entry for user '$USERNAME' in the .htpasswd file using $ENCRYPT_METHOD encryption."
generate_htpasswd_entry "$USERNAME" "$PASSWORD" "$ENCRYPT_METHOD" > "$HTPASSWD_PATH"

# Generate IP-based access rules if IPs are provided
IP_RULES=""
if [ -n "$ALLOWED_IPS" ]; then
    echo "Configuring access without authentication for IPs: $ALLOWED_IPS (Apache $APACHE_VERSION syntax)"
    IP_RULES=$(generate_ip_rules "$ALLOWED_IPS" "$APACHE_VERSION")
fi

# Add authentication configuration to the .htaccess file
cat << EOF >> "$HTACCESS_PATH"

# HTTP Basic Authentication Configuration
AuthType Basic
AuthName "Restricted Area"
AuthUserFile "$HTPASSWD_PATH"
EOF

# For Apache 2.4 without IP rules or Apache 2.2, we need to add Require valid-user
if [ -z "$ALLOWED_IPS" ]; then
    if [ "$APACHE_VERSION" = "2.4" ]; then
        echo "Require valid-user" >> "$HTACCESS_PATH"
    elif [ "$APACHE_VERSION" = "2.2" ]; then
        echo "Require valid-user" >> "$HTACCESS_PATH"
    fi
fi

# Add IP rules if any
if [ -n "$IP_RULES" ]; then
    echo -e "$IP_RULES" >> "$HTACCESS_PATH"
fi

echo "HTTP Basic authentication successfully added to the .htaccess file."
echo "Username: $USERNAME"
echo "Encryption method: $ENCRYPT_METHOD"
echo "Password file: $HTPASSWD_PATH"
echo "Apache version: $APACHE_VERSION"
if [ -n "$ALLOWED_IPS" ]; then
    echo "IPs allowed without authentication: $ALLOWED_IPS"
fi

exit 0 