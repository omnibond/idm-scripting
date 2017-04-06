#!/usr/bin/python
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
#    The receiving application should respond to the move with a STATUS
#    and an optional STATUS_MESSAGE which can be returned for IDM engine 
#    processing and logging facilities.
#
#    The format for returning STATUS and STATUS_MESSAGE are as follows:
#
#      status_<level>("<optional message>")
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

# include the IDM Library
from idmlib import *

logger("debug", "move.py", " moving ")
trace(" move.py ")

class_name = idmgetvar("CLASS_NAME")

# INSERT CUSTOM CODE HERE
#
# Retrieve additional information about the event and send back a
# status document indicating the level of success for this move.
#


# For the skeleton script, simply return a "Not Implemented" status
status_warning("Not Implemented")

