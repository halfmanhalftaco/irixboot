#!/bin/bash

# irixboot
# ftpdist.sh - populate local disk with IRIX install images

IRIXVERS="6.5"

# FTP urls
## IRIX foundation
foundation="http://ftp.irisware.net/pub/irix-os/irix-6.5/network-installs/foundation1.tar.gz
http://ftp.irisware.net/pub/irix-os/irix-6.5/network-installs/foundation2.tar.gz
http://ftp.irisware.net/pub/irix-os/irix-6.5/network-installs/onc3nfs.tar.gz"
## 6.5.30 overlays
overlay="http://ftp.irisware.net/pub/irix-os/irix-6.5/network-installs/irix-6.5.30/apps.tar.gz
http://ftp.irisware.net/pub/irix-os/irix-6.5/network-installs/irix-6.5.30/disc1.tar.gz
http://ftp.irisware.net/pub/irix-os/irix-6.5/network-installs/irix-6.5.30/disc2.tar.gz
http://ftp.irisware.net/pub/irix-os/irix-6.5/network-installs/irix-6.5.30/disc3.tar.gz"
## Dev
devel="http://ftp.irisware.net/pub/irix-os/devel/developmentlibraries.tar.gz
http://ftp.irisware.net/pub/irix-os/devel/mipspro-74/devf_13.tar.gz
http://ftp.irisware.net/pub/irix-os/devel/mipspro-74/mipspro-7.4.3m.tar
http://ftp.irisware.net/pub/irix-os/devel/mipspro-74/mipspro744update.tar.gz
http://ftp.irisware.net/pub/irix-os/devel/mipspro-74/mipspro_c.tar.gz
http://ftp.irisware.net/pub/irix-os/devel/mipspro-74/mipspro_cee.tar.gz
http://ftp.irisware.net/pub/irix-os/devel/mipspro-74/mipspro_cpp.tar.gz
http://ftp.irisware.net/pub/irix-os/devel/mipspro-74/mipsproap.tar.gz
http://ftp.irisware.net/pub/irix-os/devel/mipspro-74/prodev.tar.gz"
## Extras
extras="http://ftp.irisware.net/pub/irix-os/extras/perfcopilot.tar.gz
http://ftp.irisware.net/pub/irix-os/extras/sgipostscriptfonts.tar.gz"


### Partition/Format our data disk (will hold IRIX distribution)
formatdisk(){
	echo "Formatting /dev/sdb..."
	
	if [[ ! -e /dev/sdb1 ]]; then
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

fetchfile(){
	_url="$1"
	wget "${_url}"
}


copydist(){
	for _url in $foundation ; do 
		cd /irix
		echo "Processing archives for version $IRIXVERS"

		wget "${_url}"
		_an=$(basename "${_url}")
		tar xvzf "${_an}"
	done

	for _url in $overlay ; do 
		cd /irix
		echo "Processing archives for version $IRIXVERS"

		wget "${_url}"
		_an=$(basename "${_url}")
		tar xvzf "${_an}"
	done

	for _url in $devel ; do 
		cd /irix
		echo "Processing archives for version $IRIXVERS"

		wget "${_url}"
		_an=$(basename "${_url}")
		if [[ "$_an"  == "mipspro-7.4.3m.tar" ]] ; then
			tar xvf "${_an}"
		else
			tar xvzf "${_an}"
		fi
	done

	for _url in $extras ; do 
		cd /irix
		echo "Processing archives for version $IRIXVERS"

		wget "${_url}"
		_an=$(basename "${_url}")
		tar xvzf "${_an}"
	done
	
	echo "$IRIXVERS" > /irix/.irixboot
	chown -R guest.guest /irix
}


main(){
	### Check if disk is already mounted from previous provisioning
	### and check whether it is the correct version
	echo "Checking IRIX distribution..."

	mkdir -p /irix

	if [[ -f /irix/.irixboot ]]; then
		OLDVERS=$(cat /irix/.irixboot)
		if [[ "$OLDVERS" == "$IRIXVERS" ]]; then
			echo "Found an existing disk with $IRIXVERS"
			exit 0
		else
			echo "Existing disk contains IRIX $OLDVERS, replacing with $IRIXVERS..."
		fi
	else
		echo "No IRIX files found on local disk, copying from disk images..."
	fi

	formatdisk
}

main