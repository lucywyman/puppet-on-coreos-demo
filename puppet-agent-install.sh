#!/bin/bash

if ps aux | grep "puppet" | grep -v grep 2> /dev/null
then
    echo "Puppet Agent is already installed. Moving on..."
else
    # Install puppet agent 
    sudo rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
    sudo yum install -y puppet-agent
    sudo /opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true

    # Configure /etc/hosts file
    sudo echo "# Host config for Puppet Master and Agent Nodes
10.20.1.80   puppet-master puppet-master.delivery.puppetlabs.net
10.20.1.81   puppet-agent puppet-agent.delivery.puppetlabs.net
10.20.1.82   coreos-agent coreos-agent.delivery.puppetlabs.net" >> /etc/hosts

    # Add optional alternate DNS names to /etc/puppet/puppet.conf
    sudo echo "[agent]
server=puppet-master.delivery.puppetlabs.net" >> /etc/puppetlabs/puppet/puppet.conf

    sudo /opt/puppetlabs/bin/puppet agent --enable
fi
