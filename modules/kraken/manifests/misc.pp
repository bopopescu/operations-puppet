
# == Class kraken::misc::web
#
class kraken::misc::web {
	require kraken::hadoop::config, kraken::storm
	
	$frontend_hostname = "analytics1027.eqiad.wmnet"
	$namenode_hostname = $kraken::hadoop::config::namenode_hostname
	$storm_hostname    = $kraken::storm::nimbus_host
	$storm_port        = $kraken::storm::ui_port
	
	file { "/var/www/index.php":
		content => template("kraken/index.php.erb"),
	}

	file { "/var/www/monitor":
		ensure => "directory",
	}

	file { "/var/www/monitor/index.php":
		source => "puppet:///modules/kraken/monitor_index.php",
	}
}


# == Class kraken::misc::mysql_java
# Installs libmysql-java Java mysql bindings.
class kraken::misc::mysql_java {
	package { "libmysql-java":
		ensure => installed,
	}
}


# == Class kraken::misc::mysql::server
# Sets up a mysql server for misc Kraken services.
# TODO:  This reaches out to a generic manifest,
# rather than a module.  We should have a mysql module.
class kraken::misc::mysql::server {
	# Set up a mysql database
	# with the datadir at /a/mysql
	class { "generic::mysql::server":
		datadir => "/a/mysql",
		version => "5.5",
	}
}

# == Define kraken::misc::email::aliases
# TODO: I don't think this define should
# be part of the kraken module.
define kraken::misc::email::alias($email) {
	$line = "$name: $email"
	exec { "email_aliases_$name":
		command => "/bin/echo '$line' >> /etc/aliases",
		unless  => "/bin/grep -q '$line' /etc/aliases",
	}

	# TODO:  Why isn't this working?
	# Nothing actually happens. :(
	# file_line { "email_aliases_$name":
	# 		path => "/etc/aliases",
	# 		line => "$name: $email"
	# 	}
}

# == Class kraken::misc::cron::email
# Make sure all cron email goes to otto@wikimedia.org
class kraken::misc::email::aliases {
	$admin_email = "otto@wikimedia.org"
	kraken::misc::email::alias { "hdfs": email => $admin_email }
	kraken::misc::email::alias { "root": email => $admin_email }
}




# == Define kraken::misc::backup::hdfs
# Installs a cron job to periodically back up data to HDFS.
# Must specify either $command or $source_file.
#
# == Parameters:
# $command         - Output of the command will be saved into hdfs
# $source_file     - This file will be put into hdfs
# $compress        - If true, the output or the file will be compressed using gzip
# $backup_filename - Name of the backup file
# $backup_dirname  - Name of the backup sub directory
# $backup_dir      - The root backup dir to put backups in.  The actual files will be in $backup_dir/$name.  Default: /backups
# $backup_user     - The user to run commands as.
#
# $hour,$minute,$month,$monthday,$weekday - Same parameters as the cron puppet resource type.
#
# TODO: Should this be in cdh4 module?
define kraken::misc::backup::hdfs(
	$command         = undef,
	$source_file     = undef,
	$compress        = true,
	$backup_filename = undef,
	$backup_dirname  = undef,
	$backup_dir      = "/backups",
	$backup_user     = 'hdfs',
	$hour            = undef,
	$minute          = undef,
	$month           = undef,
	$monthday        = undef,
	$weekday         = undef)


