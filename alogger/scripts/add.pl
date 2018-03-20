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
$i->logger($global_config->{TRACEPRIO}, "add.pl", "***".$ENV{'BASENAME'}."/add.pl *** ");
$i->trace("*** $SCRIPT_DIR/add.pl ***");



# retrieve variables
my $class_name = $i->idmgetvar('CLASS_NAME');
my $SRC_DN = $i->idmgetvar('SRC_DN');
my $SRC_ENTRY_ID = $i->idmgetvar('SRC_ENTRY_ID');

my @fields;
@fields = split("\n",$i->idmgetvar('DirXMLjnsuDDNSPrefix'));
my $ddns_prefix = $fields[0];

@fields = split("\n",$i->idmgetvar('DirXMLjnsuDescription'));
my $description = $fields[0];

@fields = split("\n",$i->idmgetvar('DirXMLjnsuDevice'));
my $device = $fields[0];

@fields = split("\n",$i->idmgetvar('DirXMLjnsuDeviceName'));
my $device_name = $fields[0];

@fields = split("\n",$i->idmgetvar('DirXMLjnsuDHCPAddress'));
my $ip_addr = $fields[0];

@fields = split("\n",$i->idmgetvar('DirXMLjnsuDisabled'));
my $disabled = $fields[0];

@fields = split("\n",$i->idmgetvar('DirXMLjnsuHWAddress'));
my $hw_addr = $fields[0];

@fields = split("\n",$i->idmgetvar('DirXMLjnsuInfectedPorts'));
my $infected_ports = $fields[0];

@fields = split("\n",$i->idmgetvar('DirXMLjnsuMDisabled'));
my $mdisabled = $fields[0];

@fields = split("\n",$i->idmgetvar('DirXMLjnsuMDisabler'));
my $mdisabler = $fields[0];

@fields = split("\n",$i->idmgetvar('DirXMLjnsuNvrExpires'));
my $never_expires = $fields[0];

@fields = split("\n",$i->idmgetvar('DirXMLjnsuRegAddTime'));
my $reg_add_time = $fields[0];

@fields = split("\n",$i->idmgetvar('DirXMLjnsuUserDN'));
my $user_dn = $fields[0];

@fields = split("\n",$i->idmgetvar('DirXMLjnsuRegVersion'));
my $reg_version = 0;
$reg_version = $fields[0];

@fields = split("\n",$i->idmgetvar('DirXMLjnsuStaticAddr'));
my $static_addr = $fields[0];

@fields = split("\n",$i->idmgetvar('DirXMLjnsuInfected'));
my $infected = $fields[0];

@fields = split("\n",$i->idmgetvar('DirXMLjnsuGroupDN'));
my $group_dn = $fields[0];

@fields = split("\n",$i->idmgetvar('DirXMLjnsuDisabledTime'));
my $disabled_time = $fields[0];

@fields = split("\n",$i->idmgetvar('DirXMLjnsuWhyDisabled'));
my $why_disabled = $fields[0];



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
            IP_ADDR = ".$dbh->quote($ip_addr).",
            HW_ADDR = ".$dbh->quote($hw_addr).",
            DESCRIPTION = ".$dbh->quote($description).",
            DDNS_PREFIX = ".$dbh->quote($ddns_prefix).",
            DEVICE = ".$dbh->quote($device).",
            DEVICE_NAME = ".$dbh->quote($device_name).",
            DISABLED = ".$dbh->quote($disabled).",
            INFECTED_PORTS = ".$dbh->quote($infected_ports).",
            MDISABLED = ".$dbh->quote($mdisabled).",
            MDISABLER = ".$dbh->quote($mdisabler).",
            WHY_DISABLED = ".$dbh->quote($why_disabled).",
            DISABLED_TIME = ".$dbh->quote($disabled_time).",
            NEVER_EXPIRES = ".$dbh->quote($never_expires).",
            REG_ADD_TIME = ".$dbh->quote($reg_add_time).",
            USER_DN = ".$dbh->quote($user_dn).",
            GROUP_DN = ".$dbh->quote($group_dn).",
            INFECTED = ".$dbh->quote($infected).",
            REG_VERSION = ".$dbh->quote($reg_version).",
            STATIC_ADDR = ".$dbh->quote($static_addr).",
            ACTION = 'ADD' "
           ;

my $result = $dbh->do($sql);


if ($result == 1) {
  # The modify was successful
  $i->idmsetvar("COMMAND", "ADD_ASSOCIATION");
  $i->idmsetvar("ASSOCIATION", "jnsu-".$hw_addr);
  $i->idmsetvar("DEST_DN", $SRC_DN);
  $i->idmsetvar("DEST_ENTRY_ID", $SRC_ENTRY_ID);
  $i->idmsetvar("EVENT_ID", time() );
  $i->status_success("Added DirXMLjnsuNetworkDevice jnsu-$hw_addr");
}
else{
  $i->status_error("Error addding DirXMLjnsuNetworkDevice $hw_addr");
}
