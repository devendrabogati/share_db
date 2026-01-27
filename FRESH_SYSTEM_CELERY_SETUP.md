# Fresh System Celery Worker Setup Guide

Complete step-by-step guide to deploy ncc-celery-worker on a new/fresh system with identical configuration.

**Note**: This guide handles **different paths on different systems** automatically.

---

## Define Your System Paths

Before starting, **set these variables** based on your system:

```bash
# CUSTOMIZE THESE FOR YOUR SYSTEM
PROJECT_USER="db"                                    # User who will run celery
PROJECT_HOME="/home/db"                              # Home directory of PROJECT_USER
PROJECT_PATH="/home/db/projects/NCC-Dev/NCC"        # Full path to NCC project
VENV_NAME=".venv"                                    # Virtual env folder name

# For reference:
# System 1: PROJECT_HOME=/home/db, PROJECT_PATH=/home/db/projects/NCC-Dev/NCC
# System 2: PROJECT_HOME=/opt/app, PROJECT_PATH=/opt/app/ncc-project
# System 3: PROJECT_HOME=/usr/local/ncc, PROJECT_PATH=/usr/local/ncc/app
```

---

## Prerequisites Checklist

Before starting, ensure your fresh system has:

- [ ] Python 3.9+ installed
- [ ] pip installed
- [ ] Redis server running (`redis-cli ping` returns PONG)
- [ ] PostgreSQL running (if using database tasks)
- [ ] Git installed
- [ ] User account created (e.g., `db`, `ncc`, `app`)
- [ ] Sudo access
- [ ] **Your project path defined** (see above)

---

## Step 1: Prepare the System

### Install Required Packages

```bash
sudo apt update
sudo apt install -y python3 python3-venv python3-pip git
```

### Create Dedicated User (if doesn't exist)

```bash
# Check if user exists
id $PROJECT_USER

# If not found, create it (adjust PROJECT_USER variable)
sudo useradd -m -s /bin/bash $PROJECT_USER

# Add to sudo group (optional, if needed)
sudo usermod -aG sudo $PROJECT_USER
```

### Switch to the project user

```bash
sudo su - $PROJECT_USER
```

---

## Step 2: Clone/Copy Project Code

### Option A: Clone from Git Repository

```bash
cd ~
mkdir -p projects/NCC-Dev
cd projects/NCC-Dev
git clone <your-repo-url> NCC
cd NCC
```

### Option B: Copy from Existing System (with different paths)

```bash
# On source system (path: /home/db/projects/NCC-Dev/NCC)
scp -r /home/db/projects/NCC-Dev/NCC user@<new-system>:/path/to/project/location/NCC

# On new system (path might be: /opt/app/ncc)
cd /opt/app/ncc
```

**Note**: The destination path can be different! Just update `PROJECT_PATH` variable.

---

## Step 3: Create Python Virtual Environment

```bash
# Navigate to your project (use your actual path)
cd $PROJECT_PATH

# Create virtual environment
python3 -m venv $VENV_NAME

# Activate it
source $VENV_NAME/bin/activate

# Verify Python in venv
which python
# Should show: /path/to/your/project/.venv/bin/python
```

---

## Step 4: Install Dependencies

```bash
# Upgrade pip
pip install --upgrade pip

# Install project dependencies
pip install -r requirements.txt

# Verify Celery installation
python -c "import celery; print(celery.__version__)"
```

---

## Step 5: Configure Environment Variables

### Copy or Create .env File

```bash
# Copy from source system
scp /path/to/.env db@<new-system>:~/projects/NCC-Dev/NCC/.env

# OR create new .env with required variables
nano .env
```

### Essential .env Variables for Celery

```bash
# Redis Configuration
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0

# Celery Worker Configuration
CELERY_WORKER_CONCURRENCY=4
CELERY_WORKER_PREFETCH_MULTIPLIER=1
CELERY_WORKER_MAX_TASKS_PER_CHILD=1000

# Task Timeouts
CELERY_TASK_TIME_LIMIT=3600
CELERY_TASK_SOFT_TIME_LIMIT=3300

# PostgreSQL (if needed)
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=ncc_admin
POSTGRES_USER=ncc_user
POSTGRES_PASSWORD=your_password

# Other required variables
# (copy from your existing .env)
```

---

## Step 6: Test Celery Worker Manually

Before creating the systemd service, test if it works:

```bash
# While in venv
.venv/bin/celery -A src.app.core.celery_app worker --loglevel=info --concurrency=4

# Should show:
# - celery@<hostname> ready
# - Registered tasks
# - Connected to redis://localhost:6379/0
```

**Press Ctrl+C to stop after verifying it works.**

---

## Step 7: Create Systemd Service File (Path-Aware)

**IMPORTANT**: Update the paths in the service file to match your system!

