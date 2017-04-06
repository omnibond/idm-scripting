#!/usr/bin/python
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
#      idmsetvar("ASSOCIATION", <association>)
#      idmsetvar("DEST_DN", <dest_dn>)
#      idmsetvar("DEST_ENTRY_ID", <dest_entry_id>)
#      idmsetvar("EVENT_ID", <event_id>)
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

logger("debug", "add.py", " add called ")
trace(" add.py ")

# retrieve any necessary information from the shim, such as CLASS_NAME of
# of the object being added
class_name = idmgetvar("CLASS_NAME")

# INSERT CUSTOM CODE HERE
# 
# Retrieve additional information about the event and send back an
# association for this object along with a status document
#
#

import re
import sys
import time
import smtplib
import simplejson
from email.mime.text import MIMEText

# import the driver's config
from config import *

# common stuff for initializing the Google API Client
from apilib import *

# Google API Client stuff
from apiclient.errors import HttpError
from apiclient.errors import InvalidJsonError
from apiclient.errors import UnknownApiNameOrVersion

def sendThisMail(to):
	receivers = [to]
	
	smtp_server = idmgetdrvvar('smtp-server')
	reply_to = idmgetdrvvar('reply-to')
	subject = idmgetdrvvar('email-subject')
	body = idmgetdrvvar('email-body')
	
	msg = MIMEText(body)
	msg['From'] = reply_to
	msg['To'] = ", ".join(receivers)
	msg['Subject'] = subject
	
	server = smtplib.SMTP(smtp_server)
	
	try:
		# server.set_debuglevel(1)
		server.sendmail(reply_to, receivers, msg.as_string())
	except Exception as e:
		trace("ERROR: Sendmail failed - %s" % str(e))
		sys.exit()
	finally:
		server.quit()

src_dn = idmgetvar("SRC_DN")
src_entry_id = idmgetvar("SRC_ENTRY_ID")

iuname = idmgetvar("ADD_CN")
ipassw = idmgetvar("PASSWORD")
ifname = idmgetvar("ADD_FNAME")
ilname = idmgetvar("ADD_LNAME")
email = "%s@%s" % (iuname, API_DOMAIN)

if not ifname:
	ifname = "Noname"

# check valid input lengths
if len(iuname) < 1 or len(iuname) > 50 or len(ipassw) < 3 or len(ipassw) > 50:
	status_error("add - Invalid input length - 400")
	sys.exit()

# check valid username
if not re.match(r'^[a-z0-9]{1,}$', iuname, re.I):
	status_error("add - Invalid username - 400")
	sys.exit()

# Add user by using the Google API Client Library
user = {
	'primaryEmail': email,
	'password': ipassw,
	'suspended': False,
	'name': {
		'givenName': ifname,
		'familyName': ilname
	}
}

try:
	# get API service object
	service = get_service(
		API_NAME, API_VERSION, USERS_API_SCOPES, USERS_API_ADMIN_EMAIL,
		USERS_API_CLIENT_EMAIL, USERS_API_KEY_FILE, USERS_API_STORAGE_FILE)
	
	service.users().insert(body=user).execute()
	
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
	elif error_code == 409:
		# should this be status_error or status_success
		status_error("%s" % error)
	else:
		status_retry("%s" % error)
	
	sys.exit()

idmsetvar("COMMAND", "ADD_ASSOCIATION")
idmsetvar("ASSOCIATION", iuname)
idmsetvar("DEST_DN", src_dn)
idmsetvar("DEST_ENTRY_ID", src_entry_id)
idmsetvar("EVENT_ID", "%d" % time.time())
status_success("OK")

trace("Sending email to %s... " % email)
try:
	time.sleep(1) # Give google a second to get the account setup.  Otherwise email bounces...
	sendThisMail(email)
	trace("Email sent")
except:
	trace("Failed to send email")
