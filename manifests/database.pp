/*

==Definition: postgresql::database

Create a new PostgreSQL database

*/
define postgresql::database(
  $ensure=present,
  $owner=false,
  $encoding=false,
  $template="template1",
  $source=false,
  $overwrite=false) {

  $ownerstring = $owner ? {
    false   => "",
    default => "-O $owner"
  }

  $encodingstring = $encoding ? {
    false   => "",
    default => "-E $encoding",
  }

  case $ensure {
    present: {
      exec { "Create $name postgres db":
        path    => "/bin:/usr/bin",
        command => "createdb $ownerstring $encodingstring $name -T $template",
        user    => "postgres",
        unless  => "test \$(psql -tA -c \"SELECT count(*)=1 FROM pg_catalog.pg_database where datname='${name}';\") = t",
        require => Postgresql::Cluster["main"],
      }
    }
    absent:  {
      exec { "Remove $name postgres db":
        path    => "/bin:/usr/bin",
        command => "dropdb $name",
        user    => "postgres",
        onlyif  => "test \$(psql -tA -c \"SELECT count(*)=1 FROM pg_catalog.pg_database where datname='${name}';\") = t",
        require => Postgresql::Cluster["main"],
      }
    }
    default: {
      fail "Invalid 'ensure' value '$ensure' for postgres::database"
    }
  }

  # Drop database before import
  if $overwrite {
    exec { "Drop database $name before import":
      path    => "/bin:/usr/bin",
      command => "dropdb ${name}",
      onlyif  => "psql -l | grep '$name  *|'",
      user    => "postgres",
      before  => Exec["Create $name postgres db"],
      require => Postgresql::Cluster["main"],
    }
  }

  # Import initial dump
  if $source {
    # TODO: handle non-gziped files
    exec { "Import dump into $name postgres db":
      path    => "/bin:/usr/bin",
      command => "zcat -f ${source} | psql ${name}",
      user    => "postgres",
      onlyif  => "test $(psql ${name} -c '\\dt' | wc -l) -eq 1",
      require => Exec["Create $name postgres db"],
    }
  }
}