Exit the project user and return to sudo:

```bash
exit  # Exit from project user
```

Create the service file with YOUR paths:

```bash
# Set variables for your system
PROJECT_USER="db"
PROJECT_PATH="/home/db/projects/NCC-Dev/NCC"
VENV_PATH="$PROJECT_PATH/.venv"

# Create the service file
sudo tee /etc/systemd/system/ncc-celery-worker.service > /dev/null << EOF
[Unit]
Description=NCC EDMS Celery Worker
After=network.target

[Service]
Type=exec
User=$PROJECT_USER
Group=$PROJECT_USER
WorkingDirectory=$PROJECT_PATH
Environment=PATH=$VENV_PATH/bin
EnvironmentFile=$PROJECT_PATH/.env
ExecStart=$VENV_PATH/bin/celery -A src.app.core.celery_app worker --loglevel=info --concurrency=4 --max-tasks-per-child=1000
ExecReload=/bin/kill -s HUP \$MAINPID
KillSignal=SIGTERM
TimeoutStopSec=30
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ncc-celery-worker

NoNewPrivileges=true
PrivateTmp=false

[Install]
WantedBy=multi-user.target
EOF
```

**Verify the created file:**

```bash
cat /etc/systemd/system/ncc-celery-worker.service
```

It should show YOUR paths, for example:
```
User=db
WorkingDirectory=/home/db/projects/NCC-Dev/NCC
Environment=PATH=/home/db/projects/NCC-Dev/NCC/.venv/bin
ExecStart=/home/db/projects/NCC-Dev/NCC/.venv/bin/celery ...
```

Or if using different paths:
```
User=ncc
WorkingDirectory=/opt/app/ncc
Environment=PATH=/opt/app/ncc/.venv/bin
ExecStart=/opt/app/ncc/.venv/bin/celery ...
```

---

## Step 8: Enable and Start the Service

```bash
# Reload systemd daemon to register new service
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable ncc-celery-worker

# Start the service
sudo systemctl start ncc-celery-worker

# Check status
systemctl status ncc-celery-worker
```

Expected output:
```
● ncc-celery-worker.service - NCC EDMS Celery Worker
     Loaded: loaded (/etc/systemd/system/ncc-celery-worker.service; enabled; preset: enabled)
     Active: active (running) since ...
   Main PID: XXXX (celery)
```

---

## Step 9: Verify Service is Working

```bash
# Check service status
systemctl status ncc-celery-worker

# Check logs
journalctl -u ncc-celery-worker -f

# Should see:
# - Connected to redis://localhost:6379/0
# - Registered tasks loaded
# - Ready to accept tasks
```

---

## Complete Automated Setup Script (Path-Flexible)

Save this as `setup-celery-new-system.sh` on the new system:

