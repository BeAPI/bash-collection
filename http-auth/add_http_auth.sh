#!/bin/bash

# Script to add HTTP authentication to an .htaccess file
# The password is stored in an .htdigest file

# Function to display help
show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -f, --file      Path to the .htaccess file (default: ./.htaccess)"
    echo "  -d, --digest    Path to the .htdigest file (default: ./.htdigest)"
    echo "  -r, --realm     Realm name (default: 'Restricted Area')"
    echo "  -u, --user      Username (default: 'admin')"
    echo "  -p, --password  Password (if not specified, it will be asked interactively)"
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

# Function to generate an htdigest entry without using the htdigest command
generate_htdigest_entry() {
    local username="$1"
    local realm="$2"
    local password="$3"
    
    # Generate the MD5 hash of username:realm:password
    local md5_digest
    if command -v md5sum &> /dev/null; then
        md5_digest=$(echo -n "$username:$realm:$password" | md5sum | cut -d' ' -f1)
    elif command -v md5 &> /dev/null; then
        # For macOS which uses md5 instead of md5sum
        md5_digest=$(echo -n "$username:$realm:$password" | md5)
    else
        echo "Error: No MD5 hashing command found (md5sum or md5)."
        exit 1
    fi
    
    echo "$username:$realm:$md5_digest"
}

# Default values
HTACCESS_FILE="./.htaccess"
HTDIGEST_FILE="./.htdigest"
REALM="Restricted Area"
USERNAME="admin"
PASSWORD=""

# Process arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            HTACCESS_FILE="$2"
            shift 2
            ;;
        -d|--digest)
            HTDIGEST_FILE="$2"
            shift 2
            ;;
        -r|--realm)
            REALM="$2"
            shift 2
            ;;
        -u|--user)
            USERNAME="$2"
            shift 2
            ;;
        -p|--password)
            PASSWORD="$2"
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

# Convert to absolute paths without using realpath
HTACCESS_PATH=$(get_absolute_path "$HTACCESS_FILE")
HTDIGEST_PATH=$(get_absolute_path "$HTDIGEST_FILE")

# Check if directories exist
HTACCESS_DIR=$(dirname "$HTACCESS_PATH")
if [ ! -d "$HTACCESS_DIR" ]; then
    echo "Error: The directory for the .htaccess file '$HTACCESS_DIR' does not exist."
    exit 1
fi

HTDIGEST_DIR=$(dirname "$HTDIGEST_PATH")
if [ ! -d "$HTDIGEST_DIR" ]; then
    echo "Error: The directory for the .htdigest file '$HTDIGEST_DIR' does not exist."
    exit 1
fi

# Check if the .htaccess file already exists
if [ -f "$HTACCESS_PATH" ]; then
    echo "The .htaccess file already exists at '$HTACCESS_PATH'."
    
    # Check if authentication is already configured
    if grep -q "AuthType Digest" "$HTACCESS_PATH"; then
        echo "HTTP Digest authentication is already configured in the .htaccess file."
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

# Create or update the .htdigest file
if [ ! -f "$HTDIGEST_PATH" ]; then
    echo "Creating .htdigest file at '$HTDIGEST_PATH'."
    touch "$HTDIGEST_PATH"
fi

# Generate the entry in the .htdigest file using our own function
echo "Generating entry for user '$USERNAME' in the .htdigest file."
generate_htdigest_entry "$USERNAME" "$REALM" "$PASSWORD" > "$HTDIGEST_PATH"

# Add authentication configuration to the .htaccess file
cat << EOF >> "$HTACCESS_PATH"

# HTTP Digest Authentication Configuration
AuthType Digest
AuthName "$REALM"
AuthUserFile "$HTDIGEST_PATH"
Require valid-user

EOF

echo "HTTP Digest authentication successfully added to the .htaccess file."
echo "Username: $USERNAME"
echo "Realm: $REALM"
echo "Password file: $HTDIGEST_PATH"

exit 0 