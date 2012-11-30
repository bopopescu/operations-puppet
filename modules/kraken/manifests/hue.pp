# == Class kraken::hue
# Includes cdh4 hue, which will ensure that
# a hue server is running.  This will also
# Include kraken::hue:backup to ensure that
# the Hue database is periodically backed up.
class kraken::hue {
	# hue server
	class { "cdh4::hue":
		# TODO:  Change secret_key and put it in private puppet repo.
		secret_key => "MQBvbk9fk9u1hSr7S13auZyYbRAPK0BbSr6k0NLokTNswv1wNU4v90nUhZE3",
		require    => [Class["kraken::hadoop::config"], Class["kraken::oozie::server"], Class["kraken::hive::server"]],
	}

	include kraken::hue::backup
}

# == Class kraken::hue::backup
#
# Periodically backs up Hue SQLite database.
# Since we are already using Hadoop, and hadoop
# has a redundant filesystem, then lets save this in
# HDFS!
class kraken::hue::backup {
	# we need sqlite3 to do dumps of hue desktop.db SQLite database.
	package { "sqlite3": ensure => "installed" }
	
	$hue_database_path    = "/usr/share/hue/desktop/desktop.db"
	$hue_hdfs_backup_path = "/backups/hue"
	$backup_user = "hdfs"

	# create $backup_path if it doesn't already exist.
	exec { "mkdir_hdfs_${hue_hdfs_backup_path}":
		command => "hadoop fs -mkdir -p $hue_hdfs_backup_path",
		unless  => "hadoop fs -ls -d $hue_hdfs_backup_path | grep -q $hue_hdfs_backup_path",
		user    => $backup_user,
		path    => "/bin:/usr/bin",
		require => Class["cdh4::hadoop::config"],
	}

	# Create a daily SQL dump of the Hue database,
	# and then back it up into HDFS.
	cron { "hue_database_backup":
		command => "backup_file=\"hue_desktop.db_\$(/bin/date +%Y-%m-%d_%H.%M.%S).gz\" && /usr/bin/sqlite3 $hue_database_path .dump | /bin/gzip -c > /tmp/\$backup_file && /usr/bin/hadoop fs -put /tmp/\$backup_file $hue_hdfs_backup_path/\$backup_file",
		user    => $backup_user,
		minute  => 0,
		hour    => 8,
		require => [Class["cdh4::hue"], Package["sqlite3"], Exec["mkdir_hdfs_${hue_hdfs_backup_path}"]],
	}
}