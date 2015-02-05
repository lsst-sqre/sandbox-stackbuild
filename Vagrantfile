# generate a psuedo unique hostname to avoid droplet name/aws tag collisions.
# eg, "jhoblitt-sxn-<os>"
# based on:
# https://stackoverflow.com/questions/88311/how-best-to-generate-a-random-string-in-ruby
def gen_hostname(boxname)
  "#{ENV['USER']}-#{(0...3).map { (65 + rand(26)).chr }.join.downcase}-#{boxname}"
end

PUPPET_RPM_SCRIPT = <<-EOS.gsub(/^\s*/, '')
  yum clean all
  if rpm -q puppet; then
    yum update -y puppet
  else
    yum -y install puppet
  fi
  touch /etc/puppet/hiera.yaml
  yum update -y --exclude=kernel\*
EOS

PUPPET_DEB_SCRIPT = <<-EOS.gsub(/^\s*/, '')
  apt-get update
  # on 14.04, upgrade will both install on upgrade but this is not that case on
  # 12.04
  if dpkg --status puppet; then
    apt-get upgrade -y puppet
  else
    apt-get install -y puppet
  fi
  touch /etc/puppet/hiera.yaml
  apt-get upgrade -y
  apt-get autoremove -y
EOS

def provider_setup(reposcript, puppetscript, config, override)
  override.vm.provision 'puppetlabs-release',
    type: "shell",
    preserve_order: true,
    inline: reposcript
  config.vm.provision 'bootstrap-puppet',
    type: "shell",
    preserve_order: true,
    inline: puppetscript
end

def rpm_provider_setup(script, config, override)
  provider_setup(script, PUPPET_RPM_SCRIPT, config, override)
end

def deb_provider_setup(script, config, override)
  provider_setup(script, PUPPET_DEB_SCRIPT, config, override)
end

Vagrant.configure('2') do |config|

  config.vm.define 'el6', primary: true do |define|
    define.vm.hostname = gen_hostname('el6')

    script = <<-EOS.gsub(/^\s*/, '')
      rpm -q puppetlabs-release || rpm -Uvh --force http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
    EOS

    define.vm.provider :virtualbox do |provider, override|
      override.vm.box = 'puppetlabs/centos-6.5-64-nocm'
      rpm_provider_setup(script, config, override)
    end
    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'centos-6-5-x64'
      rpm_provider_setup(script, config, override)
    end
  end

  config.vm.define 'el7' do |define|
    define.vm.hostname = gen_hostname('el7')

    script = <<-EOS.gsub(/^\s*/, '')
      rpm -q puppetlabs-release || rpm -Uvh --force http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
    EOS

    define.vm.provider :virtualbox do |provider, override|
      override.vm.box = 'puppetlabs/centos-7.0-64-nocm'
      rpm_provider_setup(script, config, override)
    end
    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'centos-7-0-x64'
      rpm_provider_setup(script, config, override)
    end
  end

  config.vm.define 'f20' do |define|
    define.vm.hostname = gen_hostname('f20')

    script = <<-EOS.gsub(/^\s*/, '')
      rpm -q puppetlabs-release || rpm -Uvh --force http://yum.puppetlabs.com/puppetlabs-release-fedora-20.noarch.rpm
    EOS

    define.vm.provider :virtualbox do |provider, override|
      override.vm.box = 'chef/fedora-20'
      rpm_provider_setup(script, config, override)
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
      rpm_provider_setup(script, config, override)
    end
  end

  config.vm.define 'f21' do |define|
    define.vm.hostname = gen_hostname('f21')

    # PL repo for f21 hasn't been released
    script = <<-EOS.gsub(/^\s*/, '')
      rpm -q puppetlabs-release || rpm -Uvh --force http://yum.puppetlabs.com/puppetlabs-release-fedora-20.noarch.rpm
    EOS

    define.vm.provider :virtualbox do |provider, override|
      override.vm.box = 'chef/fedora-21'
      rpm_provider_setup(script, config, override)
    end
    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'fedora-21-x64'
      rpm_provider_setup(script, config, override)
    end
  end

  config.vm.define 'u12' do |define|
    define.vm.hostname = gen_hostname('u12')

    script = <<-EOS.gsub(/^\s*/, '')
      DEB="puppetlabs-release-precise.deb"
      if [ ! -e $DEB ]; then
        wget https://apt.puppetlabs.com/${DEB}
      fi
      dpkg -i $DEB
    EOS

    define.vm.provider :virtualbox do |provider, override|
      override.vm.box = 'ubuntu/precise64'
      deb_provider_setup(script, config, override)
    end
    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'ubuntu-12-04-x64'
      deb_provider_setup(script, config, override)
    end
  end

  config.vm.define 'u14' do |define|
    define.vm.hostname = gen_hostname('u14')

    script = <<-EOS.gsub(/^\s*/, '')
      DEB="puppetlabs-release-trusty.deb"
      if [ ! -e $DEB ]; then
        wget https://apt.puppetlabs.com/${DEB}
      fi
      dpkg -i $DEB
    EOS

    define.vm.provider :virtualbox do |provider, override|
      override.vm.box = 'ubuntu/trusty64'
      deb_provider_setup(script, config, override)
    end
    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'ubuntu-14-04-x64'
      deb_provider_setup(script, config, override)
    end
  end

  if Vagrant.has_plugin?("vagrant-hostmanager")
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = false
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = false
  end

  if Vagrant.has_plugin?('vagrant-librarian-puppet')
    config.librarian_puppet.placeholder_filename = ".gitkeep"
  end

  # intended to allow per-provider fiddling
  config.vm.provision 'preflight',
    type: "shell",
    inline: '/bin/true'

  # setup the remote repo needed to install a current version of puppet
  config.vm.provision 'puppetlabs-release',
    type: "shell",
    inline: '/bin/true'

  # install puppet
  config.vm.provision 'bootstrap-puppet',
    type: "shell",
    inline: '/bin/true'

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
    override.ssh.username = SANDBOX_GROUP
    override.ssh.private_key_path = SSH_PRIVATE_KEY_PATH
    override.vm.synced_folder '.', '/vagrant', :disabled => true

    provider.token = DO_API_TOKEN
    provider.region = 'nyc3'
    provider.size = '16gb'
    provider.setup = true
    provider.ssh_key_name = SSH_PUBLIC_KEY_NAME
  end
end

# concept from:
# http://ryan.muller.io/devops/2014/03/26/chef-vagrant-and-digital-ocean.html
SANDBOX_GROUP = ENV['SQRE_SANDBOX_GROUP'] || 'sqreuser'
if File.exist? "#{Dir.home}/.#{SANDBOX_GROUP}"
  root="#{Dir.home}/.#{SANDBOX_GROUP}"
  load "#{root}/do/credentials.rb"
  SSH_PRIVATE_KEY_PATH="#{root}/ssh/id_rsa_#{SANDBOX_GROUP}"
  SSH_PUBLIC_KEY_NAME=SANDBOX_GROUP
else
  DO_API_TOKEN="<digitalocean api token>"
  SSH_PRIVATE_KEY_PATH="#{ENV['HOME']}/.ssh/id_rsa"
  SSH_PUBLIC_KEY_NAME=ENV['USER']
end

# -*- mode: ruby -*-
# vi: set ft=ruby :
