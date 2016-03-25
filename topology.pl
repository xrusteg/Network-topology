#!/usr/bin/perl -w
use strict;
use Net::SNMP qw(snmp_dispatcher oid_lex_sort);
use Data::Dumper qw(Dumper);
use GraphViz;
use List::MoreUtils qw/uniq/;
use JSON::RPC::Client;
use JSON;
use Zabbix::Tiny;
use Data::Dumper;

sub opros {
	my ($ip, $oid) = @_;
	my %res;
  my ($ses, $err) = Net::SNMP->session(
		-hostname	=>	$ip,
		-version	=>	"2",
		-community	=>	"public"
	);
  return %{$ses->get_table("$oid")};
#	print Dumper \%res;
}

my $username = 'Admin';
my $password = 'zabbix';
my $url = 'http://127.0.0.1/zabbix/api_jsonrpc.php';

my $zabbix = Zabbix::Tiny->new(
    server   => $url,
    password => $password,
    user     => $username
);


my @groups = ("Routers", "Switches", "Nodes"); #создаем группы, если их нет
foreach my $group (@groups) {
	my $exists = $zabbix->do('hostgroup.exists', name => $group);
#print 'true' if $exists;
	if (!$exists) {
		my $res = $zabbix->do('hostgroup.create', name => $group);
		print Dumper \$res;
	}
}

my @switches = ("192.168.11.13", "192.168.11.16");
my $router = "192.168.11.11";

my $groupid = $zabbix->do('hostgroup.get', {filter => {'name'	=>	("Routers")},}) -> [0]{'groupid'};

my $exists = $zabbix->do('host.exists', host => $router);
if (!$exists) {
my	$res = $zabbix->do('host.create', 
	{
		host => $router,
		interfaces => {
			'type'	=>	'1',
			'main'	=>	'1',
			'useip'	=>	'1',
			'ip'	=>	$router,
			'dns'	=>	'',
			'port'	=>	'10050'
		},
		groups	=>	{'groupid'	=>	$groupid},
		templates	=>	{'templateid'	=>	'10104'},
	}
	);
#	print Dumper \$res;
}

$groupid = $zabbix->do('hostgroup.get', {filter => {'name'	=>	("Switches")},}) -> [0]{'groupid'};

foreach my $switch (@switches) {
	my $exists = $zabbix->do('host.exists', host => $switch);
	if (!$exists) {
		my	$res = $zabbix->do('host.create', 
		{
			host => $switch,
			interfaces => {
				'type'	=>	'1',
				'main'	=>	'1',
				'useip'	=>	'1',
				'ip'	=>	$switch,
				'dns'	=>	'',
				'port'	=>	'10050'
			},
			groups	=>	{'groupid'	=>	$groupid},
			templates	=>	{'templateid'	=>	'10104'},
		}
	);
#	print Dumper \$res;
	}
}

my $oid = ".1.3.6.1.2.1.4.22.1.2.2";
my %res = opros($router,$oid);
my %ip_mac;

foreach (keys(%res)) { #снятие с роутера ип->мак
	my $ip = substr($_, 24);
	my $mac = substr($res{$_}, 2);
	my @macs = ($mac =~ m/.{2}/g );
	$mac = join(":", @macs);
	$ip_mac{$ip} = $mac;
}
#print Dumper \%ip_mac;

my $selementid = 1;
my $x = 640;
my $y = 50;
my @nodes;
my @links;

push (@nodes, {		
		'elementid' => '10112',
		'selementid' => $selementid,
		'elementtype' => '0',
		'iconid_off' => '2',
		'x' => $x,
		'y' => $y
	}
);
$x = 426;
$y += 50;
$selementid++;
push (@nodes, {		
		'elementid' => '10113',
		'selementid' => $selementid,
		'elementtype' => '0',
		'iconid_off' => '2',
		'x' => $x,
		'y' => $y
	}
);

	push (@links, {
		'selementid1' => '1',
		'selementid2' => $selementid,
		}
	);
$x += 426;
#$y += 50;
$selementid++;
push (@nodes, {		
		'elementid' => '10114',
		'selementid' => $selementid,
		'elementtype' => '0',
		'iconid_off' => '2',
		'x' => $x,
		'y' => $y
	}
);
	push (@links, {
		'selementid1' => '2',
		'selementid2' => $selementid,
		}
	);
	
my $sel_id;


