# -*- mode: ruby -*-
# vim: set ft=ruby :
home = ENV['HOME']
ENV["LC_ALL"] = "en_US.UTF-8"

Vagrant.configure(2) do |config|

  # ================================= app server =======================================

    config.vm.define "odoo" do |odoo|
    # имя виртуальной машины
    odoo.vm.box = 'debian11/v1230.1' 
    odoo.vm.provider "virtualbox" do |vb|
      vb.name = "odoo"
    end
    # hostname виртуальной машины
    odoo.vm.hostname = "odoo"
    # настройки сети
    odoo.vm.network "private_network", ip: "192.168.56.50"
    odoo.vm.synced_folder ".", "/vagrant",  
          type: "rsync",
          rsync_auto: "true",
          rsync_exclude: [".git/",".vagrant/",".gitignore","Vagrantfile"]
          #odoo.vm.provision "shell", path: "provision/prepare-host.sh"
    end

  # ================================ postgresql node-01 =================================
    config.vm.define "pgnode-m" do |pgnode|
    # имя виртуальной машины
    pgnode.vm.box = 'debian11/v1230.1' 
    pgnode.vm.provider "virtualbox" do |vbc|
      vbc.name = "pgnode-m"
    end
    # hostname виртуальной машины
    pgnode.vm.hostname = "pgnode-m"
    # настройки сети
    pgnode.vm.network "private_network", ip: "192.168.56.51"
    pgnode.vm.synced_folder ".", "/vagrant",  
          type: "rsync",
          rsync_auto: "true",
          rsync_exclude: [".git/",".vagrant/",".gitignore","Vagrantfile"]
          #pgnode.vm.provision "shell", path: "provision/prepare-host.sh"
    end


  # ================================ postgresql node-02 =================================
  config.vm.define "pgnode-s" do |pgnodes|
    # имя виртуальной машины
    pgnodes.vm.box = 'debian11/v1230.1' 
    pgnodes.vm.provider "virtualbox" do |vbc|
      vbc.name = "pgnode-s"
    end
    # hostname виртуальной машины
    pgnodes.vm.hostname = "pgnode-s"
    # настройки сети
    pgnodes.vm.network "private_network", ip: "192.168.56.52"
    pgnodes.vm.synced_folder ".", "/vagrant",  
          type: "rsync",
          rsync_auto: "true",
          rsync_exclude: [".git/",".vagrant/",".gitignore","Vagrantfile"]
          #pgnode.vm.provision "shell", path: "provision/prepare-host.sh"
    end

  # # ====================== Barman backup =====================================
    config.vm.define "barman" do |barman|
    # имя виртуальной машины
    barman.vm.box = 'debian11/v1230.1' 
    barman.vm.provider "virtualbox" do |vbc|
      vbc.name = "barman"
    end
    # hostname виртуальной машины
    barman.vm.hostname = "barman"
    # настройки сети
    barman.vm.network "private_network", ip: "192.168.56.58"
    barman.vm.synced_folder ".", "/vagrant",  
        type: "rsync",
        rsync_auto: "true",
        rsync_exclude: [".git/",".vagrant/",".gitignore","Vagrantfile"]
        #pgnode.vm.provision "shell", path: "provision/prepare-host.sh"
  end

  # ======================================= log server ===============================

  config.vm.define "log-server" do |logsrv|
    # имя виртуальной машины
    logsrv.vm.box = 'centos/7' 
    logsrv.vm.provider "virtualbox" do |vbc|
      vbc.name = "log-server"
    end
    # hostname виртуальной машины
    logsrv.vm.hostname = "log-server"
    # настройки сети
    logsrv.vm.network "private_network", ip: "192.168.56.56"
    logsrv.vm.synced_folder ".", "/vagrant",  
          type: "rsync",
          rsync_auto: "true",
          rsync_exclude: [".git/",".vagrant/",".gitignore","Vagrantfile"]
          #logsrv.vm.provision "shell", path: "provision/prepare-host.sh"
  end
  
  # ======================================= Zabbix ===============================

  config.vm.define "zabbix" do |zabbix|
    # имя виртуальной машины
    zabbix.vm.box = 'debian11/v1230.1' 
    zabbix.vm.provider "virtualbox" do |vbc|
      vbc.name = "zabbix"
    end
    # hostname виртуальной машины
    zabbix.vm.hostname = "zabbix"
    # настройки сети
    zabbix.vm.network "private_network", ip: "192.168.56.57"
    zabbix.vm.synced_folder ".", "/vagrant",  
          type: "rsync",
          rsync_auto: "true",
          rsync_exclude: [".git/",".vagrant/",".gitignore","Vagrantfile"]
          #logsrv.vm.provision "shell", path: "provision/prepare-host.sh"
  end


  # # ================================= Backup server ===================================

    config.vm.define "backupfile" do |backupfile|
    # имя виртуальной машины
    backupfile.vm.box = 'centos/7' 
    backupfile.vm.provider "virtualbox" do |vbc|
      vbc.name = "backupfile"
  end
    # hostname виртуальной машины
    backupfile.vm.hostname = "backup"
    # настройки сети
    backupfile.vm.network "private_network", ip: "192.168.56.55"
    backupfile.vm.synced_folder ".", "/vagrant",  
        type: "rsync",
        rsync_auto: "true",
        rsync_exclude: [".git/",".vagrant/",".gitignore","Vagrantfile"]
        #pgnode.vm.provision "shell", path: "provision/prepare-host.sh"
   end

  # ======================================= Bastion GW ===============================

  config.vm.define "bastion" do |bastion|
    # имя виртуальной машины
    bastion.vm.box = 'centos/7' 
    bastion.vm.provider "virtualbox" do |vbc|
      vbc.name = "bastion"
    end
    # hostname виртуальной машины
    bastion.vm.hostname = "bastion"
    # настройки сети
    bastion.vm.network "private_network", ip: "192.168.56.254"
    bastion.vm.synced_folder ".", "/vagrant",  
          type: "rsync",
          rsync_auto: "true",
          rsync_exclude: [".git/",".vagrant/",".gitignore","Vagrantfile"]
          #logsrv.vm.provision "shell", path: "provision/prepare-host.sh"

# ssh-pub add in servers
  config.vm.provision "shell", inline: <<-SHELL
  cat /vagrant/provision/vagrant-key.pub >> /home/vagrant/.ssh/authorized_keys
  SHELL

    end
end
