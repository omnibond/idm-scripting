<?php
include_once($MYPATH ."classMain.php");
// include any other classes that you'll need to reference in your app
// here...
// include_once($MYPATH . "someOtherClassINeed.php");


class myapp_main extends classMain {

   function getNavMenu() {
      if (!$this->authUser()) {
        print "Please log in..";
        return;
      }
       
      $links = array(
                     "home" => "Instructions",
                     "add_registration" => "Add Registration",
                     "delete_registration" => "My Registrations"
       //              "logout" => "Logout"
                    );

      foreach($links as $link => $linktext) {
         if ($link != $this->getSessionVar('seq_filename')) {
            print $this->formNavLink($linktext, 'navform', $link, '', '', 'class="navlink"')."<br>";
         } else {
            print "<span class=\"navlink\">$linktext</span>";
         }
      }
   }
}
?>
