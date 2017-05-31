#!/usr/bin/python
#
# DESCRIPTION
#
#   This script servers the purpose of setting up necessary information to be
#   used by the standard event scripts (add, modify, delete, query, rename,
#   and move).  Among these items are utilities for logging, debugging,
#   retrieving variables from the driver, and setting up system and driver
#   file paths.  In addition, driver and subscriber initialization parameters
#   (init-params) are passed in here for processing.
#
# ACCESSING INFORMATION
#
#   val = idmgetvar(<variable>)
#
#     This can be invoked to retrieve a variable from the driver.  The output
#     from this command must be stored away into a shell variable.
#
#
# INCOMING VARIABLES
#
#   DRIVER_INIT_PARAM_param1
#     Contains the value of the driver initialization parameter, param1
#
#   SUBSCRIBER_INIT_PARAM_param1
#     Contains the value of the subscriber initialization parameter, param1
#
#   COMMAND
#     Contains the command that is to be executed (add, modify, delete, query,
#     rename or move) by the subscriber.
#
#

# include the IDM Library
from idmlib import *

# import the driver's config
from config import *

# setup script paths
os.environ['PATH'] = SCRIPTS_DIR + ":" + os.environ.get('PATH')

###################################################################
#
# Send some informational trace messages to the shim trace file
#
###################################################################
trace(" Executing subscriber script ")


###################################################################
#
# Call the appropriate script, based on the command type.
# Novell Identity Manager supports the following basic commands:
#   query, add, modify, modify-password, delete, rename, move
#
###################################################################
# Begin the event from Identity Manager
logger("debug", "subscriber.py", " subscriber ")

command = idmgetvar("COMMAND")
if command == "query":
  os.system("query.py")
elif command == "add":
  os.system("add.py")
elif command == "modify":
  os.system("modify.py")
elif command == "modify-password":
  os.system("modify-password.py")
elif command == "delete":
  os.system("delete.py")
elif command == "rename":
  os.system("rename.py")
elif command == "move":
  os.system("move.py")
else:
  status_error("Unhandled Command: ",command)

trace(" subscriber script execution finished ")

