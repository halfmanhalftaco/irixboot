#!/bin/bash

# irixboot
# boot.sh - start services on each boot
# (c) 2017 Andrew Liles
# https://github.com/halfmanhalftaco/irixboot
# LICENCE: MIT

HOST_NAME="$1"
DOMAIN="$2"
HOST_IP="$3"
CLIENT_IP="$4"
CLIENT_MAC="$5"
NETMASK="$6"

### Calculate network address
### http://stackoverflow.com/questions/15429420/given-the-ip-and-netmask-how-can-i-calculate-the-network-address-using-bash
IFS=. read -r i1 i2 i3 i4 <<< $HOST_IP
IFS=. read -r m1 m2 m3 m4 <<< $NETMASK
NETWORK=$(printf "%d.%d.%d.%d\n" "$((i1 & m1))" "$((i2 & m2))" "$((i3 & m3))" "$((i4 & m4))")

### rename machine
echo "irixboot" > /etc/hostname
cp /etc/hosts.orig /etc/hosts
sed -i "s/contrib-jessie\.raw/irixboot.$DOMAIN/" /etc/hosts
sed -i 's/contrib-jessie/irixboot/' /etc/hosts
/etc/init.d/hostname.sh


### populate DNS, rhosts, hosts.equiv
echo "Populating /etc/hosts, hosts.equiv, .rhosts..."
sed -i 's/^#interface.*/interface=eth1/' /etc/dnsmasq.conf
echo $CLIENT_IP $HOST_NAME.$DOMAIN >> /etc/hosts
echo $HOST_IP irixboot.$DOMAIN >> /etc/hosts
su guest -c "echo $HOST_NAME.$DOMAIN root > ~/.rhosts"
echo "$HOST_NAME" > /etc/hosts.equiv
echo "irixboot" >> /etc/hosts.equiv

### Configure DHCP/BOOTP
echo "Configuring BOOTP..."
sed -i 's/INTERFACES.*/INTERFACES=eth1/' /etc/default/isc-dhcp-server
cat << EOF > /etc/dhcp/dhcpd.conf
subnet $NETWORK netmask $NETMASK { ignore unknown-clients; }

host $HOST_NAME {
	hardware ethernet $CLIENT_MAC;
	fixed-address $CLIENT_IP;
	option domain-name-servers $HOST_IP;
	option domain-name "$DOMAIN";
	}
EOF

echo "Starting dnsmasq..."
service dnsmasq start

echo "Starting isc-dhcp-server..."
service isc-dhcp-server start

echo "Starting tftpd-hpa..."
service tftpd-hpa start

echo "Starting inetd (rsh)..."
service openbsd-inetd start

echo "Ready to network boot '$HOST_NAME'"