#!/usr/bin/perl -w
use strict;
use Net::SNMP qw(snmp_dispatcher oid_lex_sort);
use Data::Dumper qw(Dumper);
use GraphViz;

my $host = "192.168.11.13";
my $comm = "public";
my $oid = ".1.3.6.1.2.1.17.7.1.2.2.1.2";
#print "";

my ($ses, $err) = Net::SNMP->session(
	-hostname	=>	$host,
	-version	=>	"2",
	-community	=>	"public"
);
my $res = $ses->get_table(".1.3.6.1.2.1.17.7.1.2.2.1.2");

my @mac;
my %hex;
my $c;
#print Dumper \%$res;
foreach (keys(%{$res})) {
	#print "$_ -> $res->{$_}\n";
	$_ =~ /(.1.3.6.1.2.1.17.7.1.2.2.1.2.1.)(.*)/;
	@mac = split(/\./, $2);
	$c = 0;
	foreach my $i (@mac) {
		$mac[$c] = sprintf ("%x", $i);# "$i\n";
		$c++;
	}
	$hex{join("-",@mac)} = $res->{$_};
}
foreach my $hex_mac (keys%hex) {
#	print "$hex_mac => $hex{$hex_mac}\n";
}
$ses->close;

$host = "192.168.11.16";
($ses, $err) = Net::SNMP->session(
	-hostname	=>	$host,
	-version	=>	"2",
	-community	=>	"public"
);
$res = $ses->get_table(".1.3.6.1.2.1.17.7.1.2.2.1.2");
#print $err;
#print Dumper \%$res;

my %hex1;
foreach (keys(%{$res})) {
	#print "$_ -> $res->{$_}\n";
	$_ =~ /(.1.3.6.1.2.1.17.7.1.2.2.1.2.1.)(.*)/;
	@mac = split(/\./, $2);
	$c = 0;
	foreach my $i (@mac) {
		$mac[$c] = sprintf ("%x", $i);# "$i\n";
		$c++;
	}
	$hex1{join("-",@mac)} = $res->{$_};
}

#print Dumper \%$hex1;
foreach my $hex_mac (keys %hex1) {
	#print "$hex_mac -> $hex1{$hex_mac}\n";
}
#print "=-=================\n";
foreach my $hex_mac (keys %hex) {
	#print "$hex_mac -> $hex{$hex_mac}\n";
}
my $g = GraphViz->new();

#$g->add_node("Switch13");
#foreach my $hex_mac (sort {$hex{$a} <=> $hex{$b}} keys %hex) {
#	$g->add_node("$hex_mac");
#	$g->add_edge("$hex_mac" => "Switch13", label => "$hex{$hex_mac}");
#	print "$hex{$hex_mac}\n";
#}

$g->add_node("Switch16");
foreach my $hex_mac (sort {$hex1{$a} <=> $hex1{$b}} keys %hex1) {
	$g->add_node("$hex_mac");
	$g->add_edge("$hex_mac" => "Switch16", label => "$hex1{$hex_mac}");
	print "$hex1{$hex_mac}\n";
}


print $g->as_png;
