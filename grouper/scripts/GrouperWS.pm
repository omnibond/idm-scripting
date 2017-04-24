package GrouperWS;

use warnings;
use strict;
use WWW::Curl::Easy;
use LWP::UserAgent;
use HTTP::Status qw(status_message);
use Crypt::CBC;
use Crypt::Rijndael;
use JSON;
use Data::Dumper;

# GrouperWS::new(%options) - constructor
sub new {
  my ($class) = shift;
  my $self = {};

  for (my $i = 0; $i < (@_-1); $i += 2) {
      my $field = $_[$i];
      my $value = $_[$i+1];
      $self->{$field} = $value;
  }

  # get access to methods
  bless $self, $class;

  # check for urlPrefix, username, and password
  foreach (("urlPrefix", "username", "password")) {
      if (!$self->{$_}) {
          $self->trace("Constructor is missing $_");
          return undef;
      }
  }

  return $self;
}

# GrouperWS::trace($msg) - write message if tracing
sub trace {
  my ($self, $msg) = @_;

  if ($self->{debugStdout}) {
    print $msg;
  }
  if ($self->{debugStderr}) {
    print STDERR $msg;
  }
  if ($self->{idmlib}) {
    $self->{idmlib}->trace($msg);
  }
}


# GrouperWS::debug_json($jsonObj, $jsonData) - debug JSON content to debug facility
sub debug_json {
  my ($self, $header, $prefix, $jsonObj, $jsonData) = @_;

  return if !$self->{debugJSON} || !$jsonObj || !$jsonData;

  # encode "pretty" JSON
  my $jsonText = $jsonObj->pretty->encode($jsonData);

  # header
  $self->trace("$header\n");
  # debug line-by-line
  foreach my $line (split(/\n/, $jsonText)) {
    $self->trace("$prefix: $line\n");
  }

}

# GrouperWS::send_request($method, $requrl, $post)
# Build the REST URL and submit to the server.
# Returns HTTP error code and an *array ref* of JSON data (even if only 1 JSON object returned) or undef
sub send_request {
  my ($self, $method, $requrl, $post) = @_;
  my $ua = LWP::UserAgent->new( timeout => (($self->{requestTimeout} && $self->{requestTimeout} > 2) ? $self->{requestTimeout} : 60));
  my $jsonObj = JSON->new->utf8->allow_nonref;

  $self->{resultMessage} = "";
  $self->{resultCode} = "";
  $self->{success} = "";
  $self->trace("send_request: begin  method: $method  requrl: $requrl\n");

  $ua->default_headers->authorization_basic($self->{username}, $self->{password});  

  # Build URL
  my $url;
  $url = $self->{urlPrefix} . "/$requrl";

  $self->trace("URL: $url\n");
# Build HTTP request
  $self->trace("send_request: Method: $method URL: $url\n");
  my $req = HTTP::Request->new($method, $url);
  # Encode to JSON if applicable
  if ($post) {
    $req->content_type('text/x-json');
    my $json;
    eval { $json = $jsonObj->encode($post); };
    # exception
    if (!$json) {
      $self->trace("send_request: JSON encode error: " . $@);
      return(500, undef);
    }

    $self->debug_json("send_request: JSON POST content:", "send_request", $jsonObj, $post);

    $req->content($json);
  }

  my $response = $ua->request($req);
  my $content = $response->content;

  # decode JSON response
  my $jsonData;
  eval { $jsonData = $jsonObj->decode($content); };
  if (!$jsonData) {
    $self->trace("send_request: JSON decode error: " . $@);
    $self->trace("send_requst: Content: " . $response->content . "\n");
    $self->{resultMessage} = $response->$content;
    $self->{resultCode} = $response->code;
    $self->{success} = "F";
    return($response->code, "");
  }
  $self->debug_json("send_request: JSON response content:", "send_request", $jsonObj, $jsonData);

  # make a list if necessary
  my @jsonList;
  if (ref($jsonData) eq "HASH") {
    push(@jsonList, $jsonData);
  }
  else {
    push(@jsonList, @$jsonData);
  }

  my $resultMetadata;
  my $key;

  eval { $key = (keys(%{$jsonList[0]})) [0]; };
  eval { $resultMetadata = $jsonList[0]->{$key}->{resultMetadata}; };
  if(defined($resultMetadata)){
    $self->{resultMessage} = $resultMetadata->{resultMessage};
    $self->{resultCode} = $resultMetadata->{resultCode};
    $self->{success} = $resultMetadata->{success};
  }

  $self->trace("send_request: end (" . $response->code . ")\n");

  return($response->code, \@jsonList);
}

# GrouperWS::findStems($name, $filterType) - get a list of matching stems. 
# filterType may be: FIND_BY_STEM_NAME, FIND_BY_STEM_NAME_APPROXIMATE, FIND_BY_PARENT_STEM_NAME 
# return output
sub findStems {
  my ($self, $name , $filterType) = @_;

  $self->trace("findStems: begin\n");

  $self->trace("findStems: search for stems named $name with filterType = $filterType\n");

  my %req = (
             "WsRestFindStemsLiteRequest" => {
                                              "actAsSubjectId" => $self->{username},
                                              "stemName" => "$name",
                                              "stemQueryFilterType" => $filterType
                                             }
            );

  # Server request
  my ($code, $output) = $self->send_request("POST", "stems", \%req);

  my $stems = "";
  if($code == 200){
    eval { $stems = $output->[0]->{WsFindStemsResults}->{stemResults}; };
  }

  $self->trace("findStems: end\n");

  return($code, $stems);
}

