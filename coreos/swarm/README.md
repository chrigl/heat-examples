# Setting up a docker swarm cluster

Booting a [docker swarm](https://www.docker.com/products/docker-swarm) cluster on CoreOS in OpenStack, using [Heat Orchestration Templates](http://docs.openstack.org/developer/heat/template_guide/hot_guide.html). Default setup consists of 1 frontend and 3 backend nodes. Containers should be scheduled to the backend nodes, loadbalancer (or basically everything that has to be accessable from the outside) on the frontend nodes. For swarm discovery, etcd2 is used. This could be reused for any service discovery.

## How to start

Create an environment file to set required parameters. Alternatively you could pass them to ```heat```, using ```-P``` (the same way like ```discovery_url```).
Have as well a look into ```coreos-stack.yaml``` for available parameters.

Default values of ```image``` and ```front_image``` is ```CoreOS Stable```. You may want to change this, or create an image with this name. Have a look at the [CorOS documentation](https://coreos.com/os/docs/latest/booting-on-openstack.html).

```
$ cat coreos-env.yaml
parameters:
  key_name: YOUR SSH PUB KEY IN OPENSTACK
  public_net: ID OF YOUR PUBLIC NET
  image: NAME OF THE CORE OS IMAGE IN YOUR OPENSTACK
  flavor: m1.micro
  front_image: NAME OF THE CORE OS IMAGE IN YOUR OPENSTACK
  front_flavor: m1.micro
$ heat stack-create -f coreos-stack.yaml -e coreos-env.yaml -P discovery_url=(curl "https://discovery.etcd.io/new?size=3") my-swarm-stack
```

Network and instances should be created.

```
> nova list
+--------------------------------------+--------------------------+---------+------------+-------------+-----------------------------------------------------------+
| ID                                   | Name                     | Status  | Task State | Power State | Networks                                                  |
+--------------------------------------+--------------------------+---------+------------+-------------+-----------------------------------------------------------+
| e63359d3-f44b-4ec3-9dd1-23ab64276d2d | my-swarm-stack-back0     | ACTIVE  | -          | Running     | coreos-network-my-swarm-stack=10.0.1.13                   |
| 044d82e4-e33a-4ece-af91-57a9fd21cd8b | my-swarm-stack-back1     | ACTIVE  | -          | Running     | coreos-network-my-swarm-stack=10.0.1.12                   |
| d0fbd037-991a-43aa-905b-8f6af70ce99c | my-swarm-stack-back2     | ACTIVE  | -          | Running     | coreos-network-my-swarm-stack=10.0.1.14                   |
| dd9ed1d0-d5d1-4abf-a9be-e89423e70884 | my-swarm-stack-front0    | ACTIVE  | -          | Running     | coreos-network-my-swarm-stack=10.0.1.11, 1.247.85.135     |
+--------------------------------------+--------------------------+---------+------------+-------------+-----------------------------------------------------------+
```

After successful creation of the stack (check ```heat stack-list``` and ```heat resource-list my-coreos-stack```), you should be able to log into the created front node:
```
$ ssh -A -lcore $PUBLIC_IP_OF_FRONT

CoreOS alpha (960.0.0)
Update Strategy: No Reboots
Failed Units: 1
  user-configdrive.path
 # this fails from time to time. I have no idea why, and it does not influence the setup
```

The default configuration creates an ```etcd2``` and a ```swarm``` cluster. So, you should see the ```swarm nodes```:
(on the front node ```docker``` command is automatically connected to the ```swarm manage```. To just connect the local docker, ```unset DOCKER_HOST``` before calling ```docker```)

```
core@my-swarm-fromt0 ~ $ etcdctl ls /docker/swarm/nodes
/docker/swarm/nodes/10.0.1.14:2375
/docker/swarm/nodes/10.0.1.12:2375
/docker/swarm/nodes/10.0.1.13:2375
/docker/swarm/nodes/10.0.1.11:2375

core@my-swarm-front0 ~ $ docker info
Containers: 5
 Running: 5
 Paused: 0
 Stopped: 0
Images: 5
Server Version: swarm/1.1.3
Role: primary
Strategy: spread
Filters: health, port, dependency, affinity, constraint
Nodes: 4
 chris-coreos-swarm-back0.novalocal: 10.0.1.13:2375
  └ Status: Healthy
  └ Containers: 1
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 2.056 GiB
  └ Labels: executiondriver=native-0.2, kernelversion=4.4.1-coreos, kind=backend, operatingsystem=CoreOS 960.0.0 (Coeur Rouge), storagedriver=overlay
  └ Error: (none)
  └ UpdatedAt: 2016-03-12T11:53:58Z
 chris-coreos-swarm-back1.novalocal: 10.0.1.11:2375
  └ Status: Healthy
  └ Containers: 1
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 2.056 GiB
  └ Labels: executiondriver=native-0.2, kernelversion=4.4.1-coreos, kind=backend, operatingsystem=CoreOS 960.0.0 (Coeur Rouge), storagedriver=overlay
  └ Error: (none)
  └ UpdatedAt: 2016-03-12T11:54:33Z
 chris-coreos-swarm-back2.novalocal: 10.0.1.14:2375
  └ Status: Healthy
  └ Containers: 1
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 2.056 GiB
  └ Labels: executiondriver=native-0.2, kernelversion=4.4.1-coreos, kind=backend, operatingsystem=CoreOS 960.0.0 (Coeur Rouge), storagedriver=overlay
  └ Error: (none)
  └ UpdatedAt: 2016-03-12T11:54:05Z
 chris-coreos-swarm-front0.novalocal: 10.0.1.12:2375
  └ Status: Healthy
  └ Containers: 2
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 2.056 GiB
  └ Labels: executiondriver=native-0.2, kernelversion=4.4.1-coreos, kind=frontend, operatingsystem=CoreOS 960.0.0 (Coeur Rouge), storagedriver=overlay
  └ Error: (none)
  └ UpdatedAt: 2016-03-12T11:54:41Z
Plugins:
 Volume:
 Network:
Kernel Version: 4.4.1-coreos
Operating System: linux
Architecture: amd64
CPUs: 4
Total Memory: 8.225 GiB
Name: a872262f4693
```

Please have a look at the [swarm](https://docs.docker.com/swarm/) and [etcd2](https://coreos.com/etcd/docs/latest/) documentation for further information.
