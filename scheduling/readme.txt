kubectl get nodes -o json | jq ".items[]|{name:.metadata.name, taints:.spec.taints}"

kubect taint nodes <node-name> release=qa:NoSchedule

kubect taint nodes <node-name> release=qa:NoSchedule-
