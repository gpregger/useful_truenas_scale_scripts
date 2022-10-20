#!/bin/bash

if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ $# == 0 ] || [ $# -gt 2 ] 
then
    echo
    echo "Usage: k3shell PodNamespace [PodShell]"
    echo 
    echo "The ix- prefix in the pod namespace is optional"
    echo "The Script will find the first running Pod (from k3s get pods -A) in the specified namespace and open a shell to it"
    echo "If no shell is specified /bin/bash is assumed"
    echo
    echo "Example: k3shell nextcloud"
    echo "Example: k3shell ix-wolweb /bin/sh"
    echo
    exit 0
fi

namespace=$1
if [ "$2" == "" ]
then
    containerShell=/bin/bash
else
    containerShell=$2
fi

pods=`k3s kubectl get pods -A | grep -P "^${namespace}(?=\s)"`

# if no pods found in namespace try prefacing namespace with "ix-" so app-name works too
if [ "$pods" == "" ]
then
    namespace=ix-$namespace
    pods=`k3s kubectl get pods -A | grep -P "^${namespace}(?=\s)"`
fi

while read -r line 
do
    status=`echo "$line" | tr -s " " |cut -d " " -f4`
    if [ "$status" == "Running" ]
    then
        pod=`echo "$line" | tr -s " " |cut -d " " -f2`
        break
    fi
done < <(echo "$pods")

if [ "$pod" == "" ]
then
    echo "No running pod found in namespace $namespace"
    exit 0
fi

k3s kubectl exec --namespace $namespace --stdin --tty $pod -- $containerShell
