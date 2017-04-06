<?php
//This should be the default in PHP>4.2
ini_set("register_globals", 0);

$GLOBALS['MYPATH'] = '';

//include your class that extends classMain.php
include_once($GLOBALS['MYPATH'] ."myapp_main.php");

//Instantiate the object.
$main = new myapp_main();

?>
