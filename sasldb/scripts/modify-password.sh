#!/bin/sh
#
# DESCRIPTION
# 
#   This script implements the modify-password command for the extenrnal
#   Linux/UNIX application.
#
#   The modify-password is a command from IDM engine to the subscriber to 
#   modify an object password in the application.  An ASSOCIATION is the
#   unique key of the object to modify.
#
#   A driver may or may not implement this functionality, depending on the 
#   applicability to the application.
#
#
# VARIABLES
#
#   SRC_DN
#     The distinguished name of the source object that generated the event in
#     the namespace of eDirectory.
#
#   DEST_DN
#     The distinguished name of the target object in the namespace of the
#     receiver.
#
#   CLASS_NAME
#     The name of the base class of the object.  The class name is mapped 
#     between the application and eDirectory name spaces by the schema mapping
#     rule so that IDM will see the name in the eDirectory namespace and a 
#     driver will see the name in the application name space.
#
#   EVENT_ID
#     An identifier used to tag the result of an event or command.
#
#   OLD_PASSWORD
#     Specifies the current password.
#
#   PASSWORD
#     Specifies the new password.
#
#
# REPLY FORMAT
#
#    The receiving application should respond to the modify with a STATUS
#    and an optional STATUS_MESSAGE which can be returned for IDM engine 
#    processing and logging facilities.
#
#    The format for STATUS and STATUS_MESSAGE are as follows:
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
#

# include the IDM Library
. $IDMLIB

LOGGER -p $TRACEPRIO " *** "`$BASENAME $0`" *** "
TRACE " *** "`$BASENAME $0`" *** "

# check our association
association=`IDMGETVAR ASSOCIATION`
if [ -z "$association" ]; then
  # if we cannot derive the association, exit with an error
  STATUS_ERROR "modify-password could not retrieve an association"
  exit 255
else
  loginName=$ASSOCIATION
fi

# retrieve the password and check that it's valid
password=`IDMGETVAR PASSWORD`
if [ -z "$password" ]; then
  STATUS_ERROR "modify-password no password was specified for $loginName"
  exit 255
fi

PASSWD_COMMAND="$SASLPASSWD -p -c -u $SASL_DOMAIN -a $SASL_APPNAME"
if [ -n "$SASL_FILEDB" ]; then
  PASSWD_COMMAND="$SASLPASSWD -f $SASL_FILEDB"
fi

# call the saslpasswd utility to modify this user's password
$PASSWD_COMMAND $loginName <<DO_NOT_EDIT
$password
DO_NOT_EDIT

# check the return code
RC=$?
if [ "$RC" -eq 0 ]
then
  LOGGER -p $CMDOKPRIO "$loginName's password has been reset:RC=$RC:"
  STATUS_SUCCESS
else
  LOGGER -p $CMDFAILPRIO "Failed to reset password for $loginName:RC=$RC:"
  STATUS_ERROR "modify-password was unable set sasldb password for $loginName"
fi
