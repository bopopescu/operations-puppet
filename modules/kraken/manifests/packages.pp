# Place for common package dependencies.

class kraken::packages::mysql_java {
	package { "libmysql-java":
		ensure => installed,
	}	
}
