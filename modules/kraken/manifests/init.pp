# == Class kraken
# This class should be included on all analytics nodes.
class kraken {
	$smtp_host = "mchenry.wikimedia.org"
	$email     = "kraken@wikimedia.org"

	# TODO: remove apt_source and kraken::misc::temp
	# when we go to production
	include kraken::misc::temp
	include cdh4::apt_source

	include kraken::misc::email::aliases

	# kraken repository should be available on all kraken nodes
	include kraken::repository

	# install common cdh4 packages and config
	class { "cdh4":
		require => Class["cdh4::apt_source"],
	}

	# zookeeper config is common to all nodes
	class { "kraken::zookeeper::config":
		require => Class["cdh4::apt_source"]
	}

	# hadoop config is common to all nodes
	class { "kraken::hadoop::config":
		require => Class["cdh4::apt_source"],
	}

	# Ensure /var/log/kraken exists.
	# Some things will write logs files here.
	file { "/var/log/kraken":
		ensure => "directory",
		mode   => 0775,
		owner  => "root",
		group  => "hadoop",
	}

	# 
	# # kafka client and config is common to all nodes
	# class { "kraken::kafka::client":
	# 	require => File["/etc/apt/sources.list.d/kraken.list"],
	# }

	#
	# # storm client and config is common to all nodes
	# class { "kraken::storm::client":
	# 	require => File["/etc/apt/sources.list.d/kraken.list"],
	# }
}

# clone the kraken working repository into /opt
class kraken::repository {
	$directory = "/opt/kraken"
	$url       = "https://github.com/wmf-analytics/kraken.git"
	$owner     = "root"
	$group     = "root"

	# many kraken scripts require Python docopt from Pip
	include generic::pythonpip
	exec { "install-python-docopt":
		command => "pip --proxy=http://brewster.wikimedia.org:8080 install docopt",
		path    => ["/usr/bin", "/usr/local/bin"],
		creates => "/usr/local/lib/python2.7/dist-packages/docopt.py",
		require => Class["generic::pythonpip"],
	}

	# Clone the kraken repository and ensure it
	# is at its latest revision
	git::clone{ "kraken":
		directory => $directory,
		origin    => $url,
		owner     => $owner,
		group     => $group,
		ensure    => "latest",
	}
}