#!/bin/bash

if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ $# -lt 1 ] || [ $# -gt 3 ] 
then
    echo
    echo "Usage: dcshell composeProject service [shell]"
    echo 
    echo "The Script will find the first running container (from docker ps) with the name ix-AppName-AppName-1"
    echo "If no shell is specified /bin/bash is assumed"
    echo
    echo "Example: dcshell nextcloud app"
    echo "Example: dcshell ix-searxng searxng /bin/sh"
    echo
    exit 0
fi

composeProject=$1
container=$2

if [ "$3" == "" ]
then
    containerShell=/bin/bash
else
    containerShell=$3
fi

composeProjects=`docker compose ls | tail -n +2 | cut -d " " -f1 | grep -P "^${composeProject}$"`

# if no pods found in namespace try prefacing namespace with "ix-" so app-name works too
if [ "$composeProjects" == "" ]
then
    composeProject=ix-$composeProject
    composeProjects=`docker compose ls | grep -i $composeProject`
fi

if [ "$composeProjects" == "" ]
then
    echo "No matching compose project found"
    exit 1
fi

containers=`docker compose -p $composeProject ps | tail -n +2 | cut -d " " -f1 | rev | cut -d "-" -f2 | rev`

if [ -n "$container" ]
then
    if [[ $(echo ${containers[@]} | fgrep -w $container) ]]
    then
        docker compose -p $composeProject exec -it $container $containerShell
        exit 0
    fi
    echo "No container called \"$container\" found in $composeProject"
fi

echo "Available containers in $composeProject:"
echo "$containers" | sed -e 's/^/  /'
exit 1
