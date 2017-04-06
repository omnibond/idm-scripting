#!/usr/bin/perl

use File::Tail;
use strict ;
use SDBM_File ;
use Fcntl ;

my %hash ;
my $file;
my $line;
my $filename = "/tmp/jnsu-offers";

my $ip_addr = "192.168.1.252";
my $hw_addr = "0c:1d:08:10:0e:1f";
my $dev_name = "jnsu-0c:1d:08:10:0e:1f";

      #add to change log
`/opt/novell/usdrv/bin/usclh -c DirXMLjnsuNetworkDevice -a jnsu-$hw_addr -t add -s jnsu-$hw_addr << EOF
ADD_DirXMLjnsuDHCPAddress=$ip_addr
ADD_DirXMLjnsuHWAddress=$hw_addr
ADD_DirXMLjnsuDeviceName=jnsu-$hw_addr
ADD_DirXMLjnsuDevice=$dev_name
`;
