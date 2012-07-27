/*

==Class: postgresql::suse::base

This class is dedicated to the SuSE distribution.

SuSE uses the same package names in every distribution, and doesn't allow
(unless using custom packages) to have different versions in parallel as
debian does - thus, only this class is used. -vjt

*/
class postgresql::suse::base inherits postgresql::base {

  include postgresql::params
  include postgresql::client

  $version = $::lsbdistrelease ? {
    '11.4' => '9.0'
  }

  Package["postgresql"] {
    alias => "postgresql-${version}",
  }

  service {"postgresql":
    ensure    => running,
    enable    => true,
    hasstatus => true,
    require   => Package["postgresql"],
  }

  exec {"reload postgresql ${version}":
    refreshonly => true,
    command     => "/etc/init.d/postgresql reload",
  }
}

