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

  $puppet_script = <<-EOS.gsub(/^\s*/, '')
    rpm -q puppetlabs-release || rpm -Uvh --force http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
    #rpm -q puppet || yum -y install puppet
    yum update -y puppet
    touch /etc/puppet/hiera.yaml
  EOS

  config.vm.provision 'bootstrap',
    type: "shell",
    inline: $puppet_script

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
    ]
  end

  config.vm.provider :virtualbox do |provider, override|
    override.vm.box     = 'centos-65-x64'
    override.vm.box_url = 'http://puppet-vagrant-boxes.puppetlabs.com/centos-65-x64-virtualbox-puppet.box'

    provider.memory = 2048
    provider.cpus = 2
  end

  # taken from:
  # https://github.com/mitchellh/vagrant/issues/2339
  file_to_disk = File.realpath( "." ).to_s + "/disk.vdi"
  if ! File.exist?(file_to_disk)
    config.vm.provider :virtualbox do |provider, override|
      provider.customize [
        'createhd',
        '--filename', file_to_disk,
        '--format', 'VDI',
        '--size', 32 * 1024
      ]
      provider.customize [
        'storageattach', :id,
        '--storagectl', 'IDE Controller',
        '--port', 1, '--device', 0,
        '--type', 'hdd', '--medium',
        file_to_disk
      ]

      $part_script = <<-EOS.gsub(/^\s*/, '')
        if [ ! -e /dev/sdb1 ]; then
          parted -s /dev/sdb mklabel msdos
          parted -s /dev/sdb mkpart primary 0 -- -1
          pvcreate /dev/sdb1
          vgextend VolGroup /dev/sdb1
          lvextend -l +100%FREE --resizefs /dev/VolGroup/lv_root
        fi
      EOS
      $part_script = $part_script + $puppet_script

      # We're in provisioner ordering hell here as the partitioning needs to be
      # done before puppet attempts to configure swap space.  We have to play
      # games with overriding an existing shell provisioner that was declared
      # before the puppet provisioner in order to get this to work.
      override.vm.provision 'bootstrap',
        type: 'shell',
        inline: $part_script,
        preserve_order: true
    end
  end

  config.vm.provider :digital_ocean do |provider, override|
    override.vm.box = 'digital_ocean'
    override.vm.box_url = 'https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box'
    override.ssh.username = 'sqre'
    override.ssh.private_key_path = "#{Dir.home}/.sqre/ssh/id_rsa_sqre"
    override.vm.synced_folder '.', '/vagrant', :disabled => true

    provider.token = DO_API_TOKEN
    provider.image = 'centos-6-5-x64'
    provider.region = 'nyc3'
    provider.size = '2gb'
    provider.setup = true
    provider.ssh_key_name = 'sqre'
  end
end

# concept from:
# http://ryan.muller.io/devops/2014/03/26/chef-vagrant-and-digital-ocean.html
load "#{Dir.home}/.sqre/do/credentials.rb"

# -*- mode: ruby -*-
# vi: set ft=ruby :
