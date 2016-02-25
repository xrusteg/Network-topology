#!/usr/bin/perl
use strict;
use warnings;
use Zabbix::Tiny;
use Data::Dumper;

my $username = 'Admin';
my $password = 'zabbix';
my $url = 'http://127.0.0.1/zabbix/api_jsonrpc.php';

my $zabbix = Zabbix::Tiny->new(
    server   => $url,
    password => $password,
    user     => $username
);

my $hosts = $zabbix->do(
    'host.get',  # First argument is the Zabbix API method
    output    => [qw(hostid name host)],  # Remaining parameters to 'do' are the params for the zabbix method.
    monitored => 1,
    limit     => 2,
    ## Any other params desired
);

print Dumper \$hosts;

# Print some of the retrieved information.
my $hostid;
for my $host (@$hosts) {
    if ($host->{name} eq "orange pi") {$hostid = $host->{hostid};}
#print "Host ID: $host->{hostid} - Display Name: $host->{name}\n";
}

