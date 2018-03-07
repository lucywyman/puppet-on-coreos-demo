# -*- mode: ruby -*-
# # vi: set ft=ruby :

CLOUD_CONFIG_PATH = File.join(File.dirname(__FILE__), "user-data")
#NETWORK = '.delivery.puppetlabs.net'
#NETWORK = '.wellsely.net'
NETWORK = ''

Vagrant.configure("2") do |config|
  config.vm.define "puppetmaster" do |master|
    master.vm.box = "ubuntu/xenial64"
    master.vm.hostname = "puppet-master#{NETWORK}"
    master.vm.network "private_network", ip: "10.20.1.80"
    master.vm.provision :hosts, :sync_hosts => true
    master.vm.provision "shell",
      path: "puppet-master-install.sh",
      env: {"NETWORK" => "#{NETWORK}"}
    master.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--memory", "4096"]
    end
  end

# config.vm.define "puppetagent" do |agent|
#   agent.vm.box = "centos/7"
#   agent.vm.hostname = "puppet-agent#{NETWORK}"
#   agent.vm.network "private_network", ip: "10.20.1.81"
#   agent.vm.provision :hosts, :sync_hosts => true
#   agent.vm.provision "shell",
#     path: "puppet-agent-install.sh",
#     env: {"NETWORK" => "#{NETWORK}"}
# end

  config.vm.define "coreosagent" do |agent|
    agent.ssh.insert_key = false
    agent.ssh.forward_agent = true
    agent.vm.box = "coreos-beta"
    agent.vm.box_url = "https://storage.googleapis.com/beta.release.core-os.net/amd64-usr/current/coreos_production_vagrant.json"
    agent.vm.hostname = "coreos-agent#{NETWORK}"

    agent.vm.provider :virtualbox do |v| 
      # On VirtualBox, we don't have guest additions or functional vboxsf
      # in CoreOS, so tell Vagrant that so it can be smarter.
      v.check_guest_additions = false
      v.functional_vboxsf     = false
      v.memory = 2048
      v.cpus = 1
      v.customize ["modifyvm", :id, "--cpuexecutioncap", "100"]
    end

    agent.vm.network :private_network, ip: "10.20.1.82"
    agent.vm.provision :hosts, :sync_hosts => true

    if File.exist?(CLOUD_CONFIG_PATH)
      agent.vm.provision :file, :source => "#{CLOUD_CONFIG_PATH}", :destination => "/tmp/vagrantfile-user-data"
      agent.vm.provision :shell,
        :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/",
        :privileged => true,
        :env => {"NETWORK" => "#{NETWORK}"}
    end

  end
end
