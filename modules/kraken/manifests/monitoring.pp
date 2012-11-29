# TODO: move monitoring service functions into specific service classes.

class kraken::monitoring::jmxtrans {
	# include jmxtrans
	include jmxtrans

	# set the default output writer to ganglia.
	Jmxtrans::Metrics {
		ganglia => "239.192.1.32:8649"
	}
}

# TODO: does this need to inherit?
# set up jmx monitoring for kafka.
class kraken::monitoring::kafka inherits kraken::monitoring::jmxtrans {
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