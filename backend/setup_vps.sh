#!/bin/bash

# setup_vps.sh
# Usage: ./setup_vps.sh start <USER>@<IP>

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <USER>@<IP>"
    echo "Example: $0 root@192.168.1.10"
    exit 1
fi

TARGET=$1

echo "🚀 Starting VPS Setup on $TARGET..."

# 1. Copy SSH Key to avoid password prompts
echo "🔑 Copying SSH key..."
ssh-copy-id -i ~/.ssh/id_rsa.pub "$TARGET" || echo "⚠️  SSH Key copy failed or already exists. Continuing..."

# 2. Update System & Install Dependencies
echo "📦 Updating system and installing dependencies..."
ssh "$TARGET" 'bash -s' << 'EOF'
    # Update system
    apt update && apt upgrade -y

    # Install essentials
    apt install -y curl git ufw

    # Install Docker
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
    else
        echo "Docker already installed."
    fi

    # Install Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo "Installing Docker Compose..."
        apt install -y docker-compose-plugin
    else
        echo "Docker Compose already installed."
    fi

    # Configure Firewall
    echo "Configuring Firewall..."
    ufw allow OpenSSH
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable

    # Create App Directory
    mkdir -p /var/www/silkoul-backend
    chown -R $USER:$USER /var/www/silkoul-backend

    echo "✅ VPS Setup Complete!"
EOF

echo "🎉 Done! Your VPS is ready for deployment."
