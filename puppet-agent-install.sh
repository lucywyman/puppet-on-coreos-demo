#!/bin/bash

if ps aux | grep "puppet" | grep -v grep 2> /dev/null
then
    echo "Puppet Agent is already installed. Moving on..."
else
    # Install puppet agent 
    sudo rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
    sudo yum install -y puppet-agent
    sudo /opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true

    # Add optional alternate DNS names to /etc/puppet/puppet.conf
    sudo echo "[agent]
server=puppet-master" >> /etc/puppetlabs/puppet/puppet.conf

    sudo /opt/puppetlabs/bin/puppet agent --enable
fi
