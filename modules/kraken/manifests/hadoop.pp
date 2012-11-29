
# == Class kraken::hadoop::config
# Hadoop config common to all analytics nodes.
class kraken::hadoop::config {
	$namenode_hostname        = "analytics1010.eqiad.wmnet"
	$hadoop_name_directory    = "/var/lib/hadoop/name"

	$hadoop_data_directory    = "/var/lib/hadoop/data"
	$datanode_mounts = [
		"$hadoop_data_directory/c",
		"$hadoop_data_directory/d",
		"$hadoop_data_directory/e",
		"$hadoop_data_directory/f",
		"$hadoop_data_directory/g",
		"$hadoop_data_directory/h",
		"$hadoop_data_directory/i",
		"$hadoop_data_directory/j",
		"$hadoop_data_directory/k",
		"$hadoop_data_directory/l"
	]

	class { "cdh4::hadoop::config":
		namenode_hostname    => $namenode_hostname,
		datanode_mounts      => $datanode_mounts,
		dfs_name_dir         => [$hadoop_name_directory],
		dfs_block_size       => 268435456,  # 256 MB
		map_tasks_maximum    => ($processorcount - 2) / 2,
		reduce_tasks_maximum => ($processorcount - 2) / 2,
		map_memory_mb        => 1536,
		io_file_buffer_size  => 131072,
		reduce_parallel_copies => 10,
		mapreduce_job_reuse_jvm_num_tasks => -1,
		mapreduce_child_java_opts => "-Xmx512M",
	}
}

# == Class kraken::hadoop::worker
#
class kraken::hadoop::worker {
	# hadoop worker (datanode, etc.)
	include cdh4::hadoop::worker
}

# == Class kraken::hadoop::master
# Includes cdh4:hadoop::master and 
# makes sure hadoop UI .css files are in place.
class kraken::hadoop::master {
	# hadoop master (namenode, etc.)
	include cdh4::hadoop::master

	# Hadoop namenode web interface is missing a css file.
	# Put it in the proper place.
	# See: https://issues.apache.org/jira/browse/HDFS-3578
	file { "/usr/lib/hadoop-hdfs/webapps/static":
		ensure  => "directory",
		require => Class["cdh4::hadoop::master"],
	}
	file { "/usr/lib/hadoop-hdfs/webapps/static/hadoop.css":
		source  => "file:///usr/lib/hadoop-0.20-mapreduce/webapps/static/hadoop.css",
		require => File["/usr/lib/hadoop-hdfs/webapps/static"],
	}
}

# == Class kraken::hadoop::metrics
# Includes cdh4::hadoop::metrics using the analytics eqiad ganglia mcast address.
class kraken::hadoop::metrics {
	class { "cdh4::hadoop::metrics":
		# TODO:  Use analytics ganglia cluster mcast_address from ganglia.pp in production.
		ganglia_hosts => ["239.192.1.32:8649"],
	}
}