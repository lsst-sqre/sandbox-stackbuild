LSST Stack build sandbox
========================

Prerequisites
-------------

* Vagrant 2.0.x
* `git` - needed to clone this repo

### Vagrant Installation

OSX
---

### Install Vagrant

```shell
wget https://releases.hashicorp.com/vagrant/2.0.3/vagrant_2.0.3_x86_64.dmg
hdiutil mount vagrant_2.0.3_x86_64.dmg
sudo installer -package /Volumes/Vagrant/Vagrant.pkg -target /
hdiutil unmount /Volumes/Vagrant
rm vagrant_2.0.3_x86_64.dmg
```

```shell
# sanity check
$ which vagrant
/usr/bin/vagrant
```

### How to accept the Xcode License from the CLI

This step can be skipped if you have already accepted the Xcode license or
installed an unmolested version of `git`/etc..

If you see a warning like the following:

```shell
$ git


Agreeing to the Xcode/iOS license requires admin privileges, please re-run as
root via sudo.
```

Run this command:

```shell
sudo xcodebuild -license accept
```

Then verify that the license warning is gone:

```shell
# sanity check
$ git --version
git version 1.8.5.2 (Apple Git-48)
```

Fedora 21
---------

### Install Vagrant

```shell
sudo yum install -y https://dl.bintray.com/mitchellh/vagrant/vagrant_2.0.3_x86_64.rpm
```

Sanity check

```shell
/usr/bin/vagrant
```

Vagrant plugins
---------------

These are required:

* vagrant-digitalocean '~> 0.7.3'

DigitalOcean example
--------------------

    git clone git@github.com:lsst-sqre/sandbox-stackbuild.git
    cd sandbox-stackbuild
    vagrant up el7

Other useful commands
---------------------

    vagrant up --provider=virtual_box
    vagrant up --provider=digital_ocean
    vagrant up <hostname> --provider=digital_ocean
    vagrant status
    vagrant ssh
    vagrant ssh <hostname>
    vagrant halt  # restart with vagrant up
    vagrant halt <hostname>  # restart with vagrant up
    vagrant destroy -f
    vagrant destroy -f <hostname>


    wget https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub
