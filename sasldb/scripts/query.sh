#!/bin/sh
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

# include the IDM Library
. $IDMLIB

LOGGER -p $TRACEPRIO " *** "`$BASENAME $0`" *** "
TRACE " *** "`$BASENAME $0`" *** "

SCOPE=`IDMGETVAR SCOPE`
CLASS_NAME=`IDMGETVAR CLASS_NAME`; export CLASS_NAME
ASSOCIATION=`IDMGETVAR ASSOCIATION`; export ASSOCIATION
DEST_DN=`IDMGETVAR DEST_DN`; export DEST_DN
SEARCH_CLASSES=`IDMGETVAR SEARCH_CLASSES`; export SEARCH_CLASSES

if [ "$SCOPE" = "entry" ]; then
  # entry scope queries ask about a particular object

  # check for an association, if the object has already
  # been associated
  SEARCH_BASE=""

  if [ -n "$ASSOCIATION" ]; then
    # the search base for our query is the association
    SEARCH_BASE=$ASSOCIATION;
  else
    # without an association, we can use the DEST_DN field to
    # determine the search base for our query
    $SEARCH_BASE = $DEST_DN;
  fi

  # now we should have a search base determined
  if [ -n "$SEARCH_BASE" ]; then
    loginName=$SEARCH_BASE
    ENTRY=`$SASLDBLISTUSERS | grep "$loginName"`
    if [ -n "$ENTRY" ]
    then
      IDMSETVAR "COMMAND" "instance"
      IDMSETVAR "EVENT_ID" $EVENT_ID
      IDMSETVAR "SRC_DN" $loginName
      IDMSETVAR "CLASS_NAME" $CLASS_NAME
      IDMSETVAR "ASSOCIATION" $loginName
    fi

    # check for which attributes to return (read)
    ALL_READ_ATTRS=`IDMGETVAR "ALL_READ_ATTRS"`
    if [ "$ALL_READ_ATTRS" = "true" ]; then
      loginName=`echo $ENTRY | awk -F@ '{print $1}'`
      IDMSETVAR "ATTR_loginName" "$loginName"
    else
      # return only those attributes which are requested
      IFS=,
      for READ_ATTR in $READ_ATTRS; do
        if [ "$READ_ATTR" = "loginName" ]; then
          loginName=`echo $ENTRY | awk -F@ '{print $1}'`
          IDMSETVAR "ATTR_loginName" "$loginName"
        fi
      done
    fi
  else
    # No search base could be made
    STATUS_ERROR "Could not derive a search base"
  fi

else
  # subtree or subordinate query

  # retrieve the search attributes/values to search on
  SEARCH_ATTR_loginName=`IDMGETVAR "SEARCH_ATTR_loginName"`

  if [ -z "$SEARCH_ATTR_loginName" ]; then
    SEARCH_ATTR_loginName=".*"
  fi

  # lookup user
  REGEXP="^$SEARCH_ATTR_loginName@.*"

  IFS=$NEWLINE
  for ENTRY in `$SASLDBLISTUSERS | grep $REGEXP`
  do
    IFS=$IFSSAVE

    loginName=`echo $ENTRY | awk -F: '{print $1}'`

    IDMSETVAR "COMMAND" "instance"
    IDMSETVAR "EVENT_ID" $EVENT_ID
    IDMSETVAR "SRC_DN" $loginName
    IDMSETVAR "CLASS_NAME" $CLASS_NAME
    IDMSETVAR "ASSOCIATION" $loginName

    # with each instance document, return all read attrs that were
    # requested by the query:

    # check for which attributes to return (read)
    ALL_READ_ATTRS=`IDMGETVAR "ALL_READ_ATTRS"
    if [ "$ALL_READ_ATTRS" = "true" ]; then
      IDMSETVAR "ATTR_loginName" "$loginName"
    else
      # return only those attributes which are requested
      for READ_ATTR in $READ_ATTRS; do
        if [ "$READ_ATTR" eq "loginName" ]; then
          IDMSETVAR "ATTR_loginName" "$loginName"
        fi
      done
    fi
  done

  IFS=$IFSSAVE; export IFS
fi

# For the skeleton script, simply return a "Not Implemented" status
STATUS_SUCCESS
