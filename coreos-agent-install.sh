#!/bin/bash

# Configure /etc/hosts file
sudo echo "# Host config for Puppet Master and Agent Nodes
10.20.1.80   puppet-master puppet-master${NETWORK}
10.20.1.81   puppet-agent puppet-agent${NETWORK}
10.20.1.82   coreos-agent coreos-agent${NETWORK}" >> /etc/hosts

# Add optional alternate DNS names to /etc/puppet/puppet.conf
sudo echo "[agent]
server=puppet-master${NETWORK}" >> /etc/puppetlabs/puppet/puppet.conf
