
__all__ = []

import os
import logging

__all__.extend(['SCRIPTS_DIR'])
SCRIPTS_DIR = os.environ.get('INSTALL_PATH') + '/scripts'

__all__.extend([
	'LOG_LEVEL', 'LOG_NAME', 'LOG_FILE', 'gmail_logger'
])

LOG_LEVEL = logging.INFO
LOG_NAME = 'gmail-driver'
LOG_FILE = '/tmp/gmail.log'

logging.basicConfig(level=LOG_LEVEL, filename=LOG_FILE)
gmail_logger = logging.getLogger(LOG_NAME)

#
# Google domain and service account credentials used to access the
# GMail API by the driver.
#
__all__.extend([
	'API_DOMAIN', 'API_NAME', 'API_VERSION',
	'USERS_API_SCOPES', 'USERS_API_ADMIN_EMAIL',
	'USERS_API_CLIENT_ID', 'USERS_API_CLIENT_EMAIL', 
	'USERS_API_PUBLIC_KEY', 'USERS_API_KEY_FILE',
	'USERS_API_STORAGE_FILE'
])

##
# TEST/DEV
##
# See the README for setting up an API user
API_DOMAIN = "testgmail.example.com"
USERS_API_ADMIN_EMAIL = "testapiuser@testgmail.example.com"
USERS_API_CLIENT_ID = "numbers-gibberish.apps.googleusercontent.com"
USERS_API_CLIENT_EMAIL = "numbers-gibberish@developer.gserviceaccount.com"
USERS_API_PUBLIC_KEY = "hash string"
USERS_API_KEY_FILE = SCRIPTS_DIR + "/keys/testUserAPIClientKey.p12"
USERS_API_STORAGE_FILE = SCRIPTS_DIR + "/cache/gmail-user-api.storage"

# These probably do not need to be changed unless the API changes
API_NAME = 'admin'
API_VERSION = 'directory_v1'
USERS_API_SCOPES = ['https://www.googleapis.com/auth/admin.directory.user']

##
# PRODUCTION
## 
# See the README for setting up an API user
# API_DOMAIN = "gmail.example.com"
# USERS_API_ADMIN_EMAIL = "apiuser@gmail.example.com"
# USERS_API_CLIENT_ID = "numbers-gibberish.apps.googleusercontent.com"
# USERS_API_CLIENT_EMAIL = "numbers-gibberish@developer.gserviceaccount.com"
# USERS_API_PUBLIC_KEY = "hash string"
# USERS_API_KEY_FILE = SCRIPTS_DIR + "/keys/userAPIClientKey.p12"
# USERS_API_STORAGE_FILE = SCRIPTS_DIR + "/cache/gmail-user-api.storage"

# These probably do not need to be changed unless the API changes
# API_NAME = 'admin'
# API_VERSION = 'directory_v1'
# USERS_API_SCOPES = ['https://www.googleapis.com/auth/admin.directory.user']