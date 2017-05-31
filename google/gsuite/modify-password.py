#!/usr/bin/python
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

logger("debug", "modify-password.py", " modifying password ")
trace(" modify-password.py ")

# retrieve the association and new password
association = idmgetvar("ASSOCIATION")
password = idmgetvar("PASSWORD")


# INSERT CUSTOM CODE HERE
#
# Retrieve additional information about the event and send back a
# status document indicating the level of success for this modify-password.
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

iuname = association
ipassw = password

# check valid input lengths
if len(iuname) < 1 or len(iuname) > 50:
	status_error("modify-password - bad association 400")
	sys.exit()

# check valid username
if not re.match(r'^[a-z0-9]{1,}$', iuname, re.I):
	status_error("modify-password - bad username 400")
	sys.exit()

# check valid input lengths for password
if len(ipassw) < 3 or len(ipassw) > 50:
	status_error("modify-password - bad password %s 400" % ipassw)
	sys.exit()

try:
	service = get_service(
		API_NAME, API_VERSION, USERS_API_SCOPES, USERS_API_ADMIN_EMAIL,
		USERS_API_CLIENT_EMAIL, USERS_API_KEY_FILE, USERS_API_STORAGE_FILE)
	
	userKey = "%s@%s" % (iuname, API_DOMAIN)
	body = {
		'password': ipassw
	}
	
	service.users().patch(userKey=userKey, body=body).execute()
	
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