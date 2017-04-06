<?php
/*
 * Created on Dec 14, 2006
 *
 * To change the template for this generated file go to
 * Window - Preferences - PHPeclipse - PHP - Code Templates
 */
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>Network Registration</title>
<link href="assets/style.css" rel="stylesheet" type="text/css" />
</head>
<body>
<table width="100%" cellpadding="10">
<tr><td></td><td><img src="img/netregistration.gif" width="351" height="39" align="right" /></td></tr></table> 

Put your use policy here

<p><a name="acceptButton" id="acceptButton"></a>By clicking &quot;Accept&quot; you signify that you have read and will abide by the terms of the use policy.  You must accept this policy to use the network.</p>
<font color="red"><?=$tmplt['usrMessage']?></font>
<form method="post">Description:
<input name="description" size="40" maxlength="40" type="text" value="<?=$tmplt['devDescription']?>"/>
<input type="submit" name="submit" value="Accept"/>
</body>
</html>
