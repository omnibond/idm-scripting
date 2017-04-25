#!/bin/perl
#

use strict;

# include the IDM Library
use IDMLib;
my $idmlib = new IDMLib();

my $SCRIPT_DIR = $ENV{'INSTALL_PATH'}."scripts/";

# call out to globals script
include $INSTALL_PATH/scripts/globals.pl

# log a message to the system log
$idmlib->logger($TRACEPRIO, "poll.pl", " **** poll.pl *** ");

#
# Insert custom code here to poll for events and submit
# them to the change log, using the $CHANGELOG tool
#
