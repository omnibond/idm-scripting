#!/usr/bin/perl
#
# DESCRIPTION
#   The globals.pl script sets global information, such as file paths and
#   settings that are used by all scripts.
#
#
use strict;

# set up the database scripts location
our $SCRIPT_DIR;

# set some global path and variable information
$ENV{'PATH'} = "/usr/xpg4/bin:/usr/bin:/usr/ucb:/usr/ccs/bin:/usr/local/bin:/bin:/usr/sbin";

return {
   ################  BEGIN Modifiable Flags  ###########################
   
   # define symbolic priorities for certain classes of frequently logged
   # messages.
   TRACEPRIO => "debug",
   CMDOKPRIO => "info",
   CMDFAILPRIO => "err",
   PUBEVENTPRIO => "info",
   
   # general script tracing options
   
   #################  END Modifiable Flags  ############################
   
   OS_TYPE => `uname -s`,
   OS_VER => `uname -r`,
   
   
   # define our location for the password md5/crypt generator
   USUTIL => $ENV{'INSTALL_PATH'}."bin/usutil",
   
   # Define each script location and execution method
   IDMLIB => $ENV{'INSTALL_PATH'}."/scripts/idmlib.pl",
   ADD_SCRIPT => "$SCRIPT_DIR/add.pl",
   ASSOCIATION_SCRIPT => "$SCRIPT_DIR/association.pl",
   QUERY_SCRIPT => "$SCRIPT_DIR/query.pl",
   MODIFY_SCRIPT => "$SCRIPT_DIR/modify.pl",
   DELETE_SCRIPT => "$SCRIPT_DIR/delete.pl",
   RENAME_SCRIPT => "$SCRIPT_DIR/rename.pl",
   MOVE_SCRIPT => "$SCRIPT_DIR/move.pl",
   MODIFY_PASSWORD_SCRIPT => "$SCRIPT_DIR/modify-password.pl",
   POLL_SCRIPT => "$SCRIPT_DIR/poll.pl"
}
