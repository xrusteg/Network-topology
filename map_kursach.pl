#!/usr/bin/perl -w
use strict;
use Net::SNMP qw(snmp_dispatcher oid_lex_sort);
use Data::Dumper qw(Dumper);
use GraphViz;
use List::MoreUtils qw/uniq/;

my @hosts = qw (192.168.11.13 192.168.11.16);
my $href;
my %res;
my @mac;
my @port;
my $i;
my $g = GraphViz->new();
my $oid;
foreach my $ip (@hosts) {
	my ($ses, $err) = Net::SNMP->session(
		-hostname	=>	$ip,
		-version	=>	"2",
		-community	=>	"public"
	);
	%res = %{$ses->get_table(".1.3.6.1.2.1.17.7.1.2.2.1.2")};
#	%res = uniq %res; #убирает только ключи, маки остаются,но криво - используются как ключи

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
	foreach (keys(%res)) {
	#print "$_ -> $res->{$_}\n";
		$_ =~ /(.1.3.6.1.2.1.17.7.1.2.2.1.2.1.)(.*)/;
		@mac = split(/\./, $2);
		$c = 0;
		foreach my $i (@mac) {
			$mac[$c] = sprintf ("%x", $i);# "$i\n";
			$c++;
		}
		$hex_mac{join("-",@mac)} = $res{$_};
	}

	if ($ip eq "192.168.11.13") {
		$oid = ".1.3.6.1.2.1.3.1.1.2.22.1";
	}
	else {$oid = ".1.3.6.1.2.1.3.1.1.2.30.1";}
	
	%res = %{$ses->get_table($oid)};
	print Dumper \%res;
	foreach (keys(%res)) {
		$_ =~ /(.1.3.6.1.2.1.3.1.1.2.22.1)(.*)/;
		print $_, "\n";
	}

	$g->add_node("$ip");
	foreach my $mac (sort {$hex_mac{$a} <=> $hex_mac{$b}} keys %hex_mac) {#сортировка портов
		$g->add_node("$mac");
		$g->add_edge("$mac" => "$ip", label => "$hex_mac{$mac}");
#	print "$hex{$hex_mac}\n";
	}

#	foreach my $hex_mac (keys %res) {print "$hex_mac -> $res{$hex_mac}\n";}
#print Dumper \%res;


#	print "\n";

}

#print $g->as_png;
#выдаются 22 и 7 порты 13 комм в выдаче у 16 комм
#у 13 30 порт 16 и ещё хз какой 

