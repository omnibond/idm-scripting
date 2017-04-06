#!/bin/sh
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

DEL_COMMAND="$SASLPASSWD -d -u $SASL_DOMAIN -a $SASL_APPNAME"
if [ -n "$SASL_FILEDB" ]; then
  DEL_COMMAND="$DEL_COMMAND -f $SASL_FILEDB"
fi

ASSOCIATION=`IDMGETVAR ASSOCIATION`
if [ -n "$ASSOCIATION" ]
then
  loginName=$ASSOCIATION
else
  STATUS_ERROR "delete event did not contain an association"
  exit 255
fi

# specify the user to delete
DEL_COMMAND="$DEL_COMMAND $loginName"

# execute the sasl command
EXEC $DEL_COMMAND
