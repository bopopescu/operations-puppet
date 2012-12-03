class kraken::hive::server {
	include kraken::misc::mysql_java
	include kraken::hive::database

	# symlink the mysql.jar into /var/lib/hive/lib
	file { "/usr/lib/hive/lib/mysql.jar":
		ensure  => "/usr/share/java/mysql.jar",
		require => [Class["kraken::misc::mysql_java"], Package["hive-metastore"], Package["hive-server"]],
	}

	class { "cdh4::hive::server":
		jdbc_driver              => "com.mysql.jdbc.Driver",
		jdbc_url                 => "jdbc:mysql://localhost:3306/$kraken::hive::database::db_name",
		jdbc_username            => $kraken::hive::database::db_user,
		jdbc_password            => $kraken::hive::database::db_pass,
		stats_enabled            => true,
		stats_dbclass            => "jdbc:mysql",
		stats_jdbcdriver         => "com.mysql.jdbc.Driver",
		stats_dbconnectionstring => "jdbc:mysql://localhost:3306/$kraken::hive::database::stats_db_name?user=$kraken::hive::database::db_user&amp;password=$kraken::hive::database::db_pass",
		require                  => [File["/usr/lib/hive/lib/mysql.jar"], Class["kraken::hive::database"]],
	}
}

# == Class kraken::hive::database
# Sets ups a database for hive metadata
class kraken::hive::database {
	include kraken::misc::mysql::server
	
	$db_name    = "hive_metastore"
	$db_user    = "hive"
	# TODO: put this in private puppet repo
	$db_pass    = "hive"

	# name for hive db stats.
	# the same mysql user will be used.
	$stats_db_name = "hive_metrics"

	# hive is going to need an hive database and user.
	exec { "hive_mysql_create_database":
		command => "/usr/bin/mysql -e \"CREATE DATABASE $db_name; USE $db_name; SOURCE /usr/lib/hive/scripts/metastore/upgrade/mysql/hive-schema-0.8.0.mysql.sql;\"",
		unless  => "/usr/bin/mysql -e 'SHOW DATABASES' | /bin/grep -q $db_name",
		user    => "root",
		require => Class["kraken::misc::mysql::server"],
	}

	exec { "hive_mysql_create_stats_database":
		command => "/usr/bin/mysql -e \"CREATE DATABASE $stats_db_name; USE $stats_db_name;\"",
		unless  => "/usr/bin/mysql -e 'SHOW DATABASES' | /bin/grep -q $stats_db_name",
		user    => "root",
		require => Class["kraken::misc::mysql::server"],
	}

	exec { "hive_mysql_create_user":
		command => "/usr/bin/mysql -e \"CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_pass'; CREATE USER '$db_user'@'127.0.0.1' IDENTIFIED BY '$db_pass'; GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost' WITH GRANT OPTION; GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'127.0.0.1' WITH GRANT OPTION; GRANT ALL PRIVILEGES ON $stats_db_name.* TO '$db_user'@'localhost' WITH GRANT OPTION; GRANT ALL PRIVILEGES ON $stats_db_name.* TO '$db_user'@'127.0.0.1' WITH GRANT OPTION; FLUSH PRIVILEGES;\"",
		unless  => "/usr/bin/mysql -e \"SHOW GRANTS FOR '$db_user'@'127.0.0.1'\" | grep -q \"TO '$db_user'\"",
		user    => "root",
		require => [Exec["hive_mysql_create_database"], Exec["hive_mysql_create_stats_database"]],
	}
}


# == Class kraken::hive::database::backup
# Daily mysqldumps hive database and stores into HDFS. 
class kraken::hive::database::backup {
	require kraken::hive::database
	require kraken::hadoop::config
	
	kraken::misc::backup::hdfs::mysql { "hive":
		databases => [$kraken::hive::database::db_name, $kraken::hive::database::stats_db_name],
		mysql_user => $kraken::hive::database::db_user,
		mysql_pass => $kraken::hive::database::db_pass,
		minute  => 0,
		hour    => 6,
	}
}