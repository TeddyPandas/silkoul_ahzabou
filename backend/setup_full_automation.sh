#!/bin/bash

# setup_full_automation.sh
# Usage: ./setup_full_automation.sh <USER>@<IP>

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <USER>@<IP>"
    echo "Example: $0 root@185.194.216.251"
    exit 1
fi

TARGET=$1
SSH_KEY_PATH="$HOME/.ssh/id_rsa"

echo "🚀 Starting Full Automation Setup on $TARGET..."

# 1. Check for SSH Key or Generate One
if [ ! -f "$SSH_KEY_PATH" ] && [ ! -f "$SSH_KEY_PATH.pub" ]; then
    echo "⚠️  No SSH key found at $SSH_KEY_PATH."
    echo "🔑 Generating a new SSH key pair for automation..."
    # Generate key without paraphrase (-N "")
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N ""
    chmod 600 "$SSH_KEY_PATH"
    chmod 644 "$SSH_KEY_PATH.pub"
    echo "✅ SSH Key generated with secure permissions."
else
    echo "✅ SSH Key already exists."
fi

# 2. Copy SSH Key to VPS
echo "📤 Copying SSH public key to VPS (You may be asked for your password one last time)..."
ssh-copy-id -i "$SSH_KEY_PATH.pub" "$TARGET"

if [ $? -eq 0 ]; then
    echo "✅ SSH Key copied successfully."
else
    echo "⚠️  Could not copy SSH key. Maybe it's already there or connection failed."
fi

# 3. Run the VPS Setup Script
echo "🔧 Running VPS configuration script..."
./setup_vps.sh "$TARGET"

echo "🎉 FULL AUTOMATION COMPLETE!"
echo ""
echo "👉 NEXT STEP: Add these secrets to your GitHub Repository:"
echo "   (Settings > Secrets and variables > Actions)"
echo ""
echo "   VPS_HOST: $(echo $TARGET | cut -d@ -f2)"
echo "   VPS_USER: $(echo $TARGET | cut -d@ -f1)"
echo "   SSH_PRIVATE_KEY: (Copy the content below)"
echo "---------------------------------------------------"
cat "$SSH_KEY_PATH"
echo "---------------------------------------------------"
