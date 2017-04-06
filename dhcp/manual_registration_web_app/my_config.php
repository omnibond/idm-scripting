<?php


//Unique identifier for this application
//This is need to prevent session data from getting stepped on by
//other apps using this framework.
$this->set_application_id('dev-6b6f570a-c336-1024-7300-0090276dcac6');

//debug mode
$this->set('debug',false); //TRUE or FALSE

//use DEV_USER instead of the true authenticated user
//$this->set('AUTH_USER_IS_DEV_USER',TRUE);
$this->set('DEV_USER','SOMEUSER');

// Name of application
$this->set('application_title','Network Registration System');

// Author signature (will be included in the Meta HTML)
$this->set('application_author','Billy Cook (wrcook@clemson.edu)');

// Org name (will be included in the Meta HTML)
$this->set('orgname','Clemson University');

// This is the file that contains all the Javascript code your app will need.
$this->set('common_javascript','common_javascript.php');

$this->set('nav_button_type','html'); 

// Show a "crumb trail" in the navigation header
$this->set('show_nav_crumbtrail',FALSE);

//File for common visible headers
$this->set('common_headers_file','common_headers.php');


// depreceated. alias for PHP_SELF incase it needs to be locally
// overwritten
$this->set('ME',$_SERVER['PHP_SELF']);

// Use CSS stylesheet or not
$this->set('use_stylesheet',TRUE); //TRUE or FALSE

// CSS stylesheet to use (Can be a relative or absolute URL)
$this->set('stylesheet','styles.css');


// some colors
$this->set('main_bgcolor','#FFFFFF');
$this->set('link_color'	 ,'#0000CC');
$this->set('vlink_color','#0000CC');
$this->set('alink_color','#0000CC');
$this->set('table_bgcolor','#0099FF');
$this->set('active_bgcolor','#FFFFFF');
$this->set('dim_bgcolor','#3399CC');
$this->set('error_color','#FFFF66');
$this->set('warn_color','red');
$this->set('reqd_color','#FF0000');
$this->set('bgalt_color1','#FFFFFF');
$this->set('bgalt_color2','#EEEEEE');
