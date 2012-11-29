# == Class kraken::misc::web::index
#
class kraken::misc::web::index {
	require kraken::hadoop::config, kraken::storm
	
	$frontend_hostname = "analytics1027.eqiad.wmnet"
	$namenode_hostname = $kraken::hadoop::config::namenode_hostname
	$storm_hostname    = $kraken::storm::nimbus_host
	$storm_port        = $kraken::storm::ui_port
	
	file { "/var/www/index.php":
		content => template("kraken/index.php.erb"),
	}
}






# TODO: Remove this class once we are
# no longer hosting our own puppetmaster.

# this class does things that ops production
# usually does, or that we will not need
# in production when we are finished with testing.
class kraken::misc::temp {
	if $hostname != 'analytics1001' {
		Exec {
			environment => "http_proxy=http://brewster.wikimedia.org:8080"
		}

		file { "/etc/profile.d/http_proxy.sh":
			mode    => 0755,
			content => 'export http_proxy="http://brewster.wikimedia.org:8080"
',
		}
	}

	# Make sure puppet runs apt-get update!
	exec { "/usr/bin/apt-get update":
		timeout => 240,
		returns => [ 0, 100 ],
	}

	package { ["curl", "dstat"]: ensure => "installed", before => Class["cdh4::apt_source"] }	

	file { "/etc/profile.d/analytics.sh":
		content => '
alias pupup="pushd .; cd /etc/puppet.analytics && sudo git pull; popd"
alias puptest="sudo puppetd --test --verbose --server analytics1001.wikimedia.org --vardir /var/lib/puppet.analytics --ssldir /var/lib/puppet.analytics/ssl --confdir=/etc/puppet.analytics"
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
			notify => Exec["/usr/bin/apt-get update"],
	}

	
}