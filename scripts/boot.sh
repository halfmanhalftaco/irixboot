#!/bin/bash

# irixboot
# boot.sh - start services on each boot
# (c) 2018 Andrew Liles
# https://github.com/halfmanhalftaco/irixboot
# LICENCE: MIT

CLIENT_NAME="$1"
CLIENT_IP="$2"
CLIENT_MAC="$3"
DOMAIN="$4"
NETMASK="$5"
HOST_IP="$6"

### Calculate network address
### http://stackoverflow.com/questions/15429420/given-the-ip-and-netmask-how-can-i-calculate-the-network-address-using-bash
IFS=. read -r i1 i2 i3 i4 <<< $HOST_IP
IFS=. read -r m1 m2 m3 m4 <<< $NETMASK
NETWORK=$(printf "%d.%d.%d.%d\n" "$((i1 & m1))" "$((i2 & m2))" "$((i3 & m3))" "$((i4 & m4))")

echo "Populating /etc/hosts, hosts.equiv, .rhosts..."
cp /etc/hosts.irixboot /etc/hosts
sed -i "s/\.raw/.$DOMAIN/" /etc/hosts
echo $CLIENT_IP $CLIENT_NAME.$DOMAIN >> /etc/hosts
echo $HOST_IP irixboot.$DOMAIN >> /etc/hosts
su guest -c "echo $CLIENT_NAME.$DOMAIN root > ~/.rhosts"
echo "$CLIENT_NAME" > /etc/hosts.equiv
echo "irixboot" >> /etc/hosts.equiv

echo "Configuring BOOTP..."
cat << EOF > /etc/dhcp/dhcpd.conf
subnet $NETWORK netmask $NETMASK { ignore unknown-clients; }

host $CLIENT_NAME {
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

echo "Ready to network boot '$CLIENT_NAME'"

## Display some useful info about the IRIX files
cd /irix

echo "*** Partitioners found:"
find . -name "fx.*" -type f | sed 's#./#bootp():/#'

echo "*** Paths for Inst:"
find . -name dist -type d | sed 's#./#irixboot:#'

