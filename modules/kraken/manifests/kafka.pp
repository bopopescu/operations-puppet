class kraken::kafka {
	require kraken::zookeeper::config
	include kafka, kafka::install
	class { "kafka::config":
		zookeeper_hosts => $kraken::zookeeper::config::zookeeper_hosts,
	}
}

class kraken::kafka::server inherits kraken::kafka {
	# kafka broker server
	include kafka::server
	include kraken::monitoring::kafka
}

class kraken::kafka::client inherits kraken::kafka {
	# no need to do anything, all we need
	# are classes from parent class kraken::kafka.
}