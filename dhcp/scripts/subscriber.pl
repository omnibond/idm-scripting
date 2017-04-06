#!/usr/bin/perl
#
# DESCRIPTION
#
#   This script servers the purpose of setting up necessary information to be 
#   used by the standard event scripts (add, modify, delete, query, rename,
#   and move).  Among these items are utilities for logging, debugging, 
#   retrieving variables from the driver, and setting up system and driver 
#   file paths.  In addition, driver and subscriber initialization parameters
#   (init-params) are passed in here for processing.
#
# ACCESSING INFORMATION
#
#   var = idmgetvar(<variable>);
#     This can be invoked to retrieve a variable from the driver.  The output
#     from this command must be stored away into a perl variable
#
# INCOMING VARIABLES
# 
#   COMMAND
#     Contains the command that is to be executed (add, modify, delete, query,
#     rename or move) by the subscriber.
#
#

use strict;
use IDMLib;
use Data::Dumper;

my $idmlib = new IDMLib();


###################################################################
#
# Save driver and subscriber initialization parameters
#
###################################################################

# set up the database scripts location
our $SCRIPT_DIR = $ENV{'INSTALL_PATH'}."/scripts";

# call out to globals script to import any global script properties
our $global_config = do "$SCRIPT_DIR"."/globals.pl";

###################################################################
#
# Send some informational trace messages to the shim trace file
#
###################################################################
$idmlib->trace("<====== Executing subscriber script ========>");


###################################################################
#
# Call the appropriate script, based on the command type.
# Novell Identity Manager supports the following basic commands:
#   query, add, modify, modify-password, delete, rename, move
#
###################################################################
# Begin the event from Identity Manager
#$idmlib->logger($global_config->{TRACEPRIO}, "subscriber.pl", "*** subscriber.pl ***");

my $command = $idmlib->idmgetvar("COMMAND");

if ($command eq "query") {
  do $global_config->{QUERY_SCRIPT};
} elsif ($command eq "add") {
  do $global_config->{ADD_SCRIPT};
} elsif ($command eq "modify") {
  do $global_config->{MODIFY_SCRIPT};
} elsif ($command eq "modify-password") {
  do $global_config->{MODIFY_PASSWORD_SCRIPT};
} elsif ($command eq "delete") {
  do $global_config->{DELETE_SCRIPT};
} elsif ($command eq "rename") {
  do $global_config->{RENAME_SCRIPT};
} elsif ($command eq "move") {
  do $global_config->{MOVE_SCRIPT};
} else {
  # send back an error status for this unrecognized command
  $idmlib->status_error("Unhandled Command: $command");
}

$idmlib->trace("<====== subscriber script execution finished ========>");
