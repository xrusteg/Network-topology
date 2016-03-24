#!/usr/bin/perl
use strict;
use warnings;
use JSON::RPC::Client;
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

my @nodes;
my @links;

my @mapid;
#$mapid[0] = $zabbix->do('map.getobjects', name => 'topology') -> [0]{'sysmapid'};
#my $qmapid = $zabbix->do('map.delete', \@mapid);

my @hosts;
my $res = $zabbix->do('host.get', groupids => '6', output => 'host');
foreach (@$res) {
#	print $$_{'hostid'}, "\n";
	push (@hosts, $$_{'hostid'});
#	print Dumper \$_;
#	print "QWE";
}
print Dumper \@hosts;
#print Dumper \$res->[2];


