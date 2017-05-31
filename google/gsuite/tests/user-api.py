#!/usr/bin/python -m

# import sys
# sys.path.append('../')

import httplib2
import simplejson
from pprint import pprint

# import the driver's config
from config import *
from apilib import *

# include the Google APIs Client Library
from apiclient import errors
from apiclient.discovery import build
from oauth2client.file import Storage
from oauth2client.client import SignedJwtAssertionCredentials

# http = None
# storage = None
# credentials = None
service = None
test_user = {
	'primaryEmail': "idm_gmail_driver_test@%s" % API_DOMAIN,
	'password': 'test1234qazx',
	'name': {
		'givenName': 'IDMGmail',
		'familyName': 'DriverTest'
	}
}

def connect():
	print "Connecting...",
	
	# global http, storage, credentials, service
	# http = httplib2.Http()
	# storage = Storage('/tmp/gmail.storage')
	# credentials = storage.get()
	
	# if credentials is None or credentials.invalid:
	# 	credentials = SignedJwtAssertionCredentials(USERS_API_CLIENT_EMAIL, 
	# 		USERS_API_PRIVATE_KEY, USERS_API_SCOPES, sub=USERS_API_ADMIN_EMAIL)
		
	# 	storage.put(credentials)
	# else:
	# 	credentials.refresh(http)

	# http = credentials.authorize(http)
	# service = build('admin', 'directory_v1', http=http)
	
	global service
	service = get_service(
		API_NAME, API_VERSION, USERS_API_SCOPES, USERS_API_ADMIN_EMAIL,
		USERS_API_CLIENT_EMAIL, USERS_API_KEY_FILE, USERS_API_STORAGE_FILE)
	
	print "Connected"

def insert_user():
	print "Inserting user:"
	pprint(test_user)
	
	kwargs = {
		'body': test_user
	}
	
	result = service.users().insert(**kwargs).execute()
	
	print "\nResult:"
	pprint(result)

def modify_user():
	userKey = test_user['primaryEmail']
	givenName = "Modified%s" % test_user['name']['givenName']
	
	print "Modifying user %s..." % userKey
	print "The new givenName should be: %s" % givenName
	
	test_user['name']['givenName'] = givenName
	
	kwargs = {
		'userKey': userKey,
		'body': {
			'name': test_user['name']
		}
	}
	
	result = service.users().update(**kwargs).execute()
	
	print "\nResult:"
	pprint(result)

def patch_user():
	userKey = test_user['primaryEmail']
	password = "patched1234qazx"
	
	print "Patching user password %s..." % userKey
	print "The new password should be: %s" % password
	
	kwargs = {
		'userKey': userKey,
		'body': {
			'password': password
		}
	}
	
	result = service.users().patch(**kwargs).execute()
	
	print "\nResult:"
	pprint(result)

def get_user():
	userKey = test_user['primaryEmail']
	print "Getting user %s..." % userKey
	
	result = service.users().get(userKey=userKey).execute()
	
	print "\nResult:"
	pprint(result)

def delete_user():
	userKey = test_user['primaryEmail']
	print "Deleting user %s..." % userKey
	
	result = service.users().delete(userKey=userKey).execute()
	
	print "\nResult (empty = success):"
	pprint(result)

def list_users():
	print "Listing users..."
	
	kwargs = {
		'domain': API_DOMAIN,
		'orderBy': 'email'
	}
	
	results = service.users().list(**kwargs).execute()
	users = results['users']
	
	for user in users:
		print "\t%s" % user['primaryEmail']


if __name__ == "__main__":
	try:
		connect()
		print "\n"
		insert_user()
		print "\n"
		modify_user()
		print "\n"
		patch_user()
		print "\n"
		get_user()
		print "\n"
		delete_user()
		print "\n"
		list_users()
		
	except errors.HttpError, e:
		try:
			# Load JSON body.
			error = simplejson.loads(e.content).get('error')
			print 'Error code: %d' % error.get('code')
			print 'Error message: %s' % error.get('message')
			print "Errors: \n%s" % error.get('errors')
			# More error information can be retrieved with error.get('errors').
		except ValueError as e:
			# Could not load JSON body.
			print 'HTTP Status code: %d' % e.resp.status
			print 'HTTP Reason: %s' % e.resp.reason
	except Exception as e:
		print 'An error occurred: %s' % e