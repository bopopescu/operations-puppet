class coredb_mysql(
	$shard,
	$read_only,
	$skip_name_resolve,
	$mysql_myisam,
	$mysql_max_allowed_packet,
	$disable_binlogs,
	$innodb_log_file_size,
	$innodb_file_per_table,
	$long_timeouts,
	$enable_unsafe_locks,
	$large_slave_trans_retries,
	$slow_query_digest) {

	include coredb_mysql::base,
		coredb_mysql::conf,
		coredb_mysql::heartbeat,
		coredb_mysql::packages,
		coredb_mysql::utils

	if $slow_query_digest == true {
		include coredb_mysql::slow_digest
	}

	Class["coredb_mysql"] -> Class["coredb_mysql::conf"]
}
