## Google G-Suite Scripting Plug-In

These scripts require the latest version of Python 2
Required Python Modules:
To verify the module versions look in the python site-packages directories or
run: pip list

NOTE: Installing the google API client may install a different and/or duplicate
       version of pyOpenSSL and possible other modules which could cause problems.
       See the "Possible Installation Issues" section below.
        

cffi (0.8.6)
google-api-python-client (1.4.0)
httplib2 (0.9.1)
oauth2client (1.4.7)
pyOpenSSL (0.14)
simplejson (3.6.5)
smtplib
pprint
MIMEText from email.mime.text


Install Google API Python Client
--------------------------------

https://github.com/google/google-api-python-client

Requires the latest version of Python 2
[zypper|yum|apt-get] install python python-pip

If pip for python is available...
pip install --upgrade google-api-python-client

If pip for python is not available...
wget https://bootstrap.pypa.io/ez_setup.py -O - | python
easy_install --upgrade google-api-python-client



Create Google Project and Service Account
-----------------------------------------

Guide: https://developers.google.com/accounts/docs/OAuth2ServiceAccount#creatinganaccount

After creating the account and generating the P12 key copy the cliend ID, email address, etc..
and paste it into the config file for the scripts.

Be sure to setup the domain wide athority to the service account. The current 
scope(s) required are: https://www.googleapis.com/auth/admin.directory.user

Setup up an admin user that has access to the Admin SDK Directory API
e.g: idm_driver_api_user@example.com. This user will need to have at least
the "User Management Admin" role. Set USERS_API_ADMIN_EMAIL to the 
admin user's email in config.py.



Verify Setup and Configuration
--------------------------------

The user-api test will call each user API method and can be used to check if the
right version of python and python modules are installed and verify that the API
user and service account has been setup correctly.

./run-tests.sh tests/user-api.py



Possible Installation Issues
----------------------------

Using an OS's package manager (zypper, yum, apt-get, etc..) in combination with pip 
may cause different versions of the same python module to be installed. If you get
python errors when running the user-api test, check all of the python site-packages 
directories to see if there are any duplicate python modules installed. Remove any duplicates
if the versions do not match up with the version listed above. 

To find all of the python site-packages directories run:
find /usr/ -type d -name site-packages | grep python
