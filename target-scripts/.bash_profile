# Set the default brightness (maximum 7)
brightnessctl s 5

export PATH=$PATH:/usr/games

# Execute the Reform setup script on login
if [ ! -f /root/.reform-setup-completed ]; then
  /root/setup
fi
