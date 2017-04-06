# Copyright (C) 2008 Novell, Inc.

function idm_rename
{
  # ******************************************
  # * Add implementation-specific code here. *
  # ******************************************

  # ******************************************
  # * Exchange Management Shell:             *
  # *   See Modify.ps1 for sample code for   *
  # *   locating user mailboxes.             *
  # * Note: Depending on the settings of the *
  # *  AD Driver, you may receive a modify   *
  # *  event for the DirXML-ADAliasName      *
  # *  attribute after this event.           *
  # ******************************************

  idm_statussuccess "Rename event succeeded"
}
