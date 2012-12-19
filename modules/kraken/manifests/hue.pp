# == Class kraken::hue
# Includes cdh4 hue, which will ensure that
# a hue server is running.  This will also
# Include kraken::hue:backup to ensure that
# the Hue database is periodically backed up.
class kraken::hue {
	# hue server
	class { "cdh4::hue":
		# TODO:  Change secret_key and put it in private puppet repo.
		secret_key             => $kraken::private::hue_secret_key,
		smtp_host              => $kraken::smtp_host,
		smtp_from_email        => "hue@$fqdn",
		ldap_url               => "ldaps://virt0.wikimedia.org ldaps://virt1000.wikimedia.org",
		ldap_bind_dn           => "cn=proxyagent,ou=profile,dc=wikimedia,dc=org",
		ldap_bind_password     => $kraken::private::ldap_bind_password,
		ldap_base_dn           => "dc=wikimedia,dc=org",
		ldap_username_pattern  => "uid=<username>,ou=people,dc=wikimedia,dc=org",
		ldap_user_filter       => "objectclass=person",
		ldap_user_name_attr    => "uid",
		ldap_group_filter      => "objectclass=posixgroup",
		ldap_group_member_attr => "member",
		require                => [Class["kraken::hadoop::config"], Class["kraken::oozie::server"], Class["kraken::hive::server"]],
	}

	# include this temporary class until Cloudera releases
	# an new version of hue with this fix.
	include kraken::hue::ldap_patch

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

# == Class kraken::hue::ldap_patch
# 
# NOTE: This is only here temporarily, until Cloudera merges in this
# JIRA: https://issues.cloudera.org/browse/HUE-978
# 
#
# Hue useradmin Ldap group syncing doesn't work as is.
# Use puppet to install the patched version of the file.
class kraken::hue::ldap_patch {
	file { "/usr/share/hue/apps/useradmin/src/useradmin/ldap_access.py":
		source  => "puppet:///modules/kraken/hue_ldap_access.py",
		owner   => 'root',
		group   => 'root',
		mode    => 0644,
		notify  => Service['hue']
	}
}