```bash
#!/bin/bash

# ============================================
# CUSTOMIZE THESE VARIABLES FOR YOUR SYSTEM
# ============================================
PROJECT_USER="db"                                    # User to run celery
PROJECT_PATH="/home/db/projects/NCC-Dev/NCC"       # Full project path
VENV_NAME=".venv"                                   # Virtual env folder name

# Derived paths (don't change)
VENV_PATH="$PROJECT_PATH/$VENV_NAME"
PROJECT_PARENT=$(dirname "$PROJECT_PATH")

# ============================================
# END OF CONFIGURATION
# ============================================

set -e  # Exit on error

echo "=== NCC Celery Worker Setup on Fresh System ==="
echo "USER: $PROJECT_USER"
echo "PATH: $PROJECT_PATH"
echo "VENV: $VENV_PATH"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Step 1: Install dependencies
echo -e "${BLUE}Step 1: Installing system dependencies...${NC}"
sudo apt update
sudo apt install -y python3 python3-venv python3-pip git

# Step 2: Create user if doesn't exist
echo -e "${BLUE}Step 2: Ensuring $PROJECT_USER user exists...${NC}"
if ! id -u $PROJECT_USER > /dev/null 2>&1; then
    echo "Creating user '$PROJECT_USER'..."
    sudo useradd -m -s /bin/bash $PROJECT_USER
else
    echo "User '$PROJECT_USER' already exists"
fi

# Step 3: Create directories
echo -e "${BLUE}Step 3: Creating project directories at $PROJECT_PARENT...${NC}"
sudo mkdir -p "$PROJECT_PARENT"
sudo chown -R $PROJECT_USER:$PROJECT_USER "$PROJECT_PARENT"

# Step 4: Setup venv and install deps
echo -e "${BLUE}Step 4: Setting up Python virtual environment at $VENV_PATH...${NC}"
cd "$PROJECT_PATH"

# Create venv as project user
sudo -u $PROJECT_USER python3 -m venv "$VENV_NAME"

# Install packages as project user
sudo -u $PROJECT_USER "$VENV_PATH/bin/pip" install --upgrade pip
sudo -u $PROJECT_USER "$VENV_PATH/bin/pip" install -r requirements.txt

# Step 5: Create .env if doesn't exist
if [ ! -f "$PROJECT_PATH/.env" ]; then
    echo -e "${BLUE}Step 5: Creating .env file...${NC}"
    sudo -u $PROJECT_USER cp "$PROJECT_PATH/.env.example" "$PROJECT_PATH/.env" 2>/dev/null || \
    sudo -u $PROJECT_USER tee "$PROJECT_PATH/.env" > /dev/null << 'ENVEOF'
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0
CELERY_WORKER_CONCURRENCY=4
CELERY_WORKER_PREFETCH_MULTIPLIER=1
CELERY_WORKER_MAX_TASKS_PER_CHILD=1000
CELERY_TASK_TIME_LIMIT=3600
CELERY_TASK_SOFT_TIME_LIMIT=3300
ENVEOF
fi

# Step 6: Create systemd service
echo -e "${BLUE}Step 6: Creating systemd service with paths...${NC}"
echo "User: $PROJECT_USER"
echo "Path: $PROJECT_PATH"
echo "Venv: $VENV_PATH"

sudo tee /etc/systemd/system/ncc-celery-worker.service > /dev/null << SVCEOF
[Unit]
Description=NCC EDMS Celery Worker
After=network.target

[Service]
Type=exec
User=$PROJECT_USER
Group=$PROJECT_USER
WorkingDirectory=$PROJECT_PATH
Environment=PATH=$VENV_PATH/bin
EnvironmentFile=$PROJECT_PATH/.env
ExecStart=$VENV_PATH/bin/celery -A src.app.core.celery_app worker --loglevel=info --concurrency=4 --max-tasks-per-child=1000
ExecReload=/bin/kill -s HUP \$MAINPID
KillSignal=SIGTERM
TimeoutStopSec=30
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ncc-celery-worker

NoNewPrivileges=true
PrivateTmp=false

[Install]
WantedBy=multi-user.target
SVCEOF

# Step 7: Enable and start service
echo -e "${BLUE}Step 7: Enabling and starting service...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable ncc-celery-worker
sudo systemctl start ncc-celery-worker

# Step 8: Verify
echo -e "${BLUE}Step 8: Verifying installation...${NC}"
sleep 2
systemctl status ncc-celery-worker

echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "Service Configuration:"
echo "  User: $PROJECT_USER"
echo "  Path: $PROJECT_PATH"
echo "  Venv: $VENV_PATH"
echo ""
echo "Service status:"
systemctl status ncc-celery-worker --no-pager
echo ""
echo "View logs with:"
echo "  journalctl -u ncc-celery-worker -f"
```

**Usage with custom paths:**

```bash
# Edit script to set your paths
nano setup-celery-new-system.sh

# Change these lines to your system:
# PROJECT_USER="db"                                    # e.g., "ncc", "app", "celery"
# PROJECT_PATH="/home/db/projects/NCC-Dev/NCC"       # e.g., "/opt/app/ncc"

# Run the script
chmod +x setup-celery-new-system.sh
./setup-celery-new-system.sh
```

---

## System Comparison: Source vs Fresh (with Different Paths)

| Component | Source System | Fresh System 1 | Fresh System 2 |
|-----------|---------------|----------------|----------------|
| **User** | db | db | ncc |
| **Home Path** | /home/db | /home/db | /opt/app |
| **Project Path** | /home/db/projects/NCC-Dev/NCC | /home/db/projects/ncc | /opt/app/ncc-worker |
| **Venv Path** | .../NCC/.venv | .../ncc/.venv | .../ncc-worker/.venv |
| **Venv Python** | .../NCC/.venv/bin/python | .../ncc/.venv/bin/python | .../ncc-worker/.venv/bin/python |
| **Celery Binary** | .../NCC/.venv/bin/celery | .../ncc/.venv/bin/celery | .../ncc-worker/.venv/bin/celery |
| **.env Location** | .../NCC/.env | .../ncc/.env | .../ncc-worker/.env |
| **Service Name** | ncc-celery-worker | ncc-celery-worker | ncc-celery-worker |
| **Service Config** | DIFFERENT | DIFFERENT | DIFFERENT |

**Key Point**: Service name stays the same, but paths in the service file are different!

---

## Path Customization Examples

Here are real examples of how paths change on different systems:

### Example 1: Standard Home Directory (Like Current System)
```bash
PROJECT_USER="db"
PROJECT_PATH="/home/db/projects/NCC-Dev/NCC"
VENV_PATH="/home/db/projects/NCC-Dev/NCC/.venv"

# Service will have:
User=db
WorkingDirectory=/home/db/projects/NCC-Dev/NCC
ExecStart=/home/db/projects/NCC-Dev/NCC/.venv/bin/celery ...
```

