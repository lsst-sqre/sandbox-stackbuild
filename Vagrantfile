# vagrant plugin install vagrant-digitalocean

# generate a psuedo unique string to append to the VM name to avoid droplet name/aws tag collisions.
# eg, "jhoblitt-sxn"
# based on:
# https://stackoverflow.com/questions/88311/how-best-to-generate-a-random-string-in-ruby
USER_TAG = "#{ENV['USER']}-#{(0...3).map { (65 + rand(26)).chr }.join.downcase}"

Vagrant.configure('2') do |config|

  config.vm.define :stackbuild do |sb|
    sb.vm.hostname = "stackbuild-#{USER_TAG}"
  end

  if Vagrant.has_plugin?("vagrant-hostmanager")
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = false
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = false
  end

  config.vm.provider :digital_ocean do |provider, override|
    override.vm.box = 'digital_ocean'
    override.vm.box_url = 'https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box'
    override.ssh.username = 'sqre'
    override.ssh.private_key_path = "#{Dir.home}/.sqre/ssh/id_rsa_sqre"

    provider.token = API_TOKEN
    provider.image = 'centos-6-5-x64'
    provider.region = 'nyc3'
    provider.size = '2gb'
    provider.setup = true
    provider.ssh_key_name = 'sqre'
  end

  $script = <<EOS
rpm -q puppetlabs-release || rpm -Uvh --force http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
rpm -q puppet || yum -y install puppet
touch /etc/puppet/hiera.yaml
EOS

  config.vm.provision "shell", inline: $script

  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "manifests"
    puppet.module_path = "modules"
    puppet.manifest_file = "init.pp"
    puppet.options = [
     '--verbose',
     '--report',
     '--show_diff',
     '--pluginsync',
     '--disable_warnings=deprecations',
## '--debug',
## '--parser future',
    ]
  end
end

# concept from:
# http://ryan.muller.io/devops/2014/03/26/chef-vagrant-and-digital-ocean.html
load "#{Dir.home}/.sqre/do/credentials.rb"

# -*- mode: ruby -*-
# vi: set ft=ruby :
