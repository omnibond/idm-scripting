# idmlib.py
# Identity Manager Scripting library for Python

import os

def status(level, message):
  idmsetvar("COMMAND", "status")
  idmsetvar("STATUS_LEVEL", level)

  if message != "":
    idmsetvar("STATUS_MESSAGE", message)

def status_success(message):
  status("success", message)

def status_error(message):
  status("error", message)

def status_fatal(message):
  status("fatal", message)

def status_warning(message):
  status("warning", message)

def status_retry(message):
  status("retry", message)

def heartbeat_success(message):
  status_success(message)
  idmsetvar("STATUS_TYPE", "heartbeat")

def heartbeat_error(message):
  status_error(message)
  idmsetvar("STATUS_TYPE", "heartbeat")

def heartbeat_warning(message):
  status_warning(message)
  idmsetvar("STATUS_TYPE", "heartbeat")

def idmgetvar(var):
  ussmh = os.environ.get('INSTALL_PATH') + "bin/ussmh"
  val = os.popen(ussmh + " -event " + var, 'r').readlines()
  if len(val) > 0:
    return val[0]
  
  var = "ADD_%s" % var
  val = os.popen(ussmh + " -event " + var, 'r').readlines()
  if len(val) > 0:
    return val[0]
  else:
    return ""

def idmgetdrvvar(var):
  ussmh = os.environ.get('INSTALL_PATH') + "bin/ussmh"
  val = os.popen(ussmh + " -driver " + var, 'r').readlines()
  if len(val) > 0:
    return val[0]
  else:
    return ""

def idmgetpubvar(var):
  ussmh = os.environ.get('INSTALL_PATH') + "bin/ussmh"
  val = os.popen(ussmh + " -publisher " + var, 'r').readlines()
  if len(val) > 0:
    return val[0]
  else:
    return ""

def idmgetsubvar(var):
  ussmh = os.environ.get('INSTALL_PATH') + "bin/ussmh"
  val = os.popen(ussmh + " -subscriber " + var).readlines()
  if len(val) > 0:
    return val[0]
  else:
    return ""

def idmgetqvar(var):
  ussmh = os.environ.get('INSTALL_PATH') + "bin/ussmh"
  val = os.popen(ussmh + " -query " + var).readlines()
  if len(val) > 0:
    return val[0]
  else:
    return ""

def idmsetvar(name, value):
  ussmh = os.environ.get('INSTALL_PATH') + "bin/ussmh"
  os.system("printf \"%s\" \"IDMSETVAR: " + name + "=" + value + "\" | " + ussmh + " -write")

def idmquery(classname, association, readattrs):
  ussmh = os.environ.get('INSTALL_PATH') + "bin/ussmh"
  
  os.system("printf \"%s\" \"IDMQUERY: BEGIN\" | " + ussmh + " -write")
  os.system("printf \"%s\" \"IDMQUERY: COMMAND=query\" | " + ussmh + " -write")
  os.system("printf \"%s\" \"IDMQUERY: SCOPE=entry\" | " + ussmh + " -write")
  os.system("printf \"%s\" \"IDMQUERY: CLASS_NAME=" + classname + "\" | " + ussmh + " -write")
  os.system("printf \"%s\" \"IDMQUERY: ASSOCIATION=" + association + "\" | " + ussmh + " -write")

  if readattrs != "":
    # specifying no read-attrs, returns everything
    os.system("printf \"%s\" \"IDMQUERY: READ_ATTRS=" + read_attrs + "\" | " + ussmh + " -write")

  os.system("printf \"%s\" \"IDMQUERY: END\" | " + ussmh + " -write")

  # wait for query to complete
  os.system(ussmh + " -wait-for-query")


def logger(priority, facility, message):
  os.system("logger -p " + priority + " -t " + facility + " " + message)


def trace(message):
  ussmh = os.environ.get('INSTALL_PATH') + "bin/ussmh"
  os.system("printf \"%s\" \"" + message + "\" | " + ussmh + " -write")

