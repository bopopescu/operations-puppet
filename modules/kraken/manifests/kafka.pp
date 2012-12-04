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
# $topics            - Kafka topics to consume from, comma separated.  If $regex is true, then $topics should be a regex.
# $consumer_group    - Kafka Consumer Group, this is used to ID consumption state in ZooKeeper
# $hdfs_output_dir   - HDFS path to save consumed messages in
# $limit             - Number of messages to consume.  Default: -1.  -1 means messages will be consumed until the end of the Kafka buffer.
# $regex             - true or false.  If true, $topics should be a regex.
# $user              - Cron job will be installed in this user's crontab
#
# $hour,$minute,$month,$monthday,$weekday - Same parameters as the cron puppet resource type.
#
define kraken::kafka::consumer::hadoop(
	$topics,
	$consumer_group,
	$hdfs_output_dir,
	$limit           = "-1",
	$regex           = false,
	$user            = "hdfs",
	$hour            = undef,
	$minute          = undef,
	$month           = undef,
	$monthday        = undef,
	$weekday         = undef)
{
	require kraken
	require kraken::repository # the consumer script we use is from this repository
	require kraken::hadoop::config
	require kraken::zookeeper::config
	require kraken::kafka::consumer::hadoop::package

	$consume_command = "/opt/kraken/bin/kafka-hadoop-consume --topic=$topics --group=$consumer_group --output=$hdfs_output_dir --limit=$limit"
	# append --regex if we should use a regex topic match
	$command = $regex ? {
		true  => "$consume_command --regex",
		false => "$consume_command",
	}

	cron { "kafka_hadoop_consumer_${name}":
		command  => $consume_command,
		user     => $user,
		hour     => $hour,
		minute   => $minute,
		month    => $month,
		monthday => $monthday,
		weekday  => $weekday,
		require  => [Class["kraken::kafka::consumer::hadoop::package"], Class["kraken::repository"]],
	}
}