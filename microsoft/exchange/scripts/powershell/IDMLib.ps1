# Copyright (C) 2008 Novell, Inc.

# The EventReader utility
$EVENTREADER = "bin\EventReader.exe"
# The IdmEvent utility
$IDMEVENT = "bin\IdmEvent.exe"

# Declarations for parameters
$DRIVERPARAMPREFIX = "DRIVER_INIT_PARAM_"
$SUBSCRIBERPARAMPREFIX = "SUBSCRIBER_INIT_PARAM_"
$PUBLISHERPARAMPREFIX = "PUBLISHER_INIT_PARAM_"

# The associative array for parameters
$parameters = @{}

# The array for event values
$eventvalues = @{}

$global:commandflag = $false

# Filenames
$global:inputfile = ""
$global:outputfile = ""
$global:queryfile = ""
$global:queryrspfile = ""

# Query instance array
$queryinstance = @{}

# Query constants
$QI_ASSOCIATION = "ASSOCIATION"
$QI_DN = "SRC_DN"
$QI_CLASS_NAME = "CLASS_NAME"
$QI_ATTRS = "ATTRS"

# Variables for publishing events
$publishvalues = @{}
$global:publishflag = $false

# additonal variables
$global:installpath = ""
$global:tracefile = ""
$global:scripttracing = $true

# Initialize variables
function idm_scriptinit
{
  param([string]$inputfilename)

  $global:inputfile = $inputfilename
  $global:outputfile = $inputfile + ".OUT"
  $global:queryfile = $inputfile + ".QRY"
  $global:queryrspfile = $inputfile + ".QRP"

  idm_setpaths

  # Stop on PowerShell error
  $global:ErrorActionPreference = "Stop"

  # Process data in the current code page
  # Note: doesn't work in service on PowerShell v2
  trap {
     [Console]::InputEncoding = [System.Text.Encoding]::Default
     [Console]::OutputEncoding = [System.Text.Encoding]::Default
  }
  $global:OutputEncoding = [System.Text.Encoding]::Default
}

# Read the driver parameters from the parameters file
function idm_readparams
{
  param([string]$filename)
  
  $lines = Get-Content $filename
  if ($lines -eq $null) {
    idm_trace "Unable to read parameter file $filename"
	return
  }

  foreach ($line in $lines) {
    if ($line.contains("=")) {
	  $index = $line.indexof("=")
	  $name = $line.substring(0, $index)
	  $value = $line.substring($index+1)
	  $parameters[$name] = $value
	}
  }

}

# Return the driver parameter value for the given name
# Parameters have case-insensitive names and are single-valued
function idm_getdriverparam
{
  param([string]$paramname)

  $value = $parameters[$DRIVERPARAMPREFIX + $paramname]
  if ($value -eq $null) { $value = $parameters[$paramname] }

  return $value
}

# Return the Subscriber parameter value for the given name
function idm_getsubscriberparam
{
  param([string]$paramname)

  $value = $parameters[$SUBSCRIBERPARAMPREFIX + $paramname]
  if ($value -eq $null) { $value = $parameters[$paramname] }

  return $value
}

# Return the Publisher parameter value for the given name
function idm_getpublisherparam
{
  param([string]$paramname)

  $value = $parameters[$PUBLISHERPARAMPREFIX + $paramname]
  if ($value -eq $null) { $value = $parameters[$paramname] }

  return $value
}

# Set constants from driver parameters
function idm_setpaths
{
  $global:installpath = idm_getdriverparam "INSTALL_PATH"
  if ($installpath -eq $null) {
    $path = Get-Location
	$global:installpath = $path.toString()    
  }
  # append trailing backslash
  if ($global:installpath.substring($installpath.length-1, 1) -ne "\") {
    $global:installpath += "\"
  }

  # set tracefile location
  $global:tracefile = idm_getdriverparam "script-trace-file"
  if ($global:tracefile -eq $null -or $global:tracefile -eq "") {
    $global:tracefile = "logs\script-trace.log"
  }

}

function idm_readevent
{
  # Execute the EventReader utility to retrieve event data
  $lines = &$EVENTREADER $inputfile "nvpairs"  

  # Error checking
  if ($LASTEXITCODE -ne 0) {
    idm_trace "EventReader failed to process $inputfile with error code $LASTEXITCODE"
	exit $LASTEXITCODE
  }
  elseif ($lines -eq $null) {
    idm_trace "EventReader returned no data reading $inputfile"
	return
  }
  
  # Parse each line
  foreach ($line in $lines) {
    if ($line.contains("=")) {
	  # Split into name and value
      $equals = $line.indexof("=", 0)
	  $name = $line.substring(0, $equals)
	  $value = $line.substring($equals+1)
	  # Assign value to eventvalues hashtable
	  # Multiple values are supported
	  $eventvalues[$name] += [string[]] $value
    }
  }
}

