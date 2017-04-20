#!/bin/bash

# irixboot
# init.sh - install packages and adjust settings
# (c) 2017 Andrew Liles
# https://github.com/halfmanhalftaco/irixboot
# LICENCE: MIT

echo "Initializing irixboot..."

echo "Installing packages..."
apt-get -yqq install tftpd-hpa isc-dhcp-server rsh-server dnsmasq mksh parted xfsprogs rsync tcpdump

### disable upstream nameserver (now that we don't need it anymore)
sed -i 's/^nameserver/#nameserver/' /etc/resolv.conf

### keep a copy of the original hosts file for subsequent boots
cp /etc/hosts /etc/hosts.orig

echo "Adjusting kernel IPv4 settings..."
### Adjust IPv4 kernel settings to agree with SGI
echo << EOF >> /etc/sysctl.conf
net.ipv4.ip_no_pmtu_disc = 1
net.ipv4.ip_local_port_range = 2048 32767
EOF

sysctl -p

echo "Enabling efs/xfs kernel modules..."
### Enable filesystems we'll need later
echo "efs" >> /etc/modules
echo "xfs" >> /etc/modules
modprobe -a efs xfs

echo "Disabling services..."
### Disable & stop services until we are ready (start them in boot.sh)
invoke-rc.d openbsd-inetd stop
update-rc.d openbsd-inetd disable
invoke-rc.d isc-dhcp-server stop
update-rc.d isc-dhcp-server disable
invoke-rc.d tftpd-hpa stop
update-rc.d tftpd-hpa disable
invoke-rc.d dnsmasq stop
update-rc.d dnsmasq disable

### Configure tftpd directory
echo "Configuring tftpd-hpa..."
sed -i 's/^TFTP_DIRECTORY.*$/TFTP_DIRECTORY="\/irix"/' /etc/default/tftpd-hpa
sed -i 's/^TFTP_OPTIONS.*$/TFTP_OPTIONS=\"--secure -vvvv\"/' /etc/default/tftpd-hpa



echo "Initialization complete."
