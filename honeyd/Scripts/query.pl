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
#     $imdlib->idmsetvar("COMMAND" "INSTANCE");         (zero or more)
#     $imdlib->idmsetvar("CLASS_NAME", $class-name);    (mandatory)
#     $imdlib->idmsetvar("SRC_DN", $src-dn);            (optional)
#     $imdlib->idmsetvar("ASSOCIATION", $association);  (optional)
#     $imdlib->idmsetvar("PARENT", $parent);            (optional)
#     $imdlib->idmsetvar("ATTR_attribute", $value);     (zero or more)
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

$idmlib->logger($global_config->{TRACEPRIO}, "query.pl", " *** query.pl *** ");
$idmlib->trace(" *** query.pl *** ");

# retrieve information from the query event
my $SCOPE = $idmlib->idmgetvar("SCOPE");
my $CLASS_NAME = $idmlib->idmgetvar("CLASS_NAME");
my $ASSOCIATION = $idmlib->idmgetvar("ASSOCIATION");
my $DEST_DN = $idmlib->idmgetvar("DEST_DN");
my $SEARCH_CLASSES = $idmlib->idmgetvar("SEARCH_CLASSES");

# check the query scope
if ($SCOPE eq "entry") {
  # entry scope queries ask about a particular object

  # check for an association, if the object has already 
  # been associated
  my $SEARCH_BASE = "";
  if ($ASSOCIATION ne "") {
    # the association was created by the scripts and should
    # be sufficient in determining this particular object's
    # class type (CLASS_NAME).

    # the search base for our query is the association for
    # the sample skeleton scripts
    $SEARCH_BASE = $ASSOCIATION;
  } else {
    # without an association, we can use the DEST_DN field to
    # determine the search base for our query
    
    $SEARCH_BASE = $DEST_DN;
  }

  # now we should have a search base determined
  if ($SEARCH_BASE ne "") {

    # INSERT CUSTOM CODE HERE
    #
    # Read the object $SEARCH_BASE which identifies the object
    # name we're interested in reading.  Create an association
    # string for this object that can be used to uniquely identify
    # the object.
    #
    # If the object is found, return:
    #$idmlib->idmsetvar("COMMAND", "instance");
    #$idmlib->idmsetvar("EVENT_ID", $EVENT_ID);
    #$idmlib->idmsetvar("SRC_DN", $SEARCH_BASE);
    #$idmlib->idmsetvar("CLASS_NAME", $CLASS_NAME);
    #$idmlib->idmsetvar("ASSOCIATION", $ASSOCIATION);
    #

    # check for which attributes to return (read)
    my $ALL_READ_ATTRS = $idmlib->idmgetvar("ALL_READ_ATTRS");
    if ($ALL_READ_ATTRS eq "true") {
      # return all attributes that can be read

      #
      # INSERT CUSTOM CODE HERE
      #
      #$idmlib->idmsetvar("ATTR_attr1", "value1");
      #$idmlib->idmsetvar("ATTR_attr2", "value2");
    } else {
      # return only those attributes which are requested
      foreach $READ_ATTR (@READ_ATTRS) {
        #
        # INSERT CUSTOM CODE HERE
        #
        if ($READ_ATTR eq "attr1") {
          $idmlib->idmsetvar("ATTR_attr1", "value1");
        } elsif ($READ_ATTR eq "attr2") {
          $idmlib->idmsetvar("ATTR_attr1", "value1");
        }
      }
    } 
  } else {
    $idmlib->status_error("Unable to derive a search base");
  }
} else {
  # we have a subtree or subordinate query search
  foreach $SEARCH_CLASS (@SEARCH_CLASSES) {

    # INSERT CUSTOM CODE HERE
    # 
    # Search for the object defined by this particular
    # SEARCH_CLASS and SEARCH_ATTRS.  Return zero or more
    # instances along with a status document indicating the
    # level of success.
    #
  
    # retrieve the search attributes/values to search on 
    my $SEARCH_ATTR_attr1 = $idmlib->idmgetvar("SEARCH_ATTR_attr1"); 
    my $SEARCH_ATTR_attr2 = $idmlib->idmgetvar("SEARCH_ATTR_attr2"); 

    # For each entry that matches, return an instance document:
    #
    #$idmlib->imdsetvar("COMMAND", "instance");
    #$idmlib->idmsetvar("EVENT_ID", $EVENT_ID);
    #$idmlib->idmsetvar("SRC_DN", $SEARCH_BASE);
    #$idmlib->idmsetvar("CLASS_NAME", $CLASS_NAME);
    #$idmlib->idmsetvar("ASSOCIATION", $ASSOCIATION);
    #

    # with each instance document, return all read attrs that were
    # requested by the query:

    # check for which attributes to return (read)
    my $ALL_READ_ATTRS = $idmlib->idmgetvar("ALL_READ_ATTRS");
    if ($ALL_READ_ATTRS eq "true") {
      # return all attributes that can be read

      #
      # INSERT CUSTOM CODE HERE
      #
      #$idmlib->idmsetvar("ATTR_attr1", "value1");
      #$idmlib->idmsetvar("ATTR_attr2", "value2");
    } else {
      # return only those attributes which are requested
      for $READ_ATTR (@READ_ATTRS) {
        #
        # INSERT CUSTOM CODE HERE
        #
        if ($READ_ATTR eq "attr1") {
          $idmlib->idmsetvar("ATTR_attr1", "value1");
        } elsif ($READ_ATTR eq "attr2") {
          $idmlib->idmsetvar("ATTR_attr1", "value1");
        }
      }
    } 
  }
}


# For the skeleton script, simply return a "Not Implemented" status
$idmlib->status_warning("Not Implemented");
