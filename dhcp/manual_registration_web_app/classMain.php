<?php

include_once($GLOBALS['MYPATH'] ."classConfig.php");

session_start();

  /** 
   * Application Framework
   *
   * @author Barry Johnson <cyclist@clemson.edu>
   * @version 1.0
   * @access public
   * @copyright cyclist
   *
   */

   class classMain {

     var $user_msg;
     var $conf;
     var $APPID;

     /** 
      * Class Constructor
      *
      * @access public
      * @since 1.0
      */

      
      function classMain($entry='welcome.php',$appid=NULL) {
         //setup globals
         global $_GET;
         global $_POST;
         global $_SESSION;

         //get a new config object for application and framework-global
         //config options
                  
         $this->conf = new classConfig();
         
         //get our application id 
         if ($appid == NULL) {
            $this->APPID = $this->conf->get_application_id();
         } else {
            $this->APPID = $this->conf->get_application_id().$appid;
         }
          
         
         //the start of this app and session
         if  ($_SESSION[$this->APPID]['seq_filename'] == '') {            
             
             $_SESSION[$this->APPID]['crumbtrail'] = array($this->conf->get('application_title'));
             $_SESSION[$this->APPID]['seq_filename'] = $entry;
             $_SESSION[$this->APPID]['titlefilemap']['Home'] = $entry;
                
                   
             include($GLOBALS['MYPATH'] . $_SESSION[$this->APPID]['seq_filename']);          
           
         } else {
         
             
           include($GLOBALS['MYPATH'] . $_SESSION[$this->APPID]['seq_filename']);
           
           
         }

      }

     /** 
      * This function is used to send the application to the next screen.
      *
      * @param string $where The next filename in sequence
      * @param bool $addtocrumbtrail If TRUE add it, otherwise don't
      * @access public
      * @return void
      * @since 1.0
      */

      function gotoNextPage($where,$addtocrumbtrail=TRUE,$crumbtext=NULL) {
        global $_POST;
        global $_SESSION;
        
      
        
        //If it's not in there already 
        //Map our page titles to filenames for crumbtrail reference later 
        
          $_SESSION[$this->APPID]['titlefilemap'][$_POST['nextpage']] = $where;
        
        
        if ($_POST['nextpage'] == 'Home') {
            $_SESSION[$this->APPID]['crumbtrail'] = array($this->conf->get('application_title'));
        } else {
           
           //if we've been here before we want to chop based on crumb title, not nextpage

           //see if nextpage is already in the crumbtrail.   
           
             $chopkey = array_search($_POST['nextpage'],
                                   $_SESSION[$this->APPID]['crumbtrail']);

                       
//           if ($chopkey != FALSE) { 
//                                     
//           $chopkey = array_search($where,
//                                   $_SESSION[$this->APPID]['crumbtrail']);    
//           }            
         
           //If so chop the trail from that occurence on.

           if ($chopkey != FALSE) {                        
              //print_r($chopkey);
             array_splice ($_SESSION[$this->APPID]['crumbtrail'], $chopkey);      
           } 
           
           //add the page to the end of the trail if we should
           if ($addtocrumbtrail == TRUE) {
             if ($crumbtext == NULL) {   
             $_SESSION[$this->APPID]['crumbtrail'][] = $_POST['nextpage'];           
           } else {
              $_SESSION[$this->APPID]['crumbtrail'][] = $crumbtext;
           }
         }
        }
        
        $_POST['nextpage'] = '';       
          $_SESSION[$this->APPID]['seq_filename'] = $where;      
          //print "Including: ". $_SESSION[$this->APPID]['seq_filename'] ."<br>";      
        include($GLOBALS['MYPATH']. $_SESSION[$this->APPID]['seq_filename']);
        //print "in gotoNextPage";
        exit();
      }

     /** 
      * Includes common javascript on all screens.
      *
      * @access public
      * @return void
      * @since 1.0
      */

      function commonJavaScript() {

        include($GLOBALS['MYPATH']. $this->conf->get('common_javascript'));                  
         
      }

      function formNavLink($title,
                           $form,
                           $altdest='',
                           $confirmstr='',
                           $selectid='',
                           $attrs = ''
                           ) {

        if ($altdest == '') {
           
             $altdest = $title;
           
        }   

        $jscript = "";
        //if no confirm or select
        if (($confirmstr == '') && ($selectid == '')) {
           
           $jscript = "setNextpage('$form', '$altdest')";
           
          //if select but no confirm
        } elseif  (($confirmstr == NULL) && ($selectid != NULL)) {
           
           $jscript = "selectAndSetNextpage('$form', '$altdest','$selectid')";
        
          //if select and confirm   
        } elseif  (($confirmstr != NULL) && ($selectid != NULL)){
           
           $jscript = "selectAndSetNextpageConfirm('$form', '$altdest','$selectid','$confirmstr')";
           
          //if we have confirm but no select.
        } elseif (($confirmstr != NULL) && ($selectid == NULL)){

           $jscript = "setNextpageConfirm('$form', '$altdest','$confirmstr')";
        }

        //print "<a href=\"javascript:($jscript)\" onclick=\"$jscript\" $attrs onMouseOver=\"window.status='$title'; return true;\" onMouseOut=\"window.status=''; return true;\">$title</a>";

        print "<a onclick=\"$jscript\" title=\"$title\" $attrs onMouseOver=\"window.status='$title'; return true;\" onMouseOut=\"window.status=''; return true;\">$title</a>";


     }



     /** 
      * Includes common javascript on all screens.
      *
      * @access public
      * @param string $title Title to display on the button
      * @param string $form Name of the form to submit
      * @param string $size Which size Flash Button to use
      * @param string $altdest Alternate destination to be used when you 
      *               want to display something different than where you 
      *               really want to go
      * @return void
      * @since 1.0
      */

      function formNavButton($title,
                             $form,
                             $size="large",
                             $altdest='',
                             $confirmstr='',
                             $selectid=''                             
                             ) {
         
        if ($altdest == '') {
           
             $altdest = $title;
           
        }   
         
        if ($this->conf->get('nav_button_type') == 'flash') {
                      
            $buttonurlpath = $this->conf->get('nav_button_url_path');
      
            switch ($size) {
               case "large":
                  $buttonfile = "button2.swf";
                  $width = "200";
                  break;              
               case "small": 
                  $buttonfile = "button.swf";
                  $width = "100";
                  break;
               case "medium":
                  $buttonfile = "button15.swf";
                  $width = "150";
                  break;                        
            }
         

            $title = urlencode($title);
            $buttonurl = $buttonurlpath . $buttonfile;
            
         
         } // 

            $jscript = "xyz";
            //if no confirm or select
            if (($confirmstr == '') && ($selectid == '')) {
               
               $jscript = "setNextpage('$form', '$altdest')";
               
              //if select but no confirm
            } elseif  (($confirmstr == NULL) && ($selectid != NULL)) {
               
               $jscript = "selectAndSetNextpage('$form', '$altdest','$selectid')";
            
              //if select and confirm   
            } elseif  (($confirmstr != NULL) && ($selectid != NULL)){
               
               $jscript = "selectAndSetNextpageConfirm('$form', '$altdest','$selectid','$confirmstr')";
               
              //if we have confirm but no select.
            } elseif (($confirmstr != NULL) && ($selectid == NULL)){

               $jscript = "setNextpageConfirm('$form', '$altdest','$confirmstr')";
            }
         include($GLOBALS['MYPATH']. $this->conf->get('nav_button_type').'_navbutton.php');  
                         
      }

     /** 
      * Includes HTML <HEAD> element
      *
      * @access public
      * @return void
      * @since 1.0
      */
      
      function includeHead() {
         
         include($GLOBALS['MYPATH']. 'head.php');
         
      }

     /** 
      * Includes HTML <BODY> tag
      *
      * @access public
      * @return void
      * @since 1.0
      */

      
      function includeBodyStart() {
         
         echo "<BODY BGCOLOR='" . $this->conf->get('main_bgcolor') ."' ";
         echo "  ALINK='" . $this->conf->get('alink_color') ."' ";
         echo "  VLINK='" . $this->conf->get('vlink_color') ."' ";
         echo "  LINK='" . $this->conf->get('link_color') ."'>";
         echo "\n";
         if ($this->conf->get('use_stylesheet') == TRUE) {
         
             echo '<link rel="stylesheet" href="'.
             $this->conf->get('stylesheet') .'" type="text/css">';
         }
      }

     /** 
      * Dumps debug variables to the page in a table
      *
      * @param string $file __FILE__ from the calling php file
      * @param mixed $others array of var => value to display along with standard debug variables
      * @access public
      * @return void
      * @since 1.0
      */


      function includeDebugInfo($file='',$others='') {
      
         if ($this->conf->get('debug') == TRUE ) {
           print "<p><FONT SIZE='-1'><b>Debug info:</b> $file</FONT><br>";
           print "<TABLE BORDER='1'WIDTH='100%'> ".
                 "<TH>var</TH><TH>value</TH>".
                 
                 "<TR>".
                 "<TD VALIGN='TOP' ALIGN='LEFT'><FONT SIZE='-1'><b>_SESSION:</b></FONT></TD>".
                 "<TD><FONT SIZE='-1'>".
                 $this->debugVar($_SESSION).
                 "</FONT></TD></TR>".

                 "<TR>".
                 "<TD VALIGN='TOP' ALIGN='LEFT'><FONT SIZE='-1'><b>_POST:</b></FONT></TD>".
                 "<TD><FONT SIZE='-1'>".
                 $this->debugVar($_POST).
                 "</FONT></TD></TR>".

                 "<TR>".
                 "<TD VALIGN='TOP' ALIGN='LEFT'><FONT SIZE='-1'><b>AUTH_USER:</b></FONT></TD>".
                 "<TD><FONT SIZE='-1'>".
                 (isset($GLOBALS['REMOTE_USER'])) ?  $this->debugVar($GLOBALS['REMOTE_USER']) : "".
                 "</FONT></TD></TR>";                 
                 
           if (is_array($others)) {
                //print other passed vars
                foreach($others as $key => $value) {
                   
                     print "<TR>".
                 "<TD VALIGN='TOP' ALIGN='LEFT'><FONT SIZE='-1'><b>$key:</b></FONT></TD>".
                 "<TD><FONT SIZE='-1'>".
                 $this->debugVar($value).
                 "</FONT></TD></TR>";                   
                }
           }                 
           print "</TABLE></p>";
                       
         }   
         
      }

     /** 
      * Includes HTML </BODY> tag
      *
      * @access public
      * @return void
      * @since 1.0
      */

      function includeBodyEnd() {
         
         echo "</BODY>";
         
      }

     /** 
      * Set or display messages to the user
      *
      * @access public
      * @param mixed $msg The message to the user
      * @since 1.0
      */
      
      function userMessage($msg='') {
         
         if (($msg == '') && ($this->user_msg != '')) {
            
           echo '<font color="'.$this->conf->get('warn_color').'" size="+3">'. 
                $this->user_msg .'</font> <p>';
            
         } else {
         
           $this->user_msg = $msg;   
            
         }
      }


     /** 
      * Captures the output of print_r and returns it in a string
      *
      * @access public
      * @param mixed $var The variable to print_r
      * @return string $ret_str
      * @since 1.0
      */
      
      function debugVar($var) {
         ob_start();
         print_r($var);
         $ret_str = ob_get_contents();
         ob_end_clean();   
         return "<PRE>".$ret_str."</PRE>";
      }

     /** 
      * Includes common header html
      *
      * @access public
      * @return void
      * @since 1.0
      */

      
      function includeCommonHeader() {
         

         if  ($this->conf->get('common_headers_file') != '') {
                     
            include($GLOBALS['MYPATH']. $this->conf->get('common_headers_file'));
         }
      }


      // Returns class name
      function GetClassName() {
         return 'classMain';
      }


      //open and new window with our standard button..
      function newWindowButton($title, $url, $size="large") {

        if ($this->conf->get('nav_button_type') == 'flash') {

            $buttonurlpath = $this->conf->get('nav_button_url_path');

                switch ($size) {
                        case "large":
                           $buttonfile = "button2.swf";
                           $width = "200";
                           break;
                        case "small":
                           $buttonfile = "button.swf";
                           $width = "100";
                           break;
                        case "medium":
                           $buttonfile = "button15.swf";
                           $width = "150";
                           break;
                }


           $title = urlencode($title);
           $buttonurl = $buttonurlpath . $buttonfile;


         }

         $jscript = "void window.open('$url')";

         include($GLOBALS['MYPATH']. $this->conf->get('nav_button_type').'_navbutton.php');

      }

        function setSessionVar($var,$val) {

                $_SESSION[$this->APPID][$var] = $val;

        }

        function getSessionVar($var) {

                return $_SESSION[$this->APPID][$var];

        }

        function navFormEnd() {
                echo "</FORM>\n";
        }

        function htmlEnd() {
                echo "</HTML>\n";
        }

        function htmlStart() {
                echo "<HTML>\n";
        }

        function sendHTML($html) {
                echo $html . "\n";
        }

   function authUser() {

      if ($this->conf->get('AUTH_USER_IS_DEV_USER')) {

         return $this->conf->get('DEV_USER');   
      } else {

          return strtoupper($_SERVER['REMOTE_USER']);

      }

   }



   function getDisplayText($key) {

      if ($this->conf->get('debug')) {
         return "<b>[$key]</b><br>".$this->conf->get($key);
      } else {
         return $this->conf->get($key);
      }
   }

   function navFormStart($name = 'navform', $attrs = '') {
      echo "    
            <FORM method=\"POST\" action=\"index.php\" name=\"$name\" $attrs>
            <!-- placeholder for javascript -->
            <input type=\"hidden\" name=\"nextpage\" value=\"\">
           ";          
   }

}
?>
