#!/bin/sh
#----------------------- THIS SCRIPT CANNOT RUN NOT AS ROOT

User="{YOUR_LINUX_USERNAME_HERE}"

#-----------------------
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 
(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/$User/.profile
brew tap vultr/vultr-cli
brew install vultr-cli 