# Return an array of all the event value names
function idm_geteventvaluenames
{
  return $eventvalues.keys
}

# Return an array of all the attribute change value names
# May include value ADDs or REMOVEs, plus the PASSWORD
# Returns $null if none available
function idm_geteventattrnames
{
  foreach ($name in $eventvalues.keys) {
    if (($name -eq "PASSWORD") `
	    -or ($name.substring(0, 4) -eq "ADD_" -and $name.substring(0, 8) -ne "ADD_REF_") `
	    -or ($name.substring(0, 7) -eq "REMOVE_" -and $name.substring(0, 11) -ne "REMOVE_REF_")) {	  
      $attrnames += [string[]] $name	  
	}
  }
  
  return $attrnames
}

# Return an array of values for the specified name/value pair
function idm_geteventvalues
{
  param([string]$name)

  if ($eventvalues[$name] -ne $null) {
    return $eventvalues[$name]
  }
  else {
    # Returns array for values with ADD_ prefixed
	# May return $null
    return $eventvalues["ADD_" + $name]
  }

}

# Return a single value for the specified name/value pair
function idm_geteventvalue
{
  param([string]$name)

  if ($eventvalues[$name] -ne $null) {
    return $eventvalues[$name][0]
  }
  elseif ($eventvalues["ADD_" + $name] -ne $null) {
    return $eventvalues["ADD_" + $name][0]
  }

}

# Write the command... must be done before writing other values
function idm_setcommand
{
  param([string]$command)
  "IDMSETVAR: COMMAND=" + $command | Out-File $outputfile -encoding Default -append
  $global:commandflag = $true
}

# Write a name/value pair back for the driver to process
# You may specify one value or an array of values
function idm_writevalues
{
  param([string]$name, $values)
  if ($global:commandflag) {
    foreach ($value in $values) {
	  "IDMSETVAR: " + $name + "=" + $value | Out-File $outputfile -encoding Default -append
	}
  }
  else {
    idm_trace "idm_setcommand must be called before idm_writevalues"
  }
}
  
# Single-value shortcut for idm_writevalues
function idm_writevalue
{
  param([string]$name, [string]$value)

  idm_writevalues $name $value
}

# Write an event status for processing by the driver
function idm_status
{
  param([string]$level, [string]$message)
  idm_setcommand "status"
  idm_writevalue "STATUS_LEVEL" $level
  idm_writevalue "STATUS_MESSAGE" $message 
}

function idm_statussuccess
{
  param([string]$message)

  idm_status "success" $message
}

function idm_statuserror
{
  param([string]$message)

  idm_status "error" $message
}

function idm_statusfatal
{
  param([string]$message)

  idm_status "fatal" $message
}

function idm_statuswarning
{
  param([string]$message)

  idm_status "warning" $message
}

function idm_statusretry
{
  param([string]$message)

  idm_status "retry" $message
}

function idm_heartbeatsuccess
{
  param([string]$message)

  idm_statussuccess $message
  idm_writevalue "STATUS_TYPE" "heartbeat"
}

function idm_heartbeaterror
{
  param([string]$message)

  idm_statuserror $message
  idm_writevalue "STATUS_TYPE" "heartbeat"
}

function idm_heartbeatwarning
{
  param([string]$message)

  idm_statuswarning $message
  idm_writevalue "STATUS_TYPE" "heartbeat"
}

# Write a value or array of values for a query
# *** Not Used ***
# function idm_querywritevalues
# {
#  param([string]$name, $values)
#
#  foreach ($value in $values) {
#    "IDMQUERY: " + $name + "=" + $value | Out-File $queryfile -encoding Default -append
#  }
#}
#
# Write a single value for a query
# function idm_querywritevalue
# {
#  param([string]$name, [string]$value)
#
#  idm_querywritevalues $name $value
#}

# Initialize query variables
function idm_queryinit
{
  $global:queryassociation = ""
  $global:querysearchscope = ""
  $global:queryreadparent = $false
  $global:querysearchattrs = @{}
  $global:queryproperties = @{}  
}

function idm_querysetassociation 
{
  param([string]$association)

  $global:queryassociation = $association
}

