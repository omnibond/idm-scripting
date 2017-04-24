#!/usr/bin/perl
#
# DESCRIPTION
#
#   This script implements the add command for the external Linux/UNIX
#   application.
#
#   The add command is an input command.  The IDM engine sends an add command 
#   to the subscriber shim to request that the external application add an 
#   entry.
#
#
# VARIABLES
#
#   SRC_DN
#     Specifies the distinguished name of the entry to add, in the name space
#     of eDirectory.  When the IDM engine sends the add command, the subscriber
#     should copy the SRC_DN attribute to the outgoing DEST_DN command.
#
#   SRC_ENTRY_ID
#     Specifies the entry ID of the entry that generated the add event.  It is
#     specified in the name space of eDirectory.  When the IDM engine sends 
#     the add command, the subscriber should copy the SRC_ENTRY_ID attribute
#     to the outgoing DEST_ENTRY_ID command.
#
#   CLASS_NAME
#     Specifies the base class of the entry being added.
#
#   TEMPLATE_DN
#     Specifies the distinguished name, in the subscriber's name space, of the
#     template to use when creating the entry.
#
#   EVENT_ID
#     Specifies an identifier used to identify a particular instance of the 
#     command.
#
#   ADD_<ATTR_NAME>
#     Specifies an attribute name/value to add with the entry, where 
#     <ATTR_NAME> is literally replaced by the name of the attribute being
#     added.
#
#   PASSWORD
#     Specifies the initial password for the entry.
#
#
# REPLY FORMAT
#
#    The receiving application should respond to the add with a STATUS_LEVEL
#    and if the add suceeded, the subscriber must also return an ASSOCIATION.
#    Optionally, a STATUS_MESSAGE may also be returned to pass string messages
#    to the IDM engine for processing and logging.
#
#    If the add event does not contain values for all attributes defined in 
#    the create rules, the IDM engine discards the add command for the entry.
#    When a modify command is received for this entry, IDM queries eDirectory
#    for the missing attributes.  If all attributes now have values, IDM 
#    changes the modify into an add command.
#
#    The format for returning ASSOCIATION, DEST_DN, DEST_ENTRY_ID, EVENT_ID, 
#    STATUS, STATUS_MESSAGE are as follows:
#
#      $idmlib->idmsetvar("ASSOCIATION", $<association>);
#      $idmlib->idmsetvar("DEST_DN", $<dest_dn>);
#      $idmlib->idmsetvar("DEST_ENTRY_ID", $<dest_entry_id>);
#      $idmlib->idmsetvar("EVENT_ID", $<event_id>);
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
my $SRC_DN = $idmlib->idmgetvar("SRC_DN");
my $EVENT_ID = $idmlib->idmgetvar("EVENT_ID");
my $basedn = $idmlib->idmgetgcv("basedn");
my $grouperbase = $idmlib->idmgetgcv("grouperBaseFolderPath");
my $provisionFlat = $idmlib->idmgetgcv("provisionFlat");
my @DESC = $idmlib->idmgetvar("Description");
# Handle multi-valued descriptions
my $desc = "";
foreach my $d (@DESC){
  if($desc ne ""){
    $desc .= "  ";
  }
  $desc .= $d;
}
my ($folderpath, $name)  = $grouper->calcFolderPath($SRC_DN, $basedn, $grouperbase, $provisionFlat);

if(($folderpath eq "") || ($name eq "")){
  $idmlib->status_error("Could not calculate a folder path!");
  exit(1);
}
my ($code, $result);

$idmlib->trace("Base DN:         $basedn\n");
$idmlib->trace("Base Folder:     $grouperbase\n");
$idmlib->trace("Provision Flat:  $provisionFlat\n");
$idmlib->trace("Source DN:       $SRC_DN\n");
$idmlib->trace("Folder Path:     $folderpath\n");
$idmlib->trace("Name:            $name\n");
$idmlib->trace("Desc:            $desc\n");


if(($CLASS_NAME eq "Organizational Unit") ||
   ($CLASS_NAME eq "Organization")){

  ($code, $result) = $grouper->stemSave("$folderpath:$name", $desc);
  $idmlib->trace("code: $code\n");
}
elsif($CLASS_NAME eq "Group"){
  ($code, $result) = $grouper->groupSave("$folderpath", "$name", $desc);
  $idmlib->trace("code: $code\n");

  foreach my $member (split("\n", $idmlib->idmgetvar("ADD_Member"))){
    $member =~ /([^\\]+)$/;
    my $user = $1;
    $idmlib->trace("ADD: $member ($user)\n");
    my ($code, $result) = $grouper->addMember("$folderpath:$name", $user);
    $idmlib->trace("code: $code\n");
  }
}
else  {
  $idmlib->status_error("Bad classname: $CLASS_NAME");
}

if(($code == 200) || ($code == 201)) {
  $idmlib->status_success("$code");
  $idmlib->idmsetvar("COMMAND", "ADD_ASSOCIATION");
  $idmlib->idmsetvar("EVENT_ID", $EVENT_ID);
  $idmlib->idmsetvar("ASSOCIATION", "$CLASS_NAME|$folderpath:$name");
  $idmlib->idmsetvar("DEST_DN", $SRC_DN);

}
else {
  $idmlib->status_error("$code: " . $grouper->{resultMessage});
}
