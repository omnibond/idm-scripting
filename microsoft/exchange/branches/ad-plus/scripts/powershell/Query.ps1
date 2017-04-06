# Copyright (C) 2008 Novell, Inc.

function idm_query
{
  # ******************************************
  # * Add implementation-specific code here. *
  # * Set the command to INSTANCE.           *
  # ******************************************

  # Get domain name
  $sys = Get-WMIObject Win32_ComputerSystem
  $domain = $sys.domain

  $classname = idm_geteventvalue "SEARCH_CLASSES"
  $association = idm_geteventvalue "ASSOCIATION"
  # association corresponds to object GUID
  if ($association -ne $null) {
    # build domain root in LDAP format
    $domaindn = "LDAP://"
    $tokens = $domain.split(".")
    for ($i = 0; $i -lt $tokens.length; $i++) {
      $domaindn += "dc=" + $tokens[$i]
      if ($i -lt ($tokens.length-1)) {
        $domaindn += ","
      }
    } 
    $scope = "subtree"
    $base = $domaindn
    # format GUID for search
    for ($i = 0; $i -lt 32; $i += 2) {
      $searchguid += "\" + $association.Substring($i, 2)
    }
	$filter = "(objectGUID=" + $searchguid + ")"
  }
  else {
    # get query properties
    $scope = idm_geteventvalue "SCOPE"
    $classname = idm_geteventvalue "CLASS_NAME"
    $base = "LDAP://" + (idm_geteventvalue "DEST_DN")

    $names = idm_geteventvaluenames
    $filter = "(&(objectClass=$classname)"
    foreach ($name in $names) {
      if ($name -eq $null) { break }
	  if ($name -match "^SEARCH_ATTR") {
	    $attrname = $name.substring(12)
	    $values = idm_geteventvalues $name
	    foreach ($value in $values) {
	      if ($value -eq $null) { break }
		  $filter += "(" + $attrname + "=" + $value + ")"
	    }
	  }
    }
    $filter += ")"
  }

  # Connect to AD
  $adconn = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$domain")
  $adconn.PSBase.AuthenticationType = [System.DirectoryServices.AuthenticationTypes]::FastBind
  $adconn.PSBase.Path = $base

  # Create search object
  $searcher = New-Object "System.DirectoryServices.DirectorySearcher"
  $searcher.SearchRoot = $adconn
  # set scope -- subtree is the default scope
  if ($scope -eq "entry") {
    $searcher.SearchScope = [System.DirectoryServices.SearchScope]::Base
  }
  elseif ($scope -eq "subordinates") {
    $searcher.SearchScope = [System.DirectoryServices.SearchScope]::OneLevel
  }
  $allattrs = idm_geteventvalue "ALL_READ_ATTRS"
  if ($allattrs -ne "TRUE") {
    $noattrs = idm_geteventvalue "NO_READ_ATTRS"
	if ($noattrs -ne "TRUE") {
	  $attrs = idm_geteventvalues "READ_ATTRS"
	}
  }
  if ($attrs -ne $null) {
    $searcher.PropertiesToLoad.AddRange($attrs)
  }
  # Always retrieve the GUID to be the association
  if (-not $searcher.PropertiesToLoad.Contains("objectGUID")) {
    $index = $searcher.PropertiesToLoad.Add("objectGUID")
  }
  $searcher.Filter = $filter

  # Execute the search
  $res = $searcher.FindOne()

  if ($res -ne $null) {
    # return query instance
    idm_setcommand "INSTANCE"
    idm_writevalue "CLASS_NAME" $classname
    # retrieve GUID and format as string
    $guidbytes = $res.Properties.Item("objectGUID").Item(0)
    # make hex string of GUID in binary order
    foreach ($byte in $guidbytes) {
      $guid += [String]::Format("{0:x2}", $byte);
    }
    idm_writevalue "ASSOCIATION" $guid
    idm_writevalue "SRC_DN" $res.Properties.Item("distinguishedName")
    foreach ($prop in $res.Properties.PropertyNames) {
      if ($prop -ne "distinguishedName" -and $prop -ne "adspath") {
        if ($allattrs -eq "TRUE" -or $attrs -contains $prop) {
          idm_writevalue ("ATTR_" + $prop) $res.Properties.Item("$prop")
		}
	  }
    }
    idm_statussuccess "Query event succeeded"
    return
  }
  # if an association was provided, issue a warning if there is an error message
  if ($association -ne $null) {
    if ($error.count -gt 0) {
	  idm_statuswarning ($Error.Item(0).Exception.Message + $Error.Item(0).InvocationInfo.PositionMessage.Replace("`n", " "))
	}
	else {
	  idm_statuswarning "Could not locate associated object; cause unknown"
	}
  }
  else {
    idm_statussuccess "Query event succeeded"
  }
  
}
