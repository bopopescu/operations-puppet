# role/analytics.pp
@monitor_group { "analytics-eqiad": description => "analytics servers in eqiad" }

# Role classes for Analytics and Kraken services.
#
# This file contains base classes and final includable classes.
# The includable role classes are:
#
#   role::analytics::frontend         - Front end Kraken interfaces (hue, oozie, etc.)
#   role::analytics::hadoop::master   - Hadoop master services (namenode, resourcemanager, jobhistory, etc.)
#   role::analytics::hadoop::worker   - Hadoop worker services (datanode, nodemanager)
#   role::analytics::kafka            - Kafka Broker
#   role::analytics::public           - Machines with public facing IP addresses act as proxies to backend services.
#   role::analytics::storm::master    - Storm Nimubs Server
#   role::analytics::storm::worker    - Storm Supervisor Server
#   role::analytics::zookeeper        - Zookeeper Server
#

# == Class role::analytics::public
# Sets up a proxy from the public web interface in the Analytics Cluster
class role::analytics::public inherits role::analytics {
	include kraken::proxy
	include kraken::misc::web::index
}

# == Class role::analytics::frontend
# Frontend web services for Analytics Cluster.
# E.g. Hue, Oozie, etc.
class role::analytics::frontend inherits role::analytics {
	# include a mysql database for Sqoop and Oozie
	# with the datadir at /a/mysql
	class { "generic::mysql::server":
		datadir => "/a/mysql",
		version => "5.5",
	}
	
	# include the kraken index.php file.
	# TODO:  Puppetize webserver classes.
	include kraken::misc::web::index

	# Oozie server
	include kraken::oozie::server
	# Hive metastore and hive server
	include kraken::hive::server
	# Hue server
	include kraken::hue
}


# == Class role::analytics::kafka
# Kafka Broker Server role
class role::analytics::kafka inherits role::analytics {
	include kraken::kafka::server
}

# == Class role::analytics::kafka::producer::event
# Reads from the /event log stream coming from
# Varnish servers and produces the messages to Kafka.
class role::analytics::kafka::producer::event inherits role::analytics {
	include kraken::kafka::client
	class { "misc::udp2log":
		monitor => false,
	}
	include misc::udp2log::iptables

	# /event log stream udp2log instance.
	# This udp2log instance has filters
	# to produce into Kafka.
	misc::udp2log::instance { "event":
		port                => "8422",
		monitor_packet_loss => false,
		monitor_processes   => false,
		monitor_log_age     => false,
		require             => [Class["kraken::kafka::client"], Class["misc::udp2log::iptables"]]
	}
}

# == Class role::analytics::zookeeper
# Zookeeper Server Role
class role::analytics::zookeeper inherits role::analytics {
	# zookeeper server
	include kraken::zookeeper::server
}

# Storm roles

# == Class role::analytics::storm::master
# Storm Nimbus Server role
class role::analytics::storm::master inherits role::analytics {
	include kraken::storm::master
	# Storm UI server
	include kraken::storm::frontend
}

# == Class role::analytics::storm::worker
# Storm Supervisor Server role
class role::analytics::storm::worker inherits role::analytics {
	include kraken::storm::worker
}


# Hadoop roles

# == Class role::analytics::hadoop::master
# Hadoop NameNode and ResourceManager
class role::analytics::hadoop::master inherits role::analytics::hadoop {
	include kraken::hadoop::master
}

# == Class role::analytics::hadoop::worker
# Hadoop DataNode and NodeManager
class role::analytics::hadoop::worker inherits role::analytics::hadoop {
	include kraken::hadoop::worker
}



# Base role classes

# == Class role::analyics
# Base analytics role class.
# All analytics nodes use this role or a 
# role that inherits from it.
class role::analytics {
	system_role { "role::analytics": description => "analytics server" }
	$nagios_group = "analytics-eqiad"
	# ganglia cluster name.
	$cluster = "analytics"

	# include standard,
	include admins::roots,
		accounts::diederik,
		accounts::dsc,
		accounts::otto,
		accounts::dartar,
		accounts::erosen,
		accounts::olivneh,
		accounts::erik

	sudo_user { [ "diederik", "dsc", "otto" ]: privileges => ['ALL = (ALL) NOPASSWD: ALL'] }

	# Install Sun/Oracle Java JDK on analytics cluster
	java { "java-6-oracle": 
		distribution => 'oracle',
		version      => 6,
	}

	# We want to be able to geolocate IP addresses
	include geoip

	# udp-filter is a useful thing!
	include misc::udp2log::udp_filter
	
	# include default kraken classes, woohoo!
	include kraken
}

# == Class role::analytics::hadoop
# Base hadoop role class.  All hadoop
# nodes use a role class that inhertit from this.
class role::analytics::hadoop inherits role::analytics {
	# hadoop metrics is common to all hadoop nodes
	class { "kraken::hadoop::metrics":
		require => Class["kraken::hadoop::config"],
	}
}

# front end interfaces for Kraken and Hadoop
class role::analytics::frontend inherits role::analytics {
	# include a mysql database for Sqoop and Oozie
	# with the datadir at /a/mysql
	class { "generic::mysql::server":
		datadir => "/a/mysql",
		version => "5.5",
	}
}
