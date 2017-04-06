<?
   if (isset($_POST['nextpage'])) {
      switch($_POST['nextpage']) {
      
              case "home":
                $this->gotoNextPage("welcome.php", FALSE);
              break;
      
              case "delete_registration":
                $this->gotoNextPage("delete_registration.php", FALSE);
              break;
      
              case "add_registration":
                $this->gotoNextPage("add_registration.php", FALSE);
              break;
      
              case "logout":
                $this->setSessionVar("AUTHUSER", "");
                $this->gotoNextPage("welcome.php", FALSE);
              break;
      
      }
   }
?>
