<?php


/*

Abstraction layer for LDAP calls
*/

class LDAPUtils {

	var $_hosts;
	var $_connectuser;
	var $_connectpass;
	var $_searchbase;
	var $ds;

	// "Public" methods

	function LDAPUtils($debug_toggle = '') {
			//Very Basic Constructor.  If anything is sent as a parameter
		//then debugging mode is enabled.
	if ($debug_toggle) {
			$this->_debug = true;
		}
		//Get init values
		include("ldapconfig.php");
	}

	function cleanUp() {
		$this->_disconnect();
	}

	function _disconnect() {

		ldap_unbind($this->ds);

	}

	function _connectAndBind() {

		//if ($this->ds) return true;

		$this->ds = ldap_connect($this->_hosts);
		if ($this->ds) {

			// binding to ldap server
			$ldapbind = ldap_bind($this->ds, $this->_connectuser, $this->_connectpass);

			// verify binding
			if ($ldapbind) {
				return true;
			} else {

				return false;
			}
		}

	}

    function registerDevice($deviceDN,$userid, $description, $devLinkKey="") {
        
        $tostore['DirXMLjnsuRegVersion'] = 1;
        $tostore['DirXMLjnsuDescription'] = $description;
        $tostore['DirXMLjnsuRegAddTime'] = time();
        $tostore['DirXMLjnsuUserDN'] = $this->_getUserDN($userid);
        
        if (($tostore['DirXMLjnsuUserDN'] == null) && ($this->error == true)) {
           //user wasn't found so let's error out
           return null;       	
        }
        //print "to store = ". $tostore['DirXMLjnsuUserDN'];
        
        if ($devLinkKey == "") {
           //create the link key from the md5 of the userid and description if none supplied
           $devLinkKey = md5($tostore['DirXMLjnsuUserDN'] . $description);
        }
        $tostore['DirXMLjnsuDevice'] = $devLinkKey;

        if (!$this->_connectAndBind()) {

            $this->error = true;
            $this->errmsg = "Directory connect and bind error";
            return null;
        }

        $rc = ldap_mod_replace($this->ds,$deviceDN,$tostore);
                 
                       
        if (!$rc) {       
           $this->error = true;
                   $this->errmsg = ldap_error($this->ds);
                   return null;       
        }      
        
        //if we get this far, return the devLinkLey to be stored in a cookie
        return $devLinkKey;     

    } //endfunction

	function getDeviceDN($ipaddr) {

		if (!$this->_connectAndBind()) {

			$this->error = true;
			$this->errmsg = "Directory connect and bind error";
			return null;
		}

		$sr = ldap_search($this->ds, $this->_searchbase, "(&(DirXMLjnsuDHCPAddress=".$ipaddr.")(objectclass=DirXMLjnsuNetworkDevice))");


		if ($entryID = ldap_first_entry($this->ds, $sr)) {
			return ldap_get_dn($this->ds, $entryID);
			
	    }

        //$this->_debugVar($sr);

		$this->error = true;
		$this->errmsg = "Ip Addr / Device not found.";
		return null;

	}
	
	function isInfected($ipaddr) {
		
	  	if (!$this->_connectAndBind()) {

			$this->error = true;
			$this->errmsg = "Directory connect and bind error";
			return null;
		}	
		
		$sr = ldap_search($this->ds, $this->_searchbase, "(&(DirXMLjnsuDHCPAddress=".$ipaddr.")(objectclass=DirXMLjnsuNetworkDevice)(|(DirXMLjnsuDisabled=true)(DirXMLjnsuInfected=true)))");

		if ($entryID = ldap_first_entry($this->ds, $sr)) {
			return true;
		}
	
	   return false;	
		
	}
	
	function getDeviceRecordByLinkKey($devLinkKey) {

		if (!$this->_connectAndBind()) {

			$this->error = true;
			$this->errmsg = "Directory connect and bind error";
			return null;
		}

		$sr = ldap_search($this->ds, $this->_searchbase, "(&(DirXMLjnsuDevice=".$devLinkKey.")(objectclass=DirXMLjnsuNetworkDevice))");


		if ($entryID = ldap_first_entry($this->ds, $sr)) {
			//return ldap_get_dn($this->ds, $entryID);
			$result = ldap_get_attributes($this->ds, $entryID);
			$toreturn['description'] =  $result['DirXMLjnsuDescription'][0];
			$toreturn['userid'] =  $result['DirXMLjnsuUserDN'][0];
			$toreturn['timestamp'] =  $result['DirXMLjnsuRegAddTime'][0];
			return $toreturn;
			
	    }

        $this->_debugVar($sr);

		$this->error = true;
		$this->errmsg = "Previous Registration Not Found";
		return null;

	}
	
      function _debugVar($var) {
         ob_start();
         print_r($var);
         $ret_str = ob_get_contents();
         ob_end_clean();   
         return "<PRE>".$ret_str."</PRE>";
      }

	function _getUserDN($userid) {

		if (!$this->_connectAndBind()) {

			$this->error = true;
			$this->errmsg = "Directory connect and bind error";
			return null;
		}

		for ($index = 0; $index < sizeof($this->_userdnsearchbases); $index ++) {
			$searchbase = $this->_userdnsearchbases[$index];

			$sr = ldap_search($this->ds, $searchbase, "(&(cn=".$userid.")(objectClass=Person))");

			if ($entryID = ldap_first_entry($this->ds, $sr)) {
				return ldap_get_dn($this->ds, $entryID);
			}
		}

		$this->error = true;
		$this->errmsg = "User does not exist in Junetsu tree.";
		return null;

	}



	function _stripFDN($FDN) {

		$FDN = strtolower($FDN);

		$pos = strpos($FDN, 'cn=');

		if ($pos === FALSE) {
			//already stripped
			return $FDN;
		} else {
			//get rid of cn=
			$FDN = substr($FDN, 3);
			$FDN = substr($FDN, 0, strpos($FDN, ',ou='));
			return $FDN;

		}
	}

	function Error() {
		if ($this->error) {
			return true;
		} else {

			return false;
		}
	}

	function ErrorDescription() {
		return $this->errmsg;
	}

	//
	// Below here are the "private" methods.  Private as in not-published.
	// PHP does not allow for true private methods and object classes
	//

	function _Debug_Dump($sendxml, $gotxml) {
		// Called from $this->talk_to_transproc if debugging enabled   
		print "<HR>SentXML: <PRE>".htmlentities($sendxml)."</PRE><P>";
		print "GotXML: <PRE>".htmlentities($gotxml)."</PRE><HR>";
	}

	//End of Class  
}

// Base class to replicate the Collection Object 
// that is used in Visual Basic


//defined sort function for usort
function _transproc_cmp($a, $b) {

	$myA = strtolower($a->LastName.", ".$a->FirstName." ".$a->MI);
	$myB = strtolower($b->LastName.", ".$b->FirstName." ".$b->MI);

	if ($myA == $myB)
		return 0;
	return ($myA > $myB) ? 1 : -1;

}
?>
