# = Class: solr
#
# This class installs/configures/manages Solr service.
#
# == Parameters:
#
# $schema:: Schema file for Solr (only one schema per instance supported)
#
# == Sample usage:
#
#   class { "solr":
#     schema => "puppet:///modules/solr/schema-ttmserver.xml",
#   }

class solr::install {
  package { "solr-jetty":
    ensure => present,
  }

  # For some reason running solr this way needs jdk
  package { "openjdk-6-jdk":
    ensure => present,
  }
}

class solr::config ( $schema = undef ) {
  File {
    owner => 'jetty',
    group => 'root',
    mode  => '0644'
  }

  file { "/etc/default/jetty":
    ensure  => present,
    source  => "puppet:///modules/solr/jetty",
    owner   => 'root',
    require => Class["solr::install"],
    notify  => Class["solr::service"],
  }

  if $schema != undef {
    file { "schema":
      ensure  => present,
      path    => "/etc/solr/conf/schema.xml",
      source  => $schema,
      require => Class["solr::install"],
      notify  => Class["solr::service"],
    }
  }

  # Apparently there is a bug in the debian package
  # and the default symlink points to non-existing dir
  # webapp instead of web
  file { "/usr/share/jetty/webapps/solr":
    ensure => "link",
    target => "/usr/share/solr/web",
  }
}

class solr::service {
  service { "jetty":
    ensure => running,
    enable => true,
  }
}

class solr ($schema = undef) {
  include solr::install, solr::service
  class { "solr::config":
    schema => $schema,
  }
}