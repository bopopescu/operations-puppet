# == Class kraken::proxy
# Uses haproxy to set up a proxy to
# internally hosted web services.
#
class kraken::proxy {
	require kraken::hadoop::config, kraken::storm

	$namenode_hostname = $kraken::hadoop::config::namenode_hostname
	$frontend_hostname = "analytics1027.eqiad.wmnet"
	$hue_hostname      = $frontend_hostname
	$oozie_hostname    = $frontend_hostname
	$storm_hostname    = $kraken::storm::nimbus_host
	$storm_port        = $kraken::storm::ui_port

	package { "haproxy": ensure => "installed" }

	file { "/etc/haproxy/haproxy.cfg":
		content => template("kraken/haproxy.cfg.erb"),
		require => Package["haproxy"],
	}
	
	service { "haproxy":
		ensure    => running,
		enable    => true,
		subscribe => File["/etc/haproxy/haproxy.cfg"],
	}
}
