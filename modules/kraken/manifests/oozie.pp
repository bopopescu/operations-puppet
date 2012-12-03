
class kraken::oozie::server {
	include kraken::misc::mysql_java
	include kraken::oozie::database

	# symlink the mysql.jar into /var/lib/oozie
	file { "/var/lib/oozie/mysql.jar":
		ensure  => "/usr/share/java/mysql.jar",
		require => Class["kraken::misc::mysql_java"]
	}

	class { "cdh4::oozie::server":
		# disable authorization service security, for now.
		# TODO:  enable this once we better figure out
		# oozie jobs.
		authorization_service_security_enabled => false,
		jdbc_driver       => "com.mysql.jdbc.Driver",
		jdbc_url          => "jdbc:mysql://localhost:3306/$kraken::oozie::database::db_name",
		jdbc_database     => $kraken::oozie::database::db_name,
		jdbc_username     => $kraken::oozie::database::db_user,
		jdbc_password     => $kraken::oozie::database::db_pass,
		require           => [File["/var/lib/oozie/mysql.jar"], Class["kraken::oozie::database"]],
	}
}


class kraken::oozie::database {
	include kraken::misc::mysql::server
	
	$db_name    = "oozie"
	$db_user    = "oozie"
	# TODO: put this in private puppet repo
	$db_pass    = "oozie"
	# oozie is going to need an oozie database and user.
	exec { "oozie_mysql_create_database":
		command => "/usr/bin/mysql -e \"CREATE DATABASE $db_name; GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost' IDENTIFIED BY '$db_pass'; GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'%' IDENTIFIED BY '$db_pass';\"",
		unless  => "/usr/bin/mysql -e 'SHOW DATABASES' | /bin/grep -q $db_name",
		user    => 'root',
		require => Class["kraken::misc::mysql::server"]
	}
	
	# The WF_JOBS proto_action_conf is TEXT type by default.
	# This isn't large enough for things that Hue submits.
	# Change it to MEDIUMTEXT.
	exec { "oozie_alter_WF_JOBS":
		command => "/usr/bin/mysql -e 'ALTER TABLE oozie.WF_JOBS CHANGE proto_action_conf proto_action_conf MEDIUMTEXT;'",
		unless  => "/usr/bin/mysql -e 'SHOW CREATE TABLE oozie.WF_JOBS\\G' | grep proto_action_conf | grep -qi mediumtext",
		user    => "root",
		require => Exec["oozie_mysql_create_database"],
	}
}
