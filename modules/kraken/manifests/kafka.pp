class kraken::kafka {
	require kraken  # need this to make sure hadoop group is present
	require kraken::zookeeper::config
	include kafka, kafka::install

	# make sure kafka log directory exists (this is not the data log buffer dir).
	$log_directory = "/var/log/kafka"
	$log_file = "$log_directory/kafka.log"

	# ensure that Kafka log directory exists
	file { $log_directory:
		ensure => "directory",
		mode   => 0775,
		owner  => "kafka",
		group  => "kafka",
	}

	# ensure that Kafka log file is writeable.
	# TODO:  FIX: For some reason, even though udp2log is in
	# the kafka group, it still coudn't write to the file
	# even though it is group writeable.  Just make it 666 for now.
	file { $log_file:
		ensure  => "file",
		mode    => 0666,
		owner   => "kafka",
		group   => "kafka",
		require => File[$log_directory]
	}

	class { "kafka::config":
		zookeeper_hosts => $kraken::zookeeper::config::zookeeper_hosts,
		kafka_log_file  => $log_file,
		require         => File[$log_file],
	}
}

class kraken::kafka::server inherits kraken::kafka {
	# kafka broker server
	include kafka::server
	include kraken::monitoring::kafka::server
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
# $frequency         - how often this cron job runs in minutes.  Use 0 if daily.  This is passed to the kafka-hadoop-consume script.  Default: 15.
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
	$frequency       = "15",
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

	# Since this command will be wrapped in cronic,
	# Redirect stderr to stdout.  The KafkaConsumer
	# generates a lot of logs on stderr, and we
	# only want to get them emailed out if there
	# is a bad exit code.
	# (See define kraken::cron in kraken/cron.pp.)
	$consume_command = "/opt/kraken/bin/kafka-hadoop-consume --topic=$topics --group=$consumer_group --output=$hdfs_output_dir --limit=$limit --frequency=$frequency --redirect-stderr"
	# append --regex if we should use a regex topic match
	$command = $regex ? {
		true  => "$consume_command --regex",
		false => "$consume_command",
	}
	$logfile = "/var/log/kraken/kafka_hadoop_consumer_${name}.log"

	kraken::cron { "kafka_hadoop_consumer_${name}":
		command  => $command,
		logfile  => $logfile,
		user     => $user,
		hour     => $hour,
		minute   => $minute,
		month    => $month,
		monthday => $monthday,
		weekday  => $weekday,
		require  => [Class["kraken::kafka::consumer::hadoop::package"], Class["kraken::repository"]],
	}
}