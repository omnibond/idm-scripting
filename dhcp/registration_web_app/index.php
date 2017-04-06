<?php
 include_once("LDAPUtils.php");
 include_once("lang.php");
 
/*
 * Created on Nov 30, 2006
 *
 * To change the template for this generated file go to
 * Window - Preferences - PHPeclipse - PHP - Code Templates
 */
 
 //check for submitted POST var
 //phpinfo();
 if ($_POST['submit'] != "Accept") {
 
 //if the var doesn't exist
  
    //prefill form template variables with blanks.
    
    $tmplt['devDescription'] = "";
    $tmplt['usrMessage'] = "";
    
    //setup connection.
    $ldh = new LDAPUtils();
    
	//get the IP address of thier machine from the request vars.
    if ($_SERVER["REMOTE_ADDR"] != "") {
     $browserIPAddr = $_SERVER["REMOTE_ADDR"];
    } else {
   	  $browserIPAddr = $_SERVER["REMOTE_ADDR"];
    }	
    
    //check to see if this machine is infected.
    if ($ldh->isInfected($browserIPAddr)) {
    	
    	$tmplt['usrMessage'] = INFECTED;
    	$tmplt['infected'] = true;
    	
      //if not infected check for cookie from previous reg on this machine. 	
    } elseif ($_COOKIE['jnsureg'] != "") { 
    	
	  //lookup reg data from link key in cookie
      $devRecord = $ldh->getDeviceRecordByLinkKey($_COOKIE['jnsureg']);
      
      if ($devRecord != null) {
      	  $tmplt['devDescription'] = $devRecord['description'];
      	  $tmplt['usrMessage'] = MULTINIC;
      }
    } 	
    
    //show them the form for registration
    if ($_GET['noframes']) {
      include('formtemplatenf.php');
    }else {
      include('formtemplate.php');	
    }
    //exit();
 
 } else  { // (The submitted POST var does exist)
 
   //validate that the filled out the form correctly.
   //if not set the usrMessage, reshow the userform, and exit.
   

   //get the IP address of thier machine from the request vars.
   if ($_SERVER["REMOTE_ADDR"] != "") {
     $browserIPAddr = $_SERVER["REMOTE_ADDR"];
   } else {
   	  $browserIPAddr = $_SERVER["REMOTE_ADDR"];
   }
   
   
   //lookup thier DN from ldap.  
   
   $ldh = new LDAPUtils();
 
   $deviceDN = $ldh->getDeviceDN($browserIPAddr);
 
   //register them (including link key in DirXMLjnsuDevice)
   
   $storedLinkKey = $ldh->registerDevice($deviceDN, getAuthUser(), $_POST['description'], $_COOKIE['jnsureg']);
 
   //check for a problem... if so tell em and get out
   if (($storedLinkKey == null)|| ($ldh->Error())) {
      print "An error occurred<br>" . $ldh->ErrorDescription();
      exit();
   }
     	
   //store cookie with link var value
   
   setcookie('jnsureg', $storedLinkKey, time()+60*60*24*365*3);
   
   
   //show them "thanks response" 
     include('thankyou.php');

 }
    
    
function getAuthUser() {
  return strtolower($_SERVER['REMOTE_USER']);
}    
?>
