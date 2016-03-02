#!/usr/bin/perl
use strict;
use warnings;
use JSON::RPC::Client;
use Zabbix::Tiny;
use Data::Dumper;

#################
#Получаем ИД карты по имени и сносим её без каких либо доп. модулей, ибо с Zabbix::Tiny нифига не работает
#################

my $client = new JSON::RPC::Client;
my $url = 'http://127.0.0.1/zabbix/api_jsonrpc.php';
my $authID;
my $response;

my $json = {
	jsonrpc => "2.0",
	method => "user.login",
	params => {
		user => "Admin",
		password => "zabbix"
	},
	id => 1,
#	auth => "null"
};

$response = $client->call($url, $json);

# Check if response was successful
die "Authentication failed\n" unless $response->content->{'result'};

$authID = $response->content->{'result'};

$json = {
	jsonrpc => "2.0",
	method => "map.getobjects",
	params => {
		name => "topology",
	},
	id => 1,
	auth => $authID
};
$response = $client->call($url, $json);

my $sysmapid = $response->content->{result}[0]{sysmapid}; #получение id карты по имени
die "Get id failed\n" unless $response->is_success;

$json = {
	jsonrpc => "2.0",
	method => "map.delete",
	params => ["$sysmapid"],
	id => 1,
	auth => $authID
};
$response = $client->call($url, $json);
print Dumper \$response;




##############
#Ищем ИД хоста по имени, рисуем карту с хостом
##############
my $username = 'Admin';
my $password = 'zabbix';
#my $url = 'http://127.0.0.1/zabbix/api_jsonrpc.php';

my $zabbix = Zabbix::Tiny->new(
    server   => $url,
    password => $password,
    user     => $username
);

my $hosts = $zabbix->do(
    'host.get',
    output    => [qw(hostid name host)],
);

#print Dumper \$hosts;
my $hostid;
my @arr_hash;
for my $host (@$hosts) { #hostid по имени
    if ($host->{name} eq "orange pi") {$hostid = $host->{hostid};}
}


my %params = (
	'name' => 'topology',
	'width' => '600',
	'height' => '600',
	'selements' => [
		{
			'elementid' => '10106',
			'selementid' => '1',
			'elementtype' => '0',
			'iconid_off' => '2',
			'x' => '50',
			'y' => '150'
		},
		{
			'elementid' => '10107',
			'selementid' => '2',
			'elementtype' => '0',
			'iconid_off' => '2',
			'x' => '200',
			'y' => '150'

		},
		{
			'elementid' => '10108',
			'selementid' => '3',
			'elementtype' => '0',
			'iconid_off' => '2',
			'x' => '400',
			'y' => '150'

		},
		{
			'elementid' => '10109',
			'selementid' => '4',
			'elementtype' => '0',
			'iconid_off' => '2',
			'x' => '100',
			'y' => '100'

		},
		{
			'elementid' => '10110',
			'selementid' => '5',
			'elementtype' => '0',
			'iconid_off' => '2',
			'x' => '400',
			'y' => '100'

		}
	],
	'links' => [
		{
		'selementid1' => '1',
		'selementid2' => '4',
		},
		{
		'selementid1' => '4',
		'selementid2' => '2',
		},
		{
		'selementid1' => '5',
		'selementid2' => '3',
		},
		{
		'selementid1' => '4',
		'selementid2' => '5',
		}
	]
	);
my $res = $zabbix->do('map.create',%params);
print Dumper \$res;

