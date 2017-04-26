#!/bin/bash

# irixboot
# init.sh - install packages and adjust settings
# (c) 2017 Andrew Liles
# https://github.com/halfmanhalftaco/irixboot
# LICENCE: MIT

echo "Initializing irixboot..."

echo "Renaming machine to 'irixboot'..."
echo "irixboot" > /etc/hostname
sed -i 's/contrib-jessie/irixboot/g' /etc/hosts
/etc/init.d/hostname.sh
invoke-rc.d rsyslog restart

### keep a copy of the hosts file for subsequent boots
cp /etc/hosts /etc/hosts.irixboot

echo "Installing packages..."
apt-get -qq -y install tftpd-hpa isc-dhcp-server rsh-server dnsmasq mksh parted xfsprogs rsync tcpdump

### disable upstream nameserver (now that we don't need it anymore)
sed -i 's/^nameserver/#nameserver/' /etc/resolv.conf

### only bind to our bridge interface for dnsmasq & dhcp
sed -i 's/^#interface.*/interface=eth1/' /etc/dnsmasq.conf
sed -i 's/INTERFACES.*/INTERFACES=eth1/' /etc/default/isc-dhcp-server

echo "Adjusting kernel IPv4 settings..."
echo "net.ipv4.ip_no_pmtu_disc=1" >> /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range = 2048 32767" >> /etc/sysctl.conf
sysctl -p

echo "Enabling efs/xfs kernel modules..."
echo "efs" >> /etc/modules
echo "xfs" >> /etc/modules
modprobe -a efs xfs

echo "Disabling services..."
invoke-rc.d openbsd-inetd stop > /dev/null 2>&1
update-rc.d openbsd-inetd disable > /dev/null 2>&1
invoke-rc.d isc-dhcp-server stop > /dev/null 2>&1
update-rc.d isc-dhcp-server disable > /dev/null 2>&1
invoke-rc.d tftpd-hpa stop > /dev/null 2>&1
update-rc.d tftpd-hpa disable > /dev/null 2>&1
invoke-rc.d dnsmasq stop > /dev/null 2>&1
update-rc.d dnsmasq disable > /dev/null 2>&1

echo "Configuring tftpd-hpa..."
mkdir /irix
sed -i 's/^TFTP_DIRECTORY.*$/TFTP_DIRECTORY="\/irix"/' /etc/default/tftpd-hpa
sed -i 's/^TFTP_OPTIONS.*$/TFTP_OPTIONS=\"--secure -vvvv\"/' /etc/default/tftpd-hpa

echo "Creating 'guest' user..."
if ! id -u guest >/dev/null 2>&1; then useradd -s /bin/ksh -d /irix guest; fi