# GrouperWS::stemSave($name, $desc) - create or update a stem
# The name of the stem must be a full path separated by colons
# return output
sub stemSave {
  my ($self, $name, $desc) = @_;

  $self->trace("stemSave: begin\n");

  $self->trace("stemSave: create or update stem named $name with desc: $desc\n");

  my %req = (
             "WsRestStemSaveLiteRequest" => {
                                              "actAsSubjectId" => $self->{username},
                                              "stemName" => "$name",
                                              "description" => "$desc" 
                                             }
            );

  my $urlname = $name;
  $urlname =~ s/:/\%3A/g;
  # Server request
  my ($code, $output) = $self->send_request("POST", "stems/$urlname", \%req);

  my $stem = "";
  if(($code == 200) || ($code == 201)){
    eval { $stem = $output->[0]->{WsStemSaveLiteResult}->{wsStem}; };
  }
  $self->trace("stemSave: end\n");
  return($code, $stem);
}


# GrouperWS::stemDelete($nam) - delete a stem
# The name of the stem must be a full path separated by colons
# return output
sub stemDelete {
  my ($self, $name , $desc) = @_;

  $self->trace("stemDelete: begin\n");

  $self->trace("stemDelete: delete stem named $name\n");

  my %req = (
             "WsRestStemDeleteLiteRequest" => {
                                              "actAsSubjectId" => $self->{username},
                                              "stemName" => "$name",
                                             }
            );

  my $urlname = $name;
  $urlname =~ s/:/\%3A/g;
  # Server request
  my ($code, $output) = $self->send_request("DELETE", "stems/$urlname", \%req);

  my $stem = "";
  if($code == 200){
    eval { $stem = $output->[0]->{WsStemDeleteLiteResult}->{wsStem}; };
  }

  $self->trace("stemDelete: end\n");

  return($code, $stem);
}

# GrouperWS::findGroups($name, $filterType) - get a list of matching groups. 
# filterType may be: FIND_BY_GROUP_NAME_EXACT, FIND_BY_GROUP_NAME_APPROXIMATE, FIND_BY_GROUP_UUID 
# return output
sub findGroups {
  my ($self, $name , $filterType) = @_;

  $self->trace("findGroups: begin\n");

  $self->trace("findGroups: search for groups named $name with filterType = $filterType\n");

  my %req = (
             "WsRestFindGroupsLiteRequest" => {
                                              "actAsSubjectId" => $self->{username},
                                              "groupName" => "$name",
                                              "queryFilterType" => $filterType
                                             }
            );

  # Server request
  my ($code, $output) = $self->send_request("POST", "groups", \%req);

  my $groups = "";
  if($code == 200){
    eval { $groups = $output->[0]->{WsFindGroupsResults}->{groupResults}; };
  }

  $self->trace("findGroups: end\n");

  return($code, $groups);
}

# GrouperWS::groupSave($stem, $name, $desc) - create or update a group in the supplied stem
# return output
sub groupSave {
  my ($self, $stem, $name, $desc) = @_;

  $self->trace("groupSave: begin\n");

  $self->trace("groupSave: Creating or updating group named $name in stem $stem desc: $desc\n");

  my $groupname = "$stem:$name";
  my %req = (
             "WsRestGroupSaveLiteRequest" => {
                                              "actAsSubjectId" => $self->{username},
                                              "groupName" => "$stem:$name",
                                              "description" => "$desc"
                                             }
            );

  my $urlname = $groupname;
  $urlname =~ s/:/\%3A/g;
  # Server request
  my ($code, $output) = $self->send_request("POST", "groups/$urlname", \%req);

  my $group = "";
  if(($code == 200) || ($code == 201)){
    eval { $group = $output->[0]->{WsGroupSaveLiteResult}->{wsGroup}; };
  }

  $self->trace("groupSave: end\n");

  return($code, $group);
}

# GrouperWS::groupDelete($name) - delete a group 
# return output
sub groupDelete {
  my ($self, $stem, $name) = @_;

  $self->trace("groupDelete: begin\n");

  $self->trace("groupDelete: Delete group named $name in stem $stem\n");

  my $groupname = "$stem:$name";
  my %req = (
             "WsRestGroupDeleteLiteRequest" => {
                                              "actAsSubjectId" => $self->{username},
                                              "groupName" => "$stem:$name",
                                             }
            );

  my $urlname = $groupname;
  $urlname =~ s/:/\%3A/g;
  # Server request
  my ($code, $output) = $self->send_request("DELETE", "groups/$urlname", \%req);

  my $group = "";
  if($code == 200){
    eval { $group = $output->[0]->{WsGroupDeleteLiteResult}->{wsGroup}; };
  }

  $self->trace("groupDelete: end\n");

  return($code, $group);
}

