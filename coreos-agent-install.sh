#!/bin/bash

# Configure /etc/hosts file
#sudo echo "# Host config for Puppet Master and Agent Nodes
#10.20.1.80   puppet-master puppet-master.delivery.puppetlabs.net
#10.20.1.81   puppet-agent puppet-agent.delivery.puppetlabs.net
#10.20.1.82   coreos-agent coreos-agent.delivery.puppetlabs.net" >> /etc/hosts

# Add optional alternate DNS names to /etc/puppet/puppet.conf
sudo echo "[agent]
server=puppet-master.delivery.puppetlabs.net" >> /etc/puppetlabs/puppet/puppet.conf

# Install python
VERSIONS=${VERSIONS:-"3.5.4.3504"}
GLIB="-glibc-2.12-404899"

# make directory
mkdir -p /opt/python/bin /opt/bin
cd /opt

wget http://downloads.activestate.com/ActivePython/releases/${VERSIONS}/ActivePython-${VERSIONS}-linux-x86_64${GLIB}.tar.gz
tar -xzvf ActivePython-${VERSIONS}-linux-x86_64${GLIB}.tar.gz

mv ActivePython-${VERSIONS}-linux-x86_64${GLIB} apy && cd apy && ./install.sh -I /opt/python/

ln -s /opt/python/bin/easy_install /opt/bin/easy_install
ln -s /opt/python/bin/pip3 /opt/bin/pip3
ln -s /opt/python/bin/python /opt/bin/python
ln -s /opt/python/bin/virtualenv /opt/bin/virtualenv