{
	require cdh4::hadoop::config

	if (!$command and !$source_file) {
		fail("Must specify one of \$command or \$source_file when using define kraken::misc::backup::hdfs.")
	}

	# if backup_direname was specifed, then store backups
	# in $backup_path/$backup_dirname, 
	# else store them in $backup_dir/$name
	$backup_path = $backup_dirname ? {
		undef   => "${backup_dir}/${name}",
		default => "${backup_dir}/${backup_dirname}"
	}

	# create $backup_path if it doesn't already exist.
	exec { "mkdir_hdfs_${backup_path}":
		command => "hadoop fs -mkdir -p $backup_path",
		unless  => "hadoop fs -ls -d $backup_path | grep -q $backup_path",
		user    => $backup_user,
		path    => "/bin:/usr/bin",
	}

	# determine hdfs $backup_file

	# $timestamp_command will be prefixed at the end of each file backup.
	# (Need to escape %; cron uses this as newline separator.)
	$timestamp_command = "\$(/bin/date \"+\\%Y-\\%m-\\%d_\\%H.\\%M.\\%S\")"	
	$backup_file = $backup_filename ? {
		# if backup_filename was not given, then infer the filename from $name or $source_file
		undef   => $command ? {
			# use $source_file for $backup_file
			undef   => "${backup_path}/\$(/usr/bin/basename ${source_file})_${timestamp_command}",
			# else $command was specified, so use just use $name
			default => "${backup_path}/${name}_${timestamp_command}",
		},
		# else, we were given a specific filename to use, so use that.
		default => "$backup_path/${backup_filename}_${timestamp_command}",
	}

	# if we are backing up using a command,
	# pipe the output of the command into hadoop fs -put
	if ($command) {
		# if compress is true, then first pipe the output through gzip
		$backup_command = $compress ? {
			true    => "${command} | /bin/gzip -c | /usr/bin/hadoop fs -put - ${backup_file}.gz",
			false   => "${command} | /usr/bin/hadoop fs -put - ${backup_file}",
		}
	}	
	# else just put the file
	else {
		# if compress is true, then first gzip the file
		$backup_command = $compress ? {
			true    => "/bin/gzip -c ${source_file} | /usr/bin/hadoop fs -put - ${backup_file}.gz",
			false   => "/usr/bin/hadoop fs -put ${source_file} ${backup_file}",
		}
	}

	# Create a cron job that periodically backs up
	# the $source_file or the output of $command into HDFS.
	kraken::cron { "${name}_hdfs_backup":
		command  => $backup_command,
		user     => $backup_user,
		hour     => $hour,
		minute   => $minute,
		month    => $month,
		monthday => $monthday,
		weekday  => $weekday,
		require  => [Class["cdh4"],  Exec["mkdir_hdfs_${backup_path}"]],
	}
}




# == Define kraken::misc::mysql::backup
# Installs a cron to back up mysqldump database dumps to HDFS.
# This uses the kraken::misc::backup::hdfs define.
#
# == Parameters:
# $databases         - Array of database names to dump
# $compress          - If true, files will be gzip compressed.  Default: true.
# $mysql_user
# $mysql_pass
#
# $hour,$minute,$month,$monthday,$weekday - Same parameters as the cron puppet resource type.
#
define kraken::misc::backup::hdfs::mysql(
	$databases,
	$compress        = true,
	$mysql_user      = 'root',
	$mysql_pass      = '',
	$hour            = undef,
	$minute          = undef,
	$month           = undef,
	$monthday        = undef,
	$weekday         = undef)
{
	kraken::misc::backup::hdfs { "${name}_mysql":
		command         => inline_template("/usr/bin/mysqldump --user=$mysql_user --password=$mysql_pass --databases <%= databases.class == Array ? databases.join(' ') : databases %> "),
		backup_filename => "${name}.sql",
		backup_dirname  => $name,
		compress        => $compress,
		hour            => $hour,
		minute          => $minute,
		month           => $month,
		monthday        => $monthday,
		weekday         => $weekday,
		require         => Class["kraken::misc::mysql::server"],
	}
}





# TODO: Remove this class once we are
# no longer hosting our own puppetmaster.

# this class does things that ops production
# usually does, or that we will not need
# in production when we are finished with testing.
class kraken::misc::temp {
	# include kraken::private class.
	# this is manually put in place on analytics1001.
	# it is not in git.
	include kraken::private
	
	if $hostname != 'analytics1001' {
		file { "/etc/profile.d/http_proxy.sh":
			mode    => 0755,
			content => 'export http_proxy="http://brewster.wikimedia.org:8080"
',
		}

		# set git proxy for root on non analytics1001 hosts
		exec { "git_proxy":
			command => "/usr/bin/git config --global --add http.proxy http://brewster.wikimedia.org:8080",
			unless  => "/bin/grep -q 'proxy = http://brewster.wikimedia.org:8080' /root/.gitconfig",
			user    => "root",
			require => Package["git-core"],
		}
	}

	package { ["curl", "dstat"]: ensure => "installed", before => Class["cdh4::apt_source"] }	

	file { "/etc/profile.d/analytics.sh":
		content => '
alias pupup="pushd .; cd /etc/puppet.analytics && sudo git pull; popd"
alias puptest="sudo puppetd --test --verbose --server analytics1001.wikimedia.org --vardir /var/lib/puppet.analytics --ssldir /var/lib/puppet.analytics/ssl --confdir=/etc/puppet.analytics --rundir=/var/run/puppet.analytics"
alias pupsign="sudo puppetca --vardir /var/lib/puppet.analytics --ssldir /var/lib/puppet.analytics/ssl --confdir=/etc/puppet.analytics sign "
export HADOOP_MAPRED_HOME=/usr/lib/hadoop-mapreduce',
		mode => 0755,
	}

	file {
		"/etc/apt/sources.list.d/kraken.list":
			content => "deb http://analytics1001.wikimedia.org/apt binary/
deb-src http://analytics1001.wikimedia.org/apt source/
",
			mode => 0444,
	}
}