
# == Class kraken::flume
# 
class kraken::flume($agent_name = undef) {
	include kraken::flume::install
	include kraken::flume::source::udp
	class { "kraken::flume::config":
		agent_name => $agent_name,
	}
	class { "kraken::flume::agent":
		require => Class["kraken::flume::config"],
	}
}

class kraken::flume::agent {
	service { "flume-ng-agent":
		ensure => "running",
		enable => true,
	}
}

class kraken::flume::config($agent_name = undef) {
	require kraken::flume::install
	require kraken::flume::source::udp

	$flume_conf_template = $agent_name ? {
		undef   => "kraken/flume/flume.conf.erb",
		default => "kraken/flume/flume-${agent_name}.conf.erb",
	}

	file { "/etc/flume-ng/conf/log4j.properties":
		content => template("kraken/flume/log4j.properties.erb"),
	}

	file { "/etc/flume-ng/conf/flume-env.sh":
		content => template("kraken/flume/flume-env.sh.erb"),
	}

	file { "/etc/flume-ng/conf/flume.conf":
		content => template($flume_conf_template),
	}

	file { "/etc/default/flume-ng-agent":
		content => template("kraken/flume/flume-ng-agent.default.erb"),
	}
}

# == Class kraken::flume::install
# Temporarly using src tarball for flume 1.3.1 so that we can do
# regex extraction of timestamps.  Also downloading custom built
# jar for flume-udp-source.
# 
# TODO: Use CDH4's .debs if/when we go to production.
class kraken::flume::install {
	# need to make sure CDH4's flume is not installed.
	package { ["flume-ng", "flume-ng-agent"]: ensure => absent }

	$flume_version = "1.3.1"
	$flume_dir     = "apache-flume-${flume_version}-bin"
	$flume_tarball = "${flume_dir}.tar.gz"
	$flume_url = "http://analytics1027.eqiad.wmnet/files/$flume_tarball"

	$flume_download_path = "/opt/flume-ng"
	$flume_path           = "$flume_download_path/$flume_dir"
	$flume_install_path  = "/usr/lib/flume-ng"


	file { "$flume_download_path":
		ensure => "directory",
	}

	# download and unpack Flume NG from Apache url.
	exec { "flume_install":
		command => "/usr/bin/wget $flume_url && /bin/tar -xvf $flume_tarball",
		cwd     => "$flume_download_path",
		creates => "$flume_path",
		require => File["$flume_download_path"],
	}

	# symlnk flume into /usr/lib/flume-ng
	file { $flume_install_path:
		ensure  => $flume_path,
		require => Exec["flume_install"],
	}
	# install /usr/bin/flume-ng to exec /usr/lib/flume-ng/bin/flume-ng
	file { "/usr/bin/flume-ng":
		content => template("kraken/flume/flume-ng.bin.erb"),
		mode    => 0755,
		require => File[$flume_install_path],
	}

	# make sure flume group and user are present.
	group { "flume":
		ensure => "present",
		system => true,
		require => Exec["flume_install"],
	}
	user { "flume":
		name       => "flume",
		gid        => "flume",
		comment    => "Flume User",
		shell      => "/bin/false",
		home       => "/var/run/flume-ng",
		system     => true,
		ensure     => "present",
		managehome => false,
		require    => [Group["flume"], Exec["flume_install"]],
	}

	# install the flume-agent-ng init.d script
	file { "/etc/init.d/flume-ng-agent": 
		content => template("kraken/flume/flume-ng-agent.init.d"),
		mode    => 0755,
		require  => [Exec["flume_install"], User["flume"]],
	}

	# symlink /etc/flume-ng/conf to /usr/lib/flume-ng/conf
	file { "/etc/flume-ng":
		ensure => "directory",
		require => File["$flume_install_path"]
	}
	file { "/etc/flume-ng/conf":
		ensure  => "$flume_path/conf",
		require => File["/etc/flume-ng"],
	}

	# make sure /var/run/flume-ng and /var/log/flume-ng
	# and /var/lib/flume (for file channel) dirs exist
	file { ["/var/run/flume-ng", "/var/log/flume-ng", "/var/lib/flume"]:
		ensure => "directory",
		owner  => "flume",
		group  => "flume",
		require => [User["flume"], Exec["flume_install"]],
	}
}

# == Class kraken::flume::source::udp
# Downloads our custom flume-udp-source .jar
# from analytics1001.
class kraken::flume::source::udp {
	# download our custom flume-udp-source .jar file
	# (It was built against 1.4.0, but meh, this is all temporary!)
	$flume_udp_source_jar = "flume-udp-source-1.4.0-SNAPSHOT.jar"
	$flume_udp_source_url = "http://analytics1027.eqiad.wmnet/files/$flume_udp_source_jar"
	exec { "flume_udp_source_install":
		command => "/usr/bin/wget $flume_udp_source_url",
		cwd     => $kraken::flume::install::flume_download_path,
		creates => "$kraken::flume::install::flume_download_path/$flume_udp_source_jar",
		require => Class["kraken::flume::install"],
	}
	# symlink the name to something without the version
	file { "${kraken::flume::install::flume_install_path}/lib/flume-udp-source.jar":
		ensure  => "${kraken::flume::install::flume_download_path}/$flume_udp_source_jar",
		require => Exec["flume_udp_source_install"],
	}
}
