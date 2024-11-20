#!/bin/bash

# Define the repository directory
REPO_DIR="~/Desktop/slideshows"

# Define the path to the local webpage
WEBPAGE_PATH="$REPO_DIR/main_desk_slideshow/index.html"

# Ensure the repository exists
if [ ! -d "$REPO_DIR/.git" ]; then
    echo "Cloning repository..."
    git clone https://github.com/UofL-CSE-IT/slideshows "$REPO_DIR"
fi

# Navigate to the repository directory
cd "$REPO_DIR" || exit 1

# Fetch the latest changes
git fetch

# Check for updates
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse @{u})

if [ "$LOCAL" != "$REMOTE" ]; then
    echo "Updates detected. Pulling latest changes..."
    git pull

    # Kill existing Firefox kiosk instances
    echo "Restarting Firefox kiosk mode..."
    pkill -f "firefox.*--kiosk"

    # Start Firefox in kiosk mode
    nohup firefox --kiosk "file://$WEBPAGE_PATH" &>/dev/null &
else
    echo "No updates detected."
fi

# Ensure Firefox is running
if ! pgrep -f "firefox.*--kiosk" > /dev/null; then
    echo "Starting Firefox in kiosk mode..."
    nohup firefox --kiosk "file://$WEBPAGE_PATH" &>/dev/null &
fi
