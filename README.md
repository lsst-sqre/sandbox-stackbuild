LSST Stack build sandbox
========================

Prerequisites
-------------

* Vagrant 1.7.x
* `git` - needed to clone this repo

Suggested
---------

* VirtualBox (used by Vagrant)

SQRE credentials
----------------

    cd ~
    git clone ~/Dropbox/Josh-Frossie-share/git/sqre.git .sqre
    chmod 0700 .sqre
    ls -lad .sqre

Vagrant plugins
---------------

    vagrant plugin install vagrant-hostmanager
    vagrant plugin install vagrant-librarian-puppet --plugin-version '~> 0.9.0'
    vagrant plugin install vagrant-digitalocean

### Suggested for usage with virtualbox

    vagrant plugin install vagrant-cachier

Sandbox
-------

    vagrant plugin install vagrant-librarian-puppet --plugin-version '~> 0.9.0'
	vagrant plugin install vagrant-hostmanager
    vagrant plugin install vagrant-cachier
	vagrant plugin install vagrant-digitalocean
	vagrant plugin install vagrant-aws

    git clone git@github.com:lsst-sqre/sandbox-stackbuild.git
    cd sandbox-stackbuild
    vagrant up --provider=digital_ocean

Other useful commands
---------------------
    vagrant up --provider=virtual_box
    vagrant up --provider=digital_ocean
    vagrant up --provider=aws
    vagrant up <hostname> --provider=digital_ocean
	vagrant status
	vagrant ssh
	vagrant ssh <hostname>
	vagrant halt  # restart with vagrant up
	vagrant halt <hostname>  # restart with vagrant up
	vagrant destroy -f
	vagrant destroy -f <hostname>
