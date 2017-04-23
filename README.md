# IDM Scripting Plug-Ins
The idm-scripting repository contains open source plug-ins to the Identity Management Scripting scritping driver developed by Omnibond and sold through Microfocus as the NetIQ Identity Manger Scripting Driver (https://www.netiq.com/documentation/idm45drivers/bi_impl_scripting/data/bi_impl_scripting.html)

The scripting driver plug-ins turn the scripting driver into customizable integrations to various systems.

Omnibond also developes additional drivers for Mainframe, i Series, Linux/UNIX, Blackboard and user settings which you can find documentation on at: https://www.netiq.com/documentation/identity-manager-46-drivers/


Respective addins are in the following directory structure:

**Google/gmail**
- Provides Identity integration with GSuite applications.

**Microsoft/Exchange**
- Provides Identity integration with Microsoft Exchange 

**Microsoft/windows/domain**
- Provides Identity integration directly with local windows security and windows Domain accounts.

**sasldb/**
- Provides connectivity to the sasldb database, used by many Linux and UNIX applications for Simple Authentication Security Layer (SASL).

**DHCP/**
- Enabled Identity integration with DHCP, this enabled DHCP registrations to create device entries into the vault to tie network and identity systems together.

**Honeyd/**
- Enables Identity device integration with Honeyd to detect devices with bots or worms and can be used with the DHCP scripts to remove a device from the network at the next DHCP lease renewal.
