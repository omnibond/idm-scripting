package IDMLib;

use strict;
use Data::Dumper;

sub new {
    my ($class) = shift;

    my $self = {
    };
    bless $self, $class;
    return $self;
}

########################################################################
#
# status() is called by the status_ methods to report a status
#   in the form of name/value pairs.
#
#   $1 is the level (success, error, retry, fatal, warning)
#   $2 is the optional message
#
########################################################################
sub status
{
  my $self = shift;
  my $level = shift;
  my $status_message = shift;

  $self->idmsetvar("COMMAND", "status");
  $self->idmsetvar("STATUS_LEVEL", $level);

  if (!$status_message eq '') {
    $self->idmsetvar("STATUS_MESSAGE", $status_message);
  }
}

########################################################################
#
# status_success() reports a successful status document to the engine.
#   The engine will see the following XDS document:
#
#     <status level="success">optional message</status>
#
########################################################################
sub status_success
{
  my $self = shift;
  my $message = shift;
  $self->status("success", $message);
}

########################################################################
#
# status_error() reports an error status document to the engine.
#   The engine will see the following XDS document:
#
#     <status level="error">optional message</status>
#
########################################################################
sub status_error
{
  my $self = shift;
  my $message = shift;
  $self->status("error", $message);
}

########################################################################
#
# status_fatal() reports a fatal status document to the engine, instr-
#   ucting the engine to stop the driver.  The engine will see the
#   following XDS document:
#
#     <status level="fatal">optional message</status>
#
########################################################################
sub status_fatal
{
  my $self = shift;
  my $message = shift;
  $self->status("fatal", $message);
}

########################################################################
#
# status_warning() reports an error status document to the engine.
#   The engine will see the following XDS document:
#
#     <status level="warning">optional message</status>
#
########################################################################
sub status_warning
{
  my $self = shift;
  my $message = shift;
  $self->status("warning", $message);
}

########################################################################
#
# status_retry() reports a fatal status document to the engine, instr-
#   ucting the engine to retry this event later.  The engine will see the
#   following XDS document:
#
#     <status level="retry">optional message</status>
#
########################################################################
sub status_retry
{
  my $self = shift;
  my $message = shift;
  $self->status("retry", $message);
}

########################################################################
#
# heartbeat_success() reports a success status document to the engine,
#   triggered by a heartbeat interval timer.  The engine will see the
#   following XDS document:
#
#     <status level="success" type="heartbeat">optional message</status>
#
########################################################################
sub heartbeat_success
{
  my $self = shift;
  my $message = shift;
  $self->status_success($message);
  $self->idmsetvar("STATUS_TYPE", "heartbeat");
}

sub heartbeat_error
{
  my $self = shift;
  my $message = shift;
  $self->status_error($message);
  $self->idmsetvar("STATUS_TYPE", "heartbeat");
}

sub heartbeat_warning
{
  my $self = shift;
  my $message = shift;
  $self->status_warning($message);
  $self->idmsetvar("STATUS_TYPE", "heartbeat");
}


########################################################################
#
# idmgetvar() is called by all scripts to retrieve variables from
#    shared memory.
#
########################################################################
sub idmgetvar
{
  my $self = shift;
  my $var_name = shift;
  my $smtool = $ENV{'INSTALL_PATH'}."bin/ussmh -event";

  # call the shared memory tool to retrieve value
  my $var=`$smtool $var_name`;

  if ( $var eq '' ) {
     $var=`$smtool ADD_$var_name`;
  }

  return $var;
}

sub idmgetdrvvar {
  my $self = shift;
  my $varname = shift;

  my $smtool = $ENV{'INSTALL_PATH'}."bin/ussmh -driver";
  return `$smtool $varname`;

}

sub idmgetpubvar {
  my $self = shift;
  my $varname = shift;

  my $smtool = $ENV{'INSTALL_PATH'}."bin/ussmh -publisher";
  return `$smtool $varname`;

}

sub idmgetsubvar {
  my $self = shift;
  my $varname = shift;

  my $smtool = $ENV{'INSTALL_PATH'}."bin/ussmh -subscriber";
  return `$smtool $varname`;

}

########################################################################
#
# idmgetqvar() is called by all scripts to retrieve variables from
#    shared memory during a query operation.
#
########################################################################
sub idmgetqvar
{
  my $self = shift;
  my $var_name = shift;
  my $smtool = $ENV{'INSTALL_PATH'}."bin/ussmh -query";

  # call the shared memory tool to retrieve value
  my $var=`$smtool $var_name`;

  if ( $var eq '' ) {
    $var=`$smtool ADD_$var_name`;
  }

  return $var;
}

########################################################################
#
# idmsetvar() is called by all scripts to send variables back to the
#    driver shim for engine processing.
#
########################################################################
sub idmsetvar
{
  my $self = shift;
  my $retvar_var=shift;
  my $retvar_val=shift;
  my $smtool = $ENV{'INSTALL_PATH'}."bin/ussmh -write";

  open(USSMH, "| $smtool");
  print USSMH "IDMSETVAR: ".$retvar_var."=".$retvar_val."\n";
  close(USSMH);
}

