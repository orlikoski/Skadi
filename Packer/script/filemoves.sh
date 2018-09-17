#!/bin/bash

echo "Moving default files around"
# Make Skadi background the default background
sudo cp /tmp/SkadiBackground.jpg /usr/share/backgrounds/SkadiBackground.jpg; \
sudo chmod 644 /usr/share/backgrounds/SkadiBackground.jpg; \
sudo ln -fs /usr/share/backgrounds/SkadiBackground.jpg /usr/share/backgrounds/DefaultBackground.jpg

# Add Skadi default bookmarks to Desktop
sudo mkdir -p /home/skadi/.mozilla/firefox/eozwibc3.default/
sudo chown -R skadi:skadi /home/skadi/.mozilla
sudo cp /tmp/places.sqlite /home/skadi/.mozilla/firefox/eozwibc3.default/places.sqlite
sudo chmod 644 /home/skadi/.mozilla/firefox/eozwibc3.default/places.sqlite
