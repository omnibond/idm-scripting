#!/usr/bin/perl
use DB_File::Lock;
use Fcntl qw(:flock O_RDWR O_CREAT);
use strict;
use Data::Dumper;
use MLDBM qw(DB_File::Lock);
use File::Tail;


# include the IDM Library
use IDMLib;
my $idmlib = new IDMLib();

our $SCRIPT_DIR = $ENV{'INSTALL_PATH'}."scripts/";

# call out to globals script to import any global script properties
my $config = do "$SCRIPT_DIR"."/globals.pl";

# log a message to the system log
$idmlib->logger($config->{TRACEPRIO}, "poll.pl", " **** poll.pl *** ");

#
# Insert custom code here to poll for events and submit
# them to the change log, using the $CHANGELOG tool
#

my %ips_hash;
my $filename = "infected_ips.db";
my $locking = "write";
my $ip_hashref;
my $ipaddr;
my $port;
my $ports_hashref;
my @ports;
my $ports_list = "";

# MLDBM allows dbm files to store complex types while using DB_File::Lock for locking
tie(%ips_hash, "MLDBM", $SCRIPT_DIR."/".$filename, O_CREAT|O_RDWR, 0666, $DB_HASH, $locking);

# fetch entry for current IP
foreach $ipaddr (keys %ips_hash) {

   undef @ports;
   my $ports_hashref = $ips_hash{$ipaddr};
   foreach $port (keys %{$ports_hashref}) {

      # add the port and num hits to the ports array
      push(@ports, $port."-".${$ports_hashref}{$port});

      # remove the record from the dbm file
      delete $ips_hash{$ipaddr};
   }

   # join port/num hit data with commas
   $ports_list = join(",", @ports);
my $now = time();
   # push data on changelog
`/opt/novell/usdrv/bin/usclh -c DirXMLjnsuNetworkDevice -t modify << EOF
ADD_DirXMLjnsuDHCPAddress=$ipaddr
ADD_DirXMLjnsuInfectedPorts=$ports_list
ADD_DirXMLjnsuDisabled=true
ADD_DirXMLjnsuDisabledTime=$now
ADD_DirXMLjnsuInfected=true
`;
}

# close the dbm file
untie(%ips_hash);
