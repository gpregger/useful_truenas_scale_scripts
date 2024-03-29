#!/bin/bash

if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ $# == 0 ] || [ $# -gt 2 ] 
then
    echo
    echo "Usage: k3logs PodNamespace [-f]" 
    echo 
    echo "The ix- prefix in the pod namespace is optional"
    echo "The Script will find the first Pod (from k3s get pods -A) in the specified namespace and show its logs"
    echo
    echo -f	follow the log output
    echo
    echo "Example: k3logs nextcloud -f"
    echo
    exit 0
fi

namespace=$1

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
    if [ "$status" != "TaintToleration" ] && [ "$status" != "UnexpectedAdmissionError" ]
    then
        pod=`echo "$line" | tr -s " " |cut -d " " -f2`
        break
    fi
done < <(echo "$pods")

if [ "$pod" == "" ]
then
    echo "No pod found in namespace $namespace"
    exit 0
fi

k3s kubectl logs --namespace $namespace $pod $2
