class riak($riak_ring = "", $riakhost = $fqdn, $backend_profile = "default") {
	$package_filename = "riak_1.1.2-1_amd64.deb"
	$package_location = "/tmp/${package_filename}"
	$nodename = "riak@${riakhost}"

	file {
		"${package_location}":
			ensure => present,
			mode => 660,
			source => "puppet:///modules/riak/${package_filename}"
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
			content => template('riak/app.config.erb'),
			require => Package["riak"],
			notify => Service["riak"],
	}

	file {
		"/etc/riak/vm.args":
			ensure => present,
			mode => 644,
			content => template('riak/vm.args.erb'),
			require => Package["riak"],
			notify => Service["riak"],
	}

	exec {
	    "/usr/sbin/riak-admin join ${riak_ring}":
	    onlyif => [
	        "test -n \"${riak_ring}\"",
	        "test \"${node_name}\" != \"${riak_ring}\"",
	        "test `sudo /usr/sbin/riak-admin status | grep ^ring_members | grep ${riak_ring} | wc -l` -eq 0"
	        ],
	    require => Service["riak"]
	}
}

