#!/bin/sh

CONTAINER=fullctl_routeserver
PODMAN_CMD="sudo podman"

if $PODMAN_CMD ps --format "{{.Names}}" | grep -q "$CONTAINER"; then
	#echo "Container is running."
	$PODMAN_CMD exec -it "$CONTAINER" /srv/bird/sbin/birdc $@
else
	echo "$CONTAINER is not running." >&2
	exit 1
fi

