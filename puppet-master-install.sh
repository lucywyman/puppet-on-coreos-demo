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

    # Add optional alternate DNS names to /etc/puppet/puppet.conf
    sudo echo "
[main]
dns_alt_names = puppet,puppet-master
[agent]
server=puppet" >> /etc/puppetlabs/puppet/puppet.conf
fi
