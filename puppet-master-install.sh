#!/bin/bash

if ps aux | grep "puppet" | grep -v grep 2> /dev/null
then
    echo "Puppet Master is already installed. Exiting..."
else
    # Install puppet master
    wget https://apt.puppetlabs.com/puppet5-release-xenial.deb
    sudo dpkg -i puppet5-release-xenial.deb
    sudo apt-get -yq update
    sudo apt-get -yq install puppetserver docker.io
    sudo service puppetserver start

    # Configure /etc/hosts file
    echo "# Host config for Puppet Master and Agent Nodes
10.20.1.80   puppet-master puppet-master${NETWORK}
10.20.1.81   puppet-agent puppet-agent${NETWORK}
10.20.1.82   coreos-agent coreos-agent${NETWORK}" >> /etc/hosts

    # Add optional alternate DNS names to /etc/puppet/puppet.conf
    sudo echo "
[main]
dns_alt_names = puppet,puppet-master,puppet-master${NETWORK}
[agent]
server=puppet-master${NETWORK}" >> /etc/puppetlabs/puppet/puppet.conf

    sudo hostname puppet-master${NETWORK}
    # Install some initial puppet modules on Puppet Master server
    #puppet module install puppetlabs-ntp
    #puppet module install garethr-docker
    #puppet module install puppetlabs-git
fi
