#!/usr/bin/perl -w
use strict;
use Net::SNMP qw(snmp_dispatcher oid_lex_sort);
use Data::Dumper qw(Dumper);
use GraphViz;
use List::MoreUtils qw/uniq/;

my @hosts = qw (192.168.11.13 192.168.11.16);
my $router = "192.168.11.11";
my $href;
my %res;
my @mac;
my @port;
my $i;
my $g = GraphViz->new();
my $oid;
my %ips;
my @ip;
my ($ses, $err) = Net::SNMP->session(
		-hostname	=>	$router,
		-version	=>	"2",
		-community	=>	"public"
	);
	%res = %{$ses->get_table(".1.3.6.1.2.1.4.22.1.2.2")};

#print Dumper \%res;
my $c=0;
my $tmp;
my @atmp;
foreach (keys(%res)) { #снятие с роутера ип->мак
#	$_ =~ /(.1.3.6.1.2.1.4.22.1.2.2.)(.*)/;
	$c = substr($_, 24);
	$tmp = substr($res{$_}, 2);
	@atmp = ($tmp =~ m/.{2}/g );
	$tmp = join("-", @atmp);
#	$res{$_} = $tmp;
	$ips{$c} = $tmp;
}
$ips{"192.168.11.11"} = "00-05-5d-78-de-16";
#print Dumper \%ips;

foreach my $ip (@hosts) {
	my ($ses, $err) = Net::SNMP->session(
		-hostname	=>	$ip,
		-version	=>	"2",
		-community	=>	"public"
	);



	%res = %{$ses->get_table(".1.3.6.1.2.1.17.7.1.2.2.1.2")}; #mac->port
#	%res = uniq %res; #убирает только ключи, маки остаются,но криво - используются как ключи

	#print Dumper \%res;

	my %hash;
		foreach my $mac (values %res) { #порты с кол-вом повторений
			$hash{$mac} ++;
	}

	my @ports;
	$i = 0;
	foreach my $port (keys %hash) { #порты, число повторений которых > 1
	#	print $repeat;
		if ($hash{$port} > 1) {
			$ports[$i] = $port;
			#print $hash{$repeat};
		}
	}

#foreach (@ports) {print "$_\n";}

	foreach my $mac (keys %res) {#удаление повторяющихся портов из хэша
		foreach (@ports) {
			if ($res{$mac} == $_) {
				delete $res{$mac};
			}
		}
	}

	my $c;
	my %hex_mac;
#	print Dumper \%res;
	foreach (keys(%res)) {
		@mac = split(/\./, substr($_, 30));
		$c = 0;
		foreach my $i (@mac) {
			$mac[$c] = sprintf ("%x", $i);# "$i\n";
			if (length($mac[$c]) == 1) {$mac[$c] = "0".$mac[$c];}#print $mac[$c], "\n";}
			$c++;
		}
		$hex_mac{join("-",@mac)} = $res{$_};
	}
	#print Dumper \%hex_mac;
my $flag;
	$g->add_node("$ip");
	foreach my $mac (sort {$hex_mac{$a} <=> $hex_mac{$b}} keys %hex_mac) {#сортировка портов
		$flag = 0;		
		foreach (keys %ips){
			if ($ips{$_} eq $mac) {
				$g->add_edge("$mac\n$_" => "$ip", label => "$hex_mac{$mac}");
				$flag = 1;
			}
		}
	if ($flag == 0) {$g->add_edge("$mac" => "$ip", label => "$hex_mac{$mac}");}
	}
#print Dumper \%res;
}
$g->add_edge("192.168.11.16" => "192.168.11.13");
print $g->as_png;
