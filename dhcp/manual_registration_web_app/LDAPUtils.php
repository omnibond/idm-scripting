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

        function getSearchBase() {
            return $this->_searchbase;
        }

    function registerDevice($deviceDN,$userid, $description, $devLinkKey="") {

        $userdn = $this->_getUserDN($userid);
        if (!$userdn) {
           return null;
        }
        
        $tostore['DirXMLjnsuRegVersion'] = 1;
        $tostore['DirXMLjnsuDescription'] = $description;
        $tostore['DirXMLjnsuRegAddTime'] = time();
        $tostore['DirXMLjnsuUserDN'] = $userdn;
        if ($devLinkKey == "") {
           //create the link key from the md5 of the userid and description if none supplied
           $devLinkKey = md5($userid . $description);
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

    function addAndRegisterDevice($hwaddr,$userid, $description) {

        $userdn = $this->_getUserDN($userid);
        if (!$userdn) {
           return null;
        }
        
        $tostore['DirXMLjnsuRegVersion'] = 1;
        $tostore['DirXMLjnsuDescription'] = $description;
        $tostore['DirXMLjnsuRegAddTime'] = time();
        $tostore['DirXMLjnsuUserDN'] = $userdn;
        $tostore['DirXMLjnsuDeviceName'] = "jnsu-".$hwaddr;
        $tostore['DirXMLjnsuHWAddress'] = $hwaddr;
        $tostore['objectclass'][0] = "DirXMLjnsuNetworkDevice";
        $tostore['objectclass'][1] = "Top";

        if (!$this->_connectAndBind()) {

            $this->error = true;
            $this->errmsg = "Directory connect and bind error";
            return null;
        }

        $rc = ldap_add($this->ds,"DirXMLjnsuDeviceName=jnsu-".$hwaddr.",".$this->_searchbase,$tostore);
                 
                       
        if (!$rc) {       
           $this->error = true;
                   $this->errmsg = ldap_error($this->ds);
                   return null;       
        }      
        
        return true;

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

        $this->_debugVar($sr);

		$this->error = true;
		$this->errmsg = "Ip Addr / Device not found.";
		return null;

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

                        $dnparts = ldap_explode_dn( $result['DirXMLjnsuUserDN'][0] , 1 );
			$toreturn['userid'] = $dnparts[0];

			$toreturn['timestamp'] =  $result['DirXMLjnsuRegAddTime'][0];
			return $toreturn;
			
	    }

                $this->_debugVar($sr);

		$this->error = true;
		$this->errmsg = "Previous Registration Not Found";
		return null;

	}

	function getDeviceRecordByHWAddress($macaddr) {

		if (!$this->_connectAndBind()) {

			$this->error = true;
			$this->errmsg = "Directory connect and bind error";
			return null;
		}

		$sr = ldap_search($this->ds, $this->_searchbase, "(&(DirXMLjnsuHWAddress=".$macaddr.")(objectclass=DirXMLjnsuNetworkDevice))");


		if ($entryID = ldap_first_entry($this->ds, $sr)) {
			//return ldap_get_dn($this->ds, $entryID);
			$result = ldap_get_attributes($this->ds, $entryID);
			$toreturn['description'] =  $result['DirXMLjnsuDescription'][0];
                        $dnparts = ldap_explode_dn( $result['DirXMLjnsuUserDN'][0] , 1 );
                        $toreturn['userid'] = $dnparts[0];
			$toreturn['timestamp'] =  $result['DirXMLjnsuRegAddTime'][0];
			$toreturn['regversion'] =  $result['DirXMLjnsuRegVersion'][0];
			return $toreturn;
			
	    }

        $this->_debugVar($sr);

		$this->error = true;
		$this->errmsg = "Previous Registration Not Found";
		return null;

	}

        function deleteRegistration($hwaddr) {
		if (!$this->_connectAndBind()) {

			$this->error = true;
			$this->errmsg = "Directory connect and bind error";
			return null;
		}

                return @ldap_delete($this->ds, "DirXMLjnsuDeviceName=jnsu-".$hwaddr.",".$this->_searchbase);
 
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

	function getDevicesByUserid($userid) {

		if (!$this->_connectAndBind()) {

			$this->error = true;
			$this->errmsg = "Directory connect and bind error";
			return null;
		}

                $userdn = $this->_getUserDN($userid);
                if (!$userdn) {
                    $this->error = true;
                    $this->errmsg = "Error 100.  Please contact the help desk.";
                    return array();
                }

		$sr = ldap_search($this->ds, $this->_searchbase, "(&(DirXMLjnsuUserDN=".$userdn.")(objectclass=DirXMLjnsuNetworkDevice))");

                if (ldap_count_entries($this->ds, $sr) == 0) {
                     $this->error = true;
                     $this->errmsg = "No registrations found";
                     return array();
                }

                $entries = ldap_get_entries($this->ds, $sr);

                $out = array();
                
                for ($i = 0; $i < $entries["count"]; $i++) {
                   $record['dirxmljnsudescription'] = $entries[$i]["dirxmljnsudescription"][0];
                   $record['dirxmljnsuhwaddress'] = $entries[$i]["dirxmljnsuhwaddress"][0];
                   $record['dirxmljnsuregaddtime'] = $entries[$i]["dirxmljnsuregaddtime"][0];
                   $record['dirxmljnsudescription'] = $entries[$i]["dirxmljnsudescription"][0];
                   $record['dirxmljnsuddnsprefix'] = $entries[$i]["dirxmljnsuddnsprefix"][0];
                   $record['dirxmljnsudevice'] = $entries[$i]["dirxmljnsudevice"][0];
                   $record['dirxmljnsudevicename'] = $entries[$i]["dirxmljnsudevicename"][0];
                   $record['dirxmljnsudhcpaddress'] = $entries[$i]["dirxmljnsudhcpaddress"][0];
                   $record['dirxmljnsudisabled'] = $entries[$i]["dirxmljnsudisabled"][0];
                   $record['dirxmljnsumdisabled'] = $entries[$i]["dirxmljnsumdisabled"][0];
                   $record['dirxmljnsuinfectedports'] = $entries[$i]["dirxmljnsuinfectedports"][0];
                   $record['dirxmljnsunvrexpires'] = $entries[$i]["dirxmljnsunvrexpires"][0];
                   $record['dirxmljnsureguserid'] = $entries[$i]["dirxmljnsureguserid"][0];
                   $record['dirxmljnsuregversion'] = $entries[$i]["dirxmljnsuregversion"][0];
                   $record['dirxmljnsustaticaddr'] = $entries[$i]["dirxmljnsustaticaddr"][0];

                   $out[] = $record;
                }
                return $out; 

	}
	
      function _debugVar($var) {
         ob_start();
         print_r($var);
         $ret_str = ob_get_contents();
         ob_end_clean();   
         return "<PRE>".$ret_str."</PRE>";
      }

//	function _getUserDN($userid) {
//
//		if (!$this->_connectAndBind()) {
//
//			$this->error = true;
//			$this->errmsg = "Directory connect and bind error";
//			return null;
//		}
//
//		for ($index = 0; $index < sizeof($this->userdnsearchbases); $index ++) {
//			$searchbase = $this->userdnsearchbases[$index];
//
//			$sr = ldap_search($this->ds, $searchbase, "(&(cn=".$userid.")(objectClass=Person))");
//
//			if ($entryID = ldap_first_entry($this->ds, $sr)) {
//				return ldap_get_dn($this->ds, $entryID);
//			}
//		}
//
//		$this->error = true;
//		$this->errmsg = "User not found.";
//		return null;
//
//	}

//	function _getUser($userid) {
//
//		if (!$this->_connectAndBind()) {
//
//			$this->error = true;
//			$this->errmsg = "Directory connect and bind error";
//			return null;
//		}
//
//		for ($index = 0; $index < sizeof($this->userdnsearchbases); $index ++) {
//			$searchbase = $this->userdnsearchbases[$index];
//
//			$sr = ldap_search($this->ds, $searchbase, "(&(cn=".$userid.")(objectClass=Person))");
//
//			if ($entryID = ldap_first_entry($this->ds, $sr)) {
//                
//				return ldap_get_attributes($this->ds, $entryID);
//			}
//		}
//        
//		$this->error = true;
//		$this->errmsg = "User not found.";
//		return null;
//
//	}

//	function GetUserRecord($userid) {
//
//		$result = $this->_getUser($userid);
//		// print "<PRE>".print_r($result)."</PRE>";
//		// Check for a fault
//		if ($this->error) {
//			return false;
//		} else {
//			$return_obj = new User($userid);
//			$return_obj->FullName = $result['givenName'][0]." ".$result['sn'][0];
//			$return_obj->FirstName = $result['givenName'][0];
//			$return_obj->LastName = $result['sn'][0];
//			$return_obj->EmailAddress = strtolower($result['mail'][0]);
//			$return_obj->MI = '';
//
//			return ($return_obj);
//		} //nofault
//
//	} //endfunction

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
