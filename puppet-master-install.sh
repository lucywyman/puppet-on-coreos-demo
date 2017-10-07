#!/bin/bash

if ps aux | grep "puppet" | grep -v grep 2> /dev/null
then
    echo "Puppet Master is already installed. Exiting..."
else
    # Install puppet master
    wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
    sudo dpkg -i puppetlabs-release-pc1-xenial.deb
    sudo apt-get -yq update
    sudo apt-get -yq install puppetserver
    sudo service puppetserver start

    # Configure /etc/hosts file
#    echo "# Host config for Puppet Master and Agent Nodes
#10.20.1.80   puppet-master
#10.20.1.81   puppet-agent 
#10.20.1.82   coreos-agent" >> /etc/hosts

    # Add optional alternate DNS names to /etc/puppet/puppet.conf
    sudo echo "
[main]
dns_alt_names = puppet,puppet-master
[agent]
server=puppet-master" >> /etc/puppetlabs/puppet/puppet.conf

    sudo hostname puppet-master
fi
