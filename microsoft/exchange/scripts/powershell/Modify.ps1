# Copyright (C) 2008 Novell, Inc.

function idm_modify
{
  # ******************************************
  # * Sample Exchange Management Shell code: *
  # *   Using the association (GUID) to lo-  *
  # *   cate a user mailbox.                 *
  # ******************************************
  
  # # Retrieve association
  # $assoc = idm_geteventvalue "ASSOCIATION"
  # # Convert association to byte array
  # [byte[]] $bytes = [byte] ("0x" + $assoc.Substring(0, 2))
  # for ($i = 2; $i -lt 32; $i += 2) {
  #   $bytes += [byte] ("0x" + $assoc.Substring($i, 2))
  # }
  # # Create GUID object
  # $barray = , $bytes   # Object array containing $bytes
  # $guid = New-Object "Guid" $barray
  # # Locate mailbox
  # $mailbox = Get-Mailbox $guid.ToString()
  
  # ******************************************
  # * Add implementation-specific code here. *
  # ******************************************
  
  idm_statussuccess "Modify event succeeded"
}
