#!/user/bin/perl
#
# DESCRIPTION
#
#   This perl script implements the query for the external application,
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
#     RETVAR COMMAND INSTANCE                      (zero or more)
#     RETVAR CLASS_NAME class-name                 (mandatory)
#     RETVAR SRC_DN src-dn                         (optional)
#     RETVAR ASSOCIATION association               (optional)
#     RETVAR PARENT parent                         (optional)
#     RETVAR ATTR_attribute value                  (zero or more)
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
use MIME::Base64;
use OMAPI::CORE;
use OMAPI::DHCP;
use Data::Dumper;
use IDMLib;
use Net::Interface qw(:constants mac_bin2hex);
use Socket qw(:DEFAULT :crlf);

our $SCRIPT_DIR = $ENV{'INSTALL_PATH'}."/scripts";
our $global_config = do "$SCRIPT_DIR"."/globals.pl";

our %config;
require $SCRIPT_DIR."/"."config.pl";

my $i = new IDMLib();
my $reply = "empty";
my $SRC_DN;

# Log and Trace some messages
$i->logger($global_config->{TRACEPRIO}, "query.pl", "query.pl");
$i->trace("*** $SCRIPT_DIR/query.pl ***");

# get variables
my $CLASS_NAME = $i->idmgetvar('CLASS_NAME');
my $DEST_DN = $i->idmgetvar('DEST_DN');
my $ASSOCIATION = $i->idmgetvar('ASSOCIATION');
my $SCOPE = $i->idmgetvar('SCOPE');
my $SEARCH_CLASSES = $i->idmgetvar('SEARCH_CLASSES');
my $SEARCH_ATTRS = $i->idmgetvar('SEARCH_ATTRS');
my $READ_ATTRS = $i->idmgetvar('READ_ATTRS');
my $ALL_READ_ATTRS = $i->idmgetvar('ALL_READ_ATTRS');
my $NO_READ_ATTRS = $i->idmgetvar('NO_READ_ATTRS');
my $SEARCH_ATTR_DirXMLjnsuHWAddress = $i->idmgetvar('SEARCH_ATTR_DirXMLjnsuHWAddress');
my $SEARCH_ATTR_DirXMLjnsuDHCPAddress = $i->idmgetvar('SEARCH_ATTR_DirXMLjnsuDHCPAddress');
my $SEARCH_ATTR_DirXMLjnsuDevice = $i->idmgetvar('SEARCH_ATTR_DirXMLjnsuDevice');


my $hw_addr = $SEARCH_ATTR_DirXMLjnsuHWAddress;

my @all_attrs = ("DirXMLjnsuHWAddress", "DirXMLjnsuDHCPAddress");
my @return_attrs;

# what needs to be returned?
if (defined $ALL_READ_ATTRS) {
   @return_attrs = @all_attrs;
} else {
   @return_attrs = join(" ", $READ_ATTRS); 
}

# is this action for a DirXMLjnsuNetworkDevice
if ($CLASS_NAME eq "DirXMLjnsuNetworkDevice"){
  if ($ASSOCIATION){
     my $junk;
     ($junk, $ASSOCIATION) = split("-", $ASSOCIATION);
     $SRC_DN = $ASSOCIATION;
     $hw_addr = $ASSOCIATION;
  } elsif ($DEST_DN) {
     $SRC_DN = $DEST_DN;
  } else{
    # no association or destination DN sent
    $i->status_error("No association or destination DN");
    exit -1
  }

  # only thing searchable for host entries via omapi is hardware address
  if (($SEARCH_ATTRS !~ /DirXMLjnsuHWAddress/) && ($hw_addr eq "")) {
      $i->status_error("Unable to search without hardware address");
      exit -1
  }

  # connect to dhcp server
  my $C = new OMAPI::DHCP($config{'servername'}, $config{'port'}, $config{'loginkey'});
  if (!defined $C) {
     $i->status_retry("Could not connect to DHCP server with OMAPI");
     exit;
  }


  my $filter_matches = 0;

  my $host = $C->Select_Host  ( {'hardware-address' => $hw_addr } );

  if ( defined($host) && defined($SEARCH_ATTR_DirXMLjnsuDHCPAddress) ) {
     if (join(".", unpack("C4", $host->{'ip-address'})) eq $SEARCH_ATTR_DirXMLjnsuDHCPAddress) {
        $filter_matches = 1;
     }
  }

  if ( defined($host) && $filter_matches ) {
     $i->idmsetvar("COMMAND", "instance");
     $i->idmsetvar("CLASS_NAME", "DirXMLjnsuNetworkDevice");
     $i->idmsetvar("SRC_DN", "$SRC_DN");
     $i->idmsetvar("ASSOCIATION", "jnsu-$hw_addr");
     $i->status_success("Found matching DirXMLjnsuNetworkDevice for $SRC_DN");

     my $attr;
     foreach $attr (@return_attrs) {
        if ($attr eq 'DirXMLjnsuHWAddress') {
           $i->idmsetvar("ATTR_DirXMLjnsuHWAddress", mac_bin2hex(scalar $host->{'hardware-address'}) );
        }
        if ($attr eq 'DirXMLjnsuDHCPAddress') {
           $i->idmsetvar("ATTR_DirXMLjnsuDHCPAddress", join(".", unpack("C4", $host->{'ip-address'})) );
        }
     } 
  } else {
     $i->status_success("Did not find matching entry for $hw_addr");
  }
}
else{
  # Unhandled class
  $i->status_error("Invalid class Provided");
  exit -1
}
