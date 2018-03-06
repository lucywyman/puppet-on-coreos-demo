# Managing Kubernetes and CoreOS with Puppet Demo

Ever wanted to manage your CoreOS infrastructure with Puppet? These
are the files to make it happen locally with Vagrant.

* [Managing Kubernetes and CoreOS with Puppet Demo](#managing-kubernetes-and-coreos-with-puppet-demo)
  * [Getting Started](#getting-started)
     * [Installation](#installation)
     * [Create VMs](#create-vms)
     * [Connect CoreOS Agent](#connect-coreos-agent)
  * [Install and Apply MOTD Module (Optional)](#install-and-apply-motd-module-optional)
  * [Deploy a Kubernetes Cluster to CoreOS](#deploy-a-kubernetes-cluster-to-coreos)
  * [Networking Issues](#networking-issues)
     * [Networks](#networks)
     * [/etc/hosts](#etchosts)
     * [Hostname](#hostname)

## Getting Started

### Installation

* [Vagrant](https://www.vagrantup.com/docs/installation/)
* [Vagrant Hosts Plugin](https://github.com/oscar-stack/vagrant-hosts) - this is to simplify networking setup

```
vagrant plugin install vagrant-hosts
```

### Create VMs

First thing's first: bring all the machines up
```
vagrant up
```

Then run puppet on both the master and CentOS agent to make sure your
setup is working

```
vagrant ssh puppetagent
sudo su -
puppet agent -t
```

```
vagrant ssh puppetmaster
sudo su -
puppet agent -t
puppet cert sign --all
puppet agent -t
```

### Connect CoreOS Agent

```
vagrant ssh coreosagent
sudo su -
docker run -p 443:443 -p 80:80 --rm --privileged --hostname coreos-agent -v /tmp:/tmp -v /etc:/etc -v /var:/var -v /usr:/usr -v /lib64:/lib64 --network host puppet/puppet-agent
```

Sign the cert on the puppet master VM:
```
puppet cert sign --all
```

Then run puppet agent again on the CoreOS VM
```
docker run -p 443:443 -p 80:80 --rm --privileged --hostname coreos-agent.g -v /tmp:/tmp -v /etc:/etc -v /var:/var -v /usr:/usr -v /lib64:/lib64 --network host puppet/puppet-agent
```

And there you have it!

## Install and Apply MOTD Module (Optional)

You can verify your setup is working by installing the [puppetlabs
MOTD](https://forge.puppet.com/puppetlabs/motd) module, which writes a
message to `/etc/motd`. This is a good exercise if you're newer to
Puppet and modules, but if not I recommend skipping ahead to the
Kubernetes steps.

On the puppet master:
```
puppet module install puppetlabs-motd
```

Then add the following to `/etc/puppetlabs/code/environments/production/manifests/site.pp`
```
node default {
  class { 'motd':
    content => "Hello world!/n",
  }
}
```

Run puppet on the master to make sure it's working
```
puppet agent -t
cat /etc/motd
```
and you should see 'Hello World!' printed.

Then do the same on the CoreOS machine:
```
docker run -p 443:443 -p 80:80 --rm --privileged --hostname coreos-agent -v /tmp:/tmp -v /etc:/etc -v /var:/var -v /usr:/usr -v /lib64:/lib64 --network host puppet/puppet-agent
cat /etc/motd
```

And you should see the same thing!

## Deploy a Kubernetes Cluster to CoreOS

I highly recommend going through the entire
[README](https://github.com/puppetlabs/puppetlabs-kubernetes/blob/master/README.md)
of the [Puppet Kubernetes
module](https://github.com/puppetlabs/puppetlabs-kubernetes), but
here's an abbreviated version:

### Setup

Install the module on the master (I chose to manually install):
```
puppet module install puppetlabs-kubernetes
```

Generate the module config on the master
```
docker run --rm -v $(pwd):/mnt -e OS=ubuntu -e VERSION=1.9.2 \
-e CONTAINER_RUNTIME=docker -e CNI_PROVIDER=weave -e FQDN=$HOSTNAME \
-e IP="%{::ipaddress_enp0s8}" \
-e BOOTSTRAP_CONTROLLER_IP="%{::ipaddress_enp0s8}" \
-e ETCD_INITIAL_CLUSTER="etcd-kube-master=http://%{::ipaddress_enp0s8}:2380" \
-e ETCD_IP="%{::ipaddress_enp0s8}" \
-e KUBE_API_ADVERTISE_ADDRESS="%{::ipaddress_enp0s8}" \
-e INSTALL_DASHBOARD=true puppet/kubetool
```

This will generate a file `kubernetes.yaml` in the current working
directory. Move that file to where you keep your [hieradata]()

If you're not sure, most likely:
```
mv kubernetes.yaml /etc/puppetlabs/code/environments/production/hieradata
```

### Install Kubernetes

Then open a file `/etc/puppetlabs/code/environments/production/manifests/site.pp` with
the following:
```
node coreos-agent.my.network.net {
  class {'kubernetes':
    controller           => true,
    bootstrap_controller => true,
  }

  class {'kubernetes':
    controller => true,
  }
}
```

On the CoreOS machine run
```
docker run -p 443:443 -p 80:80 --rm --privileged --hostname coreos-agent -v /tmp:/tmp -v /etc:/etc -v /var:/var -v /usr:/usr -v /lib64:/lib64 -v /opt/python/bin/pip3:/bin/pip3 --network host puppet/puppet-agent
```

## Networking Issues

I've run into a number of networking issues while setting this up, so
here's how to make sure all your ducks are in a row:

### Networks

I've found that when I'm on a <TYPE OF NETWORK> the VMs append that
network to the specified hostname for the VMs. This means that in
order for the VMs to talk to each other they actually need to connect
to `puppet-master.my.network.net` instead of just `puppet-master`. You
can find the name of your networkon Ubuntu by TODO.

I've set up the provisioning scrips to read the network name from an
environment variable, so if you run into networking issues initially
you can set that variable and rebuild your VMs to see if that
ameliorates the issue:

```
export NETWORK=.my.network.net
```

I know the extra dot is unfortunately, but I'm too lazy to set up an
if statement to include it if the variable is set :P 

### /etc/hosts

This should 

On the puppet master:
```
root@puppet-master:~# cat /etc/hosts
127.0.0.1   localhost
10.20.1.82  coreos-agent    coreosagent
10.20.1.80  puppet-master   puppet-master.my.network.net
127.0.1.1   puppet-master   puppetmaster
127.0.1.1   ubuntu-xenial   ubuntu-xenial
```

On the coreos agent:
```
coreos-agent ~ # cat /etc/hosts 
127.0.0.1 localhost
127.0.1.1 coreos-agent coreosagent
10.20.1.82 coreos-agent coreosagent
10.20.1.80 puppet-master puppet-master.my.network.net
```

### Hostname

Make sure your hosts know their own hostname!

```
hostname myhost.my.network.net
export HOSTNAME=$HOSTNAME.my.network.net
vi /etc/hostname # Set the hostname here
```
