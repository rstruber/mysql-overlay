#!/sbin/runscript
#
# Copyright (C) 2012 Codership Oy <info@codership.com>
# Modified by: Brian Evans <grknight@lavabit.com> for OpenRC
# $Header: $

depend() {
	need net
}

stop() {
	ebegin $"Shutting down "${SVCNAME}" "
	start-stop-daemon --stop --quiet --oknodo --retry TERM/30/KILL/5 \
		                  --pidfile $PIDFILE
	eend $?
}

start() {
	local rcode

	# Check that node addresses are configured
	if [ -z "$GALERA_NODES" ]; then
		eerror "List of GALERA_NODES is not configured"
		return 6
	fi
	if [ -z "$GALERA_GROUP" ]; then
		eerror "GALERA_GROUP name is not configured" 
		return 6
	fi

	GALERA_PORT=${GALERA_PORT:-4567}

	# Find a working node
	for ADDRESS in ${GALERA_NODES} 0; do
		HOST=$(echo $ADDRESS | cut -d \: -f 1 )
		PORT=$(echo $ADDRESS | cut -d \: -f 2 )
		PORT=${PORT:-$GALERA_PORT}
		nc -z $HOST $PORT >/dev/null && break
	done
	if [ ${ADDRESS} == "0" ]; then
		eerror "None of the nodes in $GALERA_NODES is accessible"
		return 1
	fi

	OPTIONS="-d -a gcomm://$ADDRESS"
	[ -n "$GALERA_GROUP" ]   && OPTIONS="$OPTIONS -g $GALERA_GROUP"
	[ -n "$GALERA_OPTIONS" ] && OPTIONS="$OPTIONS -o $GALERA_OPTIONS"
	[ -n "$LOG_FILE" ]       && OPTIONS="$OPTIONS -l $LOG_FILE"

	ebegin "Starting ${SVCNAME} "
	start-stop-daemon --start --quiet --background \
			--pidfile "${PIDFILE}" --make-pidfile \
	                  --exec /usr/bin/garbd -- $OPTIONS
	rcode=$?
	# Hack: sleep a bit to give garbd some time to fork
	sleep 1
	eend $rcode
}
