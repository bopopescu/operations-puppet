
@monitor_group { "parsoid_eqiad": description => "eqiad parsoid servers" }
@monitor_group { "parsoid_pmtpa": description => "pmtpa parsoid servers" }
@monitor_group { "parsoidcache_pmtpa": description => "pmtpa parsoid caches" }
@monitor_group { "parsoidcache_eqiad": description => "eqiad parsoid caches" }

class misc::parsoid {
	package { [ "nodejs", "npm", "build-essential", "git-core" ]:
		ensure => latest
	}

	file {
		"/var/lib/parsoid":
			ensure => directory,
			owner => parsoid,
			group => wikidev,
			mode => 2775;
		"/etc/init.d/parsoid":
			source => "puppet:///files/misc/parsoid.init",
			owner => root,
			group => root,
			mode => 0555;
		"/usr/bin/parsoid":
			source => "puppet:///files/misc/parsoid",
			owner => root,
			group => root,
			mode => 0555;
	}

	systemuser {
		parsoid:
			name => "parsoid",
			default_group => "parsoid",
			home => "/var/lib/parsoid";
	}

	service {
		"parsoid":
			hasstatus => true,
			hasrestart => true,
			enable => true,
			ensure => running,
			require => [File["/etc/init.d/parsoid"]];
	}

	monitor_service { "parsoid": description => "Parsoid", check_command => "check_http_on_port!8000" }
}

class misc::parsoid::cache {
	package { [ "varnish" ]:
		ensure => latest
	}

	file {
		"/etc/varnish/default.vcl":
			source => "puppet:///files/misc/parsoid.vcl",
			owner => root,
			group => root,
			mode => 0644;
	}

	service {
		"varnish":
			subscribe => File["/etc/varnish/default.vcl"],
			require => Package[varnish],
			ensure => "running"
	}

	monitor_service { "parsoid Varnish": description => "Parsoid Varnish", check_command => "check_http_generic!varnishcheck!6081" }
}
