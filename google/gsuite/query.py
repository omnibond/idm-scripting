#!/usr/bin/python
#
# DESCRIPTION
#
#   This script implements the query for the external application, Linux/UNIX.  
#
#   The query command is an input command or event. A query is used to find 
#   and read information about entries in the external application, therefore
#   it is both a "search" and a "read" operation.
#
#
# VARIABLES
#
#   SCOPE
#     Specifies the extent of the search.  This attribute supports
#     the following values:  
#       * subtree - indicates to search the base entry and all entries
#         in its branch of the directory tree.  If no scoope is specified,
#         subtree is used as the default value.
#       * subordinates - indicates to search the immediate subordinates of 
#         the base entry (the base entry is not searched).
#       * entry - indicates to search just the base entry.
#     For scopes other than entry, the selected entries can be further
#     limited by the search_classES and SEARCH_ATTR_ elements.  For scopes of
#     entry, the search_classES and SEARCH_ATTR_ elements are ignored.
#     
#   DEST_DN
#     Specifies the distinguished name for the starting point for the search.
#     If both the DEST_DN attribute and ASSOCIATION have values, the 
#     ASSOCIATION value is used as the starting point for the search.  If 
#     neither have values, the search begins at the root of the directory.
#
#   CLASS_NAME
#     Specififes the base class of the DEST_DN attribute.
#
#   EVENT_ID
#     Specifies an identifier used to identify a particular instance of the 
#     command or event.
#
#   ASSOCIATION
#     Specifies the unique identifier for the entry where the search begins.  
#     If  both the DEST_DN attribute and the ASSOCIATION have values, the 
#     ASSOCIATION value is used as the starting point for the search.  If 
#     neither have values, the search begins at the root of the directory.
#
#   search_classES
#     Specifies the search filter for object classes.  If the query contains no
#     search_classES elements, all entries matching the scope and the 
#     SEARCH_ATTR_ elements are returned.
# 
#   SEARCH_ATTRS
#     Contains a list of the SEARCH_ATTR_ attribute names.
#
#   SEARCH_ATTR_<ATTR_NAME>
#     Specifies the search filter for attribute values.  If more than one 
#     SEARCH_ATTR_ element is specified, the entry must match all attributes
#     to be returned.  
#
#     <ATTR_NAME> will be replaced by the literal name of the attribute, 
#     upper-cased and non-printable characters converted to underscores.
#
#   READ_ATTRS
#     Specifies which attribute values are returned with entries that match
#     the search filters.
#
#   ALL_READ_ATTRS
#     Specifies that all readable attributes should be returned.
#
#   NO_READ_ATTRS
#     Specifies that no attributes are to be returned.
#
#   READ_PARENT
#     Specifies whether the parent of the entry is returned with the entry.
#
#
# REPLY FORMAT
#
#   The receiving application should respond to the query with an INSTANCE 
#   command for each entry returned.  The response should also include a
#   status indicating whether the query was processed successfully.
#   A query should return a successful status even when no entries exist
#   that match the search criteria.
#
#   The format for the INSTANCE command is as follows:
#
#     idmsetvar("COMMAND" "INSTANCE")        (zero or more)
#     idmsetvar("CLASS_NAME", class-name)    (mandatory)
#     idmsetvar("SRC_DN", src-dn)            (optional)
#     idmsetvar("ASSOCIATION", association)  (optional)
#     idmsetvar("PARENT", parent)            (optional)
#     idmsetvar("ATTR_attribute", value)     (zero or more)
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

logger("debug", "query.py", " querying ")
trace(" query.py ")

# retrieve information from the query event
scope = idmgetvar("SCOPE")
class_name = idmgetvar("CLASS_NAME")
association = idmgetvar("ASSOCIATION")
dest_dn = idmgetvar("DEST_DN")
all_read_attrs = idmgetvar("ALL_READ_ATTRS")
read_attrs = idmgetvar("READ_ATTRS")

#search_classes = idmgetvar("search_class")
search_classes = [class_name]

try:
	# get API service object
	service = get_service(
		API_NAME, API_VERSION, USERS_API_SCOPES, USERS_API_ADMIN_EMAIL,
		USERS_API_CLIENT_EMAIL, USERS_API_KEY_FILE, USERS_API_STORAGE_FILE)
except Exception as e:
	status_error("Unable to initialize service")
	sys.exit()

