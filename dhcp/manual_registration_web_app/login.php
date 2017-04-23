<?php

switch($_POST['nextpage']) {
  
        case "Login":
           $message = '';
           if (!$this->authenticate($_POST['user'], $_POST['pass'], $message)) {
              $this->userMessage($message);
           } else {
              $this->setSessionVar("AUTHUSER", $_POST['user']);
	      $this->gotoNextPage("welcome.php", FALSE);
           }
        break;
	
	case "Something":
	$this->gotoNextPage("something.php");
	break;
	
}


$this->htmlStart();
$this->includeHead();
$this->includeBodyStart();
$this->nocrumbs = true;
$this->includeCommonHeader();


$this->navFormStart();

print $this->userMessage();
?>
Please enter your USERID and PASSWORD:<p>
<table border="0" cellpadding="3" cellspacing="0">
<tr><td align="center">
<pre>
     Userid: <input type=text name="user"><br>
   Password: <input type=password name="pass">
</pre>
</td></tr><tr><td align="center">
<?
print $this->formNavButton('Login','navform','medium');

print "</td></tr></table>";
$this->navFormEnd();
include('footer.php');
$this->includeBodyEnd();	
$this->htmlEnd();

 ?>
