include ::stdlib
include ::augeas
include ::epel
include ::sysstat

Class['epel'] -> Package<| provider == 'yum' |>

$convience_pkgs = [
  'screen',
  'tree',
]

$pkg_list = [
  'bison',
  'blas',
  'bzip2', # needed on el7 -- pulled in by bzip2-devel on el6?
  'bzip2-devel',
  'flex',
  'freetype-devel',
  'gcc-c++',
  'gcc-gfortran',
  'libuuid-devel',
  'libXt-devel',
  'ncurses-devel',
  'make',
  'openssl-devel',
  'perl',
  'readline-devel',
  'zlib-devel',
  'patch',
]

package { $pkg_list: }
package { $convience_pkgs: }

$memoryrequired = to_bytes('16 GB')
$swaprequired = $memoryrequired - to_bytes($::memorysize)

if $swaprequired < to_bytes('128 MB') {
  $newswap = 0
} else {
  $newswap = $swaprequired
}

class { 'swap_file':
  swapfilesize => $newswap,
}
