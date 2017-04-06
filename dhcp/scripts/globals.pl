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
   TRACEPRIO => "info",
   CMDOKPRIO => "info",
   CMDFAILPRIO => "err",
   PUBEVENTPRIO => "info",
   
   # general script tracing options
   
   #################  END Modifiable Flags  ############################
   
   OS_TYPE => `uname -s`,
   OS_VER => `uname -r`,
   
   
   # define our location for the password md5/crypt generator
   NXUTIL => $ENV{'INSTALL_PATH'}."bin/nxutil",
   
   # Define each script location and execution method
   IDMLIB => $ENV{'INSTALL_PATH'}."/scripts/idmlib.pl",
   ADD_SCRIPT => "$SCRIPT_DIR/add.pl",
   ADD_USER_SCRIPT => "$SCRIPT_DIR/add-user.pl",
   ADD_GROUP_SCRIPT => "$SCRIPT_DIR/add-group.pl",
   ASSOCIATION_SCRIPT => "$SCRIPT_DIR/association.pl",
   QUERY_SCRIPT => "$SCRIPT_DIR/query.pl",
   QUERY_READ_USER_SCRIPT => "$SCRIPT_DIR/query-read-user.pl",
   QUERY_READ_GROUP_SCRIPT => "$SCRIPT_DIR/query-read-group.pl",
   QUERY_SEARCH_USER_SCRIPT => "$SCRIPT_DIR/query-search-user.pl",
   QUERY_SEARCH_GROUP_SCRIPT => "$SCRIPT_DIR/query-search-group.pl",
   MODIFY_SCRIPT => "$SCRIPT_DIR/modify.pl",
   MODIFY_USER_SCRIPT => "$SCRIPT_DIR/modify-user.pl",
   ENABLE_USER_SCRIPT => "$SCRIPT_DIR/enable-user.pl",
   DISABLE_USER_SCRIPT => "$SCRIPT_DIR/disable-user.pl",
   MODIFY_GROUP_SCRIPT => "$SCRIPT_DIR/modify-group.pl",
   ADD_GROUP_MEMBER_SCRIPT => "$SCRIPT_DIR/add-group-member.pl",
   REMOVE_GROUP_MEMBER_SCRIPT => "$SCRIPT_DIR/remove-group-member.pl",
   DELETE_SCRIPT => "$SCRIPT_DIR/delete.pl",
   DELETE_USER_SCRIPT => "$SCRIPT_DIR/delete-user.pl",
   DELETE_GROUP_SCRIPT => "$SCRIPT_DIR/delete-group.pl",
   RENAME_SCRIPT => "$SCRIPT_DIR/rename.pl",
   RENAME_USER_SCRIPT => "$SCRIPT_DIR/rename-user.pl",
   RENAME_GROUP_SCRIPT => "$SCRIPT_DIR/rename-group.pl",
   MOVE_SCRIPT => "$SCRIPT_DIR/move.pl",
   MOVE_USER_SCRIPT => "$SCRIPT_DIR/move-user.pl",
   MOVE_GROUP_SCRIPT => "$SCRIPT_DIR/move-group.pl",
   MODIFY_PASSWORD_SCRIPT => "$SCRIPT_DIR/modify-password.pl",
   POLL_SCRIPT => "$SCRIPT_DIR/poll.pl"
}
