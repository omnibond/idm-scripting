# Copyright (C) 2008 Novell, Inc.

function select_mailbox_database
{
  param([string]$mode, [string]$scope, [string]$id)

  if ($mode -eq "random") {
    # generate list of servers depending on mode (may be a single server)
    if ($scope -eq "site") {
      $servers = Get-MailboxServer
    }
    elseif ($scope -eq "server") {
      $servers = Get-MailboxServer -Identity $id
    }
    else { # scope = storage group
      if ($id.IndexOf("\") -ne -1) {
        $servername = $id.Substring(0, $id.IndexOf("\"))        
      }
      else {
        # get current server
        $servername = (Get-WMIObject Win32_ComputerSystem).Name
      }
      $servers = Get-MailboxServer -Identity $servername
    }
    
    # generate list of storage groups depending on mode (may be one storage group)
    if ($scope -eq "site" -or $scope -eq "server") {
      foreach ($server in $servers) {
        [Object[]] $storagegroups += Get-StorageGroup -Server $server.Name
      }
    }
    else { # scope = storage group
      $storagegroups = Get-StorageGroup -Identity $id
    }

    # generate list of mailbox databases from applicable servers and storage groups
    foreach ($storagegroup in $storagegroups) {
      [Object[]] $mbdatabases += Get-MailboxDatabase -StorageGroup $storagegroup.Name
    }  
    
    # randomly select a mailbox database from the list
    if ($mbdatabases.length -gt 0) {
      $random = New-Object "Random"
      $i = $random.Next(0, $mbdatabases.length)
      return $mbdatabases[$i].Name
    }

  }
  elseif ($mode -eq "specific") {
    # simply use identifier provided by admin
    return $id
  }
  elseif ($mode -eq "byattribute") {
    # the id param contains the attribute name
    return (idm_geteventvalue $id)
  }
  else { # mode = default
    # select the first mailbox database supplied
    $mbdatabases = Get-MailboxDatabase
    # handles an array or a single database
    foreach ($mbdatabase in $mbdatabases) {
      # append server name for Exchange 2007 only
      $exserver = Get-ExchangeServer $mbdatabase.Server.Name
      if ($exserver.AdminDisplayVersion.Major -eq 8) {
        return $mbdatabase.Server.Name + "\" + $mbdatabase.Name
      }
      else {
        return $mbdatabase.Name
      }      
    }
  }

  # No database could be located
  return $null

}

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
  # get AD domain controller
  $dc = idm_getdriverparam "ad-dc"
  if ($dc -eq "") { $dc = $null }

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
  
    # get mailbox database based on driver parameters
    $mode = idm_getsubscriberparam "ex-shell-mailbox-mode"
    $scope = idm_getsubscriberparam "ex-shell-mailbox-scope"
    $storeid = idm_getsubscriberparam "ex-shell-mailbox-id"
    $mbdatabase = select_mailbox_database $mode $scope "$storeid"

    # Enable the mailbox
    if ($dc -ne $null) {      
      $exobject = Enable-Mailbox -Identity $id -Database $mbdatabase -DomainController "$dc" -ErrorAction Continue
    }
    else {
      $exobject = Enable-Mailbox -Identity $id -Database $mbdatabase -ErrorAction Continue
    }
  }
  elseif ($classname -eq "Group") {
    # Get location of AD Group    
    $account = idm_geteventvalue "sAMAccountName"
    $base = idm_getdriverparam "ad-base"
    $id = "cn=" + $account + "," + $base

    # Make this group a Universal group
    $group = New-Object DirectoryServices.DirectoryEntry("LDAP://" + $id)
    $group.groupType = 0x80000008
    $group.setInfo()

    # Enable it as a distribution group
    if ($dc -ne $null) {
      $exobject = Enable-DistributionGroup -Identity $id -DomainController $dc -ErrorAction Continue
    }
    else {
      $exobject = Enable-DistributionGroup -Identity $id -ErrorAction Continue
    }
  }

  # Mailbox/Distribution Group enable failed
  if ($exobject -eq $null) {
    idm_statuserror ($Error.Item(0).Exception.Message + $Error.Item(0).InvocationInfo.PositionMessage.Replace("`n", " "))
    return
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
  idm_statussuccess ("Enabled " + $id)
   
}
