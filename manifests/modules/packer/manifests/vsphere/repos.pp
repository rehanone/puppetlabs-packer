class packer::vsphere::repos inherits packer::vsphere::params {

  case $::osfamily {

    debian: {

      file { $periodic_file:
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/packer/vsphere/periodic',
      }

      # exec { "apt-update":
      #   command => "/usr/bin/apt-get update"
      # }

      # Apt::Key <| |> -> Exec["apt-update"]
      # Apt::Source <| |> -> Exec["apt-update"]

      Exec['apt_update'] -> Package <| |>

      class { 'apt':
        purge => {
          'sources.list'   => true,
          'sources.list.d' => true,
        },
      }

      apt::source { "$lsbdistcodename":
        release  => $lsbdistcodename,
        location => "$repo_mirror/$repo_name",
        repos    => "$repo_list",
        include  => {
          'src' => true,
          'deb' => true,
        },
      }

      apt::source { "${lsbdistcodename}-updates":
        release  => "$updates_release",
        location => "${repo_mirror}/${repo_name}",
        repos    => "$repo_list",
        include  => {
          'src' => true,
          'deb' => true,
        },
      }

      apt::source { "${lsbdistcodename}-security":
        release  => "$security_release",
        location => "${repo_mirror}/${security_repo_name}",
        repos    => "$repo_list",
        include  => {
          'src' => true,
          'deb' => true,
        },
      }

      if $::operatingsystem == 'Ubuntu' and $::operatingsystemrelease == '16.10' {
        apt::pin { 'apt-puppet-agent':
          packages => 'puppet-agent',
          origin   => 'apt.puppetlabs.com',
          priority => 1001,
        }
        apt::pin { 'builds-puppet-agent':
          packages => 'puppet-agent',
          origin   => 'builds.delivery.puppetlabs.net',
          priority => 1001,
        }
      }
    }

    redhat: {

      resources { 'yumrepo':
        purge => true,
      }

      if $::operatingsystem == 'RedHat' {
        # We don't have consistent mirror urls between RedHat versions:
        $base_url = $::operatingsystemmajrelease ? {
          '7' => "${repo_mirror}/rpm-rhel/7.2/${::architecture}",
          '6' => "${repo_mirror}/rpm-rhel/6.8/${::architecture}",
          '5' => "${os_mirror}/rhel50server-${::architecture}/RPMS.all"
        }
      } else {
        $base_url = $::operatingsystem ? {
          'Fedora'      => "${repo_mirror}/rpm__remote_fedora/releases/${::operatingsystemmajrelease}/Everything/${::architecture}/os",
          'CentOS'      => "${repo_mirror}/rpm__remote_centos/${::operatingsystemmajrelease}/os/${::architecture}",
          'OracleLinux' => "${os_mirror}/${loweros}-${::operatingsystemmajrelease}-${::architecture}/RPMS.all"
        }
      }

      yumrepo { "localmirror-everything":
        descr    => "localmirror-everything",
        baseurl  => "${base_url}",
        gpgcheck => "1",
        gpgkey   => "file:///etc/pki/rpm-gpg/${gpgkey}"
      }
    }

    suse: {

      zypprepo { "localmirror-os":
        descr       => "localmirror-os",
        enabled     => 1,
        autorefresh => 1,
        baseurl     => "${repo_mirror}/${loweros}-${facts[os][release][major]}-sp${facts[os][release][minor]}-${facts[os][architecture]}/RPMS.os",
        gpgcheck    => "1",
        gpgkey      => "file:///etc/pki/rpm-gpg/${gpgkey}",
        type        => 'rpm-md'
      }
    }


   default: {
     fail( "Unsupported platform: ${::osfamily}/${::operatingsystem}" )
   }
  }
}
