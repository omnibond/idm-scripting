<?php

include('standard_nav_cases.php');
include_once('LDAPUtils.php');

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

$ld = new LDAPUtils();

// handle form POST
if ($_POST['submitted']) {
   // clean up vars
   $_POST['MACADDR'] = strtoupper($_POST['MACADDR']);

   // error checking
   do {
      if (!strlen($_POST['MACADDR']) || !strlen($_POST['DESCRIPTION'])) {
         $this->userMessage("Please complete the form");
         break;
      }

      $d = "[0-9A-F]";
      if (!preg_match("/^$d{2}:$d{2}:$d{2}:$d{2}:$d{2}:$d{2}$/", $_POST['MACADDR'])) {
         $this->userMessage("Hardware Address is not in proper format.");
         break;
      }
     

      $reg = $ld->getDeviceRecordByHWAddress($_POST['MACADDR']);

      // delete network device object if it isn't registered
      if ($reg['regversion'] != 1) {
         $ld->deleteRegistration($_POST['MACADDR']);
         $reg = false;
      }

      // check for existing reg with same hw address
      if ($reg) {
         $this->userMessage("Hardware address you entered is already registered.<br>Please enter a different hardware address."); 
         break;
      }


      // add the registration since we passed error checking
      $rc = $ld->addAndRegisterDevice($_POST['MACADDR'] ,$this->authUser(), $_POST['DESCRIPTION']);

      if (!$rc) {
         print $ld->ErrorDescription()." ";
         $this->userMessage("Registration failed.  Please contact the help desk."); 
         break;
      }
      
      $this->userMessage("Registration added");                      
 

      break;
   } while (1);
}


$this->htmlStart();
$this->includeHead();
$this->includeBodyStart();
//$this->nocrumbs = true;
$this->includeCommonHeader();


$this->navFormStart();

print $this->userMessage();
?>
<span class="title">Register a device with the system</span><br>&nbsp;
<table border="0" cellpadding="3" cellspacing="0">
  <tr>
     <td colspan="2">
       Enter hardware address in format XX:XX:XX:XX:XX:XX<br>
       e.g., 00:01:E6:7B:CD:5A
     </td>
  </tr>
  <tr>
    <td nowrap><b>Hardware Address</b></td>
    <td width="100%">
       <input type="text" name="MACADDR" size="30" maxlength="17" value="<?=$_POST['MACADDR']?>">
    </td>
  </tr>
  <tr>
     <td colspan="2">
       &nbsp;
     </td>
  </tr>
  <tr>
     <td colspan="2">
      Enter a brief description that will help you
      identify this registration. <br>e.g., <i>Joe Doe  IBM Desktop Poole Rm10</i> or <i>Jane Doe  Dell Laptop Wireless</i>
      <br>(40 character limit)
     </td>
  </tr>
  <tr>
    <td>
       <b>Description</b>
    </td>
    <td>
      <input type="text" name="DESCRIPTION" size="40" maxlength="40" value="<?=stripslashes($_POST['DESCRIPTION'])?>">
    </td>
  </tr>
  <tr>
     <td colspan="2">
        <br>READ and accept the policy below to add your registration.<p>
    
        <p>Your policy here</p>

<input type="button" name="b2" value="I Accept" onclick="this.form.submit();">

     </td>
  </tr>

</table>
<input type="hidden" name="submitted" value="1">
<?
//print $this->formNavButton('Login','navform','medium');

$this->navFormEnd();
include('footer.php');
$this->includeBodyEnd();	
$this->htmlEnd();

 ?>