# Use to set CLASS_NAME, DEST_DN or EVENT_ID
function idm_querysetproperty
{
  param([string]$name, [string]$value)

  $global:queryproperties[$name] = $value
}

# Add attribute and value(s) to search
# You may specify one value or multiple values in an array
function idm_queryaddsearchattr
{
  param([string]$name, $values)

  $global:querysearchattrs[$name] += [string[]] $values
}

# Add the name of an attribute for the query to read
function idm_queryaddreadattr
{
  param([string]$name)

  if ($global:queryreadattrs -eq $null) {
    $global:queryreadattrs = [string[]] $name
  }
  else {
    $global:queryreadattrs += $name
  }
}

# Not implemented in driver
#function idm_querysetreadparent
#{
# param([boolean]$readparent)
#
#  $global:queryreadparent = $readparent
#}

# Read query responses, as well as responses from 
# get-named-password requests
function idm_queryreadresponse
{
  # init attribute array
  $attrs = @{}

  $lines = &$EVENTREADER $queryrspfile "nvpairs"
  # Error checking
  if ($LASTEXITCODE -ne 0) {
    idm_trace "EventReader failed to process $queryrspfile with error code $LASTEXITCODE"
	exit $LASTEXITCODE
  }
  elseif ($lines -eq $null) {
    idm_trace "EventReader returned no data reading $queryrspfile"
	return
  }

  $status = $false
  foreach ($line in $lines) {
    $tokens = $line.split("=")
	$name = $tokens[0]
	$value = $tokens[1]
    
    if ($name -eq "COMMAND" -and ($value -eq "INSTANCE" -or $value -eq "PASSWORD")) {	  
	  # initialize query instance
      $global:queryinstance = @{}
	  $status = $true
	}
	elseif ($name.substring(0, 5) -eq "ATTR_" -or $name -eq "PASSWORD") {
	  # set attributes read from query
	  if ($name -eq "PASSWORD") {
	    $attrname = $name
	  }
	  else {
	    $attrname = $name.substring(5)
	  }
	  $attrs[$attrname] += [string[]] $value
    }
	else {
      # set query instance properties
	  $queryinstance[$name] = $value
    }
  }

  if ($status) {
	$queryinstance[$QI_ATTRS] = $attrs
  }

  return $status
}

function idm_getqueryinstanceassociation
{
  return $queryinstance[$QI_ASSOCIATION]
}

function idm_getqueryinstancedn
{
  return $queryinstance[$QI_DN]
}

function idm_getqueryinstanceclass
{
  return $queryinstance[$QI_CLASS_NAME]
}

# Not implemented in driver
#function idm_getqueryinstanceparentassociation
#{
#  return $queryinstance[$QI_PARENT_ASSOCIATION]
#}

# Not implemented in driver
#function idm_getqueryinstanceparentdn
#{
#  return $queryinstance[$QI_PARENT_DN]
#}

function idm_getqueryinstanceattrs
{
  return $queryinstance[$QI_ATTRS]
}

function idm_getqueryinstanceattrvalues
{
  param([string]$name)

  $attrs = $queryinstance[$QI_ATTRS]
  if ($attrs -ne $null) {
    return $attrs[$name]
  }

  return $null
}

function idm_getqueryinstanceattrvalue
{
  param([string]$name)

  $attrs = $queryinstance[$QI_ATTRS]
  if ($attrs -ne $null) {
    $values = $attrs[$name]
    if ($values -ne $null) {
	  return $values[0]
	}
  }

  return $null
}

# query the identity vault
function idm_doquery
{
  # initialize array of lines to output
  $lines = [string[]] "IDMQUERY: BEGIN"

  $lines += "IDMQUERY: COMMAND=query"
  $lines += "IDMQUERY: SCOPE=entry"
  if ($querysearchassociation -ne "") {
	$lines += "IDMQUERY: ASSOCIATION=$queryassociation"
  }
  foreach ($property in $queryproperties.keys) {
    $lines += "IDMQUERY: $property=" + $queryproperties[$property]
  }
  foreach ($searchattr in $querysearchattrs.keys) {
	foreach ($attr in $querysearchattrs[$searchattr]) {
	  $lines += "IDMQUERY: SEARCH_ATTR_$searchattr=$attr"
	}
  }
  if ($queryreadattrs.length -gt 0) {
	foreach ($attr in $queryreadattrs) {
	  $lines += "IDMQUERY: READ_ATTRS=$attr"
	}
  }
  if ($queryreadparent) {
	$lines += "IDMQUERY: READ_PARENT=TRUE"
  }

  $lines += "IDMQUERY: END" 
  # output the query file (this overwrites any existing file)
  $lines | Out-File $queryfile -encoding Default

  # wait for response file from driver
  $st = idm_getdriverparam "script-timeout"
  $timeout = [int] $st
  if ($timeout -eq 0) { $timeout = 120 }
  $responsefileexists = $false
  while (-not $responsefileexists -and $timeout -gt 0) {
    $responsefileexists = Test-Path $queryrspfile
	if (-not $responsefileexists) { sleep 1 }
	$timeout--
  }
  
  $result = $false
  if ($responsefileexists) {
    $result = idm_queryreadresponse
	del $queryrspfile
  }

  return $result
}

