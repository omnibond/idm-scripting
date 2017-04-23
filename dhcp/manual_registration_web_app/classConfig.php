<?php

  /** 
   * classConfig
   *
   * @author Barry Johnson
   * @version 1.0
   * @access public
   * @copyright cyclist
   *
   * Object class that provides a layer of abstraction for configuruation data
   * This purpose is to provide and easy way to map to enterprise wide configuration
   * data later.
   */
   

   class classConfig {
   	
      var $_config_array;
      var $_application_id;
      var $_override;

      // Class constructor
      function classConfig() {
      
    
      //get global configuration however we do that
      $this->import_framework_config();
     
      //set default to not override global config options
      $this->_override = FALSE;
      
      include_once($GLOBALS['MYPATH'] ."my_config.php");


      }

      function get($variable) {
      	
      	//If override is set
      	if ($this->_override) {
      	
      	  //return this app's version of the config parm
          if ( isset($this->_config_array[$this->_application_id][$variable]) ) {
      	     return $this->_config_array[$this->_application_id][$variable];
          }
      	  //if the enterprise version isn't empty
         } elseif ($this->_config_array['framework'][$variable] != '') {
         	
         	 //return it
         	 return $this->_config_array['framework'][$variable];
         	
           } else {
           	 
           	  //otherwise return this app's version of the config parm
           	 return $this->_config_array[$this->_application_id][$variable];
           }
      }

      /**
       * @return void
       * @param variable unknown
       * @param value = '' unknown
       * @desc Set configuration parameter
       */
      function set($variable,$value='') {
      	
      	$this->_config_array[$this->_application_id][$variable] = $value;

      }
   
      function import_framework_config() {
      	
      	$this->_config_array['framework']['placeholder'] = TRUE;
      	$this->_config_array['framework']['main_bgcolor'] = '#FFFFFF';
      	//for_now do nothing.  Later we'll need this
      	
      	//Later this will be probably house a SOAP call out for enterprise
      	//wide configuration data
      }
      
      function set_application_id($id) {      
           $this->_application_id = $id;	
      }
      
      function get_application_id() {      
           return $this->_application_id;	
      }
      
      function set_config_override($ov='FALSE') {      
           $this->_override = $ov;	
      }
   }
?>
