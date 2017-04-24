#!/usr/bin/perl
#
# DESCRIPTION
#
#   This script implements the delete command for the external Linux/UNIX 
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
our $SCRIPT_DIR = $ENV{'INSTALL_PATH'}."scripts";
use lib("$SCRIPT_DIR");
use GrouperWS;

# include the IDM Library
my $idmlib = new IDMLib();

sub handle_exception {
  my ($err) = @_;

  if($err =~ /malformed JSON string/){
    # ignore - exception will be handled 
    return;
  }
  $idmlib->trace("Subscriber Got Error $err\n");
  $idmlib->status_error("$err");
  exit(1);
}


# Setup global exception handling
BEGIN {
    $SIG{__DIE__} = sub { handle_exception( $_[0] ) };
}

our $global_config;

$idmlib->logger($global_config->{TRACEPRIO}, "add.pl", " add invoked ");
$idmlib->trace(" *** add.pl *** ");

my $grouper;

my $urlPrefix = $idmlib->idmgetgcv("grouperWSUrl");
my $username = $idmlib->idmgetgcv("grouperUsername");
my $password =  $idmlib->idmgetnamedpassword("grouperPassword");
$grouper = new GrouperWS( urlPrefix => $urlPrefix,
                            username => $username,
                            password => $password);
if(!$grouper) {
  status_fatal("Could not initialize Grouper library.");
}

my $CLASS_NAME = $idmlib->idmgetvar("CLASS_NAME");
my $ASSOCIATION = $idmlib->idmgetvar("ASSOCIATION");
my $SRC_DN = $idmlib->idmgetvar("SRC_DN");
my $EVENT_ID = $idmlib->idmgetvar("EVENT_ID");
my $basedn = $idmlib->idmgetgcv("basedn");
my $grouperbase = $idmlib->idmgetgcv("grouperBaseFolderPath");
my $provisionFlat = $idmlib->idmgetgcv("provisionFlat");
my ($CLASS_NAME, $grouperName) = split(/\|/, $ASSOCIATION);

$idmlib->trace("Class Name:      $CLASS_NAME\n");
$idmlib->trace("Base DN:         $basedn\n");
$idmlib->trace("Base Folder:     $grouperbase\n");
$idmlib->trace("Provision Flat:  $provisionFlat\n");
$idmlib->trace("Source DN:       $SRC_DN\n");
$idmlib->trace("Association:     $ASSOCIATION\n");
$idmlib->trace("Grouper Name:    $grouperName\n");

my ($code, $result);

if(($CLASS_NAME eq "Organizational Unit") ||
   ($CLASS_NAME eq "Organization")){

  ($code, $result) = $grouper->stemDelete("$grouperName");
  $idmlib->trace("code: $code\n");
}
elsif($CLASS_NAME eq "Group"){
  my ($folderpath, $name);
  if($grouperName =~ /(.+):([^:]+)/){
    $folderpath = $1;
    $name = $2;
  }
  ($code, $result) = $grouper->groupDelete($folderpath, $name);
  $idmlib->trace("code: $code\n");
}
else  {
  $idmlib->status_error("Bad classname: $CLASS_NAME");
}

if(($code == 200) || ($code == 201)) {
  $idmlib->status_success("$code");
}
else {
  $idmlib->status_error("$code: " . $grouper->{resultMessage});
}
