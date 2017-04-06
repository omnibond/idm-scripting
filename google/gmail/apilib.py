__all__ = []

import httplib2
import simplejson

# include the Google APIs Client Library
from apiclient import errors
from apiclient.discovery import build
from oauth2client.file import Storage
from oauth2client.client import SignedJwtAssertionCredentials

__all__.append('get_service')
#def get_service(**service_kwargs):
def get_service(name, version, scopes, admin_email,
		client_email, key_file, storage_file, **kwargs):
	"""
	Helper for initializing a Google API Client service.
	
	:param name: the API name
	:param version:
	:param storage_file:
	:param scopes:
	:param admin_email:
	:param client_email:
	:param key_file:
	"""
	# name = service_kwargs['name']
	# version = service_kwargs['version']
	# storage_file = service_kwargs['storage_file']
	
	http = httplib2.Http(timeout=10)
	storage = Storage(storage_file)
	credentials = storage.get()
	
	if credentials is None or credentials.invalid:
		# scopes = service_kwargs['scopes']
		# admin_email = service_kwargs['admin_email']
		# client_email = service_kwargs['client_email']
		# key_file = service_kwargs['key_file']
		
		with open(key_file) as f:
			private_key = f.read()
		
		credentials = SignedJwtAssertionCredentials(
			client_email, private_key, scopes, sub=admin_email)
		
		storage.put(credentials)
	else:
		credentials.refresh(http)
	
	http = credentials.authorize(http)
	service = build(name, version, http=http)
	
	return service
	