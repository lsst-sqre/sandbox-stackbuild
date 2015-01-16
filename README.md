LSST Stack build sandbox
========================

Prerequisites
-------------

* Vagrant 1.4.x
* Ruby 1.9.3 or greater
* the Ruby `bundler` gem
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

Sandbox
-------

    git clone git@github.com:lsst-sqre/sandbox-stackbuild.git
    cd sandbox-stackbuild
    bundle install
    bundle exec librarian-puppet install
    vagrant up --provider=digital_ocean
    
