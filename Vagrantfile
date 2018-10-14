# irixboot
# vagrant configuration
# (c) 2018 Andrew Liles
# https://github.com/halfmanhalftaco/irixboot
# LICENSE: MIT

#####
# Change these settings to match your environment
#####

irixversion = '6.5'

# installmethod can be via CD images or FTP
installmethod = "ftp"
installmirror = "ftp.irisware.com"

clientname = 'indy'
clientdomain = 'sgi.halfmanhalftaco.com'
clientip = '192.168.0.100'
clientether = '08:00:69:CA:FE:42'
netmask = '255.255.255.0'

hostip = '192.168.0.193'
bridgenic = 'eth0'

##### 
# end of settings
#####


installdisk = "disk.vdi"

Vagrant.configure("2") do |config|
  config.vm.box = "debian/contrib-jessie64"
  config.vm.box_version = "8.11.0"
  #config.vm.network "public_network"
  config.vm.post_up_message = [ "irixboot configuration stage" ]
  
  config.vm.provider "virtualbox" do |v|
	  unless File.exist?(installdisk)
		  v.customize ['createhd', '--filename', installdisk, '--size', 50 * 1024]
	  end
	  v.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', installdisk]
  end

  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
  if installmethod == "cd"
    config.vm.provision "shell", path: "scripts/init.sh"
    config.vm.provision "shell", path: "scripts/dist.sh", run: 'always', args: irixversion
  elsif installmethod == "ftp"
    config.vm.provision "shell", path: "scripts/ftpdist.sh", run: 'always', args: irixversion
  end
end


Vagrant.configure("2") do |config|
  config.vm.box = "debian/contrib-jessie64"
  config.vm.box_version = "8.11.0"
  config.vm.network "public_network", ip: hostip, bridge: bridgenic
  config.vm.post_up_message = [ "irixboot running at ", hostip ]

  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
  config.vm.provision "shell", path: "scripts/init.sh"
  config.vm.provision "shell", path: "scripts/boot.sh", run: 'always', args: [clientname, clientip, clientether, clientdomain, netmask, hostip]
end