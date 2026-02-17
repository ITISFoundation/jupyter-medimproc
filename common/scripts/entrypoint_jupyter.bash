#!/bin/bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'
INFO="INFO: [$(basename "$0")] "

# BOOTING application ---------------------------------------------
echo "$INFO" "Starting container ..."
echo "$INFO" "  User    :$(id "$(whoami)")"
echo "$INFO" "  Workdir :$(pwd)"


# expect input/output folders to be mounted
stat "${DY_SIDECAR_PATH_INPUTS}" > /dev/null 2>&1 || \
        (echo "ERROR: You must mount '${DY_SIDECAR_PATH_INPUTS}' to deduce user and group ids" && exit 1)
stat "${DY_SIDECAR_PATH_OUTPUTS}" > /dev/null 2>&1 || \
    (echo "ERROR: You must mount '${DY_SIDECAR_PATH_OUTPUTS}' to deduce user and group ids" && exit 1)

# NOTE: expects docker run ... -v /path/to/input/folder:${DY_SIDECAR_PATH_INPUTS}
# check input/output folders are owned by the same user
if [ "$(stat -c %u "${DY_SIDECAR_PATH_INPUTS}")" -ne "$(stat -c %u "${DY_SIDECAR_PATH_OUTPUTS}")" ]
then
    echo "ERROR: '${DY_SIDECAR_PATH_INPUTS}' and '${DY_SIDECAR_PATH_OUTPUTS}' have different user id's. not allowed" && exit 1
fi
# check input/outputfolders are owned by the same group
if [ "$(stat -c %g "${DY_SIDECAR_PATH_INPUTS}")" -ne "$(stat -c %g "${DY_SIDECAR_PATH_OUTPUTS}")" ]
then
    echo "ERROR: '${DY_SIDECAR_PATH_INPUTS}' and '${DY_SIDECAR_PATH_OUTPUTS}' have different group id's. not allowed" && exit 1
fi

echo "listing inputs folder ${DY_SIDECAR_PATH_INPUTS}"
ls -lah "${DY_SIDECAR_PATH_INPUTS}"
echo "listing outputs folder ${DY_SIDECAR_PATH_OUTPUTS}"
ls -lah "${DY_SIDECAR_PATH_OUTPUTS}"

echo "setting correct user id/group id..."
HOST_USERID=$(stat -c %u "${DY_SIDECAR_PATH_INPUTS}")
HOST_GROUPID=$(stat -c %g "${DY_SIDECAR_PATH_INPUTS}")
CONTAINER_GROUPNAME=$(getent group | grep "${HOST_GROUPID}" | cut --delimiter=: --fields=1 || echo "")
echo "CONTAINER_GROUPNAME='$CONTAINER_GROUPNAME'"

if [ "$HOST_USERID" -eq 0 ]
then
    echo "Warning: Folder mounted owned by root user... adding $NB_USER to root..."
    addgroup "$NB_USER" root
else
    echo "Folder mounted owned by user $HOST_USERID:$HOST_GROUPID-'$CONTAINER_GROUPNAME'..."
    # take host's credentials in $NB_USER
    if [ -z "$CONTAINER_GROUPNAME" ]
    then
        echo "Creating new group my$NB_USER"
        CONTAINER_GROUPNAME=my$NB_USER
        addgroup --gid "$HOST_GROUPID" "$CONTAINER_GROUPNAME"
    else
        echo "group already exists"
    fi

    echo "adding $NB_USER to group $CONTAINER_GROUPNAME..."
    usermod --append --groups "$CONTAINER_GROUPNAME" "$NB_USER" 
    
    echo "Changing ownership of state directory /home/${NB_USER}/work/workspace"
    chown --recursive "$NB_USER" "/home/${NB_USER}/work/workspace"
    echo "Changing ownership of state directory ${DY_SIDECAR_PATH_INPUTS}"
    chown --recursive "$NB_USER" "${DY_SIDECAR_PATH_INPUTS}"
    echo "Changing ownership of state directory ${DY_SIDECAR_PATH_OUTPUTS}"
    chown --recursive "$NB_USER" "${DY_SIDECAR_PATH_OUTPUTS}"
fi

mv "${NOTEBOOK_BASE_DIR}/README.ipynb" "${NOTEBOOK_BASE_DIR}/workspace/README.ipynb" || true

echo "Removing write permissions from users in placed where they are not allowed to write:"
echo "- /home/${NB_USER}/work"
chmod gu-w "/home/${NB_USER}/work"

echo
echo "$INFO" "Starting notebook ..."
exec gosu "$NB_USER" python /usr/local/bin/service-monitor/activity_monitor.py &
exec gosu "$NB_USER" /docker/boot_notebook.bash
