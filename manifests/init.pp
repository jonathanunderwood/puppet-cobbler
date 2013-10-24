# Class: cobbler
#
# This class manages Cobbler
# https://fedorahosted.org/cobbler/
#
# Parameters:
#
#   - $service_name [type: string]
#     Name of the cobbler service, defaults to 'cobblerd'.
#
#   - $package_name [type: string]
#     Name of the installation package, defaults to 'cobbler'
#
#   - $package_ensure [type: string]
#     Defaults to 'present', buy any version can be set
#
#   - $distro_path [type: string]
#     Defines the location on disk where distro files will be
#     stored. Contents of the ISO images will be copied over
#     in these directories, and also kickstart files will be
#     stored. Defaults to '/distro'
#
#   - $manage_dhcp [type: bool]
#     Wether or not to manage ISC DHCP.
#
#   - $dhcp_dynamic_range [type: string]
#     Range for DHCP server
#
#   - $manage_dns [type: string]
#     Wether or not to manage DNS
#
#   - $dns_option [type: string]
#     Which DNS deamon to manage - Bind or dnsmasq. If dnsmasq,
#     then dnsmasq has to be used for DHCP too.
#
#   - $manage_tftpd [type: bool]
#     Wether or not to manage TFTP daemon.
#
#   - $tftpd_option [type:string]
#     Which TFTP daemon to use.
#
#   - $server_ip [type: string]
#     IP address of a server.
#
#   - $next_server_ip [type: string]
#     Next Server in cobbler config.
#
#   - $nameserversa [type: array]
#     Nameservers for kickstart files to put in resolv.conf upon
#     installation.
#
#   - $dhcp_interfaces [type: array]
#     Interface for DHCP to listen on.
#
#   - $dhcp_subnets [type: array]
#     If you use *DHCP relay* on your network, then $dhcp_interfaces
#     won't suffice. $dhcp_subnets have to be defined, otherwise,
#     DHCP won't offer address to a machine in a network that's
#     not directly available on the DHCP machine itself.
#
#   - $defaultrootpw [type: string]
#     Hash of root password for kickstart files.
#
#   - $apache_service [type: string]
#     Name of the apache service.
#
#   - $allow_access [type: string]
#     For what IP addresses/hosts will access to cobbler_api be granted.
#     Default is for server_ip, ::ipaddress and localhost
#
#   - $purge_distro  [type: bool]
#   - $purge_repo    [type: bool]
#   - $purge_profile [type: bool]
#   - $purge_system  [type: bool]
#     Decides wether or not to purge (remove) from cobbler distro,
#     repo, profiles and systems which are not managed by puppet.
#     Default is true.
#
#   - default_kickstart [type: string]
#     Location of the default kickstart. Default depends on $::osfamily.
#
#   - webroot [type: string]
#     Location of Cobbler's web root. Default: '/var/www/cobbler'.
#
# Actions:
#   - Install Cobbler
#   - Manage Cobbler service
#
# Requires:
#   - puppetlabs/apache class
#     (http://forge.puppetlabs.com/puppetlabs/apache)
#
# Sample Usage:
#
class cobbler (
  $service_name       = $::cobbler::params::service_name,
  $package_name       = $::cobbler::params::package_name,
  $settings_file      = $::cobbler::params::settings_file,
  $package_ensure     = $::cobbler::params::package_ensure,
  $distro_path        = $::cobbler::params::distro_path,
  $manage_dhcp        = $::cobbler::params::manage_dhcp,
  $dhcp_dynamic_range = $::cobbler::params::dhcp_dynamic_range,
  $manage_dns         = $::cobbler::params::manage_dns,
  $dns_option         = $::cobbler::params::dns_option,
  $dhcp_option        = $::cobbler::params::dhcp_option,
  $manage_tftpd       = $::cobbler::params::manage_tftpd,
  $tftpd_option       = $::cobbler::params::tftpd_option,
  $server_ip          = $::cobbler::params::server_ip,
  $next_server_ip     = $::cobbler::params::next_server_ip,
  $nameservers        = $::cobbler::params::nameservers,
  $dhcp_interfaces    = $::cobbler::params::dhcp_interfaces,
  $dhcp_subnets       = $::cobbler::params::dhcp_subnets,
  $dhcp_subnets_advanced = $::cobbler::params::dhcp_subnets_advanced,
  $dhcp_template      = $::cobbler::params::dhcp_template,
  $dhcp_include_files = $::cobbler::params::dhcp_include_files,
  $defaultrootpw      = $::cobbler::params::defaultrootpw,
  $apache_service     = $::cobbler::params::apache_service,
  $allow_access       = $::cobbler::params::allow_access,
  $purge_distro       = $::cobbler::params::purge_distro,
  $purge_repo         = $::cobbler::params::purge_repo,
  $purge_profile      = $::cobbler::params::purge_profile,
  $purge_system       = $::cobbler::params::purge_system,
  $default_kickstart  = $::cobbler::params::default_kickstart,
  $webroot            = $::cobbler::params::webroot,
  $auth_module        = $::cobbler::params::auth_module,
  $puppet_auto_setup  = $::cobbler::params::puppet_auto_setup,
  $sign_puppet_certs_automatically = $::cobbler::params::sign_puppet_certs_automatically,
  $remove_old_puppet_certs_automatically = $::cobbler::params::remove_old_puppet_certs_automatically,
  $manage_selinux_bools = $::cobbler::params::manage_selinux_bools
  ) inherits cobbler::params {
  # Make custom types auto require cobbler service and apache service
  Service[$cobbler::apache_service] -> Cobblerdistro <| |>
  Service[$cobbler::apache_service] -> Cobblerrepo <| |>
  Service[$cobbler::apache_service] -> Cobblersystem <| |>
  Service[$cobbler::apache_service] -> Cobblerprofile <| |>
  
  Service[$cobbler::service_name] -> Cobblerdistro <| |>
  Service[$cobbler::service_name] -> Cobblerrepo <| |>
  Service[$cobbler::service_name] -> Cobblersystem <| |>
  Service[$cobbler::service_name] -> Cobblerprofile <| |>

  # require apache modules
  include ::apache
  include ::apache::mod::wsgi
  include ::apache::mod::proxy
  include ::apache::mod::proxy_http
  include ::apache::mod::setenvif

  # install section
  package { $::cobbler::params::tftp_package:     ensure => present, }
  package { $::cobbler::params::syslinux_package: ensure => present, }
  package { $package_name:
    ensure  => $package_ensure,
    require => [ Package[$::cobbler::params::syslinux_package], Package[$::cobbler::params::tftp_package], ],
  }

  service { $service_name :
    ensure  => running,
    enable  => true,
    require => Package[$package_name],
  }

  # file defaults
  File {
    ensure => file,
    owner  => root,
    group  => root,
    mode   => '0644',
  }
  file { "${::cobbler::params::proxy_config_prefix}/proxy_cobbler.conf":
    content => template('cobbler/proxy_cobbler.conf.erb'),
    notify  => Service[$apache_service],
  }
  file { $distro_path :
    ensure => directory,
    mode   => '0755',
  }
  file { "${distro_path}/kickstarts" :
    ensure => directory,
    mode   => '0755',
  }

  # SELinux booleans
  if $manage_selinux_bools == true {
    $bools = ['cobbler_anon_write',
              'cobbler_can_network_connect',
              'cobbler_use_cifs',
              'cobbler_use_nfs',
              'httpd_can_network_connect_cobbler',
              ]
    selboolean {$bools:
      persistent => true,
      value      => on,
    }
  }
  
  augeas {'cobbler_settings':
    context => "/files/$settings_file",
    lens    => 'CobblerSettings.lns',
    incl    => $settings_file,
    changes => [
                "set default_kickstart $default_kickstart",
                "set puppet_auto_setup $puppet_auto_setup",
                "set sign_puppet_certs_automatically $sign_puppet_certs_automatically",
                "set remove_old_puppet_certs_automatically $remove_old_puppet_certs_automatically",
                "set manage_dns $manage_dns",
                "set manage_tftpd $manage_tftpd",
                "set manage_dhcp $manage_dhcp",
                "set next_server_ip $next_server_ip",
                "set server_ip $server_ip",
                "set default_password_crypted $defaultrootpw"
                ],
    require => Package[$package_name],
    notify  => Service[$service_name],
  }

  file { '/etc/cobbler/modules.conf':
    content => template('cobbler/modules.conf.erb'),
    require => Package[$package_name],
    notify  => Service[$service_name],
  }
  file { "${::cobbler::params::http_config_prefix}/distros.conf": content => template('cobbler/distros.conf.erb'), }
  file { "${::cobbler::params::http_config_prefix}/cobbler.conf": content => template('cobbler/cobbler.conf.erb'), }

  # cobbler sync command
  exec { 'cobblersync':
    command     => '/usr/bin/cobbler sync',
    refreshonly => true,
  }

  Service [$service_name] -> Exec ['cobblersync']

  # purge resources
  if $purge_distro == true {
    resources { 'cobblerdistro':  purge => true, }
  }
  if $purge_repo == true {
    resources { 'cobblerrepo':    purge => true, }
  }
  if $purge_profile == true {
    resources { 'cobblerprofile': purge => true, }
  }
  if $purge_system == true {
    resources { 'cobblersystem':  purge => true, }
  }

  # include ISC DHCP only if we choose manage_dhcp
  if $manage_dhcp == '1' {
    package { 'dhcp':
      ensure => present,
    }
    service { 'dhcpd':
      ensure  => running,
      require => [Package['dhcp'],
                  Augeas['cobbler_settings'],
                  File ['/etc/cobbler/dhcp.template'],
                  ],
      
    }
    file {'/etc/cobbler/dhcp.template':
      ensure  => present,
      owner   => root,
      group   => root,
      mode    => '0644',
      content => template($dhcp_template),
      require => Package[$package_name],
      notify  => Exec['cobblersync'],
    }
    
    Exec['cobblersync'] -> Service['dhcpd']
  }

  # logrotate script
  file { '/etc/logrotate.d/cobbler':
    source => 'puppet:///modules/cobbler/logrotate',
  }
}
# vi:nowrap:
