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

#Получаю хэш группа:ид
my %params = (
	'output' => 'extend',
	'filter' => {
		'name' => [
			'Hypervisors',
			'Virtual machines'
		]
	}
);
my $res = $zabbix->do('hostgroup.get',%params);
#print Dumper \$res;
my %group;
my @ids;
my %grp;
foreach (@$res) {
	$group{$$_{name}}=$$_{groupid};
	push(@ids, $$_{groupid}); #создаю хэш группа:ид, создаю массив с идами групп
}

#Получаю хэш группа:ид
$grp{groupids} = \@ids;
%params = (
#	'output' => 'extend',
	'output' => ['name'],
	%grp
);
my $res1 = $zabbix->do('host.get',%params);
my %hosts;
foreach (@$res1) {#Хэш имя:ид хоста
	$hosts{$$_{'name'}} = $$_{'hostid'};
#	print Dumper $_;
}
	
print Dumper \%hosts;

