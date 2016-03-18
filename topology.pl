#!/usr/bin/perl -w
use strict;
use Net::SNMP qw(snmp_dispatcher oid_lex_sort);
use Data::Dumper qw(Dumper);
use GraphViz;
use List::MoreUtils qw/uniq/;

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


my @switches = ("192.168.11.13", "192.168.11.16");
my $router = "192.168.11.11";

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

foreach my $ip (@switches) {

	my $smech;
	my %ips;

	if ($ip eq "192.168.11.13") {$oid = ".1.3.6.1.2.1.3.1.1.2.22.1"; $smech = 26};
	if ($ip eq "192.168.11.16") {$oid = ".1.3.6.1.2.1.4.22.1.2.30"; $smech = 25};

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

}

