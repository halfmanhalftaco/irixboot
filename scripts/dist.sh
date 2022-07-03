#!/bin/bash

# irixboot
# dist.sh - populate local disk with IRIX install images
# (c) 2018 Andrew Liles
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
	
	mkfs.xfs -f /dev/sdb1
	mkdir -p /irix 
	sed -i '/\/irix/d' /etc/fstab
	echo `blkid /dev/sdb1 | awk '{print$2}' | sed -e 's/"//g'` /irix xfs noatime,nobarrier 0 0 >> /etc/fstab
	mount /irix
	copydist
}


### Extract an image from the given source file to the specified directory
function extractefs {
	mount -t efs "$1" /mnt
	rsync -aq /mnt/ $2
	umount /mnt
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

		# Convert BIN/CUE files (e.g. archive.org) to raw EFS
		for i in /vagrant/irix/$IRIXVERS/$SUB/*.bin
		do
			echo "Converting BIN/CUE image \"$i\" to ISO..."
			i_bn="${i%%.bin}"
			img="${i_bn}.img"
			cue="${i_bn}.cue"
			# Skip .bin missing .cue, or already converted
			# We assume there is only one "ISO" image generated.
			if [ -f "$cue" ] && [ ! -f "${i_bn}-01.iso" ] ; then
				# This will create ${i_bn}-01.iso
				bchunk "$i" "$cue" "${i_bn}-"
			fi
		done

		for i in /vagrant/irix/$IRIXVERS/$SUB/*
		do
			case "$( basename "$i" )" in
			*.tar.gz)	# Tar/Gzip
				echo "Extracting files from \"$i\"..."
				if [ ! -d /irix/$SUB ]; then
					mkdir /irix/$SUB
				fi
				tar -C /irix/$SUB -xzpf "$i"
				;;
			*.bin|*.cue)	# BIN/CUE image -- ignore
				echo "Ignoring BIN/CUE image \"$i\""
				;;
			*.iso)		# "ISO" image
				echo "Copying files from \"$i\"..."
				# loop-mount the "ISO" image, it will
				# be a raw SGI disklabel (i.e. like a HDD),
				# not really an ISO9660 image.  We call it an "ISO"
				# because bchunk does -- it won't let us call it
				# anything else.
				d="$( losetup -f -r --show "$i" )"
				partprobe ${d}
				# EFS image is in partition 8
				extractefs ${d}p8 /irix/$SUB
				# Unmount loop image
				losetup -d $d
				;;
			*)		# EFS image (assumed)
				echo "Copying files from \"$i\"..."
				# To keep extractefs simple, we'll do our own
				# loop-mount here.
				d="$( losetup -f -r --show "$i" )"
				extractefs "$d" /irix/$SUB
				# Unmount loop image
				losetup -d $d
				;;
			esac
		done
	done
	
	echo $IRIXVERS > /irix/.irixboot
	chown -R guest.guest /irix
}

### Check if disk is already mounted from previous provisioning
### and check whether it is the correct version
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
