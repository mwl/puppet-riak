class riak {
	$package_filename = "riak_1.1.2-1_amd64.deb"
	$package_location = "/opt/packages/${package_filename}"

	file {
		"/opt/packages":
			ensure => directory,
	}

	file {
		"${package_location}":
			ensure => present,
			mode => 660,
			source => "puppet:///riak/${package_filename}"
	}

	package {
	    "libssl0.9.8":
	        ensure => installed,
	}

	package {
		"riak":
			provider => "dpkg",
			ensure => latest,
			source => $package_location,
			require => [ File[$package_location], Package["libssl0.9.8"] ],
	}

	service {
		"riak":
			ensure => running,
			require => Package["riak"],
			hasrestart => true,
			hasstatus => true,
	}

	file {
		"/etc/riak/app.config":
			ensure => present,
			mode => 644,
			source => "puppet:///riak/app.config",
			require => Package["riak"],
			notify => Service["riak"],
	}
}

