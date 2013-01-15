
# == Class kraken::flume
# 
class kraken::flume {
	include kraken::flume::install
	include kraken::flume::source::udp
	include kraken::flume::config
}


class kraken::flume::config {
	require kraken::flume::install
	require kraken::flume::source::udp

	file { "/etc/flume-ng/conf/flume-env.sh":
		content => template("kraken/flume-env.sh.erb"),
	}

	file { "/etc/flume-ng/conf/flume.conf":
		content => template("kraken/flume.conf.erb"),
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
	$flume_url = "http://mirrors.ibiblio.org/apache/flume/$flume_version/$flume_tarball"

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
		require => File["flume_download_path"],
	}

	# symlnk flume into /usr/lib/flume-ng
	file { $flume_install_path:
		ensure  => $flume_path,
		require => Exec["flume_install"],
	}
	# symlink /usr/bin/flume-ng
	file { "/usr/bin/flume-ng":
		ensure  => "$flume_install_path/bin/flume-ng",
		require => File[$flume_install_path],
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
}

# == Class kraken::flume::source::udp
# Downloads our custom flume-udp-source .jar
# from analytics1001.
class kraken::flume::source::udp {
	# download our custom flume-udp-source .jar file
	# (It was built against 1.4.0, but meh, this is all temporary!)
	$flume_udp_source_jar = "flume-udp-source-1.4.0-SNAPSHOT.jar"
	$flume_udp_source_url = "http://analytics1001.wikimedia.org:81/$flume_udp_source_jar"
	exec { "flume_udp_source_install":
		command => "/usr/bin/wget $flume_udp_source_url",
		cwd     => $kraken::flume::install::flume_download_path,
		require => Class["kraken::flume::install"],
	}
	# symlink the name to something without the version
	file { "$flume_install_path/lib/flume-udp-source.jar":
		ensure  => "${kraken::flume::install::flume_download_path}/$flume_udp_source_jar",
		require => "flume_udp_source_install",
	}
}