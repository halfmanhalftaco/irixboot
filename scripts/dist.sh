#!/bin/bash

# irixboot
# dist.sh - populate local disk with IRIX install images
# (c) 2017 Andrew Liles
# https://github.com/halfmanhalftaco/irixboot
# LICENCE: MIT

IRIXVERS="$1"

### Partition/Format our data disk (will hold IRIX distribution)
function formatdisk {
	echo "Formatting /dev/sdb..."
	
	if [ ! -e /dev/sdb1 ]
	then
		parted /dev/sdb mklabel msdos
		parted /dev/sdb mkpart primary 512 100%
		partprobe /dev/sdb
		sleep 5
	fi
	
	mkfs.xfs /dev/sdb1
	mkdir -p /irix 
	sed -i '/\/irix/d' /etc/fstab
	echo `blkid /dev/sdb1 | awk '{print$2}' | sed -e 's/"//g'` /irix xfs noatime,nobarrier 0 0 >> /etc/fstab
	mount /irix
	copydist
}


### Populate the distribution disk with CD images stored in irix/<IRIX VERSION>
### Images must be in subfolders - multiple images in a directory will be copied on top of one another
### e.g.
### irix/6.5.22/foundation/IRIX 6.5 Foundation 1.img
### irix/6.5.22/foundation/IRIX 6.5 Foundation 2.img
### irix/6.5.22/overlay/IRIX 6.5.22 Overlay 1.img
### irix/6.5.22/overlay/IRIX 6.5.22 Overlay 2.img
### irix/6.5.22/overlay/IRIX 6.5.22 Overlay 3.img

function copydist {
	if [ ! -d /vagrant/irix/$IRIXVERS ]; then
		echo "Error: no iso directory for version $IRIXVERS"
		exit 1
	fi

	cd /vagrant/irix/$IRIXVERS

	echo "Processing images for version $IRIXVERS"

	for d in */
	do
		SUB=${d::-1}
		mkdir -p /irix/$SUB

		for i in /vagrant/irix/$IRIXVERS/$SUB/*
		do
			echo "Copying files from \"$i\"..."
			mount -o loop -t efs "$i" /mnt
			rsync -aq /mnt/ /irix/$SUB
			umount /mnt
		done
	done
	
	echo $IRIXVERS > /irix/.irixboot
	
	### Create user that the IRIX installer will rsh as (guest) and assign ownership
	if ! id -u guest >/dev/null 2>&1; then useradd -s /bin/ksh -d /irix guest; fi
	chown -R guest.guest /irix
}

### Check if disk is already mounted from previous provisioning
### and check whether it is the correction version
echo "Checking IRIX distribution..."

if [ -f /irix/.irixboot ]; then
	OLDVERS=$(cat /irix/.irixboot)
	if [ "$OLDVERS" == "$IRIXVERS" ]; then
		echo "Found an existing disk with $IRIXVERS"
		exit 0
	else
		echo "Existing disk contains IRIX $OLDVERS, replacing with $IRIXVERS..."
	fi
else
	echo "No IRIX files found on local disk, copying from disk images..."
fi

formatdisk
