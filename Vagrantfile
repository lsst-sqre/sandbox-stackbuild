required_plugins = %w{
  vagrant-digitalocean
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

    define.vm.provider :digital_ocean do |provider, override|
      # XXX the slug name for 6.7 appears to be centos-6-5-x64
      provider.image = 'centos-6-x64'
    end
  end

  config.vm.define 'el7' do |define|
    hostname = gen_hostname('el7')
    define.vm.hostname = hostname

    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'centos-7-x64'
    end
  end

  config.vm.define 'f27' do |define|
    hostname = gen_hostname('f27')
    define.vm.hostname = hostname

    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'fedora-27-x64'
    end
  end

  config.vm.define 'u14' do |define|
    define.vm.hostname = gen_hostname('u14')

    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'ubuntu-14-04-x64'
    end
  end

  config.vm.define 'u16' do |define|
    define.vm.hostname = gen_hostname('u16')

    define.vm.provider :digital_ocean do |provider, override|
      provider.image = 'ubuntu-16-04-x64'
    end
  end

  config.vm.provider :digital_ocean do |provider, override|
    override.vm.box = 'digital_ocean'
    override.nfs.functional = false
    override.vm.box_url = 'https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box'
    # it appears to blow up if you set the username to vagrant...
    override.ssh.username = 'vagrant'
    override.ssh.private_key_path = SSH_PRIVATE_KEY_PATH
    override.vm.synced_folder '.', '/vagrant', :disabled => true
    override.ssh.insert_key = false

    provider.token = DO_API_TOKEN
    provider.region = 'nyc3'
    provider.size = '16gb'
    provider.setup = true
    provider.ssh_key_name = SSH_PUBLIC_KEY_NAME
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
  load do_c if File.exists? do_c
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
  pub_key = "#{SSH_PRIVATE_KEY_PATH}.pub"
  if not File.exist?(pub_key)
    require 'open-uri'
    open(pub_key, 'wb') do |file|
      file << open('https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub').read
    end
  end
end

# -*- mode: ruby -*-
# vi: set ft=ruby :
