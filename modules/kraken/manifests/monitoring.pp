# TODO: move monitoring service functions into specific service classes.

class kraken::monitoring::jmxtrans {
	# include jmxtrans
	include jmxtrans

	# set the default output writer to ganglia.
	Jmxtrans::Metrics {
		ganglia => "239.192.1.32:8649"
	}
}

# set up jmx monitoring for kafka broker server
class kraken::monitoring::kafka::server inherits kraken::monitoring::jmxtrans {
	# query kafka for jmx metrics
	jmxtrans::metrics { "kafka-$hostname":
		jmx     => "$fqdn:9999",
		queries => [ 
			{
				"obj"    => "kafka:type=kafka.BrokerAllTopicStat",
				"attr"   => [ "BytesIn", "BytesOut", "FailedFetchRequest", "FailedProduceRequest", "MessagesIn" ]
			},
			{
				"obj"    => "kafka:type=kafka.LogFlushStats",
				"attr"   => [ "AvgFlushMs", "FlushesPerSecond", "MaxFlushMs", "NumFlushes", "TotalFlushMs" ]
			},
			{
				"obj"    => "kafka:type=kafka.SocketServerStats",
				"attr"   => [ 
				"AvgFetchRequestMs",
				"AvgProduceRequestMs",
				"BytesReadPerSecond",
				"BytesWrittenPerSecond",
				"FetchRequestsPerSecond",
				"MaxFetchRequestMs",
				"MaxProduceRequestMs",
				"NumFetchRequests",
				"NumProduceRequests",
				"ProduceRequestsPerSecond",
				"TotalBytesRead",
				"TotalBytesWritten",
				"TotalFetchRequestMs",
				"TotalProduceRequestMs"
				]
			}
		]
	}
}


class kraken::monitoring::kafka::producer inherits kraken::monitoring::jmxtrans {
	# Query each of the Kafka Producers for these predefined queries
	$kafka_producer_stats_attr = [ "AvgProduceRequestsMs", "MaxProduceRequestMs", "NumProduceRequests", "ProduceRequestsPerSecond" ]
	$async_producer_stats_attr = [ "AsyncProducerDroppedEvents", "AsyncProducerEvents" ]
}


class kraken::monitoring::kafka::producer::event inherits kraken::monitoring::kafka::producer {
	# webrequest-all.100 kafka producer metrics
	jmxtrans::metrics { "kafka-producer-event-unknown-$hostname":
		jmx     => "$fqdn:9940",
		queries => [
			{
				"obj"          => "kafka:type=kafka.KafkaProducerStats",
				"resultAlias"  => "kafka_producer_KafkaProducerStats-event-unknown",
				"attr"         => $kafka_producer_stats_attr
			},
			{
				"obj"          => "kafka.producer.Producer:type=AsyncProducerStats",
				"resultAlias"  => "kafka_producer_AsyncProducerStats-event-unknown",
				"attr"         => $async_producer_stats_attr
			}
		]
	}
}

# This requires that the udp2log filters.webrequest.erb is configured to
# publish to the JMX ports below.
class kraken::monitoring::kafka::producer::webrequest inherits kraken::monitoring::kafka::producer {

	# query each Kafka udp2log Webrequest Producer

	# webrequest-all.100 kafka producer metrics
	jmxtrans::metrics { "kafka-producer-webrequest-all.100-$hostname":
		jmx     => "$fqdn:9950",
		queries => [
			{
				"obj"          => "kafka:type=kafka.KafkaProducerStats",
				"resultAlias"  => "kafka_producer_KafkaProducerStats-webrequest-all.100",
				"attr"         => $kafka_producer_stats_attr
			},
			{
				"obj"          => "kafka.producer.Producer:type=AsyncProducerStats",
				"resultAlias"  => "kafka_producer_AsyncProducerStats-webrequest-all.100",
				"attr"         => $async_producer_stats_attr
			}
		]
	}

	# webrequest-wikipedia-mobile kafka producer metrics
	jmxtrans::metrics { "kafka-producer-webrequest-wikipedia-mobile-$hostname":
		jmx     => "$fqdn:9951",
		queries => [
			{
				"obj"          => "kafka:type=kafka.KafkaProducerStats",
				"resultAlias"  => "kafka_producer_KafkaProducerStats-webrequest-wikipedia-mobile",
				"attr"         => $kafka_producer_stats_attr
			},
			{
				"obj"          => "kafka.producer.Producer:type=AsyncProducerStats",
				"resultAlias"  => "kafka_producer_AsyncProducerStats-webrequest-wikipedia-mobile",
				"attr"         => $async_producer_stats_attr
			}
		]
	}

	# webrequest-blog kafka producer metrics
	jmxtrans::metrics { "kafka-producer-webrequest-blog-$hostname":
		jmx     => "$fqdn:9952",
		queries => [
			{
				"obj"          => "kafka:type=kafka.KafkaProducerStats",
				"resultAlias"  => "kafka_producer_KafkaProducerStats-webrequest-blog",
				"attr"         => $kafka_producer_stats_attr
			},
			{
				"obj"          => "kafka.producer.Producer:type=AsyncProducerStats",
				"resultAlias"  => "kafka_producer_AsyncProducerStats-webrequest-blog",
				"attr"         => $async_producer_stats_attr
			}
		]
	}

	# webrequest-zero kafka producer metrics
	jmxtrans::metrics { "kafka-producer-webrequest-zero-$hostname":
		jmx     => "$fqdn:9953",
		queries => [
			{
				"obj"          => "kafka:type=kafka.KafkaProducerStats",
				"resultAlias"  => "kafka_producer_KafkaProducerStats-webrequest-zero",
				"attr"         => $kafka_producer_stats_attr
			},
			{
				"obj"          => "kafka.producer.Producer:type=AsyncProducerStats",
				"resultAlias"  => "kafka_producer_AsyncProducerStats-webrequest-zero",
				"attr"         => $async_producer_stats_attr
			}
		]
	}
}