# GrouperWS::getMembers($name) - returns all members of the supplied group
# return output
sub getMembers {
  my ($self, $name) = @_;

  $self->trace("getMembers: begin\n");

  $self->trace("getMembers: Getting members from group $name\n");

  my %req = (
             "WsRestGetMembersLiteRequest" => {
                                              "actAsSubjectId" => $self->{username},
                                             }
            );

  my $urlname = $name;
  $urlname =~ s/:/\%3A/g;
  # Server request
  my ($code, $output) = $self->send_request("POST", "groups/$urlname/members", \%req);

  my $members = "";
  if($code == 200){
    eval { $members = $output->[0]->{WsGetMembersLiteResult}->{wsSubjects}; };
  }

  $self->trace("getMembers: end\n");

  return($code, $members);
}

# GrouperWS::addMember($group, $user) - adds a user to a group
# return output
sub addMember {
  my ($self, $group, $user) = @_;

  $self->trace("addMember: begin\n");

  $self->trace("addMember: Addding user $user to group $group\n");

  my %req = (
             "WsRestAddMemberLiteRequest" => {
                                              "actAsSubjectId" => $self->{username},
                                              "groupName" => "$group",
                                              "subjectId" => "$user"
                                             }
            );

  my $urlname = $group;
  $urlname =~ s/:/\%3A/g;
  # Server request
  my ($code, $output) = $self->send_request("POST", "groups/$urlname/members", \%req);

  my $member = "";
  if(($code == 200) || ($code == 201)){
    eval { $member = $output->[0]->{WsAddMemberLiteResult}->{wsSubject}; };
  }

  $self->trace("addMember: end\n");

  return($code, $member);
}

# GrouperWS::deleteMember($group, $user) - delete a user from a group
# return output
sub deleteMember {
  my ($self, $group, $user) = @_;

  $self->trace("deleteMember: begin\n");

  $self->trace("deleteMember: Deleting user $user from group $group\n");

  my %req = (
             "WsRestDeleteMemberLiteRequest" => {
                                              "actAsSubjectId" => $self->{username},
                                              "groupName" => "$group",
                                              "subjectId" => "$user"
                                             }
            );

  my $urlname = $group;
  $urlname =~ s/:/\%3A/g;
  # Server request
  my ($code, $output) = $self->send_request("DELETE", "groups/$urlname/members", \%req);

  my $member = "";
  if($code == 200){
    eval { $member = $output->[0]->{WsDeleteMemberLiteResult}->{wsSubject}; };
  }

  $self->trace("deleteMember: end\n");

  return($code, $member);
}



# GrouperWS::calcFolderPath($SRC_DN, $basedn, $grouperbase) - build the folder path and name based on 
# base dn and base folder in grouper.  If provisionFLat is true, all groups will go in the base folder
# return colon delimited folder path and the name of the folder or gruop
sub calcFolderPath {
  my ($self, $SRC_DN, $basedn, $grouperbase, $provisionFlat) = @_;
  my $folderpath = "";
  my $name = "";

  $self->trace("calcFolderPath: begin\n");
  $self->trace("calcFolderPath: Source DN: $SRC_DN\n");
  if($provisionFlat eq "false"){
    # Strip tree off the front of the DNs
    my $SRC_DN_NO_TREE = "";
    if($SRC_DN =~ /^\\[^\\]+\\(.+)/){
      $SRC_DN_NO_TREE = $1;
    }
    else {
      $SRC_DN_NO_TREE = $SRC_DN;
    }
    if($basedn =~ /^\\[^\\]+\\(.+)/){
      $basedn = $1;
    }
    $self->trace("calcFolderPath: No Tree DN:   $SRC_DN_NO_TREE\n");
    $self->trace("calcFolderPath: No Tree Base: $basedn\n");
    if((index($SRC_DN_NO_TREE, $basedn) == 0) && ($SRC_DN_NO_TREE ne $basedn)){
      # strip the base dn out of the source dn and create a relative folder path
      $folderpath = substr($SRC_DN_NO_TREE, length($basedn) + 1);
    }
    else {
      $self->trace("calcFolderPath: Not in base dn!\n");
      $self->trace("calcFolderPath: end\n");
      return("","");
    }
    $self->trace("calcFolderPath: Relative DN:  $folderpath\n");
    # replace backslashes with colons
    $folderpath =~ s/\\/:/g;
    $self->trace("calcFolderPath: Relative Path:$folderpath\n");
    $folderpath = "$grouperbase:$folderpath";
    $self->trace("calcFolderPath: Grouper Path: $folderpath\n");
    # split off the name of the object from the folder
    $folderpath =~ /(.+):([^:]+)/;
    $folderpath = $1;
    $name = $2;
  }
  else {
    if($SRC_DN =~ /\\([^\\]+$)/){
      $name = $1;
      $folderpath = $grouperbase;
    }
    else {
      $self->trace("calcFolderPath: Not a valid dn!\n");
      $self->trace("calcFolderPath: end\n");
      return("","");
    }
  }
  $self->trace("calcFolderPath: end\n");
  return($folderpath, $name);
}

1;
