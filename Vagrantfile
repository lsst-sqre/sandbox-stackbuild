required_plugins = %w{
  vagrant-librarian-puppet
  vagrant-puppet-install
}

plugins_to_install = required_plugins.select { |plugin| not Vagrant.has_plugin? plugin }
if not plugins_to_install.empty?
  puts "Installing plugins: #{plugins_to_install.join(' ')}"
  system "vagrant plugin install #{plugins_to_install.join(' ')}"
  exec "vagrant #{ARGV.join(' ')}"
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
      override.vm.box = 'bento/centos-6.7'
    end
    define.vm.provider :digital_ocean do |provider, override|
      # XXX the slug name for 6.7 appears to be centos-6-5-x64
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
      provider.ami = ENV['CENTOS6_AMI'] || 'ami-67e28202'
      provider.region = 'us-east-1'
    end
  end

  config.vm.define 'el7' do |define|
    hostname = gen_hostname('el7')
    define.vm.hostname = hostname

    define.vm.provider :virtualbox do |provider, override|
      override.vm.box = 'bento/centos-7.2'
    end
    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'centos-7-2-x64'
    end
    define.vm.provider :aws do |provider, override|
      ci_hostname(hostname, provider)

      # base centos 7 ami
      # provider.ami = 'ami-c7d092f7'
      # override.ssh.username = 'centos'

      # packer build of base ami
      # provider.ami = 'ami-29576419'

      # packer built
      provider.ami = ENV['CENTOS7_AMI'] || 'ami-1bf4d571'
      provider.region = 'us-east-1'
    end
  end

  config.vm.define 'f23' do |define|
    hostname = gen_hostname('f23')
    define.vm.hostname = hostname

    define.vm.provider :virtualbox do |provider, override|
      override.vm.box = 'bento/fedora-23'
    end
    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'fedora-23-x64'
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
  config.puppet_install.puppet_version = '4.8.1'

  config.vm.provision "puppet", type: :puppet do |puppet|
    #puppet.hiera_config_path = "hiera.yaml"
    puppet.environment_path  = "environments"
    puppet.environment       = "stackbuild"
    puppet.manifests_path    = "environments/stackbuild/manifests"
    puppet.manifest_file     = "default.pp"

    puppet.options = [
     '--verbose',
     '--trace',
     '--report',
     '--show_diff',
     '--disable_warnings=deprecations',
    ]
    puppet.facter = {
      'lsst_stack_user' => 'vagrant',
      'lsst_stack_path' => '/opt/lsst/software/stack',
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
    override.ssh.username = 'vagrant'
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
    #override.ssh.private_key_path = "#{Dir.home}/.sqre/ssh/id_rsa_sqre"
    override.ssh.private_key_path = "#{Dir.home}/.vagrant.d/insecure_private_key"
    provider.keypair_name = "vagrant"
    provider.access_key_id = ENV['AWS_ACCESS_KEY_ID']
    provider.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
    provider.region = ENV['AWS_DEFAULT_REGION']
    if ENV['AWS_SECURITY_GROUPS']
      provider.security_groups = ENV['AWS_SECURITY_GROUPS'].strip.split(/\s+/)
    else
      provider.security_groups = ['sshonly']
    end
    if ENV['AWS_SUBNET_ID']
      provider.subnet_id = ENV['AWS_SUBNET_ID']
      # assume we don't have an accessible public IP
      provider.ssh_host_attribute = :private_ip_address
    end
    provider.instance_type = 'c4.2xlarge'
    provider.ebs_optimized = true
    provider.block_device_mapping = [{
      'DeviceName'              => '/dev/sda1',
      'Ebs.VolumeSize'          => 200,
      'Ebs.VolumeType'          => 'gp2',
      'Ebs.DeleteOnTermination' => 'true',
    }]
    provider.tags = { 'Name' => "stackbuild" }
    # attempt to stop hitting aws' RequestLimitExceeded - default is 2
    #provider.instance_check_interval = 10
  end

  if Vagrant.has_plugin?('vagrant-librarian-puppet')
    config.librarian_puppet.placeholder_filename = ".gitkeep"
    config.librarian_puppet.puppetfile_dir = "environments/stackbuild/modules"
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
SANDBOX_GROUP = ENV['SQRE_SANDBOX_GROUP'] || 'sqre'
if File.exist? "#{Dir.home}/.#{SANDBOX_GROUP}"
  root="#{Dir.home}/.#{SANDBOX_GROUP}"
  do_c = "#{root}/do/credentials.rb"
  aws_c = "#{root}/aws/credentials.rb"
  load do_c if File.exists? do_c
  load aws_c if File.exists? aws_c
  SSH_PRIVATE_KEY_PATH="#{root}/ssh/id_rsa_#{SANDBOX_GROUP}"
  SSH_PUBLIC_KEY_NAME=SANDBOX_GROUP
else
  if ENV['DO_API_TOKEN']
    DO_API_TOKEN = ENV['DO_API_TOKEN']
  else
    DO_API_TOKEN = '<api key...>'
  end
  SSH_PRIVATE_KEY_PATH="#{Dir.home}/.vagrant.d/insecure_private_key"
  SSH_PUBLIC_KEY_NAME='vagrant'
end

# -*- mode: ruby -*-
# vi: set ft=ruby :
