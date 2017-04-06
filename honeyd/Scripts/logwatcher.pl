#!/usr/bin/perl
use DB_File::Lock;
use Fcntl qw(:flock O_RDWR O_CREAT);
use strict;
use Data::Dumper;
use MLDBM qw(DB_File::Lock);
use File::Tail;

my %ips_hash;
my %ports;
my $filename = "/opt/novell/usdrv/scripts/infected_ips.db";
my $locking = "write";
my $line;
my @lineparts;
my $file;
my $ip_hashref;
my $ipaddr;
my $port;
my $ports_hashref;
my %new_port_hash;

$file=File::Tail->new(name=>"/var/log/honeyd/honeyd.log", maxinterval=>1, adjustafter=>7);

# process lines from the honeyd log as they are created

while (defined($line=$file->read)) {
   if ($line !~/honeyd log started/) {
      @lineparts = split(" ", $line);


      if ($lineparts[2] ne 'E') {   # ignore expiring messages from honeyd log

         # assign vars for readability
         $ipaddr = $lineparts[3];
         $port = $lineparts[6];

         if ($port =~/\:/) {
            next;
         } 

         # MLDBM allows dbm files to store complex types while using DB_File::Lock for locking
         tie(%ips_hash, "MLDBM", $filename, O_CREAT|O_RDWR, 0666, $DB_HASH, $locking) || die "Couldn't open DBM file\n";

         # fetch entry for current IP
         undef $ports_hashref;
         $ports_hashref = $ips_hash{$ipaddr}; 

         if ($ports_hashref) {  # ip address already in db

            # add port to ports hash for ip address and increment numhits by 1
            ${$ports_hashref}{$port} = ${$ports_hashref}{$port} + 1; 
            $ips_hash{$ipaddr} = $ports_hashref;

         } else {  # ip address not in db yet
            # reset port hash
            undef %new_port_hash;

            # add port to new hash for new ip address
            $new_port_hash{$port} = 1;
            $ips_hash{$ipaddr} = \%new_port_hash;

         }
         # close the dbm file
         untie(%ips_hash);
      }
   }
}
