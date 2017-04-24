#!/usr/bin/perl
#
# DESCRIPTION
#
#   This script implements the query for the external application, Linux/UNIX.  
#
#   The query command is an input command or event. A query is used to find 
#   and read information about entries in the external application, therefore
#   it is both a "search" and a "read" operation.
#
#
# VARIABLES
#
#   SCOPE
#     Specifies the extent of the search.  This attribute supports
#     the following values:  
#       * subtree - indicates to search the base entry and all entries
#         in its branch of the directory tree.  If no scoope is specified,
#         subtree is used as the default value.
#       * subordinates - indicates to search the immediate subordinates of 
#         the base entry (the base entry is not searched).
#       * entry - indicates to search just the base entry.
#     For scopes other than entry, the selected entries can be further
#     limited by the SEARCH_CLASSES and SEARCH_ATTR_ elements.  For scopes of
#     entry, the SEARCH_CLASSES and SEARCH_ATTR_ elements are ignored.
#     
#   DEST_DN
#     Specifies the distinguished name for the starting point for the search.
#     If both the DEST_DN attribute and ASSOCIATION have values, the 
#     ASSOCIATION value is used as the starting point for the search.  If 
#     neither have values, the search begins at the root of the directory.
#
#   CLASS_NAME
#     Specififes the base class of the DEST_DN attribute.
#
#   EVENT_ID
#     Specifies an identifier used to identify a particular instance of the 
#     command or event.
#
#   ASSOCIATION
#     Specifies the unique identifier for the entry where the search begins.  
#     If  both the DEST_DN attribute and the ASSOCIATION have values, the 
#     ASSOCIATION value is used as the starting point for the search.  If 
#     neither have values, the search begins at the root of the directory.
#
#   SEARCH_CLASSES
#     Specifies the search filter for object classes.  If the query contains no
#     SEARCH_CLASSES elements, all entries matching the scope and the 
#     SEARCH_ATTR_ elements are returned.
# 
#   SEARCH_ATTRS
#     Contains a list of the SEARCH_ATTR_ attribute names.
#
#   SEARCH_ATTR_<ATTR_NAME>
#     Specifies the search filter for attribute values.  If more than one 
#     SEARCH_ATTR_ element is specified, the entry must match all attributes
#     to be returned.  
#
#     <ATTR_NAME> will be replaced by the literal name of the attribute, 
#     upper-cased and non-printable characters converted to underscores.
#
#   READ_ATTRS
#     Specifies which attribute values are returned with entries that match
#     the search filters.
#
#   ALL_READ_ATTRS
#     Specifies that all readable attributes should be returned.
#
#   NO_READ_ATTRS
#     Specifies that no attributes are to be returned.
#
#   READ_PARENT
#     Specifies whether the parent of the entry is returned with the entry.
#
#
# REPLY FORMAT
#
#   The receiving application should respond to the query with an INSTANCE 
#   command for each entry returned.  The response should also include a
#   status indicating whether the query was processed successfully.
#   A query should return a successful status even when no entries exist
#   that match the search criteria.
#
#   The format for the INSTANCE command is as follows:
#
#     $idmlib->idmsetvar("COMMAND" "INSTANCE");         (zero or more)
#     $idmlib->idmsetvar("CLASS_NAME", $class-name);    (mandatory)
#     $idmlib->idmsetvar("SRC_DN", $src-dn);            (optional)
#     $idmlib->idmsetvar("ASSOCIATION", $association);  (optional)
#     $idmlib->idmsetvar("PARENT", $parent);            (optional)
#     $idmlib->idmsetvar("ATTR_attribute", $value);     (zero or more)
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
  $idmlib->trace("Query Got Error $err\n");
  $idmlib->status_error("$err");
  exit(1);
}


# Setup global exception handling
BEGIN {
    $SIG{__DIE__} = sub { handle_exception( $_[0] ) };
}

our $global_config;

$idmlib->logger($global_config->{TRACEPRIO}, "query.pl", " query invoked ");
$idmlib->trace(" *** query.pl *** ");

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

my $basedn = $idmlib->idmgetgcv("basedn");
my $grouperbase = $idmlib->idmgetgcv("grouperBaseFolderPath");
my $provisionFlat = $idmlib->idmgetgcv("provisionFlat");

# retrieve information from the query event
my $SCOPE = $idmlib->idmgetvar("SCOPE");
my $CLASS_NAME = $idmlib->idmgetvar("CLASS_NAME");
my $EVENT_ID = $idmlib->idmgetvar("EVENT_ID");
my $ASSOCIATION = $idmlib->idmgetvar("ASSOCIATION");
my $DEST_DN = $idmlib->idmgetvar("DEST_DN");
my @SEARCH_CLASSES = $idmlib->idmgetvar("SEARCH_CLASS");
my @READ_ATTRS = $idmlib->idmgetvar("READ_ATTRS");

