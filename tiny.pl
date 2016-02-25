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

my    %params = (
#	    'output' => 'extend'
	    'name' => 'topology'
	    );

my $hosts = $zabbix->do('map.getobjects',%params);#ид по имени

print Dumper \$hosts;
print $hosts->[0]{sysmapid};
# Print some of the retrieved information.
=pod 
my $hostid;
for my $host (@$hosts) {
    if ($host->{name} eq "orange pi") {$hostid = $host->{hostid};}
#print "Host ID: $host->{hostid} - Display Name: $host->{name}\n";
}
=cut
