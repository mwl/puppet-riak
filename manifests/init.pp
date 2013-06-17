class riak($riak_ring = "", $riakhost = $fqdn, $backends = [], $datadir = '/var/lib/riak', $vmargs_pa = "", $vmargs_s = "") {
	$package_filename = "riak_1.3.0-1_amd64.deb"
	$package_location = "/tmp/${package_filename}"
	$nodename = "riak@${riakhost}"

	file {
		"${package_location}":
			ensure => present,
			mode => 660,
			source => "puppet:///modules/riak/${package_filename}"
	}
  
    file {"/etc/default/riak":
        ensure => present,
        content => "ulimit -n 4096 ",
        notify => Service["riak"]
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
			require => [ File[$package_location], Package["libssl0.9.8"] ]
	}

	service {
		"riak":
			ensure => running,
			require => [Package["riak"], File["/etc/default/riak"], File["$datadir"]],
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

	file {"$datadir":
	    ensure => directory,
	    owner => "riak",
	    require => Package["riak"]
	}

	exec {
	    "/usr/sbin/riak-admin join -f ${riak_ring}":
	    onlyif => [
	        "test -n \"${riak_ring}\"",
	        "test \"${nodename}\" != \"${riak_ring}\"",
	        "test `sudo /usr/sbin/riak-admin status | grep ^ring_members | grep ${riak_ring} | wc -l` -eq 0"
	        ],
	    require => Service["riak"]
	}
}

