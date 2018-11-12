
# Set the default brightness (maximum 7)
brightnessctl s 5

# Execute the Reform setup script on login
if [ ! -f /root/.reform-setup-completed ]; then
  /root/setup
fi
