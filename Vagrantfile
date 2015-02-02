# vagrant plugin install vagrant-digitalocean

# generate a psuedo unique string to append to the VM name to avoid droplet name/aws tag collisions.
# eg, "jhoblitt-sxn"
# based on:
# https://stackoverflow.com/questions/88311/how-best-to-generate-a-random-string-in-ruby
USER_TAG = "#{ENV['USER']}-#{(0...3).map { (65 + rand(26)).chr }.join.downcase}"

Vagrant.configure('2') do |config|

  config.vm.define 'el6', primary: true do |define|
    define.vm.hostname = "el6-#{USER_TAG}"

    script = <<-EOS.gsub(/^\s*/, '')
      rpm -q puppetlabs-release || rpm -Uvh --force http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
    EOS

    define.vm.provider :virtualbox do |provider, override|
      override.vm.box = 'puppetlabs/centos-6.5-64-nocm'
      override.vm.provision 'puppetlabs-release',
        type: "shell",
        preserve_order: true,
        inline: script
    end
    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'centos-6-5-x64'
      override.vm.provision 'puppetlabs-release',
        type: "shell",
        preserve_order: true,
        inline: script
    end
  end

  config.vm.define 'el7' do |define|
    define.vm.hostname = "el7-#{USER_TAG}"

    script = <<-EOS.gsub(/^\s*/, '')
      rpm -q puppetlabs-release || rpm -Uvh --force http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
    EOS

    define.vm.provider :virtualbox do |provider, override|
      override.vm.box = 'puppetlabs/centos-7.0-64-nocm'
      override.vm.provision 'puppetlabs-release',
        type: "shell",
        preserve_order: true,
        inline: script
    end
    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'centos-7-0-x64'
      override.vm.provision 'puppetlabs-release',
        type: "shell",
        preserve_order: true,
        inline: script
    end
  end

  config.vm.define 'f20' do |define|
    define.vm.hostname = "f20-#{USER_TAG}"

    script = <<-EOS.gsub(/^\s*/, '')
      rpm -q puppetlabs-release || rpm -Uvh --force http://yum.puppetlabs.com/puppetlabs-release-fedora-20.noarch.rpm
    EOS

    define.vm.provider :virtualbox do |provider, override|
      override.vm.box = 'chef/fedora-20'

      override.vm.provision 'puppetlabs-release',
        type: "shell",
        preserve_order: true,
        inline: script
    end
    # XXX f20 is broken on DO
    #
    # The f20 DO droplet does not work with vagrant due to the ssh
    # configuration.  Reported to DO in:
    # https://cloud.digitalocean.com/support/508246
    #
    # we're also unable to fix the sudo configuration in a snapshot due to:
    # https://github.com/smdahlen/vagrant-digitalocean/issues/168
    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'fedora-20-x64'
      override.vm.provision 'puppetlabs-release',
        type: "shell",
        preserve_order: true,
        inline: script
    end
  end

  config.vm.define 'f21' do |define|
    define.vm.hostname = "f21-#{USER_TAG}"

    # there's yet a PL repo for f21
    script = <<-EOS.gsub(/^\s*/, '')
      rpm -q puppetlabs-release || rpm -Uvh --force http://yum.puppetlabs.com/puppetlabs-release-fedora-20.noarch.rpm
    EOS

    define.vm.provider :virtualbox do |provider, override|
      override.vm.box = 'chef/fedora-21'

      override.vm.provision 'puppetlabs-release',
        type: "shell",
        preserve_order: true,
        inline: script
    end
    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'fedora-21-x64'
      override.vm.provision 'puppetlabs-release',
        type: "shell",
        preserve_order: true,
        inline: script
    end
  end

  if Vagrant.has_plugin?("vagrant-hostmanager")
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = false
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = false
  end

  if Vagrant.has_plugin?('vagrant-librarian-puppet')
    config.librarian_puppet.puppetfile_dir = "modules2"
    config.librarian_puppet.placeholder_filename = ".gitkeep"
  end

  puppet_script = <<-EOS.gsub(/^\s*/, '')
    if rpm -q puppet; then
      yum update -y puppet
    else
      yum -y install puppet
    fi
    touch /etc/puppet/hiera.yaml
    yum update -y --exclude=kernel\*
  EOS

  config.vm.provision 'puppetlabs-release',
    type: "shell",
    preserve_order: true,
    inline: '/bin/true'

  config.vm.provision 'bootstrap',
    type: "shell",
    inline: puppet_script

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

      part_script = <<-EOS.gsub(/^\s*/, '')
        VOLGROUP=$(vgs --noheadings --separator , | cut -f1 -d, | tr -d [[:space:]])
        if [ ! -e /dev/sdb1 ]; then
          parted -s /dev/sdb mklabel msdos
          parted -s /dev/sdb mkpart primary 0 -- -1
          pvcreate /dev/sdb1
          vgextend ${VOLGROUP} /dev/sdb1
          lvextend -l +100%FREE --resizefs /dev/${VOLGROUP}/lv_root
        fi
      EOS
      part_script = part_script + puppet_script

      # We're in provisioner ordering hell here as the partitioning needs to be
      # done before puppet attempts to configure swap space.  We have to play
      # games with overriding an existing shell provisioner that was declared
      # before the puppet provisioner in order to get this to work.
      override.vm.provision 'bootstrap',
        type: 'shell',
        inline: part_script,
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
    provider.region = 'nyc3'
    provider.size = '16gb'
    provider.setup = true
    provider.ssh_key_name = 'sqre'
  end
end

# concept from:
# http://ryan.muller.io/devops/2014/03/26/chef-vagrant-and-digital-ocean.html
load "#{Dir.home}/.sqre/do/credentials.rb"

# -*- mode: ruby -*-
# vi: set ft=ruby :
