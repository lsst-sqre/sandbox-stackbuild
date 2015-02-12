include ::stdlib
include ::augeas
include ::sysstat
include ::wget

case $::osfamily {
  'Debian': {
    $convience_pkgs = [
      'screen',
      'tree',
      'vim'
    ]

    $pkg_list = [
      # needed for newinstall.sh
      'make',
      # list from https://confluence.lsstcorp.org/display/LSWUG/Prerequisites
      'bison',
      'curl',
      'flex',
      'g++',
      'git',
      'libbz2-dev',
      'libreadline6-dev',
      'libx11-dev',
      'libxt-dev',
      'm4',
      'zlib1g-dev',
      # needed for shapelet tests
      'libxrender1',
      'libfontconfig1',
    ]
  }
  'RedHat': {
    include ::epel
    Class['epel'] -> Package<| provider == 'yum' |>

    $convience_pkgs = [
      'screen',
      'tree',
      'vim-enhanced'
    ]

    $pkg_list = [
      'bison',
      'blas',
      'bzip2-devel',
      'bzip2', # needed on el7 -- pulled in by bzip2-devel on el6?
      'flex',
      'fontconfig',
      'freetype-devel',
      'gcc-c++',
      'gcc-gfortran',
      'git', # needed on el6, in @core for others?
      'libuuid-devel',
      'libXext',
      'libXrender',
      'libXt-devel',
      'make',
      'ncurses-devel',
      'openssl-devel',
      'patch',
      'perl',
      'readline-devel',
      'zlib-devel',
    ]
  }
  default: { fail() }
}

package { $pkg_list: }
package { $convience_pkgs: }

$memoryrequired = to_bytes('16 GB')
$swaprequired = $memoryrequired - to_bytes($::memorysize)

if $swaprequired >= to_bytes('1 GB') {
  class { 'swap_file':
    swapfilesize => $swaprequired,
  }
}

$stack_user  = 'lsstsw'
$stack_group = 'lsstsw'
$stack_path = "/home/${stack_group}/stack"

$wheel_group = $::osfamily ? {
  'Debian' => 'sudo',
  default  => 'wheel',
}

user { $stack_user:
  ensure     => present,
  gid        => $stack_group,
  groups     => [$wheel_group],
  managehome => true,
}

group { $stack_group:
  ensure => present,
}

$sshkey_parts = split($::vagrant_sshkey, '\s+')

ssh_authorized_key { $sshkey_parts[2]:
  user => $stack_user,
  type => $sshkey_parts[0],
  key  => $sshkey_parts[1],
}

file { 'stack':
  ensure  => directory,
  owner   => $stack_user,
  group   => $stack_group,
  mode    => '0755',
  path    => $stack_path,
  require => [Class['swap_file'], Package[$pkg_list]],
}

wget::fetch { 'newinstall.sh':
  source      => 'https://sw.lsstcorp.org/eupspkg/newinstall.sh',
  destination => "${stack_path}/newinstall.sh",
  execuser    => $stack_user,
  timeout     => 60,
  verbose     => true,
  require     => File['stack'],
}

file { 'newinstall.sh':
  mode    => '0755',
  path    => "${stack_path}/newinstall.sh",
  require => Wget::Fetch['newinstall.sh'],
}

exec { 'newinstall.sh':
  environment => ["PWD=${stack_path}"],
  command     => 'echo -e "yes\nyes" | newinstall.sh -c',
  path        => ['/bin', '/usr/bin', $stack_path],
  cwd         => $stack_path,
  user        => $stack_user,
  logoutput   => true,
  creates     => "${stack_path}/loadLSST.zsh",
  timeout     => 600,
  require     => File['newinstall.sh'],
}