$selementid = 4;
$x = 50;
$y = 300;
foreach my $ip (@switches) {

	my $smech;
	my %ips;

	if ($ip eq "192.168.11.13") {$oid = ".1.3.6.1.2.1.3.1.1.2.22.1"; $smech = 26;$sel_id = 2;};
	if ($ip eq "192.168.11.16") {$oid = ".1.3.6.1.2.1.4.22.1.2.30"; $smech = 25;$sel_id = 3;$x+=200;};

	%res = opros($ip,$oid);

	foreach (keys(%res)) {
		my $c1 = substr($_, $smech);
		my $tmp = substr($res{$_}, 2);
		my @atmp = ($tmp =~ m/.{2}/g );
		$tmp = join(":", @atmp);
		$ips{$c1} = $tmp;
	}

#print Dumper \%ips;

	my %ports = opros($ip,".1.3.6.1.2.1.17.7.1.2.2.1.2");
	my %hash;
		foreach my $mac (values %ports) { #порты с кол-вом повторений
			$hash{$mac} ++;
	}
#print Dumper \%hash;
	my @ports;
	my $i = 0;

	foreach my $port (keys %hash) { #порты, число повторений которых > 1
		if ($hash{$port} > 2) {
			$ports[$i] = $port;
#			$i++;
		}
	}
#print Dumper \@ports;
	foreach my $mac (keys %ports) {#удаление повторяющихся портов из хэша
		foreach (@ports) {
			if ($ports{$mac} == $_) {
				delete $ports{$mac};
			}
		}
	}
#print Dumper \%ports;
	my %mac_port;
	foreach (keys(%ports)) {
		my @mac = split(/\./, substr($_, 30));
		my $c = 0;
		foreach my $i (@mac) {
			$mac[$c] = sprintf ("%x", $i);
			if (length($mac[$c]) == 1) {$mac[$c] = "0".$mac[$c];}
			$c++;
		}
		$mac_port{join(":",@mac)} = $ports{$_};
	}
#print Dumper \%mac_port;

	my %ip_port;
	foreach my $ip (keys %ips) {
		foreach (keys %mac_port) {
			if ($ips{$ip} eq $_) {
				$ip_port{$ip} = $mac_port{$_};
			}
		}
	}

	foreach my $ip (keys %ip_mac) {
		foreach (keys %mac_port) {
			if ($ip_mac{$ip} eq $_) {
				$ip_port{$ip} = $mac_port{$_};
			}
		}
	}

print Dumper \%ip_port;

my $groupid = $zabbix->do('hostgroup.get', {filter => {'name'	=>	("Nodes")},}) -> [0]{'groupid'}; #если ид группы двузначный, не добавляет в данную группу
foreach my $node (keys(%ip_port)) {
#	print "$ip\t$ip_port{$node}\n";
	my $exists = $zabbix->do('host.exists', host => $node);
	if (!$exists) {
#		print $node;
		my	$res = $zabbix->do('host.create', 
		{
			host => $node,
			interfaces => {
				'type'	=>	'1',
				'main'	=>	'1',
				'useip'	=>	'1',
				'ip'	=>	$node,
				'dns'	=>	'',
				'port'	=>	'10050'
			},
			groups	=>	{'groupid'	=>	$groupid},
			templates	=>	{'templateid'	=>	'10104'},
			inventory_mod => '0',
			inventory	=>	{'hardware'	=>	$ip_port{$node},
				'host_router'	=>	$ip},
		}
	);
#	print Dumper \$res;
	}
}

my	$res = $zabbix->do('host.get', groupids => '6', output => 'hostid', selectInventory => ['host_router'], searchInventory => {'host_router' => $ip});
	foreach (@$res) {
		push (@nodes, {		
			'elementid' => $_->{'inventory'}{'hostid'},
			'selementid' => $selementid,
			'elementtype' => '0',
			'iconid_off' => '2',
			'x' => $x,
			'y' => $y
			}
		);
		push (@links, {
			'selementid1' => $sel_id,
			'selementid2' => $selementid,
			}
		);
		$x += 80;
		$selementid++;
	}
}


my @mapid;
$mapid[0] = $zabbix->do('map.getobjects', name => 'topology') -> [0]{'sysmapid'};
my $qmapid = $zabbix->do('map.delete', \@mapid);

my %params = (
	'name' => 'topology',
	'width' => '1280',
	'height' => '600',
	'selements' => \@nodes,
	'links' => \@links
	);
my $res = $zabbix->do('map.create',%params);
