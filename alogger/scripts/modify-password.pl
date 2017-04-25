#!/usr/bin/perl
#
# DESCRIPTION
# 
#   This script implements the modify-password command for the extenrnal
#   Linux/UNIX application.
#
#   The modify-password is a command from IDM engine to the subscriber to 
#   modify an object password in the application.  An ASSOCIATION is the
#   unique key of the object to modify.
#
#   A driver may or may not implement this functionality, depending on the 
#   applicability to the application.
#
#
# VARIABLES
#
#   SRC_DN
#     The distinguished name of the source object that generated the event in
#     the namespace of eDirectory.
#
#   DEST_DN
#     The distinguished name of the target object in the namespace of the
#     receiver.
#
#   CLASS_NAME
#     The name of the base class of the object.  The class name is mapped 
#     between the application and eDirectory name spaces by the schema mapping
#     rule so that IDM will see the name in the eDirectory namespace and a 
#     driver will see the name in the application name space.
#
#   EVENT_ID
#     An identifier used to tag the result of an event or command.
#
#   OLD_PASSWORD
#     Specifies the current password.
#
#   PASSWORD
#     Specifies the new password.
#
#
# REPLY FORMAT
#
#    The receiving application should respond to the modify with a STATUS
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

# include the IDM Library
my $idmlib = new IDMLib();

$idmlib->logger($global_config->{TRACEPRIO}, "modify-password.pl", " *** modify-password.pl *** ");
$idmlib->trace(" *** modify-password.pl *** ");

# retrieve the association and new password
my $association = $idmlib->idmgetvar("ASSOCIATION");
my $password = $idmlib->idmgetvar("PASSWORD");


# INSERT CUSTOM CODE HERE
#
# Retrieve additional information about the event and send back a
# status document indicating the level of success for this modify-password.
#


# For the skeleton script, simply return a "Not Implemented" status
$idmlib->status_warning("Not Implemented");
