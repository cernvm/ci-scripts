#/bin/bash


set -e

sudo -u vagrant brew update
sudo -u vagrant brew install jq wget Caskroom/cask/osxfuse
