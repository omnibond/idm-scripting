# Exchange Scripting Driver Plug-In
### Summary

Microsoft Exchange includes the Exchange Management Shell, a command and scripting shell based on Windows PowerShell.

NetIQ Identity Manager, with the Identity Manager Active Directory Driver, allows synchronization of identities to and from Microsoft Active Directory and Exchange. The Identity Manager Scripting Driver can be deployed with this project's scripts to allow custom functionality to be implemented for Exchange.

### Features

The 'starter' scripts included create mailboxes and distribution groups in Exchange when users and groups are created in NetIQ eDirectory™. The scripts implement several options for mailbox placement. Mailboxes can be created in a specific mailbox database, a randomly assigned database, or a database indicated by an attribute.

### What you Need

Evaluation downloads are available for the Novell products below.

- NetIQ Identity Manager and its prerequisites, namely NetIQ eDirectory and NetIQ iManager.
- (Optional) Identity Manager Designer.
- Identity Manager Integration Module for Scripting, with the latest patches.
- Scripting Driver Documentation: https://www.netiq.com/documentation/idm48drivers/bi_impl_scripting/data/bi_impl_scripting.html
- Exchange Management Shell running on a Windows system in one of the Exchange organization's domains.

### Installation

See the relevant product documentation for help installing eDirectory, iManager, Identity Manager and Scripting Driver.


**Where to Install**

The Scripting Driver consists of two primary components: the Driver Object which runs on an eDirectory/Identity Manager server, and the Driver Shim which runs as a Windows service. Additionally, it is recommended to use the Scripting Driver Script Service, a Windows service that executes scripts more efficiently.

The Windows system you use has the following prerequisites:

- A modern Windows Server OS, any Edition, x64 architecture.
- Exchange Management Shell installed (included with Exchange Management Tools).

**Installing the AD Driver**

When installing the AD Driver, use these settings:

- Configure Data Flow: Set to Bidirectional. If you don't intend to synchronize AD accounts to eDir, set the attributes to Ignore on the Publisher channel in the Driver Filter.
- If you intend to allow the Exchange starter scripts to create mailboxes, set the method for managing Exchange mailboxes to None.

If the AD Driver is already installed:

- In the Driver Filter, set the User and Group classes to Synchronize on the Publisher channel. The attributes can still be set to Ignore if you aren't synchronizing from AD.
- If you intend to allow the Exchange starter scripts to create mailboxes, set Use CDOEXM for Exchange to No.

**Installing the Scripting Driver Shim**

- Install the Windows Scripting Driver, but do not import the default driver configuration. You will use a custom driver configuration from the script package.
- Change the Novell IDM Windows Script Driver service to log on as an Exchange administrator rather than LocalSystem. Restart the service.
- If you have modified the PowerShell scripts that come with the Scripting Driver, back them up.
- Unzip Scripting-ExShell-20090923.zip to your Scripting Driver directory (usually C:\Program Files\Novell\WSDriver).

**Pre-import Tasks**

- Extend the eDirectory schema
    - Use the Extend Schema task in iManager to add the schema file Schema\exshell.sch from the installation directory.
    - Log out/log in to iManager to refresh your view of the schema.
- Extend the AD Driver filter
    - Note: these tasks can also be performed in Designer.
    - Open the AD Driver's Driver Overview in iManager.
    - Click the Driver Filter icon in the diagram to open the Driver Filter.
    - Click the User class in the Filter. Click the Add Attribute button.
    - Click the Show All Attributes link in the bottom of the window.
    - Check the DirXML-ExShellState attribute and click OK.
    - Set DirXML-ExShellState's Publish mode to Synchronize, and its Subscriber mode to Ignore.
    - Click OK to save your changes.
- Extend the AD Driver policies
    - Note: these tasks can also be performed in Designer.
    - In the AD Driver's Driver Overview, click the Publisher Channel's Event Transformation Policies icon.
    - Click Insert to insert a new policy.
    - Enter the Policy name 'Exchange Attribute Detection Policy' and click OK.
    - Select 'Import an XML file containing DirXML Script' from the Insert menu.
    - Select Rules\ADDriverPolicy.xml from the installation directory and click OK.
    - Click OK on the two screens to save the changes. The policy should be the last policy in the sequence.

**Importing the Driver Configuration**

Import the XML configuration file (IDMScripting-version.xml) in the Rules directory in your installation directory. See the Scripting Driver documenation for more details.

### Configuring the Exchange Scripts

**Post-configuration Tasks**

- Fix your Exchange Management Shell path if necessary; if your Exchange Server is installed to C:\Program Files\Microsoft\Exchange Server, skip this task.
    - Open your Exchange Management Shell Driver properties in iManager.
    - Under Driver Parameters, edit the Script Command parameter to replace the path to exshell.psc1 with the correct path.
- If the AD Driver is running as a Remote Loader on the system, change the TCP/IP ports used by the Scripting Driver.
    - The AD Driver uses ports 8090 (command) and 8091 (HTTP) by default. Choose different ports for the Scripting Driver, e.g. 9090 and 9091.
    - Stop the Scripting Driver and Driver Shim.
    - In iManager or Designer, edit Driver properties and change the port in Remote loader connection parameters to the new command port.
    - On the Connected System, edit the file conf\wsdrv.conf. Change the port number in the -connection string to the new command port. Change the port number for the -httpport parameter to the new HTTP port.
    - Restart the Driver and Driver Shim.
- If Windows Firewall is enabled on the system where the Driver Shim is installed, create a exceptions for the ports used by the AD Driver (if necessary) and the Scripting Driver Shim.
- Set the AD Name Mapping Driver Parameter to a value consistent with your AD Driver's Name Mapping Global Configuration Values. (E.g., use Logon Name Mapping if the AD Driver has Logon Name Mapping enabled.)

**Configuring Mailbox Placement**

The Exchange scripts can be configured to create mailboxes in a specific mailbox database, or to randomize placement for load balancing. The placement is controlled by three driver parameters in the driver's Subscriber Settings. These parameters are described below.

| Mailbox Placement Mode |	Mailbox Placement Scope	| Mailbox Placement Identifier |	Notes |
|------------------|:------------------------:|:----------------------------:|:-------|
| Default	               |Not used	                |Not used	                     |Place the mailbox in the default mailbox database, usually 'Mailbox Database' on the local server. |
|Specific	|Not used	|Path to desired mailbox database, e.g. MYSERVER\My Database |Place the mailbox in the specified mailbox database.|
|Random	|Site, Server or Storage Group	|Path to container of type specified by scope, or blank if 'Site' was specified.	|Randomly places mailbox in one of the databases in the site, specified server or storage group.|
|By Attribute	|Not used	|Name of attribute to use	|Place the mailbox in the database given by the specified attribute.|

The randomization does not take into account the number of mailboxes already in a database; each database has an equal chance of selection.

Paths can be a GUID, or can be of the form [Server Name][\][Storage Group Name][\][Mailbox Database Name], depending on what type of container is specified.

### Using the Script Service (IDM 4 or later)

If you wish to use the Script Service (see Scripting Driver documentation), make sure you have the latest release, then follow these additional steps:

- Change services (Driver and Script Service) to log in as an Exchange administrator. They must log in as the same user.
- Create WSDriver\conf\scriptservice.conf and this line: -command Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin
