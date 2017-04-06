#!/bin/sh
#
# DESCRIPTION
#
#   This script implements the move command for the external Linux/UNIX
#   application.
#
#   The move command is an input command.  The IDM engine sends the move
#   command to request that the external application move an entry from one
#   container to another.  The move command must contain an ASSOCIATION 
#   element.
#
#
# VARIABLES
#
#   SRC_DN
#     Specifies the distinguished name of the entry, after the move, in the 
#     namespace of eDirectory.
#
#   OLD_SRC_DN
#     Spceifies the distinguished name of the entry, before the move, in the
#     namespace of eDirectory.
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
#   PARENT_SRC_DN
#     Specifies the new container src-dn for the entry.
#
#   PARENT_ASSOCIATION
#     Specifies the new container association for the entry.
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

STATUS_ERROR "External application does not support the move operation"
