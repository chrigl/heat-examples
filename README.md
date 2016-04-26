# heat-examples
Some examples for OpenStack Orchestration

## CoreOS

Setting up a CoreOS cluster with three nodes, running the etcd2 cluster. All nodes belong to the private network 10.0.1.0/24. None of them will get a public ip address. In front of those nodes, an ssh jumphost will be available on a public ip.
* CoreOS with fleet
* CoreOS with docker-swarm
