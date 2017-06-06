irixboot
========

irixboot is designed to quickly configure a disposable VM to boot a specific version of the SGI IRIX installer over the network on an SGI machine without a whole lot of fuss. There is no need to manually extract CD images from an IRIX machine or compile kernels to get EFS support, configure BOOTP, etc.

This sets up some configuration in the VM that is not secure or may interfere with other network services (e.g. DHCP) so please don't leave it running long-term. I recommend only attaching the network interface to an isolated network for this purpose and then `vagrant halt` or `vagrant destroy` the VM when you are done installing.

## Background

After acquiring an SGI Indy, which doesn't have a CD-ROM drive, I was seeking ways to boot/install IRIX over the network. 

I was inspired to create this after being pointed at the [DINA VM](http://shiftleft.com/mirrors/dina.harrydebug.com/) and being frustrated that it didn't have EFS drivers to read the IRIX CD-ROMs built in. I figured a more repeatable/disposable build using Vagrant would be the best way to handle this problem.

The irixboot VM provides the following services:

* BOOTP server (via isc-dhcp)
* TFTP server (via tftpd-hpa)
* RSH server (via rsh-server)

## Requirements

* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant](https://www.vagrantup.com/downloads.html)
* IRIX Install disc images

I am not sure what range of IRIX versions this will work with, or what SGI machines are compatible. I have only tested the following machines and IRIX versions:

* SGI Indy R4600
* SGI Indigo2 R4400
* IRIX 5.3
* IRIX 6.2
* IRIX 6.5.22

Additionally, I've only tested the Vagrant configuration on Windows 10 with VirtualBox. Some changes changes will definitely be needed to support other hypervisors, but should work with VirtualBox on other systems as long as the 'bridgenic' parameter is updated correctly. You can list your system's interfaces as seen by Virtualbox with `VBoxManage list bridgedifs` - the `Name` parameter is the one it expects.


## Usage

All that is needed to configure a boot environment is to populate the `irix/` directory with CD images (described below) and edit the `Vagrantfile` with your environment/client settings, then `vagrant up`.

## Settings

These settings are found at the top of `Vagrantfile`. Edit them to suit your environment.

```
irixversion = '6.5.22'
```
Set this to the version of IRIX you are installing. You must create a subdirectory in the `irix` directory with the same name.

```
clientname = 'indy'
clientip = '192.168.42.100'
clientether = '08:00:69:CA:FE:42'
```
These should be obvious - the network parameters for the target SGI machine.

```
domain = 'sgi.halfmanhalftaco.com'
netmask = '255.255.255.0'
```
These are the common network parameters for your subnet.

```
hostip = '192.168.42.5'
bridgenic = 'Intel(R) Ethernet Connection (2) I219-V - VLAN : LAN'
```
This is the network configuration for the server VM. the `bridgenic` parameter is the interface name for the NIC (on your host machine - not in the VM) that is connected to the network your target is on.

NOTE: This VM starts a BOOTP server that will listen to broadcast traffic on your network segment. It is configured to ignore anything but the target system but if you have another DHCP/BOOTP server on the LAN segment it may interfere. You may want to temporarily disable DHCP/BOOTP if you are running that service on your LAN segment.

## IRIX Install Discs

Once you've imaged your SGI discs, you need to populate the `irix/` directory for irixboot to extract them. Within `irix/` should be directories with the names of the IRIX versions they contain. These version numbers must match what you configured earlier for the `irixversion` parameter in `Vagrantfile`. Within each of those directories must be subdirectories of arbitrary name, and any number of disk image files within those. Multiple files in one subdirectory will be extracted on top of each other. This is useful to avoid having to `open` several distributions from the installer, since some (all?) of the disc sets can be combined (e.g. Overlays, Foundation, etc.).

An example hierarchy:

* irix/
  * 6.5.22/
    * foundation/
		* IRIX 6.5 Foundation 1.img
		* IRIX 6.5 Foundation 2.img
	* overlay/
		* IRIX 6.5.22 Overlay 1.img
		* IRIX 6.5.22 Overlay 2.img
		* IRIX 6.5.22 Overlay 3.img
	* nfs/
		* ONC-NFS.img
	* app/
		* Applications Nov 2003.img

## Booting

###### caveat: I am not an SGI expert by any means, this is just based on my experience as to what works.

### fx (Partitioner)

If you need to boot `fx` to label/partition your disk, open the command monitor and issue the following command:

`bootp():/overlay/stand/fx.ARCS`

where `/overlay/stand/fx.ARCS` is a path relative to your selected IRIX version in the directory structure from above. Use `fx.ARCS` for R4xxx machines and `fx.64` for R5000+ machines (and others for older machines, I assume)

### sash (IRIX installer)
	
The installer can be reached through the monitor GUI as follows:

* At the maintenance boot screen, select "Install Software"
* If it prompts you for an IP address, enter the same address you entered into the Vagrantfile config for `clientip`.
* Use 'irixboot' as the install server hostname.
* For the installation path, this depends on your directory structure. If you use the structure example from above, you would use the path `overlay/dist`. Notice the lack of leading `/`.
* This should load the miniroot over the network and boot sash.
* To access the other distributions you extracted, use `open irixboot:<directory>/dist`.

# License

MIT License

Copyright (c) 2017 Andrew Liles

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.