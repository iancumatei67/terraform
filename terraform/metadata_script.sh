#!/bin/bash

# Update package lists
sudo apt-get update -y

# Install Apache
sudo apt-get install apache2 -y

# Create a simple HTML file for the website
echo "<html><head><title>Welcome to My Website</title></head><body><h1>Welcome to My Website</h1><p>This is a simple website hosted on an AWS instance.</p></body></html>" | sudo tee /var/www/html/index.html

# Restart Apache to apply changes
sudo systemctl restart apache2

