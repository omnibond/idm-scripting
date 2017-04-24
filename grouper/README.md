## Grouper Scripting Driver Plug-In

### Summary

The NetIQ Identity Manager Scripting Driver allows you to write custom scripts in order to synchronize identity management information from the IDentity Vault to an external identity management system. This project contains Perl scripts that allow synchronization from your identity vault to Grouper v2.3 or newer folders and groups. Use the scripts right 'out of the box' or customize them further to meet your needs.

### Features

- Synchronization of groups from your identity vault to Grouper, with group memberships.
- Synchronization of organizations and organizational units from your identity
  vault to Grouper folders.
- Synchronization of description and group memberships
- Event-based and/or manual synchronization.
- Groups can be provisioned into a single folder in Grouper, or the structure
  of organizations and organizational units can be mirror under a Grouper
folder.

### What you Need

Evaluation downloads are available for the NetIQ products below.

- NetIQ Identity Manager and its prerequisites, namely eDirectory and iManager.
- Identity Manager Integration Module for Scripting, with the latest patches.
- Scripting Driver Documentation
- Grouper v2.3 or later with the Grouper WS configured
- A username/password for the Grouper WS.  Refer to Grouper documentation for
  details:
https://spaces.internet2.edu/display/Grouper/Grouper+WS+Authentication  Make
sure you setup the ActAs configuration so that the Grouper WS username can
make modifications.
- Make sure Grouper is resolving external entities against your eDirectory
  tree.  Note that both the UI and the WS will need to be configured.  Refer
to Grouper documentation for details:  https://spaces.internet2.edu/display/Grouper/Grouper+-+Loader+LDAP

### Installation

See the relevant product documentation for help installing eDirectory, iManager, Identity Manager and Scripting Driver.

- Install the Scripting Driver, but do not import the default driver configuration. You will use a custom driver configuration from the script package.
- Install required Perl Modules: WWW::Curl::Easy Crypt::CBC Crypt::Rijndael JSON
- Copy the files from scripts/ and schema/ to the corresponding directories
  under /opt/novell/usdrv/
- Create a new Driver in eDirectory using iManager. Use the
  rules\grouper-scripting.xml file for driver configuration. You'll be
prompted to enter the password for the Grouper WS user.
- Go to Driver Properties and the GCVs section.  Configure the GrouperWS Base
  Url, Grouper Username, Base DN, Grouper Base Folder Path, and decide whether
to provision a flat structure.
- Start the Driver in iManager and the NetIQ IDM Scripting Driver service to begin synchronizing accounts.

Newly created groups will be synchronized to Grouper. You can also migrate
existing groups using the driver's Migrate feature. You can even migrate an
entire subtree by migrating the top level organizational unit.

