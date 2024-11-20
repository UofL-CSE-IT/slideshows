#!/bin/bash

# Define the repository directory
REPO_DIR="/home/uoflit/Desktop/slideshows"


# Define the path to the local webpage
WEBPAGE_PATH="$REPO_DIR/main_desk_slideshow/index.html"

# Navigate to the repository directory
cd "$REPO_DIR" || exit
echo "Navigated to the repository directory."
# Fetch the latest changes
git fetch

# Check if there are updates
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse @{u})

if [ "$LOCAL" != "$REMOTE" ]; then
    echo "Updates detected. Pulling latest changes..."
    git pull

    # Reload the Firefox kiosk mode
    echo "Reloading webpage..."
    pkill -f "firefox.*--kiosk" # Kill the existing Firefox instance
    nohup firefox --kiosk "file://$WEBPAGE_PATH" &>/dev/null & 
else
    echo "No updates detected."
fi


# /usr/bin/firefox --kiosk /home/uoflit/Desktop/slideshow/index.html