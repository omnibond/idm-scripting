#!/usr/bin/python
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

logger("debug", "delete.py", " deleting ")
trace(" delete.py  ")

class_name = idmgetvar("CLASS_NAME")

# INSERT CUSTOM CODE HERE
#
# Retrieve additional information about the event and send back a
# status document indicating the level of success for this delete.
#
#

import re
import sys
import simplejson

# import the driver's config
from config import *

# common stuff for initializing the Google API Client
from apilib import *

# Google API Client stuff
from apiclient.errors import HttpError
from apiclient.errors import InvalidJsonError
from apiclient.errors import UnknownApiNameOrVersion

iuname = idmgetvar("ASSOCIATION")

# check valid input lengths
if len(iuname) < 1 or len(iuname) > 50:
	status_error("delete - Invalid input length - 400")
	sys.exit()

# check valid username
if not re.match(r'^[a-z0-9]{1,}$', iuname, re.I):
	status_error("delete - Invalid username - 400")
	sys.exit()


try:
	service = get_service(
		API_NAME, API_VERSION, USERS_API_SCOPES, USERS_API_ADMIN_EMAIL,
		USERS_API_CLIENT_EMAIL, USERS_API_KEY_FILE, USERS_API_STORAGE_FILE)
	
	userKey = "%s@%s" % (iuname, API_DOMAIN)
	
	service.users().delete(userKey=userKey).execute()
	
except Exception as e:
	error = e
	error_code = None
	error_name = type(e).__name__
	
	if error_name == 'HttpError':
		try:
			# Load JSON body.
			error = simplejson.loads(e.content).get('error')
			error_code = error.get('code')
		except ValueError as ve:
			# Could not load JSON body.
			error = e.resp
	
	# API Error Codes:
	#	404 - Resource not found
	# 	409 - Entity already exists.
	# 
	# 	403 - Limits and Quotas: https://developers.google.com/admin-sdk/directory/v1/limits
	# 			dailyLimitExceeded, userRateLimitExceeded, quotaExceeded
	# 
	if error_code == 403:
		# docs say to use an exponential backoff, don't know if that's possible here
		status_retry("%s" % error)
	elif error_code == 404:
		# should this be status_error or status_success
		status_error("%s" % error)
	else:
		status_retry("%s" % error)
	
	sys.exit()

status_success("OK")