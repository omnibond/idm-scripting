# !!! Rename this file to Modify.ps1 !!!
# !!! Install in WSDriver\Scripts    !!!

# Disable a mailbox when the Identity Vault Login Disabled
# attribute is set to true, and re-connect it when set to
# false. 
# You could also use the Get-MailboxStatistics code in the
# Add.ps1 script to check whether a new user has an existing
# (disconnected) mailbox.

function idm_modify
{
  $msg = "Modify event: no changes"

  # Use the association (GUID) to locate a user mailbox.  
  $assoc = idm_geteventvalue "ASSOCIATION"
  # Convert association to byte array
  [byte[]] $bytes = [byte] ("0x" + $assoc.Substring(0, 2))
  for ($i = 2; $i -lt 32; $i += 2) {
    $bytes += [byte] ("0x" + $assoc.Substring($i, 2))
  }
  # Create GUID object
  $barray = , $bytes   # Object array containing $bytes
  $guid = New-Object "Guid" $barray
  # Locate mailbox
  $mailbox = Get-Mailbox $guid.ToString() -ErrorAction SilentlyContinue
    
  $disabled = idm_geteventvalue "Login Disabled"  
  if ($disabled -ieq "true" -and $mailbox -ne $null) {
    $alias = $mailbox.Alias
    Disable-Mailbox $mailbox.Alias -Confirm:$false
    $msg = "Mailbox $alias disabled"
  }
  elseif ($disabled -ieq "false" -and $mailbox -eq $null) {
    # Query for account name
    idm_queryinit
    idm_querysetassociation $assoc    
    idm_queryaddreadattr "DirXML-ADAliasName" # must use Identity Vault name
    if (idm_doquery) {
      $account = idm_getqueryinstanceattrvalue "sAMAccountName"
    }
    if ($account -ne $null) {
      $dmailbox = Get-MailboxStatistics | where {$_.DisconnectDate -ne $null -and $_.LegacyDN -imatch ".*$account"}
      if ($dmailbox -ne $null) {
        $mailbox = Connect-Mailbox $dmailbox.MailboxGuid $dmailbox.Database -User $dmailbox.DisplayName
        # *** if you had a custom alias or address other than account@domain, it must be set here

        $msg = "Mailbox $account connected"
      }
    }
  }

  idm_statussuccess $msg
}
