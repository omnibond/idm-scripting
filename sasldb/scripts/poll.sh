#!/bin/sh
#
# poll.sh
#
# Scans for changes to the sasldb

# include the IDM Library
. $IDMLIB

LOGGER -p $TRACEPRIO " *** "`$BASENAME $0`" *** "

# defined constants
SNAPSHOTS_DIR=$SCRIPT_DIR"/snapshots"
SASLDB_OLD="$SNAPSHOTS_DIR/passwd.old"
SASLDB_NEW="$SNAPSHOTS_DIR/passwd.new"
CHANGELOG=${INSTALL_PATH}bin/nxclh

main()
{
  ############################################
  # check sasldb for updates
  ############################################
  if [ -f "$SASLDB_OLD" ]
  then
    # possible event was created
    touch $SASLDB_NEW; chmod 600 $SASLDB_NEW
    if [ -n "$SASL_DBFILE" ]; then
      $SASLDBLISTUSERS -f $SASL_DBFILE | sort > $SASLDB_NEW
    else
      $SASLDBLISTUSERS | sort > $SASLDB_NEW
    fi

    # check_passwd_changes will handle all the logic
    check_sasldb_changes

    # finally, update map file
    cp $SASLDB_NEW $SASLDB_OLD
  else
    # passwd map file is missing, possibly first run
    touch $SASLDB_OLD; chmod 600 $SASLDB_OLD

    if [ -n "$SASL_DBFILE" ]; then
      $SASLDBLISTUSERS -f $SASL_DBFILE | sort > $SASLDB_OLD
    else
      $SASLDBLISTUSERS | sort > $SASLDB_OLD
    fi
  fi

  # if the changelog has any "hold" events, release them
  $CHANGELOG --release
}


###############################################################################
# check_sasldb_changes()
#
# This routine checks sasldb for adds and deletes.  
# Changes are submitted to the change log for publishing.
###############################################################################
check_sasldb_changes()
{
    CURR_LIST=`comm -13 $SASLDB_OLD $SASLDB_NEW`
    PREV_LIST=`comm -23 $SASLDB_OLD $SASLDB_NEW`

    # iterate over all new deletes
    IFS=$NEWLINE
    for PREV in $PREV_LIST
    do
      IFS=$IFSSAVE

      curr_loginName=`echo $CURR | awk -F@ '{print $1}'`

      ASSOCIATION=`$ASSOCIATION_SCRIPT -create $curr_loginName`

      LOGGER -p $PUBEVENTPRIO "Publisher detected a delete for $curr_loginName"

      $CHANGELOG -t delete -c User -a $ASSOCIATION -s $curr_loginName <<EOF
EOF

    done
    IFS=$IFSSAVE

    # iterate over all new adds
    IFS=$NEWLINE
    for CURR in $CURR_LIST
    do
      IFS=$IFSSAVE

      curr_loginName=`echo $CURR | awk -F@ '{print $1}'`

      ASSOCIATION=`$ASSOCIATION_SCRIPT -create $curr_loginName`

      LOGGER -p $PUBEVENTPRIO "Publisher detected an add for $curr_loginName"

      ADD_CMD=""
      # retrieve the cleartext password by running 'strings' against the database
      if [ -n "$SASL_DBFILE" ]; then
        password=`strings $SASL_DBFILE | grep -B 1 $curr_loginName | head -1`
        if [ -n "$password" ]; then
          ADD_CMD=$ADD_CMD"PASSWORD=$password"$NEWLINE
        fi
      fi

      if [ -n "$curr_loginName" ]; then 
        ADD_CMD=$ADD_CMD"ADD_loginName=$curr_loginName$NEWLINE"
      fi

      $CHANGELOG -t add -c User -a $ASSOCIATION -s $curr_loginName <<EOF
$ADD_CMD
EOF

    done
    IFS=$IFSSAVE
}

main $@
