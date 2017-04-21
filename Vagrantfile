# irixboot
# vagrant configuration
# (c) 2017 Andrew Liles
# https://github.com/halfmanhalftaco/irixboot
# LICENSE: MIT

#####
# Change these settings to match your environment
#####

irixversion = '6.5.22'

clientname = 'indy'
clientdomain = 'sgi.halfmanhalftaco.com'
clientip = '192.168.42.100'
clientether = '08:00:69:CA:FE:42'
netmask = '255.255.255.0'

hostip = '192.168.42.5'
bridgenic = 'Intel(R) Ethernet Connection (2) I219-V - VLAN : LAN'

##### 
# end of settings
#####


installdisk = './installdisk.vdi'

Vagrant.configure("2") do |config|

  config.vm.box = "debian/contrib-jessie64"
  config.vm.box_version = "8.7.0"
  config.vm.network "public_network", ip: hostip, bridge: bridgenic
  config.vm.post_up_message = [ "irixboot running at ", hostip ]
  
  config.vm.provider "virtualbox" do |v|
	  unless File.exist?(installdisk)
		v.customize ['createhd', '--filename', installdisk, '--size', 50 * 1024]
	  end
	  v.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', installdisk]

	  # this workaround was required for my case because the config.vm.network :bridge argument does not see all of my interfaces for some reason.
	  # v.customize ['modifyvm', :id, '--bridgeadapter2', "Intel(R) Ethernet Connection (2) I219-V - VLAN : RETRO"]
  end
  
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
  config.vm.provision "shell", path: "scripts/init.sh"
  config.vm.provision "shell", path: "scripts/dist.sh", run: 'always', args: irixversion
  config.vm.provision "shell", path: "scripts/boot.sh", run: 'always', args: [clientname, clientip, clientether, clientdomain, netmask, hostip]
end
