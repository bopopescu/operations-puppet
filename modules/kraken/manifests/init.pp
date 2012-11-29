# == Class kraken
# This class should be included on all analytics nodes.
class kraken {
	# TODO: remove apt_source and kraken::misc::temp
	# when we go to production
	include kraken::misc::temp
	include cdh4::apt_source

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