### Example 2: Application Server Path
```bash
PROJECT_USER="ncc"
PROJECT_PATH="/opt/app/ncc"
VENV_PATH="/opt/app/ncc/.venv"

# Service will have:
User=ncc
WorkingDirectory=/opt/app/ncc
ExecStart=/opt/app/ncc/.venv/bin/celery ...
```

### Example 3: Local Server Path
```bash
PROJECT_USER="celery"
PROJECT_PATH="/usr/local/ncc-celery/app"
VENV_PATH="/usr/local/ncc-celery/app/.venv"

# Service will have:
User=celery
WorkingDirectory=/usr/local/ncc-celery/app
ExecStart=/usr/local/ncc-celery/app/.venv/bin/celery ...
```

### Example 4: EC2 Amazon Linux
```bash
PROJECT_USER="ec2-user"
PROJECT_PATH="/home/ec2-user/ncc-app"
VENV_PATH="/home/ec2-user/ncc-app/.venv"

# Service will have:
User=ec2-user
WorkingDirectory=/home/ec2-user/ncc-app
ExecStart=/home/ec2-user/ncc-app/.venv/bin/celery ...
```

---

Before starting ncc-celery-worker on fresh system:

```bash
# Redis (required)
sudo systemctl start redis-server
redis-cli ping  # Should return PONG

# PostgreSQL (if using db tasks)
sudo systemctl start postgresql
psql -U ncc_user -d ncc_admin -c "SELECT 1"

# Application API (if needed)
sudo systemctl start ncc-api
```

---

## Troubleshooting on Fresh System

### Issue: Virtual Environment Not Found

```bash
# Solution: Recreate venv
cd /home/db/projects/NCC-Dev/NCC
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Issue: Redis Connection Error

```bash
# Check Redis status
redis-cli ping

# Start Redis if not running
sudo systemctl start redis-server

# Check Redis config
redis-cli CONFIG GET "*"
```

### Issue: User Permissions

```bash
# Fix ownership
sudo chown -R db:db /home/db/projects/NCC-Dev/NCC
sudo chown -R db:db /var/run/ncc-celery/  # if exists
```

### Issue: Module Not Found

```bash
# Check installed packages
.venv/bin/pip list

# Reinstall requirements
.venv/bin/pip install -r requirements.txt --force-reinstall
```

---

## Verification Checklist

After setup is complete:

- [ ] User `db` exists
- [ ] Project directory exists at `/home/db/projects/NCC-Dev/NCC`
- [ ] Virtual environment created
- [ ] `requirements.txt` packages installed
- [ ] `.env` file configured
- [ ] `.venv/bin/celery` executable exists
- [ ] Redis is running
- [ ] Systemd service file created
- [ ] Service enabled on boot
- [ ] Service status shows "active (running)"
- [ ] Logs show "Connected to redis://localhost:6379/0"

---

## Quick Reference Commands

```bash
# Start service
sudo systemctl start ncc-celery-worker

# Stop service
sudo systemctl stop ncc-celery-worker

# Restart service
sudo systemctl restart ncc-celery-worker

# Check status
systemctl status ncc-celery-worker

# View logs (live)
journalctl -u ncc-celery-worker -f

# View last 50 lines
journalctl -u ncc-celery-worker -n 50

# Enable on boot
sudo systemctl enable ncc-celery-worker

# Disable on boot
sudo systemctl disable ncc-celery-worker

# Reload systemd
sudo systemctl daemon-reload

# Check if service is enabled
systemctl is-enabled ncc-celery-worker
```

---

## Final Configuration Summary

**Service Name**: `ncc-celery-worker.service` *(ALWAYS same)*  
**Service Location**: `/etc/systemd/system/ncc-celery-worker.service` *(ALWAYS same)*  

**Paths** *(Change based on your system)*:
- **User**: Customize (db, ncc, celery, ec2-user, etc.)
- **Project Path**: Customize (/home/db/..., /opt/app/..., etc.)
- **Venv Path**: Project Path + /.venv
- **Config File**: Project Path + /.env

**Example configs for different systems**:
```
System 1: User=db, Path=/home/db/projects/NCC-Dev/NCC
System 2: User=ncc, Path=/opt/app/ncc  
System 3: User=celery, Path=/usr/local/ncc/app
System 4: User=ec2-user, Path=/home/ec2-user/ncc-app
```

All use the same service name: `ncc-celery-worker.service`

---

## Need Help?

Check logs for errors:
```bash
journalctl -u ncc-celery-worker -n 100 --no-pager
```

For detailed error messages:
```bash
journalctl -u ncc-celery-worker -e
```

---

**Last Updated**: January 27, 2026
