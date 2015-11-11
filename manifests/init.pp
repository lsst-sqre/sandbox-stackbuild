include ::stdlib
include ::augeas
include ::sysstat
include ::wget

$stack_user  = $::lsst_stack_user ? {
  #undef   => 'lsstsw',
  undef   => 'vagrant',
  default => $::lsst_stack_user,
}
$stack_group = $stack_user

$wheel_group = $::osfamily ? {
  'Debian' => 'sudo',
  default  => 'wheel',
}

if $::osfamily == 'RedHat' {
  include ::epel
  Class['epel'] -> Package<| provider == 'yum' |>
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

class { '::lsststack':
  install_convenience => true,
}

::lsststack::newinstall { $stack_user:
  user         => $stack_user,
  manage_user  => false,
  group        => $stack_group,
  manage_group => false,
  stack_path   => $::stack_path,
}

$memoryrequired = to_bytes('16 GB')
$swaprequired = $memoryrequired - to_bytes($::memorysize)

if $swaprequired >= to_bytes('1 GB') {
  $ensure_swap = 'present'
} else {
  $ensure_swap = 'absent'
}

class { 'swap_file':
  ensure       => $ensure_swap,
  swapfilesize => $swaprequired,
}
