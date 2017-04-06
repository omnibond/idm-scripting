<?php

include('standard_nav_cases.php');

// handle nav custom to this page
if (isset($_POST['nextpage'])) {
   switch($_POST['nextpage']) {
   
   	case "Something":
   	$this->gotoNextPage("something.php");
   	break;
   	
   }
}
   
$this->htmlStart();
$this->includeHead();
$this->includeBodyStart();
$this->includeCommonHeader();


$this->navFormStart();

?>
<table border="0" cellpadding="3" cellspacing="0">
  <tr>
     <td>
       Welcome to the Network Registration system.<p>
       This system allows you to manage your computer registrations; you can add or delete registrations for computers that you have registered.
     </td>
  </tr>
</table>

<?
include('footer.php');
$this->navFormEnd();
$this->includeDebugInfo(__FILE__);
$this->includeBodyEnd();	
$this->htmlEnd();

 ?>
