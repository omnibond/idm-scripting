#!/user/bin/perl
#
# delete.pl
#
# DESCRIPTION
#
#   This script implements the delete user command for the Meeting Maker
#   application.
#
#   The delete command is an input command. The IDM engine sends the delete
#   command to the subscriber to request that the external application delete
#   an entry.  The delete command must contain an ASSOCIATION element.
#
#
# VARIABLES
#
#   SRC_DN
#     Specifies the distinguished name of the entry to delete, in the name
#     space of eDirectory.
#
#   DEST_DN
#     Spceifies the distinguished name of the entry in the name space of the
#     receiver.
#
#   DEST_ENTRY_ID
#     Spceifies the entry ID for the entry in the name space of the receiver.
#
#   CLASS_NAME
#     Specifies the base class of the entry being deleted.
#
#   EVENT_ID
#     Specifies an identifier used to identify a particular instance of the
#     command.
#
#   ASSOCIATION
#     Specifies the unique identifier for the entry in the external application.
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
#      STATUS_<LEVEL> "<optional message>"
#
#        <LEVEL> may be one of the following values:
#        * SUCCESS
#        * WARNING
#        * ERROR
#        * RETRY
#        * FATAL
#
#      Note:  FATAL will shutdown the driver, RETRY will retry the event
#             later on.
#
use strict;
use IDMLib;        # include the IDM Library
use MIME::Base64;
use OMAPI::CORE;
use OMAPI::DHCP;
use Data::Dumper;
use Net::Interface qw(:constants mac_bin2hex);
use Socket qw(:DEFAULT :crlf);

#get globals
our %config;
our $global_config;
our $SCRIPT_DIR;

require $SCRIPT_DIR."/"."config.pl";

my $i = new IDMLib();
my $RC = 1;
my $result;

# Log and Trace some messages
$i->logger($global_config->{TRACEPRIO}, "delete.pl", "delete.pl");
$i->trace("*** $SCRIPT_DIR/delete.pl ***");

# connect to dhcp server
my $omapi = new OMAPI::DHCP($config{'servername'}, $config{'port'}, $config{'loginkey'});
if (!defined $omapi) {
   $i->status_retry("Could not connect to DHCP server with OMAPI");
   exit;
}


# retrieve variables
my $class_name = $i->idmgetvar('CLASS_NAME');
my $ASSOCIATION = $i->idmgetvar('ASSOCIATION');

# Split the association into the user name (fields[0]) and the server name
# (fields[1])
my @fields = split /-/, $ASSOCIATION;
my $hw_addr = $fields[1];

if ($class_name ne "DirXMLjnsuNetworkDevice"){
  $i->STATUS_ERROR("Unsupported Object Type");
  exit 7;
}

# Build the command to delete the user
# delete existing entry
$result = $omapi->Delete_Host( {'hardware-address' => $hw_addr } );


if ($result->{'name'} ne '') {
  $i->status_success("Deleted network device $ASSOCIATION");
}
else{
  $i->status_error("Error deleting network device $ASSOCIATION");
}


