# == Define kraken::cron
# A wrapper around Puppet's native cron resource.
# This forces the use of cronic to silence cron job
# output unless an error is encountered.
#
# TODO: Move this out of Kraken module?
#
# == Parameters:
# $logfile    - If set, output will be stored into this file with tee.  You should make sure $user has permission to write and create $logfile.
#
# The usual cron parameters.
# See: http://docs.puppetlabs.com/references/latest/type.html#cron 
#
define kraken::cron (
	$command,
	$logfile     = undef,
	$user        = undef,
	$environment = undef,
	$hour        = undef,
	$minute      = undef,
	$month       = undef,
	$monthday    = undef,
	$weekday     = undef,
	$ensure      = 'present')
{
	include kraken::cronic

	$cronic_command = $logfile ? {
		undef   => "/usr/local/bin/cronic $command",
		default => "/usr/local/bin/cronic $command | /usr/bin/tee -a $logfile",
	}

	# install a cron job wrapped in cronic
	cron { "$name":
		command     => $cronic_command,
		user        => $user,
		minute      => $minute,
		hour        => $hour,
		weekday     => $weekday,
		month       => $month,
		monthday    => $monthday,
		environment => $environment,
		ensure      => $ensure,
		require     => Class["kraken::cronic"],
	}
}

# == Class kraken::cronic
# Installs the cronic script.
# See: http://habilis.net/cronic/
class kraken::cronic {
	file { "/usr/local/bin/cronic":
		source => "puppet:///modules/kraken/cronic",
		owner  => "root",
		group  => "root",
		mode   => "0755",
	}
}