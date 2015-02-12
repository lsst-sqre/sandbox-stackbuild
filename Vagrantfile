%w{
  vagrant-hosts
  vagrant-puppet-install
  vagrant-librarian-puppet
}.each do |plugin|
  unless Vagrant.has_plugin?(plugin)
    raise "#{plugin} not installed"
  end
end

# generate a psuedo unique hostname to avoid droplet name/aws tag collisions.
# eg, "jhoblitt-sxn-<os>"
# based on:
# https://stackoverflow.com/questions/88311/how-best-to-generate-a-random-string-in-ruby
def gen_hostname(boxname)
  "#{ENV['USER']}-#{(0...3).map { (65 + rand(26)).chr }.join.downcase}-#{boxname}"
end

Vagrant.configure('2') do |config|
  config.vm.define 'el6', primary: true do |define|
    define.vm.hostname = gen_hostname('el6')

    define.vm.provider :virtualbox do |provider, override|
      override.vm.box = 'puppetlabs/centos-6.5-64-nocm'
    end
    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'centos-6-5-x64'
    end
  end

  config.vm.define 'el7' do |define|
    define.vm.hostname = gen_hostname('el7')

    define.vm.provider :virtualbox do |provider, override|
      override.vm.box = 'puppetlabs/centos-7.0-64-nocm'
    end
    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'centos-7-0-x64'
    end
  end

  config.vm.define 'f21' do |define|
    define.vm.hostname = gen_hostname('f21')

    define.vm.provider :virtualbox do |provider, override|
      override.vm.box = 'chef/fedora-21'
    end
    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'fedora-21-x64'
    end
  end

  config.vm.define 'u12' do |define|
    define.vm.hostname = gen_hostname('u12')

    define.vm.provider :virtualbox do |provider, override|
      override.vm.box = 'ubuntu/precise64'
    end
    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'ubuntu-12-04-x64'
    end
  end

  config.vm.define 'u14' do |define|
    define.vm.hostname = gen_hostname('u14')

    define.vm.provider :virtualbox do |provider, override|
      override.vm.box = 'ubuntu/trusty64'
    end
    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'ubuntu-14-04-x64'
    end
  end

  # intended to allow per-provider fiddling
  config.vm.provision 'preflight',
    type: "shell",
    inline: '/bin/true'

  # setup the remote repo needed to install a current version of puppet
  config.puppet_install.puppet_version = :latest

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
    puppet.facter = {
      "vagrant_sshkey" => File.read(SSH_PUBLIC_KEY_PATH),
    }
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

      script = <<-EOS.gsub(/^\s*/, '')
        VGNAME=$(vgs --noheadings --separator , | cut -f1 -d, | tr -d [[:space:]])
        LVLONGNAME=$(basename $(df / | tail -1 | cut -d " " -f1))
        # trim everything left of the last - in the name
        LVNAME=${LVLONGNAME##*-}

        if [ ! -e /dev/sdb1 ]; then
          parted -s /dev/sdb mklabel msdos
          parted -s /dev/sdb mkpart primary 0 -- -1
          pvcreate /dev/sdb1
          vgextend ${VGNAME} /dev/sdb1
          lvextend -l +100%FREE --resizefs /dev/${VGNAME}/${LVNAME}
        fi
      EOS

      # We're in provisioner ordering hell here as the partitioning needs to be
      # done before puppet attempts to configure swap space.  We have to play
      # games with overriding an existing shell provisioner that was declared
      # before the puppet provisioner in order to get this to work.
      override.vm.provision 'preflight',
        type: 'shell',
        preserve_order: true,
        inline: script
    end
  end

  config.vm.provider :digital_ocean do |provider, override|
    override.vm.box = 'digital_ocean'
    override.vm.box_url = 'https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box'
    # it appears to blow up if you set the username to vagrant...
    override.ssh.username = 'lsstsw'
    override.ssh.private_key_path = SSH_PRIVATE_KEY_PATH
    override.vm.synced_folder '.', '/vagrant', :disabled => true

    provider.token = DO_API_TOKEN
    provider.region = 'nyc3'
    provider.size = '16gb'
    provider.setup = true
    provider.ssh_key_name = SSH_PUBLIC_KEY_NAME
  end

  if Vagrant.has_plugin?('vagrant-librarian-puppet')
    config.librarian_puppet.placeholder_filename = ".gitkeep"
  end

  if Vagrant.has_plugin?("vagrant-hosts")
    config.vm.provision :hosts
  end

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end

  # based on:
  # https://github.com/mitchellh/vagrant/issues/1753#issuecomment-53970750
  #if ARGV[0] == 'ssh'
  #  config.ssh.username = 'lsstsw'
  #  config.ssh.private_key_path = SSH_PRIVATE_KEY_PATH
  #end
end

# concept from:
# http://ryan.muller.io/devops/2014/03/26/chef-vagrant-and-digital-ocean.html
SANDBOX_GROUP = ENV['SQRE_SANDBOX_GROUP'] || 'sqreuser'
if File.exist? "#{Dir.home}/.#{SANDBOX_GROUP}"
  root="#{Dir.home}/.#{SANDBOX_GROUP}"
  load "#{root}/do/credentials.rb"
  SSH_PRIVATE_KEY_PATH="#{root}/ssh/id_rsa_#{SANDBOX_GROUP}"
  SSH_PUBLIC_KEY_PATH="#{SSH_PRIVATE_KEY_PATH}.pub"
  SSH_PUBLIC_KEY_NAME=SANDBOX_GROUP
else
  DO_API_TOKEN="<digitalocean api token>"
  SSH_PRIVATE_KEY_PATH="#{ENV['HOME']}/.ssh/id_rsa"
  SSH_PUBLIC_KEY_PATH="#{ENV['USER']}/.ssh/id_rsa.pub"
  SSH_PUBLIC_KEY_NAME=ENV['USER']
end

# -*- mode: ruby -*-
# vi: set ft=ruby :
