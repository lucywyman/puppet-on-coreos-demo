# puppet-on-coreos-demo

Ever wanted to manage your CoreOS infrastructure with Puppet? These are the files to make it happen locally with Vagrant.

## Getting Started

### Set up Puppet master and CentOS Agent

```
vagrant up
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

Create file `/etc/puppetlabs/puppet/puppet.conf` with the following content:
```
[agent]
server=puppet-master
certname=coreos-agent
```

Then run puppet agent in a docker container
```
vagrant ssh coreosagent
sudo su -
docker run -p 443:443 -p 80:80 --rm --privileged --hostname coreos-agent.delivery.puppetlabs.net -v /tmp:/tmp -v /etc:/etc -v /var:/var -v /usr:/usr -v /lib64:/lib64 --network host puppet/puppet-agent
```

Sign the cert on the master
```
vagrant ssh puppetmaster
puppet cert sign --all
```

Then run puppet agent again on the CoreOS VM
```
docker run -p 443:443 -p 80:80 --rm --privileged --hostname coreos-agent.delivery.puppetlabs.net -v /tmp:/tmp -v /etc:/etc -v /var:/var -v /usr:/usr -v /lib64:/lib64 --network host puppet/puppet-agent
```

And there you have it!

## Install and Apply MOTD Module

You can verify your setup is working by installing the [puppetlabs MOTD](https://forge.puppet.com/puppetlabs/motd) module, which writes a message to `/etc/motd`. 

On the puppet master
```
vagrant ssh puppetmaster
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
``
puppet agent -t
cat /etc/motd
```
and you should see 'Hello World!' printed.

Then do the same on the CoreOS machine:
```
vagrant ssh coreosagent
docker run -p 443:443 -p 80:80 --rm --privileged --hostname coreos-agent.delivery.puppetlabs.net -v /tmp:/tmp -v /etc:/etc -v /var:/var -v /usr:/usr -v /lib64:/lib64 --network host puppet/puppet-agent
cat /etc/motd
```

and you should see the same thing!