# Allows user to request a named password
function idm_getnamedpassword
{
  param([string]$name)
  
  # Issue the request as a query
  "IDMGETNAMEDPWD: " + $name | Out-File $queryfile -encoding Default

  $timeout = 120
  $responsefileexists = $false
  while (-not $responsefileexists -and $timeout -gt 0) {
    $responsefileexists = Test-Path $queryrspfile
    if (-not $responsefileexists) { sleep 1 }
    $timeout--
  }

  if ($responsefileexists) {
    if (idm_queryreadresponse) {
	  $password = idm_getqueryinstanceattrvalue "PASSWORD"
	}
	del $queryrspfile
  }
  
  return $password
}

function idm_subgetnamedpassword
{
  param([string]$name)
  
  return idm_getnamedpassword $name
}

function idm_pubgetnamedpassword
{
  param([string]$name)
  
  return idm_getnamedpassword $name
}

# Specify a name/value pair to be published
# You may specify a single value or multiple values in an array
function idm_publishvalues
{
  param([string]$name, $values)

  $publishvalues[$name] += [string[]] $values
}

function idm_publishvalue
{
  param([string]$name, [string]$value)

  idm_publishvalues $name $value
}

function idm_publishinit
{
  param([string]$command)

  # reset publish values array
  $global:publishvalues = @{}

  idm_publishvalue "COMMAND" $command
  $global:publishflag = $true
}

function idm_publish
{
  # table of idmevent.exe options corresponding to event properties
  $OPTIONTABLE = @{"COMMAND" = "-t"; `
                   "CLASS_NAME" = "-c"; `
				   "EVENT_ID" = "-e"; `
				   "ASSOCIATION" = "-a"; `
				   "SRC_DN" = "-s"; `
				   "OLD_SRC_DN" = "-o"; `
				   "PASSWORD" = "-p"; `
				   "OLD_PASSWORD" = "-w"; `
				   "NEW_NAME" = "-n"; `
				   "REMOVE_OLD_NAME" = "-r"; `
				   "OLD_ASSOCIATION" = "-y"; `
				   "NEW_ASSOCIATION" = "-z"; `
				   "ENCRYPTION" = "-x"; `
				   "LEVEL" = "-l"; `
				   "MESSAGE" = "-m"; `
				   "HOLD" = "-1"; `
				   "RELEASE" = "-2"}  

  if (-not $publishflag) {
    idm_trace "idm_publishinit must be called before idm_publish"
    return $false
  }

  $status = $false
  $command = $installpath + $IDMEVENT
  
  foreach ($name in $publishvalues.keys) {
    if ($OPTIONTABLE[$name] -ne $null) {
	  $options += [string[]] $OPTIONTABLE[$name]
	  if ($name -ne "HOLD" -and $name -ne "RELEASE") {
	    $options += $publishvalues[$name][0]
	  }
	}
	else {
      foreach ($value in $publishvalues[$name]) {	    
	    $outputlines += [string[]] ($name + "=" + $value)
	  }
	}
  }

  # execute the change log tool (idmevent.exe)
  # (submit data via stdin)
  $outputlines | &$command $options

  return $LASTEXITCODE -eq 0
}

function idm_trace
{
  param([string]$message)

  if ($scripttracing) {
    $time = Get-Date

    if ($tracefile -eq $null -or $tracefile -eq "") {
      $tracefile = "logs\script-trace.log"
    }
    # create FileStream that shares script log
    $fs = [System.IO.File]::Open($tracefile, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Write)
    $sw = New-Object System.IO.StreamWriter $fs
    $sw.WriteLine($time.toString() + " " + $message)
    $sw.Close()
  }
}

# idm_execute and idm_executeio are not implemented because of
# the simplicity of executing commands within PowerShell


