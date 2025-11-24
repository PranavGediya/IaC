#!/bin/bash
set -e

################################################################################
# CONFIGURATION - EDIT THESE VALUES
################################################################################

# Git repository URL (REQUIRED)
GIT_REPO_URL=" "

# Git branch to deploy
GIT_BRANCH=" "

# Application name (used for folder and nginx config file name)
APP_NAME="GTC6"

# GitHub Personal Access Token (OPTIONAL - only needed for private repos)
# Leave empty for public repos
GITHUB_TOKEN=" "

################################################################################
# DO NOT EDIT BELOW THIS LINE
################################################################################

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Starting React App Deployment ==="
echo "Timestamp: $(date)"
echo "Git Repo: $GIT_REPO_URL"
echo "Branch: $GIT_BRANCH"
echo "App Name: $APP_NAME"

# Update system
echo "Updating system packages..."
sudo dnf update -y

# Install Git
echo "Installing Git..."
sudo dnf install git -y

# Install Node.js and npm
echo "Installing Node.js and npm..."
sudo dnf install nodejs npm -y

# Verify installations
echo "Node version: $(node --version)"
echo "npm version: $(npm --version)"
echo "Git version: $(git --version)"

# Install Nginx
echo "Installing Nginx..."
sudo dnf install nginx -y

# Start and enable Nginx
echo "Starting Nginx..."
sudo systemctl start nginx
sudo systemctl enable nginx

# Configure firewall if firewalld is running
if systemctl is-active --quiet firewalld; then
    echo "Configuring firewall..."
    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --permanent --add-service=https
    sudo firewall-cmd --reload
fi

# Create project directory
echo "Creating project directory..."
mkdir -p /home/ec2-user/projects
cd /home/ec2-user/projects

# Clone repository
echo "Cloning repository..."
if [ -d "$APP_NAME" ]; then
    echo "Directory $APP_NAME already exists, removing..."
    rm -rf "$APP_NAME"
fi

# Use token if provided, otherwise use regular URL
if [ -n "$GITHUB_TOKEN" ]; then
    echo "Using GitHub token for authentication..."
    REPO_PATH=$(echo "$GIT_REPO_URL" | sed 's|https://github.com/||')
    CLONE_URL="https://${GITHUB_TOKEN}@github.com/${REPO_PATH}"
    git clone -b "$GIT_BRANCH" "$CLONE_URL" "$APP_NAME"
else
    echo "Cloning public repository..."
    git clone -b "$GIT_BRANCH" "$GIT_REPO_URL" "$APP_NAME"
fi

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to clone repository!"
    echo "If this is a private repo, you need to set GITHUB_TOKEN"
    exit 1
fi

cd "$APP_NAME"

# Set ownership to ec2-user
chown -R ec2-user:ec2-user /home/ec2-user/projects

# Install dependencies and build as ec2-user
echo "Installing npm dependencies..."
sudo -u ec2-user npm install

echo "Building React app..."
sudo -u ec2-user npm run build

# Detect build directory (Vite uses 'dist', CRA uses 'build')
if [ -d "dist" ]; then
    BUILD_DIR="dist"
    echo "Found build directory: dist/ (Vite detected)"
elif [ -d "build" ]; then
    BUILD_DIR="build"
    echo "Found build directory: build/ (Create React App detected)"
else
    echo "ERROR: Build directory not found!"
    echo "Checked for: dist/ and build/"
    echo "Contents of current directory:"
    ls -la
    exit 1
fi

echo "Build completed successfully! Using directory: $BUILD_DIR"

# Configure Nginx
echo "Configuring Nginx..."
cat > /etc/nginx/conf.d/${APP_NAME}.conf <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    root /home/ec2-user/projects/APP_NAME_PLACEHOLDER/BUILD_DIR_PLACEHOLDER;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript image/svg+xml;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
}
EOF

# Replace placeholders with actual values
sed -i "s|APP_NAME_PLACEHOLDER|$APP_NAME|g" /etc/nginx/conf.d/${APP_NAME}.conf
sed -i "s|BUILD_DIR_PLACEHOLDER|$BUILD_DIR|g" /etc/nginx/conf.d/${APP_NAME}.conf

