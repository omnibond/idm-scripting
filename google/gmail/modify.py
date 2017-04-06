#!/usr/bin/python
#
# DESCRIPTION
#
#   This script implements the modify command for the external Linux/UNIX 
#   application.
#
#   The modify command is an input command.  The IDM engine sends a modify 
#   command to the subscriber to request that the external application modify
#   an entry.  The modify command must contain an ASSOCIATION element.
#
#
# VARIABLES
#
#   SRC_DN
#     Specifies the distinguished name of the entry to modify in the name
#     space of eDirectory.
#
#   CLASS_NAME
#     Specifies the base class of the entry being modified.  This attribute
#     is required for modify events.
#
#   EVENT_ID
#     Specifies an identifier to identify a particular instance of the command.
#
#   ASSOCIATION
#     Specifies the unique identifier for the entry in the external
#     application.  This element is required for modify events.
#
#   ADD_<ATTR_NAME>
#     Specifies one or more values to add to <ATTR_NAME>, where <ATTR_NAME> is
#     literally replaced by the name of the attribute being modified.
#
#   REMOVE_<ATTR_NAME>
#     Specifies one or more values to remove to <ATTR_NAME>, where <ATTR_NAME>
#     is literally replaced by the name of the attribute being modified.
#
#   REMOVE_ALL_<ATTR_NAME>
#     Instructs to remove all values associated with <ATTR_NAME>, where 
#     <ATTR_NAME> is literally replaced by the name of the attribute being 
#     modified.
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

logger("debug", "modify.py", " modifying ")
trace(" modify.py ")

class_name = idmgetvar("CLASS_NAME")

# INSERT CUSTOM CODE HERE
#
# Retrieve additional information about the event and send back a
# status document indicating the level of success for this modify.
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
	status_error("modify - bad association 400")
	sys.exit()

# check valid username
if not re.match(r'^[a-z0-9]{1,}$', iuname, re.I):
	status_error("modify - bad username 400")
	sys.exit()

ifname = idmgetvar("FNAME")
ilname = idmgetvar("LNAME")
isuspn = idmgetvar("SUSPENDED").split('\n')[0].lower()

has_ifname = len(ifname) > 0
has_ilname = len(ilname) > 0
has_isuspn = len(isuspn) > 0

try:
	service = get_service(
		API_NAME, API_VERSION, USERS_API_SCOPES, USERS_API_ADMIN_EMAIL,
		USERS_API_CLIENT_EMAIL, USERS_API_KEY_FILE, USERS_API_STORAGE_FILE)
	
	userKey = "%s@%s" % (iuname, API_DOMAIN)
	body = {}
	
	if has_isuspn:
		isuspn = False if isuspn == 'false' else bool(isuspn)
		body['suspended'] = isuspn
	
	if has_ifname or has_ilname:
		body['name'] = {}
		
		if has_ifname:
			body['name']['givenName'] = ifname
		
		if has_ilname:
			body['name']['familyName'] = ilname
	
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