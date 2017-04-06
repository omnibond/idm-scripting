#!/bin/sh
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
#      IDMSETVAR ASSOCIATION <association>
#      IDMSETVAR DEST_DN <dest_dn>
#      IDMSETVAR DEST_ENTRY_ID <dest_entry_id>
#      IDMSETVAR EVENT_ID <event_id>
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

# retrieve our shell variables of interest
loginName=`IDMGETVAR ADD_loginName`
EVENT_ID=`IDMGETVAR EVENT_ID`
SRC_DN=`IDMGETVAR SRC_DN`
SRC_ENTRY_ID=`IDMGETVAR SRC_ENTRY_ID`
password=`IDMGETVAR PASSWORD`

if [ -z "$loginName" ]; then
  STATUS_ERROR "add Unable to retrieve loginName"
  exit 255
fi

if [ -z "$password" ]; then
  STATUS_ERROR "add Unable to retrieve password"
  exit 255
fi

# build the add command
ADD_USER_COMMAND="$SASLPASSWD -p -c -u $SASL_DOMAIN -a $SASL_APPNAME"
if [ -n "$SASL_DBFILE" ]; then
  ADD_USER_COMMAND="$ADD_USER_COMMAND -f $SASL_DBFILE"
fi

ADD_USER_COMMAND=$ADD_USER_COMMAND" "$loginName

# Execute the add command and report any error
$ADD_USER_COMMAND<<EOF
$password
EOF

RC=$?
if [ $RC -eq 0 ]
then
  STATUS_SUCCESS

  # The add was successful; we need to return an add-association to the driver
  IDMSETVAR "COMMAND" "ADD_ASSOCIATION"
  IDMSETVAR "EVENT_ID" $EVENT_ID
  IDMSETVAR "ASSOCIATION" $loginName
  IDMSETVAR "DEST_DN" $SRC_DN
  IDMSETVAR "DEST_ENTRY_ID" $SRC_ENTRY_ID
fi
