# Copyright (C) 2008 Novell, Inc.

function idm_modify
{
  # *********************************************
  # * Sample code:                              *
  # *   Using the association (GUID) to locate  *
  # *   an object.                              *
  # *********************************************
  
  # Get domain name
  $sys = Get-WMIObject Win32_ComputerSystem
  $domain = $sys.domain

  # Retrieve association
  $assoc = idm_geteventvalue "ASSOCIATION"

  if ($assoc -ne $null -and $domain -ne $null) {
    # build domain root in LDAP format
    $domaindn = "LDAP://"
    $tokens = $domain.split(".")
    for ($i = 0; $i -lt $tokens.length; $i++) {
      $domaindn += "dc=" + $tokens[$i]
      if ($i -lt ($tokens.length-1)) {
        $domaindn += ","
      }
    } 

    # Set up AD connection
    $adconn = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$domain")
    $adconn.PSBase.AuthenticationType = [System.DirectoryServices.AuthenticationTypes]::FastBind
    $adconn.PSBase.Path = $domaindn

    # Set up AD searcher
    $searcher = New-Object System.DirectoryServices.DirectorySearcher
    $searcher.SearchRoot = $adconn
    
    # Use escaped GUID for the search filter
    $filter = "(objectGUID="
    for ($i = 0; $i -lt 32; $i += 2) {
      $filter += "\" + $assoc.Substring($i, 2)
    }
    $filter += ")"
    $searcher.Filter = $filter

    # Execute the search
    $identity = $searcher.FindOne()

    if ($identity -ne $null) {
      # ******************************************
      # * Add implementation-specific code here. *
      # ******************************************

      idm_statussuccess "Modify event succeeded"
    }
    else {
      idm_statuserror "Could not locate object for association $assoc"
    }
  }

}
