#!/usr/bin/perl
#
# DESCRIPTION
#
#   This script implements the rename command for the external Linux/UNIX 
#   application.
#
#   The rename command is an input command.  It renames the entry; it cannot
#   move an entry from one container to another in a hierarchical database.  
#   The IDM engine sends the rename command to the subscriber to request
#   that the external application rename an entry.  The rename command must
#   contain an ASSOCIATION element.
#
#
# VARIABLES
#
#   SRC_DN
#     Specifies the distinguished name of the entry in the name space of 
#     eDirectory.
#
#   OLD_SRC_DN
#     Spceifies the old distinguished name of the entry in the name space of 
#     eDirectory.
#
#   REMOVE_OLD_NAME
#     Specifies whether the old relative distinguished name should be deleted
#     or retained.  If not specififed, defaults to "true" which removes the
#     old name.
#
#   CLASS_NAME
#     Specifies the base class of the entry being moved.
#
#   EVENT_ID
#     Specifies an identifier used to identify a particular instance of the 
#     command.
#
#   ASSOCIATION
#     Specifies the unique identifier for the entry in the external application.
#
#   NEW_NAME
#     Specifies the new relative distinguished name for the entry.
#
#
# REPLY FORMAT
#
#    The receiving application should respond to the rename with a STATUS
#    and an optional STATUS_MESSAGE which can be returned for IDM engine 
#    processing and logging facilities.
#
#    The format for returning STATUS and STATUS_MESSAGE are as follows:
#
#      $idmlib->status_<level>("<optional message>");
#
#        <level> may be one of the following values:
#        * success
#        * warning
#        * error
#        * retry
#        * fatal
#
#      Note:  fatal will shutdown the driver, retry will retry the event
#             later on.
#

use strict;
use IDMLib;
use Data::Dumper;

our $global_config;

# include the IDM Library
my $idmlib = new IDMLib();

$idmlib->logger($global_config->{TRACEPRIO}, "rename.pl", " rename invoked ");
$idmlib->trace(" *** rename.pl *** ");

my $CLASS_NAME = $idmlib->idmgetvar("CLASS_NAME");

# INSERT CUSTOM CODE HERE
#
# Retrieve additional information about the event and send back a
# status document indicating the level of success for this modify.
#


# For the skeleton script, simply return a "Not Implemented" status
$idmlib->status_warning("Not Implemented");
