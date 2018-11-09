#!/bin/bash

# irixboot
# init.sh - install packages and adjust settings
# (c) 2018 Andrew Liles
# https://github.com/halfmanhalftaco/irixboot
# LICENCE: MIT
_installmethod="$1"

echo "Initializing irixboot..."

echo "Renaming machine to 'irixboot'..."
echo "irixboot" > /etc/hostname
sed -i 's/contrib-jessie/irixboot/g' /etc/hosts
/etc/init.d/hostname.sh
invoke-rc.d rsyslog restart

### keep a copy of the hosts file for subsequent boots
cp /etc/hosts /etc/hosts.irixboot

echo "Installing packages..."
echo "deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main" >> /etc/apt/sources.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
apt-get update && apt-get -qq -y install tftpd-hpa isc-dhcp-server rsh-server dnsmasq mksh parted xfsprogs rsync tcpdump ansible git 

echo "Installing ansible plays"
pushd /home/vagrant
git clone https://github.com/unxmaal/irix_ansible.git
chown -R vagrant:vagrant irix_ansible
popd

echo "Generating IRIX_Ansible inventory file"
if [[ -e /tmp/inventory.ini ]] ; then
    cp /tmp/inventory.ini /home/vagrant/irix_ansible/inventory.ini
fi

# work around dnsmasq package bug with newer dns-zone-data package
mv /usr/share/dns/root.ds /usr/share/dns/root.ds.disabled

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
mkdir -p /irix
sed -i 's/^TFTP_DIRECTORY.*$/TFTP_DIRECTORY="\/irix"/' /etc/default/tftpd-hpa
sed -i 's/^TFTP_OPTIONS.*$/TFTP_OPTIONS=\"--secure -vvvv\"/' /etc/default/tftpd-hpa
echo "Creating 'guest' user..."
if ! id -u guest >/dev/null 2>&1; then 
    useradd -s /bin/ksh -d /irix guest
fi

