<?php
      //Common Javascript functions used by the framework. 
      //Add any specific to your app at the bottom
?>

function setNextpage(theForm, where)
{
	var thevar = document.forms[theForm].elements['nextpage'];
	thevar.value = where;
   document.forms[theForm].submit();
   return true;
}


function selectAndSetNextpage(theForm, where, selectid)
{
	var thevar = document.forms[theForm].elements['nextpage'];
	var theselvar = document.forms[theForm].elements['selectid'];
	thevar.value = where;
	theselvar.value = selectid;
   document.forms[theForm].submit();
   return true;
}

function selectAndSetNextpageConfirm(theForm, where, selectid, confirmstr)
{
	if(confirm(confirmstr)) {
	
	var thevar = document.forms[theForm].elements['nextpage'];
	var theselvar = document.forms[theForm].elements['selectid'];
	thevar.value = where;
	theselvar.value = selectid;
   document.forms[theForm].submit();
   return true;
   
   }
}

function setNextpageConfirm(theForm, where, confirmstr)
{
	if(confirm(confirmstr)) {
	
	var thevar = document.forms[theForm].elements['nextpage'];
	thevar.value = where;
   document.forms[theForm].submit();
   return true;
   
   }
}


//Add your functions after this line
