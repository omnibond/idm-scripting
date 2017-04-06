#!/bin/sh
#
# DESCRIPTION
#   The globals.sh script sets global information, such as file paths and
#   settings that are used by all scripts.
#

################  BEGIN Modifiable Flags  ###########################

# define symbolic priorities for certain classes of frequently logged
# messages.
TRACEPRIO=debug; export TRACEPRIO
CMDOKPRIO=info; export CMDOKPRIO
CMDFAILPRIO=err; export CMDFAILPRIO
PUBEVENTPRIO=info; export PUBEVENTPRIO

# general script tracing options
SCRIPTS_TRACE_FILE="${INSTALL_PATH}/logs/script-trace.log"
SCRIPTS_VERBOSE=false         # set -v
SCRIPTS_TRACE_EXECUTION=false # set -x

# file locations
SASLPASSWD=`which saslpasswd 2> /dev/null`
if [ ! -x "$SASLPASSWD" ]; then
  SASLPASSWD=`which saslpasswd2`
fi
export SASLPASSWD

SASLDBLISTUSERS=`which sasldblistusers 2> /dev/null`
if [ ! -x "$SASLDBLISTUSERS" ]; then
  SASLDBLISTUSERS=`which sasldblistusers2`
fi
export SASLDBLISTUSERS
#################  END Modifiable Flags  ############################

# set some global path and variable information
PATH=/usr/xpg4/bin:/usr/bin:/usr/ucb:/usr/ccs/bin:/usr/local/bin:/bin:/usr/sbin:/usr/lib/nis
export PATH
OS_TYPE=`uname -s`; export OS_TYPE
OS_VER=`uname -r`;  export OS_VER

# set basename...
BASENAME="/bin/basename"; export BASENAME

# define some constants
NEWLINE='
'
export NEWLINE
IFSSAVE=$IFS; export IFSSAVE

# set script execution options
SCRIPT_PREFIX="/bin/sh"
SCRIPT_SUFIX=""

# turn the following flags on for very verbose and detailed script tracing
if [ "$SCRIPTS_VERBOSE" = "true" ]; then
  SCRIPT_PREFIX=$SCRIPT_PREFIX" -v"
fi
if [ "$SCRIPTS_TRACE_EXECUTION" = "true" ]; then
  SCRIPT_PREFIX=$SCRIPT_PREFIX" -x"
fi
SCRIPT_SUFFIX=" 2>> $SCRIPTS_TRACE_FILE"

# Define each script location and execution method
#  scripts may be executed with options: sh -x scriptname.sh 2> output
#
IDMLIB="$INSTALL_PATH/scripts/idmlib.sh";
  export IDMLIB
ADD_SCRIPT="$SCRIPT_PREFIX $SCRIPT_DIR/add.sh $SCRIPT_SUFFIX";
  export ADD_SCRIPT
QUERY_SCRIPT="$SCRIPT_PREFIX $SCRIPT_DIR/query.sh $SCRIPT_SUFFIX";
  export QUERY_SCRIPT
MODIFY_SCRIPT="$SCRIPT_PREFIX $SCRIPT_DIR/modify.sh $SCRIPT_SUFFIX";
  export MODIFY_SCRIPT
DELETE_SCRIPT="$SCRIPT_PREFIX $SCRIPT_DIR/delete.sh $SCRIPT_SUFFIX";
  export DELETE_SCRIPT
RENAME_SCRIPT="$SCRIPT_PREFIX $SCRIPT_DIR/rename.sh $SCRIPT_SUFFIX";
  export RENAME_SCRIPT
MOVE_SCRIPT="$SCRIPT_PREFIX $SCRIPT_DIR/move.sh $SCRIPT_SUFFIX";
  export MOVE_SCRIPT
MODIFY_PASSWORD_SCRIPT="$SCRIPT_PREFIX $SCRIPT_DIR/modify-password.sh $SCRIPT_SUFFIX";
  export MODIFY_PASSWORD_SCRIPT
