# == Class kraken::hue
# Includes cdh4 hue, which will ensure that
# a hue server is running.  This will also
# Include kraken::hue:backup to ensure that
# the Hue database is periodically backed up.
class kraken::hue {
	# hue server
	class { "cdh4::hue":
		# TODO:  Change secret_key and put it in private puppet repo.
		secret_key            => "MQBvbk9fk9u1hSr7S13auZyYbRAPK0BbSr6k0NLokTNswv1wNU4v90nUhZE3",
		ldap_url              => "ldaps://virt0.wikimedia.org ldaps://virt1000.wikimedia.org",
		ldap_cert             => "/etc/ssl/certs/Equifax_Secure_CA.pem",
		ldap_base_dn          => "dc=wikimedia,dc=org",
		ldap_username_pattern => "uid=<username>,ou=people,dc=wikimedia,dc=org",
		require               => [Class["kraken::hadoop::config"], Class["kraken::oozie::server"], Class["kraken::hive::server"]],
	}

	include kraken::hue::database::backup
}

# == Class kraken::hue::backup
#
# Periodically backs up Hue SQLite database.
# Since we are already using Hadoop, and hadoop
# has a redundant filesystem, then lets save this in
# HDFS!
class kraken::hue::database::backup {
	# we need sqlite3 to do dumps of hue desktop.db SQLite database.
	package { "sqlite3": ensure => "installed" }

	$hue_database_path    = "/usr/share/hue/desktop/desktop.db"
	$hue_hdfs_backup_path = "/backups/hue"

	kraken::misc::backup::hdfs { "hue_database":
		command         => "/usr/bin/sqlite3 $hue_database_path .dump",
		backup_dirname  => "hue",
		backup_filename => "hue_desktop.db",
		minute          => 0,
		hour            => 8,
	}
}