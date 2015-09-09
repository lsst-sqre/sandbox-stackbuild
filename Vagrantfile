%w{
  vagrant-hostmanager
  vagrant-librarian-puppet
  vagrant-puppet-install
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
def ci_hostname(hostname, provider)
  provider.user_data = <<-EOS
#cloud-config
hostname: #{hostname}
manage_etc_hosts: localhost
  EOS
end

Vagrant.configure('2') do |config|
  config.vm.define 'el6', primary: true do |define|
    hostname = gen_hostname('el6')
    define.vm.hostname = hostname

    define.vm.provider :virtualbox do |provider, override|
      override.vm.box = 'chef/centos-6.6'
    end
    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'centos-6-5-x64'
    end
    define.vm.provider :aws do |provider, override|
      ci_hostname(hostname, provider)

      # base centos 6 ami
      # provider.ami = 'ami-81d092b1'
      # override.ssh.username = 'root'

      # packer rebuild of base ami
      # provider.ami = 'ami-874b79b7'

      # packer built
      provider.ami = 'ami-67e28202'
      provider.region = 'us-east-1'
    end
  end

  config.vm.define 'el7' do |define|
    hostname = gen_hostname('el7')
    define.vm.hostname = hostname

    define.vm.provider :virtualbox do |provider, override|
      override.vm.box = 'chef/centos-7.0'
    end
    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'centos-7-0-x64'
    end
    define.vm.provider :aws do |provider, override|
      ci_hostname(hostname, provider)

      # base centos 7 ami
      # provider.ami = 'ami-c7d092f7'
      # override.ssh.username = 'centos'

      # packer build of base ami
      # provider.ami = 'ami-29576419'

      # packer built
      provider.ami = 'ami-ffe3839a'
      provider.region = 'us-east-1'
    end
  end

  config.vm.define 'f22' do |define|
    hostname = gen_hostname('f22')
    define.vm.hostname = hostname

    define.vm.provider :virtualbox do |provider, override|
      override.vm.box = 'chef/fedora-22'
    end
    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'fedora-22-x64'
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

  # setup the remote repo needed to install a current version of puppet
  config.puppet_install.puppet_version = '3.8.2'

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

  config.vm.provider :aws do |provider, override|
    override.vm.box = 'aws'
    override.vm.box_url = "https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box"
    # http://blog.damore.it/2015/01/aws-vagrant-no-host-ip-was-given-to.html
    override.nfs.functional = false
    override.vm.synced_folder '.', '/vagrant', :disabled => true
    #override.vm.synced_folder 'hieradata/', '/tmp/vagrant-puppet/hieradata'
    override.ssh.private_key_path = "#{Dir.home}/.sqre/ssh/id_rsa_sqre"
    provider.keypair_name = "sqre"
    provider.access_key_id = ENV['AWS_ACCESS_KEY_ID']
    provider.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
    provider.region = ENV['AWS_DEFAULT_REGION']
    provider.security_groups = ['sshonly']
    provider.instance_type = 'c4.2xlarge'
    provider.ebs_optimized = true
    provider.block_device_mapping = [{
      'DeviceName'              => '/dev/sda1',
      'Ebs.VolumeSize'          => 40,
      'Ebs.VolumeType'          => 'gp2',
      'Ebs.DeleteOnTermination' => 'true',
    }]
    provider.tags = { 'Name' => "stackbuild" }
  end

  if Vagrant.has_plugin?('vagrant-librarian-puppet')
    config.librarian_puppet.placeholder_filename = ".gitkeep"
  end

  if Vagrant.has_plugin?("vagrant-hostmanager")
    config.vm.provision :hostmanager
    config.hostmanager.include_offline = true
    config.hostmanager.ignore_private_ip = false
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
  do_c = "#{root}/do/credentials.rb"
  aws_c = "#{root}/aws/credentials.rb"
  load do_c if File.exists? do_c
  load aws_c if File.exists? aws_c
  SSH_PRIVATE_KEY_PATH="#{root}/ssh/id_rsa_#{SANDBOX_GROUP}"
  SSH_PUBLIC_KEY_PATH="#{SSH_PRIVATE_KEY_PATH}.pub"
  SSH_PUBLIC_KEY_NAME=SANDBOX_GROUP
else
  DO_API_TOKEN="<digitalocean api token>"
  SSH_PRIVATE_KEY_PATH="#{ENV['HOME']}/.ssh/id_rsa"
  SSH_PUBLIC_KEY_PATH="#{SSH_PRIVATE_KEY_PATH}.pub"
  SSH_PUBLIC_KEY_NAME=ENV['USER']
end

# -*- mode: ruby -*-
# vi: set ft=ruby :
