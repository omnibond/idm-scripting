#!/bin/sh
#
# DESCRIPTION
#
#   This script implements the rename command for the external Linux/UNIX 
#   application.
#
#   The rename command is an input command.  It renames the entry; it cannot
#   move an entry from one container to another in a hierarchical database.  
#   The IDM engine sends the rename command to the subscriber to request
#   that the external application rename an entry.  The rename command must
#   contain an ASSOCIATION element.
#
#
# VARIABLES
#
#   SRC_DN
#     Specifies the distinguished name of the entry in the name space of 
#     eDirectory.
#
#   OLD_SRC_DN
#     Spceifies the old distinguished name of the entry in the name space of 
#     eDirectory.
#
#   REMOVE_OLD_NAME
#     Specifies whether the old relative distinguished name should be deleted
#     or retained.  If not specififed, defaults to "true" which removes the
#     old name.
#
#   CLASS_NAME
#     Specifies the base class of the entry being moved.
#
#   EVENT_ID
#     Specifies an identifier used to identify a particular instance of the 
#     command.
#
#   ASSOCIATION
#     Specifies the unique identifier for the entry in the external application.
#
#   NEW_NAME
#     Specifies the new relative distinguished name for the entry.
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

# include the IDM Library
. $IDMLIB

LOGGER -p $TRACEPRIO " *** "`$BASENAME $0`" *** "
TRACE " *** "`$BASENAME $0`" *** "

# retrieve local shell variables
ASSOCIATION=`IDMGETVAR ASSOCIATION`
NEW_NAME=`IDMGETVAR NEW_NAME`
EVENT_ID=`IDMGETVAR EVENT_ID`
SRC_DN=`IDMGETVAR SRC_DN`
SRC_ENTRY_ID=`IDMGETVAR SRC_ENTRY_ID`

loginName=$ASSOCIATION
if [ -z "$loginName" ]; then
  STATUS_ERROR "rename-user could not derive the loginName"
  exit 255
fi

if [ -z "$NEW_NAME" ]; then
  STATUS_ERROR "rename-user event did not contain a new-name"
  exit 255
fi

# we cannot rename a user in sasldb, only delete old user and create new one
STATUS_ERROR "rename-user: Renaming users are not supported by sasldb"
exit 255
