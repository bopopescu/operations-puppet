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

# == kraken::kafka::consumer::hadoop::package
# Installs the kafka-hadoop-consumer package.
# https://github.com/wmf-analytics/kafka-hadoop-consumer
#
class kraken::kafka::consumer::hadoop::package {
	package { "kafka-hadoop-consumer": ensure => "installed" }
}

# == Define kraken::kafka::consumer::hadoop
# Sets ups a cron job to periodically consume
# a Kafka topic into Hadoop.
#
# == Parameters:
# $topic             - Kafka topic to consume from
# $consumer_group    - Kafka Consumer Group, this is used to ID consumption state in ZooKeeper
# $hdfs_output_dir   - HDFS path to save consumed messages in
# $limit             - Number of messages to consume.  Default: -1.  -1 means messages will be consumed until the end of the Kafka buffer.
# $user              - Cron job will be installed in this user's crontab
#
# $hour,$minute,$month,$monthday,$weekday - Same parameters as the cron puppet resource type.
#
define kraken::kafka::consumer::hadoop(
	$topic,
	$consumer_group,
	$hdfs_output_dir,
	$limit           = "-1",
	$user            = "hdfs",
	$hour            = undef,
	$minute          = undef,
	$month           = undef,
	$monthday        = undef,
	$weekday         = undef)
	
{
	require kraken
	require kraken::hadoop::config
	require kraken::zookeeper::config
	require kraken::kafka::consumer::hadoop::package

	# Use kraken::zookeeper::config to locate zookeeper hosts
	$zookeeper = inline_template("<%= scope.lookupvar('kraken::zookeeper::config::zookeeper_hosts').join(',') %>")

	cron { "kafka_hadoop_consumer_${name}":
		command  => "/usr/bin/kafka-hadoop-consumer -t $topic -g $consumer_group -o $hdfs_output_dir  -l $limit -z $zookeeper",
		user     => $user,
		hour     => $hour,
		minute   => $minute,
		month    => $month,
		monthday => $monthday,
		weekday  => $weekday,
		require  => Class["kraken::kafka::consumer::hadoop::package"],
	}
}