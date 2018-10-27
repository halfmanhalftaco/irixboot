# irixboot
# vagrant configuration
# (c) 2018 Eric Dodd
# https://github.com/unxmaal/irixboot
# LICENSE: MIT

#####
# Change these settings to match your environment
#####

irixversion = '6.5'

# installmethod can be via CD images or FTP
installmethod = "ftp"
installmirror = "ftp.irisware.com"

clientname = 'indy'
clientdomain = 'sgi.unxmaal.com'
clientip = '192.168.0.77'
clientether = '08:00:69:0e:af:65'
netmask = '255.255.255.0'

# this should be the secondary physical interface on your VM host to 
#   which you have a cable connected from your SGI machine
bridgenic = 'en0'
# This is the VM's IP on the point to point connection between it 
#   and the SGI
hostip = '192.168.0.1'



##### 
# end of settings
#####


installdisk = "disk.vdi"

Vagrant.configure("2") do |config|
  config.vm.box = "debian/contrib-jessie64"
  config.vm.box_version = "8.11.0"
  #config.vm.network "public_network"
  config.vm.post_up_message = [ "irixboot configuration stage" ]
  
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
  if installmethod == "cd"
    # Create XFS-formatted disk for extracted CD images
    config.vm.provider "virtualbox" do |v|
      unless File.exist?(installdisk)
        v.customize ['createhd', '--filename', installdisk, '--size', 50 * 1024]
      end
      v.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', installdisk]
    end
    config.vm.provision "file", source: "files/nekodeps_custom.0.0.1.tardist", destination: ""
    # Run local setup scripts
    config.vm.provision "shell", path: "scripts/init.sh",run: 'always', args: installmethod
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
  config.vm.provision "shell", path: "scripts/init.sh", run: 'always', args: installmethod
  config.vm.provision "shell", path: "scripts/boot.sh", run: 'always', args: [clientname, clientip, clientether, clientdomain, netmask, hostip, installmethod]
end