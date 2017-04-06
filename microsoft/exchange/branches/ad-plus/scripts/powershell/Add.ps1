# Copyright (C) 2008 Novell, Inc.

function idm_add
{
  # ***************************************************
  # * Add implementation-specific code here.          *
  # * Specify the ADD_ASSOCIATION command to supply a *
  # * unique association.                             *
  # ***************************************************
  
  # Get short domain name
  # A system that is not a DC will report itself as a domain
  $domains = Get-WMIObject Win32_NTDomain  
  foreach ($dom in $domains) {
    if ($dom.DomainName -ne $null) {
      $domain = $dom.DomainName
      break
    }
  }

  $classname = idm_geteventvalue "CLASS_NAME"
  $dn = idm_geteventvalue "SRC_DN"
  $eventid = idm_geteventvalue "EVENT_ID"

  if ($classname -eq "User") {
    # Create user identifier based on name mapping parameter
    $namemapping = idm_getdriverparam "name-mapping"  
    if ($namemapping -eq "LogonNameMap") {
      $account = idm_geteventvalue "sAMAccountName"    
      $id = $domain + "\" + $account
    }
    elseif ($namemapping -eq "FullNameMap") {
      $fullname = idm_geteventvalue "Full Name"
      $base = idm_getdriverparam "ad-base"
      $id = "cn=" + $fullname + "," + $base
    }
    else {
      # NOTE: If using custom mapping, insert below
      # Default mapping follows
      $account = idm_geteventvalue "sAMAccountName"
      $base = idm_getdriverparam "ad-base"
      $id = "cn=" + $account + "," + $base
    }
  }
  elseif ($classname -eq "Group") {
    # Get location of AD Group    
    $account = idm_geteventvalue "sAMAccountName"
    $base = idm_getdriverparam "ad-base"
    $id = "cn=" + $account + "," + $base
  }

  idm_setcommand "ADD_ASSOCIATION"
  # return GUID as association (same format as AD driver)
  $guidbytes = $exobject.Guid.ToByteArray()
  foreach ($byte in $guidbytes) {
    $guid += [String]::Format("{0:x2}", $byte)
  }
  idm_writevalue "ASSOCIATION" $guid
  idm_writevalue "EVENT_ID" $eventid
  idm_writevalue "DEST_DN" $dn
  idm_statussuccess ("Associated " + $id)
   
}