# Remove default Nginx config if it exists
if [ -f /etc/nginx/conf.d/default.conf ]; then
    echo "Removing default nginx config..."
    rm -f /etc/nginx/conf.d/default.conf
fi

# Set proper permissions for entire path (critical for Nginx to access files)
echo "Setting permissions..."
sudo chmod 755 /home/ec2-user
sudo chmod 755 /home/ec2-user/projects
sudo chmod 755 /home/ec2-user/projects/${APP_NAME}
sudo chmod -R 755 /home/ec2-user/projects/${APP_NAME}/${BUILD_DIR}

# Configure SELinux if enabled
if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
    echo "Configuring SELinux..."
    sudo chcon -R -t httpd_sys_content_t /home/ec2-user/projects/${APP_NAME}/${BUILD_DIR}
    sudo setsebool -P httpd_read_user_content 1
fi

# Test Nginx configuration
echo "Testing Nginx configuration..."
sudo nginx -t

if [ $? -ne 0 ]; then
    echo "ERROR: Nginx configuration test failed!"
    cat /etc/nginx/conf.d/${APP_NAME}.conf
    exit 1
fi

# Restart Nginx
echo "Restarting Nginx..."
sudo systemctl restart nginx

# Check Nginx status
if ! sudo systemctl is-active --quiet nginx; then
    echo "ERROR: Nginx failed to start!"
    sudo systemctl status nginx
    exit 1
fi

echo "Nginx is running successfully!"

# Create deployment script for future updates
echo "Creating deployment script..."
cat > /home/ec2-user/deploy.sh <<DEPLOY_SCRIPT
#!/bin/bash
set -e

echo "Starting deployment..."

# Navigate to project directory
cd /home/ec2-user/projects/${APP_NAME}

# Pull latest changes
echo "Pulling latest code from Git..."
git pull origin ${GIT_BRANCH}

# Install dependencies
echo "Installing dependencies..."
npm install

# Build the app
echo "Building React app..."
npm run build

# Detect build directory
if [ -d "dist" ]; then
    BUILD_DIR="dist"
elif [ -d "build" ]; then
    BUILD_DIR="build"
else
    echo "ERROR: Build directory not found!"
    exit 1
fi

# Fix permissions for entire directory path
sudo chmod -R 755 /home/ec2-user/projects/${APP_NAME}/\${BUILD_DIR}
sudo chmod 755 /home/ec2-user
sudo chmod 755 /home/ec2-user/projects
sudo chmod 755 /home/ec2-user/projects/${APP_NAME}

# Fix SELinux context if enabled
if command -v getenforce &> /dev/null && [ "\$(getenforce)" != "Disabled" ]; then
    sudo chcon -R -t httpd_sys_content_t /home/ec2-user/projects/${APP_NAME}/\${BUILD_DIR}
fi

# Test nginx config
sudo nginx -t

# Restart Nginx
echo "Restarting Nginx..."
sudo systemctl restart nginx

echo ""
echo "✓ Deployment complete!"
echo "✓ Application is running"
DEPLOY_SCRIPT

chmod +x /home/ec2-user/deploy.sh
chown ec2-user:ec2-user /home/ec2-user/deploy.sh

# Get instance public IP
INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Display status
echo ""
echo "=========================================="
echo "=== Deployment Complete ==="
echo "=========================================="
echo "Node version: $(node --version)"
echo "npm version: $(npm --version)"
echo "Nginx version: $(nginx -v 2>&1)"
echo "Application: $APP_NAME"
echo "Build directory: /home/ec2-user/projects/${APP_NAME}/${BUILD_DIR}"
echo "Nginx config: /etc/nginx/conf.d/${APP_NAME}.conf"
echo "Deployment script: /home/ec2-user/deploy.sh"
echo ""
echo "Access your application at:"
echo "  → http://$INSTANCE_IP"
echo ""
echo "To deploy updates, SSH to the server and run:"
echo "  → ./deploy.sh"
echo "=========================================="
echo "=== End of User Data Script ==="