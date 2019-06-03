# -*- mode: ruby -*-
# vi: set ft=ruby :

required_plugins = %w( vagrant-vbguest vagrant-hostsupdater )
required_plugins.each do |plugin|
    exec "vagrant plugin install #{plugin}; vagrant #{ARGV.join(" ")}" unless Vagrant.has_plugin? plugin || ARGV[0] == 'plugin'
end

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.network "private_network", ip: "192.168.10.21"

  config.vm.provider :virtualbox do |vb|
    vb.name = "wapi.lokal"
    vb.memory = 2048
    vb.cpus = 2
  end

  config.vm.hostname = "admin.webapp.lokal"
  config.hostsupdater.aliases = ["www.admin.webapp.lokal"]

  config.vm.provision "shell", path: "provision.sh"

  config.vm.synced_folder ".", "/vagrant", type: "nfs"

end

system("
  if [ #{ARGV[0]} = 'up' ]; then
    echo 'Setting up git hooks'
    # ln ./tools/shell-scripts/gitpull.sh ./.git/hooks/post-update
    # ln ./tools/shell-scripts/gitpull.sh ./.git/hooks/post-merge
  fi

  if [ #{ARGV[0]} = 'destroy' ]; then
    echo 'Removing git hooks'
    # rm ./.git/hooks/post-update
    # rm ./.git/hooks/post-merge
  fi
")