# check the query scope
if scope == "entry":
	# entry scope queries ask about a particular object

	# check for an association, if the object has already 
	# been associated
	if association != "":
		# the association was created by the scripts and should
		# be sufficient in determining this particular object's
		# class type (class_name).

		# the search base for our query is the association for
		# the sample skeleton scripts
		search_base = association
	else:
		# without an association, we can use the DEST_DN field to
		# determine the search base for our query
		search_base = dest_dn

	# now we should have a search base determined
	if search_base != "":

		# INSERT CUSTOM CODE HERE
		#
		# Read the object search_base which identifies the object
		# name we're interested in reading.  Create an association
		# string for this object that can be used to uniquely identify
		# the object.
		#
		trace("query - search_base = %s" % search_base)
		
		user = None
		userKey = "%s@%s" % (search_base, API_DOMAIN)
		
		try:
			# try to get the user
			user = service.users().get(userKey=userKey).execute()
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
			
			if error_code != 404:
				status_error("%s" % error)
				sys.exit()
		
		if not user:
			status_success("Unable to find user: %s" % userKey)
			sys.exit()
		
		
		# If the object is found, return:
		#idmsetvar("COMMAND", "instance")
		#idmsetvar("EVENT_ID", event_id)
		#idmsetvar("SRC_DN", search_base)
		#idmsetvar("CLASS_NAME", class_name)
		#idmsetvar("ASSOCIATION", association)
		#
		idmsetvar("COMMAND", "instance")
		idmsetvar("CLASS_NAME", class_name)
		idmsetvar("ASSOCIATION", search_base)

		# check for which attributes to return (read)
		if all_read_attrs == "true":
			# return all attributes that can be read

			#
			# INSERT CUSTOM CODE HERE
			#
			#idmsetvar("ATTR_attr1", "value1")
			#idmsetvar("ATTR_attr2", "value2")
			trace("query = all_read_attrs = %s" % all_read_attrs)
			
			idmsetvar("ATTR_FNAME", user['name']['givenName'])
			idmsetvar("ATTR_LNAME", user['name']['familyName'])
			idmsetvar("ATTR_SUSPENDED", user['suspended'])
			
		else:
			# return only those attributes which are requested
			for read_attr in read_attrs:
				#
				# INSERT CUSTOM CODE HERE
				#
				trace("query - read_attr = %s" % read_attr)
				
				if read_attr == "FNAME":
					idmsetvar("ATTR_FNAME", user['name']['givenName'])
				elif read_attr == "LNAME":
					idmsetvar("ATTR_LNAME", user['name']['familyName'])
				elif read_attr == "SUSPENDED":
					idmsetvar("ATTR_SUSPENDED", user['suspended'])
		
		status_success("User found: %s" % userKey)
	else:
		status_error("Unable to derive a search base")
else:
	# we have a subtree or subordinate query search
	for search_class in search_classes:

		# INSERT CUSTOM CODE HERE
		# 
		# Search for the object defined by this particular
		# search_class and SEARCH_ATTRS.  Return zero or more
		# instances along with a status document indicating the
		# level of success.
		#
		search_base = ''
		
		# check for an association, if the object has already 
		# been associated
		if association != "":
			# the association was created by the scripts and should
			# be sufficient in determining this particular object's
			# class type (class_name).

			# the search base for our query is the association for
			# the sample skeleton scripts
			search_base = association
		else:
			# without an association, we can use the DEST_DN field to
			# determine the search base for our query
			search_base = dest_dn
		
		user = None
		userKey = "%s@%s" % (search_base, API_DOMAIN)
		
		try:
			# try to get the user
			user = service.users().get(userKey=userKey).execute()
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
			
			if error_code != 404:
				status_error("%s" % error)
				sys.exit()
		
		if not user:
			status_success("Unable to find user: %s" % userKey)
			sys.exit()
	
		# retrieve the search attributes/values to search on 
		# search_attr_attr1 = idmgetvar("SEARCH_ATTR_attr1")
		# search_attr_attr2 = idmgetvar("SEARCH_ATTR_attr2") 

		# For each entry that matches, return an instance document:
		#
		#idmsetvar("COMMAND", "instance")
		#idmsetvar("EVENT_ID", event_id)
		#idmsetvar("SRC_DN", search_base)
		#idmsetvar("CLASS_NAME", class_name)
		#idmsetvar("ASSOCIATION", association)
		#
		idmsetvar("COMMAND", "instance")
		idmsetvar("CLASS_NAME", class_name)
		idmsetvar("ASSOCIATION", search_base)

		# with each instance document, return all read attrs that were
		# requested by the query:

		# check for which attributes to return (read)
		if all_read_attrs == "true":
			# return all attributes that can be read

			#
			# INSERT CUSTOM CODE HERE
			#
			#idmsetvar("ATTR_attr1", "value1")
			#idmsetvar("ATTR_attr2", "value2")
			trace("query = all_read_attrs = %s" % all_read_attrs)
			
			idmsetvar("ATTR_FNAME", user['name']['givenName'])
			idmsetvar("ATTR_LNAME", user['name']['familyName'])
			idmsetvar("ATTR_SUSPENDED", user['suspended'])
		else:
			# return only those attributes which are requested
			for read_attr in read_attrs:
				#
				# INSERT CUSTOM CODE HERE
				#
				trace("query - read_attr = %s" % read_attr)
				
				if read_attr == "FNAME":
					idmsetvar("ATTR_FNAME", user['name']['givenName'])
				elif read_attr == "LNAME":
					idmsetvar("ATTR_LNAME", user['name']['familyName'])
				elif read_attr == "SUSPENDED":
					idmsetvar("ATTR_SUSPENDED", user['suspended'])
		
		status_success("User found: %s" % userKey)