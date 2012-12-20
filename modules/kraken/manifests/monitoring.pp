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


# This requires that the udp2log filters.webrequest.erb is configured to
# publish to the JMX ports below.
class kraken::monitoring::kafka::producer::webrequest inherits kraken::monitoring::jmxtrans {
	# Query each of the Kafka Producers for these predefined queries
	$producer_queries = [
		{
			"obj"        => "kafka:type=kafka.KafkaProducerStats",
			"attr"       => [ "AvgProduceRequestsMs", "MaxProduceRequestMs", "NumProduceRequests", "ProduceRequestsPerSecond" ]
		},
		{
			"obj"        => "kafka.producer.Producer:type=AsyncProducerStats",
			"attr"       => [ "AsyncProducerDroppedEvents", "AsyncProducerEvents" ]
		}
	]

	# query each Kafka udp2log Webrequest Producer
	jmxtrans::metrics { 
		jmx     => "$fqdn:9950",
		queries => $producer_queries,
	}
	jmxtrans::metrics { 
		jmx     => "$fqdn:9951",
		queries => $producer_queries,
	}
	jmxtrans::metrics { 
		jmx     => "$fqdn:9952",
		queries => $producer_queries,
	}
	jmxtrans::metrics { 
		jmx     => "$fqdn:9953",
		queries => $producer_queries,
	}
}