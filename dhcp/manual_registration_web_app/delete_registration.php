<?php

include('standard_nav_cases.php');
include_once('LDAPUtils.php');

$ld = new LDAPUtils();

switch($_POST['nextpage']) {
  
        case "Login":
           $message = '';
           if (!$this->authenticate($_POST['user'], $_POST['pass'], $message)) {
              $this->userMessage($message);
           } else {
	      $this->gotoNextPage("add_registration.php");
           }
        break;
}

// if we get a delete request handle it before re-rendering page
if ($_POST['del_macaddr']) {
   do {
   
      if (!$ld->deleteRegistration($_POST['del_macaddr'])) {
         $this->userMessage("Error: could not delete registration.");
         break;
      }

      $this->userMessage("Registration for Mac Address ".$_POST['del_macaddr']." has been deleted.");

      break;
   }
   while (1);
}


$this->htmlStart();
$this->includeHead();
$this->includeBodyStart();
$this->includeCommonHeader();


$this->navFormStart();

print $this->userMessage();

$entries = $ld->getDevicesByUserid($this->authUser());

if (count($entries) < 1) {
    print "There are no machines registered to you in the system.";
} else {
   print "<span class=\"title\">My Registrations</span>";
   print "<table border=\"1\" cellpadding=\"3\" cellspacing=\"0\">";
   print "<tr>";
   print "<td>Delete?</td>";
   print "<td>Mac Address</td>";
   print "<td>When Added</td>";
   print "<td>Description</td>";
   print "</tr>";
   foreach ($entries as $entry) {
      print "<tr>";
      if ($entries['dirxmljnsudisabled'] == 1) {
         print "<td>disabled</td>";
      } else {
         print "<td><input type=\"button\" name=\"delete\" value=\"Delete\" onClick=\"if (confirm('Are you sure you want to delete registration for Mac address ".$entry['dirxmljnsuhwaddress']."?')) { this.form.del_macaddr.value='".$entry['dirxmljnsuhwaddress']."'; this.form.submit() }\"></td>";
      }
      print "<td>".$entry['dirxmljnsuhwaddress']."</td>";
      print "<td>".date("D M j G:i:s T Y", $entry['dirxmljnsuregaddtime'])."</td>";
      print "<td>".$entry['dirxmljnsudescription']."</td>";
      print "</tr>";
   }
   print "</table>";
   print "<input type=\"hidden\" name=\"del_macaddr\" value=\"\">";
}




//print $this->formNavButton('Login','navform','medium');

$this->navFormEnd();
include('footer.php');
$this->includeBodyEnd();	
$this->htmlEnd();

 ?>
