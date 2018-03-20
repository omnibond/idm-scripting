#!/usr/bin/perl
#
# DESCRIPTION
#
#   This script implements the modify command for the Junetsu application.
#
#   The modify command is an input command.  The IDM engine sends a modify
#   command to the subscriber to request that the external application modify
#   an entry.  The modify command must contain an ASSOCIATION element.
#
#
# VARIABLES
#
#   SRC_DN
#     Specifies the distinguished name of the entry to modify in the name
#     space of eDirectory.
#
#   CLASS_NAME
#     Specifies the base class of the entry being modified.  This attribute
#     is required for modify events.
#
#   EVENT_ID
#     Specifies an identifier to identify a particular instance of the command.
#
#   ASSOCIATION
#     Specifies the unique identifier for the entry in the external
#     application.  This element is required for modify events.
#
#   ADD_<ATTR_NAME>
#     Specifies one or more values to add to <ATTR_NAME>, where <ATTR_NAME> is
#     literally replaced by the name of the attribute being modified.
#
#   REMOVE_<ATTR_NAME>
#     Specifies one or more values to remove to <ATTR_NAME>, where <ATTR_NAME>
#     is literally replaced by the name of the attribute being modified.
#
#   REMOVE_ALL_<ATTR_NAME>
#     Instructs to remove all values associated with <ATTR_NAME>, where
#     <ATTR_NAME> is literally replaced by the name of the attribute being
#     modified.
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
use Data::Dumper;
use IDMLib;  # include the IDM Library
use DBI;
use DBD::mysql;

# get globals
our $global_config;
our $SCRIPT_DIR;

my $i = new IDMLib();
my $result = 0;

# Log and Trace some messages
$i->logger($global_config->{TRACEPRIO}, "delete.pl", "***".$ENV{'BASENAME'}."/delete.pl *** ");
$i->trace("*** $SCRIPT_DIR/delete.pl ***");



# retrieve variables
my $class_name = $i->idmgetvar('CLASS_NAME');
my $SRC_DN = $i->idmgetvar('SRC_DN');
my $SRC_ENTRY_ID = $i->idmgetvar('SRC_ENTRY_ID');
my $ASSOCIATION = $i->idmgetvar('ASSOCIATION');

my $hw_addr = "";
my $junk = "";
($junk, $hw_addr) = split("-", $ASSOCIATION);


if ($class_name ne "DirXMLjnsuNetworkDevice"){
  $i->status_error("Unsupported Object Type");
  exit 7;
}

my $dbconnstring = $i->idmgetdrvvar("db-conn-string");
my $dbuser = $i->idmgetdrvvar("db-userid");
my $dbpass = $i->idmsubgetnamedpassword("mysqldbpassword");


# connect to the database
my $dbh = DBI->connect($dbconnstring, $dbuser, $dbpass, {PrintError => 0});

if ($dbh eq '') {
   $i->status_retry("Could not connect to MySQL Database: ".$DBI::errstr);
   exit 7;
}

my $sql = "INSERT INTO JNSU_HISTORY SET
            HW_ADDR = ".$dbh->quote($hw_addr).",
            ACTION = 'DELETE'"
           ;

my $result = $dbh->do($sql);


if ($result == 1) {
  # The delete was successful
  $i->status_success("Logged delete of DirXMLjnsuNetworkDevice jnsu-$hw_addr");
}
else{
  $i->status_error("Error logging delete of DirXMLjnsuNetworkDevice $hw_addr ".$DBI::errstr);
}
