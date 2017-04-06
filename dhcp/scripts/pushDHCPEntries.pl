#!/usr/bin/perl

use File::Tail;
use strict ;
use SDBM_File ;
use Fcntl ;

my %hash ;
my $file;
my $line;
my $filename = "/tmp/jnsu-offers";

tie(%hash, 'SDBM_File', $filename, O_RDWR|O_CREAT, 0640)
    or die "Cannot open $filename: $!\n" ;

$file=File::Tail->new(name=>"/var/log/messages", maxinterval=>1, adjustafter=>7);
while (defined($line=$file->read)) {
   if ($line =~/DHCPOFFER/) {
      chop($line);
      my @parts = split(" ", $line);
      my $ip_addr = $parts[7];
      my $hw_addr = $parts[9];

      my @dev_name = undef;
      my $dev_name = "";
      my $i;

      for ($i = 10; $i < $#parts; $i++) {
         if ($parts[$i] eq "via") {
            last;
         } else {
            push(@dev_name, $parts[$i]);
         }
      }
      $dev_name = join(" ", @dev_name);
      chop($dev_name);
      $dev_name = substr($dev_name, 2, length($dev_name) );
      #print "[$ip_addr][$hw_addr][$dev_name]\n";
      $hash{$hw_addr} = 1;

  } elsif ($line =~/DHCPACK/) {
      chop($line);
      my @parts = split(" ", $line);
      my $ip_addr = $parts[7];
      my $hw_addr = $parts[9];

      my @dev_name = undef;
      my $dev_name = "";
      my $i;

      for ($i = 10; $i < $#parts; $i++) {
         if ($parts[$i] eq "via") {
            last;
         } else {
            push(@dev_name, $parts[$i]);
         }
      }
      $dev_name = join(" ", @dev_name);
      chop($dev_name);
      $dev_name = substr($dev_name, 2, length($dev_name) );

      if (defined $hash{$hw_addr}) {
         print "[$ip_addr][$hw_addr][$dev_name]\n";

      #add to change log
`/opt/novell/usdrv/bin/usclh -c DirXMLjnsuNetworkDevice -a jnsu-$hw_addr -t add -s jnsu-$hw_addr << EOF
ADD_DirXMLjnsuDHCPAddress=$ip_addr
ADD_DirXMLjnsuHWAddress=$hw_addr
ADD_DirXMLjnsuDeviceName=jnsu-$hw_addr
ADD_DirXMLjnsuDevice=$dev_name
`;
         delete $hash{$hw_addr};
      }
   }
}
untie %hash;
