## Windows Domain and Local Accounts Scripting Driver Plug-In

### Summary

The Novell Identity Manager Scripting Driver allows you to write custom scripts in order to synchronize identity management information from Novell eDirectory™ to an external identity management system. This project contains Microsoft VBScript scripts that allow synchronization from your identity vault (eDirectory) to Windows NT domains or Windows local accounts. Use the scripts right 'out of the box' or customize them further to meet your needs.

### Features

- Synchronization of user accounts from your identity vault to a Windows NT Domain, Windows local account system, or an Active Directory tree.
- Synchronization of groups from your identity vault to Windows, with group memberships.
- Synchronization of relevant attributes, like Login Disabled, Password Expiration Time and more, with conversion of Date-type attributes.
- Password synchronization from your identity vault to Windows.
- Event-based and/or manual synchronization.
- Ability to migrate existing users.
- May be extended to support users and groups on multiple Windows systems.
- Fully customizable VBScript scripts that can be used immediately or extended.
- Support for Windows 2000, Windows XP, Windows 2003, Windows Vista, Windows 2008, Windows 2012.

### What you Need

Evaluation downloads are available for the Novell products below.

- Novell Identity Manager and its prerequisites, namely Novell eDirectory and Novell iManager.
- Identity Manager Integration Module for Scripting, with the latest patches.
- Scripting Driver Documentation
- The Windows Domain and Local Accounts package in File Releases below: Scripting-WinDomain.zip.
- Windows 2000 Users:
     - Windows Script Host 5.6 below: WindowsXP-Windows2000-Script56-KB917344-x86-enu.exe
     - The patched Windows Script Driver installer below that will run on Windows 2000: windows_scriptdriver_install.exe.

### Installation

See the relevant product documentation for help installing eDirectory, iManager, Identity Manager and Scripting Driver.

- Install the Windows Scripting Driver, but do not import the default driver configuration. You will use a custom driver configuration from the script package.
- Change the Novell IDM Windows Script Driver service to log on as a domain/system administrator rather than LocalSystem. Restart the service.
- Windows 2000 users must install the linked Windows Script Host 5.6 below.
- If you have customized your Scripting Driver VBScript scripts, back them up to a different folder.
- Download the Scripting-WinDomain.zip package and extract it to your driver directory, C:\Program Files\Novell\WSDriver by default. This will overwrite most of your existing VBScript scripts.
- Create a new Driver in eDirectory using iManager. Use the rules\Scripting-WinDomain.xml file for driver configuration. You'll be prompted to enter your domain/system name during configuration.
- Start the Driver in iManager and the Novell IDM Windows Script Driver service to begin synchronizing accounts.

Newly created identities will be synchronized to Windows. Identities will use the CN attribute as the (Logon) Name in Windows. You can also migrate existing identities using the driver's Migrate feature. If you need to migrate users with group memberships, migrate all the users first, and then the groups.

Functionality is limited on Active Directory. All users and groups will be created in the Users container in AD. Only a small number of attributes are supported. For more functionality use the Novell Active Directory Driver.

### Multi-domain Functionality

Currently the scripts support synchronization to one domain, system or tree. However the scripts were written to be extended to support multiple domains; the functionality wasn't included directly because there are a variety of ways this could be accomplished.

Extending the driver will require knowledge of Identity Manager Driver Policies which are covered in the Identity Manager documentation.

Currently the name of the system is stored in a global configuration value (GCV). This value is used in the Matching Rule and Create Rule in the Driver policies. Below are two ideas for enabling multiple systems.

- **Object Attribute:** An attribute on the User and Group objects contains the domain name. Add this attribute to the Driver filter. The Matching and Create Rules use this attribute instead of the GCV for the domain name.
- **Container Placement:** The name of the container of the object indicates the domain name. The Matching and Create Rules parse this information from the object's DN and send it as the domain name instead of the GCV.

### Future Possibilities

- Support for synchronization from Windows to the identity vault.
- Built-in support for multiple domains.
- Checking that attributes are in a legal format.
