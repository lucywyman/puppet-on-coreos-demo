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

First thing's first: bring up some VMs. There are 4 VMs included here: a
puppet master, a CentOS puppet agent (for debugging), and 2 CoreOS machines
(an extra one for debugging). For this demo, you just need the master and 1
CoreOS agent.
```
vagrant up puppetmaster coreosagent
```

Then run puppet on the master to make sure puppet is installed and working
correctly.

```
vagrant ssh puppetmaster
sudo su -
puppet agent -t
```

### Connect CoreOS Agent

The puppet agent is run inside a container on CoreOS. You mount any directories you want to make changes to the container, give it privileges, and then run the puppet agent and it can make changes to the underlying CoreOS system. 

```
vagrant ssh coreosagent
sudo su -
docker run -p 443:443 -p 80:80 --rm --privileged \
-v /etc:/etc \
-v /var:/var \
-v /usr:/usr \
-v /opt/bin:/opt/bin \
--network host puppet/puppet-agent
```

Sign the cert on the puppet master VM:
```
puppet cert sign --all
```

Then run puppet agent again on the CoreOS VM
```
docker run -p 443:443 -p 80:80 --rm --privileged \
-v /etc:/etc \
-v /var:/var \
-v /usr:/usr \
-v /opt/bin:/opt/bin \
--network host puppet/puppet-agent
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
    content => "Hello world!\n",
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
docker run -p 443:443 -p 80:80 --rm --privileged \
-v /etc:/etc \
-v /var:/var \
-v /usr:/usr \
-v /opt/bin:/opt/bin \
--network host puppet/puppet-agent

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
docker run --rm -v $(pwd):/mnt -e OS=coreos -e VERSION=1.9.2 \
-e CONTAINER_RUNTIME=docker -e CNI_PROVIDER=flannel -e \
FQDN=coreos-agent \
-e IP="10.20.1.82" \
-e KUBE_IMAGE_TAG="v1.9.3_coreos.0" \
-e BOOTSTRAP_CONTROLLER_IP="10.20.1.82" \
-e ETCD_INITIAL_CLUSTER="etcd-kube-master=http://10.20.1.82:2380" \
-e ETCD_IP="10.20.1.82" \
-e KUBE_API_ADVERTISE_ADDRESS="10.20.1.82" \
-e INSTALL_DASHBOARD=true puppet/kubetool
```

This will generate a [hiera data](https://docs.puppet.com/hiera/) file
`kubernetes.yaml` in the current working directory. Move that file to where
you keep your [hieradata](https://puppet.com/docs/puppet/5.3/hiera_intro.html#hieras-three-config-layers)

If you're not sure, most likely:
```
mv kubernetes.yaml /etc/puppetlabs/code/environments/production/data
```

**Note**: For now, you'll also need to manually add `kubernetes::kube_image_tag: "v1.9.3_coreos.0"` to the data file

### Install Kubectl Binary

For Reasons, you may need to install the kubectl binary on the coreos system. 

```
curl -L https://dl.k8s.io/v1.7.13/kubernetes-server-linux-amd64.tar.gz -o ks.tar.gz
tar -xvf ks.tar.gz
mv kubernetes/server/bin/kubectl /opt/bin/
mv kubernetes/server/bin/kubelet /opt/bin/
```

### Install Kubernetes

Then open a file `/etc/puppetlabs/code/environments/production/manifests/site.pp` with
the following:
```
node 'coreos-agent.my.network.net' {
  class {'kubernetes':
    controller           => true,
    bootstrap_controller => true,
  }
}
```

Do a few other things:

```
export KUBECONFIG=/etc/kubernetes/admin.conf
systemctl start etcd-member
echo "[Service]" >> /etc/systemd/system/kubelet.service
systemctl daemon-reload && systemctl start kubelet
```

On the CoreOS machine run
```
docker run -p 443:443 -p 80:80 --rm --privileged \
-h coreos-agent \
-v /etc:/etc \
-v /var:/var \
-v /usr:/usr \
-v /lib64:/lib64 \
-v /opt/python/bin/pip3:/bin/pip3 \
-v /opt/bin:/opt/bin \
-v /opt/bin/kubectl:/bin/kubectl \
--network host puppet/puppet-agent
```

## Networking Issues

I've run into a number of networking issues while setting this up, so
here's how to make sure all your ducks are in a row:

### Networks

Sometimes the VMs append the local network name to the specified hostname for
the VMs. This means that in order for the VMs to talk to each other they
actually need to connect to `puppet-master.my.network.net` instead of just
`puppet-master`. Setting the hostnames on the machines to `myhostname.my.network.net` takes 3 steps:

```
hostname myhostname.my.network.net
export HOSTNAME=$HOSTNAME.my.network.net
# And change the hostname in your /etc/hostname file
vi /etc/hostname
```

### /etc/hosts

Make sure that your hosts all know about each other. The vagrant hosts plugin
should take care of this for you, but in case something goes awry your
`/etc/hosts` file should look something like this:

On the puppet master:
```
root@puppet-master:~# cat /etc/hosts
127.0.0.1   localhost
10.20.1.82  coreos-agent    coreosagent
10.20.1.80  puppet-master   puppet-master
127.0.1.1   puppet-master   puppetmaster
127.0.1.1   ubuntu-xenial   ubuntu-xenial
```

On the coreos agent:
```
coreos-agent ~ # cat /etc/hosts 
127.0.0.1 localhost
127.0.1.1 coreos-agent coreosagent
10.20.1.82 coreos-agent coreosagent
10.20.1.80 puppet-master puppet-master
```