########################################################################
#
# idmquery() is called by all scripts to perform a query into the
#    Identity Vault.
#   $1 is the class-name
#   $2 is the associaton to query
#   $3 are the attributes to read
#
########################################################################
sub idmquery
{
  my $self = shift;
  my $idmquery_class = shift;
  my $idmquery_assoc = shift;
  my $idmquery_read_attrs = shift;
  my $smtool = $ENV{'INSTALL_PATH'}."bin/ussmh -write";

  open(USSMH, "| $smtool");
  print USSMH "IDMQUERY: BEGIN\n";
  print USSMH "IDMQUERY: COMMAND=query\n";
  print USSMH "IDMQUERY: SCOPE=entry\n";
  print USSMH "IDMQUERY: CLASS_NAME=$idmquery_class\n";
  print USSMH "IDMQUERY: ASSOCIATION=$idmquery_assoc\n";

  # specifying no read-attrs returns everything
  if ( $idmquery_read_attrs ne '' ) {
     print USSMH "IDMQUERY: READ_ATTRS=$idmquery_read_attrs\n";
  }

  print USSMH "IDMQUERY: END\n";
  close(USSMH);

  # wait for query to complete
  $ENV{'INSTALL_PATH'}."bin/ussmh -wait-for-query"
}

########################################################################
#
# idmgetnamedpassword() is called by all scripts to retrieve a named
#    password from the Identity Vault.
#   $1 is the class-name
#   $2 is the associaton to query
#   $3 are the attributes to read
#
########################################################################
sub idmsubgetnamedpassword
{
  my $self = shift;
  my $pwname= shift;

  my $smtool = $ENV{'INSTALL_PATH'}."bin/ussmh";
  my $value = `$smtool -sub-get-named-password $pwname`;

  return $value;
}

sub idmpubgetnamedpassword
{
  my $self = shift;
  my $pwname= shift;

  my $smtool = $ENV{'INSTALL_PATH'}."bin/ussmh";
  my $value = `$smtool -pub-get-named-password $pwname`;

  return $value;
}

########################################################################
#
# logger() is called by all scripts to send a message to the system log.
#
########################################################################
sub logger
{
  my $self = shift;
  my $priority = shift;
  my $scriptname = shift;
  my $message = shift;
  if ( -f "/bin/logger" )
  {
    `/bin/logger -p $priority -t $scriptname '$message'`;
  } else {
    if ( -f "/usr/bin/logger" )
    {
      `/usr/bin/logger -p $priority -t $scriptname $message`;
    }
  }
}

########################################################################
#
# mktemp() creates a random, temporary file in the filesystem.
#
########################################################################
sub mktemp
{
  my $self = shift;
  my $option = shift;
  my $directory = shift;
  my $DIRECTORY = "";

  if ( $option eq "-p" ) {
     $DIRECTORY=$directory;
  }

  if ( $DIRECTORY eq '' ) {
     $DIRECTORY="/tmp";
  }

  my $rndnum = int( rand(20000) );
  my $RANDFILE = $DIRECTORY."/tmp.".$rndnum;

  `touch $RANDFILE; chmod 600 $RANDFILE`;
  return $RANDFILE;
}

########################################################################
#
# trace() sends a message to the driver shim trace file
#
########################################################################
sub trace
{
  my $self = shift;
  my $message = shift;
  my $smtool = $ENV{'INSTALL_PATH'}."bin/ussmh -write";

  open(USSMH, "| $smtool");
  print USSMH "TRACE: \"$message\"\n";
  close(USSMH);

}

########################################################################
#
# exec will execute a command.  In addition, it will:
#    1. Check the return code
#    2. Log the command in the system log with return code and output
#    3. Trace the command in the shim trace with return code and output
#    4. Return a status document to the driver shim for engine proc-
#       essing.
#
########################################################################
sub exec
{
   my $self = shift;
   my $command = shift;
   my $staInData = shift;

   my $response = `$command <<EOF
   $staInData
   EOF
   `;

   my $rc = $? >> 8;
   if ( $rc ==  0 )
   {
      $self->logger($ENV{'CMDOKPRIO'}, "idmlib.pl", "\"$command\"".":RC=".$rc.":".$response.":");
      $self->status_success();
   } else {
      $self->logger($ENV{'CMDFAILPRIO'}, "idmlib.pl", $command.":RC=".$rc.":".$response.":");
      $self->status_error("Command Error: \"$command\" failed with RC=$rc, response: $response");
   }

   $self->trace("COMMAND=$command:RC=$rc:RESPONSE=$response:");

   return $response;
}

########################################################################
#
# exec_without_status will execute a command.  In addition, it will:
#    1. Check the return code
#    2. Log the command in the system log with return code and output
#    3. Trace the command in the shim trace with return code and output
#
#    Note:  This method does not send a status document to the engine
#
########################################################################
sub exec_without_status
{
  my $self = shift;
   my $command= shift;

   my $response=`$command`;

   my $rc = $? >> 8;
   if ( $rc ==  0 )
   {
      $self->logger($ENV{'CMDOKPRIO'}, "idmlib.pl", $command.":RC=".$rc.":".$response.":");
   } else {
      $self->logger($ENV{'CMDFAILPRIO'}, "idmlib.pl", $command.":RC=".$rc.":".$response.":");
   }

   $self->trace("COMMAND=$command:RC=$rc:RESPONSE=$response:");

   return $rc;
}

return 1;

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

IDMLib - Perl extension for Bi-Directional Driver helper methods

=head1 SYNOPSIS

  use IDMLib;
  $i = new IDMLib();

=head1 DESCRIPTION

This module provides helper methods for the bi-directional IDM Scripting Driver for Linux and Unix.

=head2 EXPORT

None by default.


=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Omnibond Systems

=head1 COPYRIGHT AND LICENSE

=cut
