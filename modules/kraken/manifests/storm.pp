# == Class kraken::storm::master
#
# Inherits from kraken::storm to get installtion and config,
# and then configures a Storm Nimbus server and ensures that it is running.
class kraken::storm::master inherits kraken::storm {
  include storm::nimbus
}

# == Class kraken::storm::worker
#
# Inherits from kraken::storm to get installtion and config,
# and then configures a Storm Supervisor server and ensures that it is running.
class kraken::storm::worker inherits kraken::storm {
  include storm::supervisor
}

# == Class kraken::storm::frontend
#
# Inherits from kraken::storm to get installtion and config,
# and then configures a Storm UI server and ensures that it is running.
class kraken::storm::frontend inherits kraken::storm {
  include storm::ui
}

# == Class kraken::storm::client
#
# Installs Storm, but doesn't start any services.
class kraken::storm::client inherits kraken::storm {
	# no need to do anything, all we need
	# are classes from parent class kraken::storm.
}

# == Class kraken::storm
#
# Installs Storm and generic Storm configs.
class kraken::storm {
	require kraken::zookeeper::config

	$nimbus_host     = "analytics1002.eqiad.wmnet"
	$zookeeper_hosts = $kraken::zookeeper::config::zookeeper_hosts
	$ui_port         = 6999
	class { "::storm":
		nimbus_host     => $nimbus_host,
		zookeeper_hosts => $zookeeper_hosts,
		ui_port         => $ui_port,
		# use all but 2 processors on each supervisor worker machine
		worker_count    => $processorcount - 2,
	}
}