my $SEARCH_CLASS;
my $READ_ATTR;

# check the query scope
if ($SCOPE eq "entry") {
  # entry scope queries ask about a particular object

  # check for an association, if the object has already 
  # been associated
  my $SEARCH_BASE = "";
  if ($ASSOCIATION ne "") {
    ($CLASS_NAME, $ASSOCIATION) = split(/\|/, $ASSOCIATION);
    $SEARCH_BASE = $ASSOCIATION;
  } else {
    # without an association, we can use the DEST_DN field to
    # determine the search base for our query
    my ($folderpath, $name)  = $grouper->calcFolderPath($DEST_DN, $basedn, $grouperbase, $provisionFlat);

    if(($folderpath eq "") || ($name eq "")){
      $idmlib->status_error("Could not calculate a folder path!");
      exit(1);
    }
    
    $SEARCH_BASE = "$folderpath:$name";
  }

  # now we should have a search base determined
  if ($SEARCH_BASE ne "") {
    $idmlib->trace("Searching for $CLASS_NAME named $SEARCH_BASE");

    if(($CLASS_NAME eq "Organizational Unit") ||
       ($CLASS_NAME eq "Organization")){
      my($code, $stems) = $grouper->findStems($SEARCH_BASE, "FIND_BY_STEM_NAME");
      if($code != 200){
        $idmlib->status_error("$code: " . $grouper->{resultMessage});
        exit(1);
      }
      if(defined($stems)){
        foreach my $stem (@{$stems}) {
          $idmlib->idmsetvar("COMMAND", "instance");
          $idmlib->idmsetvar("EVENT_ID", $EVENT_ID);
          $idmlib->idmsetvar("SRC_DN", $SEARCH_BASE);
          $idmlib->idmsetvar("CLASS_NAME", $CLASS_NAME);
          $idmlib->idmsetvar("ASSOCIATION", "$CLASS_NAME|$SEARCH_BASE");
      
          # check for which attributes to return (read)
          my $ALL_READ_ATTRS = $idmlib->idmgetvar("ALL_READ_ATTRS");
          if ($ALL_READ_ATTRS eq "TRUE") {
            # return all attributes that can be read
            foreach my $attr (keys(%{$stem})){
              $idmlib->idmsetvar("ATTR_$attr", $stem->{$attr});
            }
          } else {
            # return only those attributes which are requested
            foreach $READ_ATTR (@READ_ATTRS) {
              $idmlib->idmsetvar("ATTR_$READ_ATTR", $stem->{$READ_ATTR});
            }
          }
        }
      }
      $idmlib->status_success("Query complete.");
    }
    elsif($CLASS_NAME eq "Group"){
      my($code, $groups) = $grouper->findGroups($SEARCH_BASE, "FIND_BY_GROUP_NAME_EXACT");
      if($code != 200){
        $idmlib->status_error("$code: " . $grouper->{resultMessage});
        exit(1);
      }
      if(defined($groups)){
        foreach my $group (@{$groups}) {
          $idmlib->idmsetvar("COMMAND", "instance");
          $idmlib->idmsetvar("EVENT_ID", $EVENT_ID);
          $idmlib->idmsetvar("SRC_DN", $SEARCH_BASE);
          $idmlib->idmsetvar("CLASS_NAME", $CLASS_NAME);
          $idmlib->idmsetvar("ASSOCIATION", "$CLASS_NAME|$SEARCH_BASE");
      
          # check for which attributes to return (read)
          my $ALL_READ_ATTRS = $idmlib->idmgetvar("ALL_READ_ATTRS");
          if ($ALL_READ_ATTRS eq "TRUE") {
            # return all attributes that can be read
            foreach my $attr (keys(%{$group})){
              $idmlib->idmsetvar("ATTR_$attr", $group->{$attr});
            }
          } else {
            # return only those attributes which are requested
            foreach $READ_ATTR (@READ_ATTRS) {
              $idmlib->idmsetvar("ATTR_$READ_ATTR", $group->{$READ_ATTR});
            }
          }
        }
      }
      $idmlib->status_success("Query complete.");
    }
    else  {
      $idmlib->status_error("Bad classname: $CLASS_NAME");
    } 
  } else {
    $idmlib->status_error("Unable to derive a search base");
  }
} else {
  # we have a subtree or subordinate query search
  $idmlib->status_warning("Not Implemented");
}

