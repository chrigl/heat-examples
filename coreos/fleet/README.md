# Setting up a fleet cluster

Booting a CoreOS fleet cluster in OpenStack, using [Heat Orchestration Templates](http://docs.openstack.org/developer/heat/template_guide/hot_guide.html). Default setup consists of 1 frontend and 3 backend nodes. Containers should be scheduled to the backend nodes, loadbalancer (or basically everything that has to be accessable from the outside) on the frontend nodes.

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
$ heat stack-create -f coreos-stack.yaml -e coreos-env.yaml -P discovery_url=(curl "https://discovery.etcd.io/new?size=3") my-coreos-stack
```

Network and instances should be created.

```
> nova list
+--------------------------------------+--------------------------+---------+------------+-------------+-----------------------------------------------------------+
| ID                                   | Name                     | Status  | Task State | Power State | Networks                                                  |
+--------------------------------------+--------------------------+---------+------------+-------------+-----------------------------------------------------------+
| e63359d3-f44b-4ec3-9dd1-23ab64276d2d | my-coreos-stack-back0    | ACTIVE  | -          | Running     | coreos-network-my-coreos-stack=10.0.1.13                  |
| 044d82e4-e33a-4ece-af91-57a9fd21cd8b | my-coreos-stack-back1    | ACTIVE  | -          | Running     | coreos-network-my-coreos-stack=10.0.1.12                  |
| d0fbd037-991a-43aa-905b-8f6af70ce99c | my-coreos-stack-back2    | ACTIVE  | -          | Running     | coreos-network-my-coreos-stack=10.0.1.14                  |
| dd9ed1d0-d5d1-4abf-a9be-e89423e70884 | my-coreos-stack-front0   | ACTIVE  | -          | Running     | coreos-network-my-coreos-stack=10.0.1.11, 1.247.85.135    |
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

The default configuration creates an ```etcd2``` and a ```fleet``` cluster. So, you should see the ```fleet nodes``` and their meta data:

```
core@STACK_NAME-front0 ~ $ fleetctl list-machines
MACHINE         IP              METADATA
044d82e4...     10.0.1.12       kind=backend
d0fbd037...     10.0.1.14       kind=backend
dd9ed1d0...     10.0.1.11       kind=frontend,public_ipv4=1.247.85.135
e63359d3...     10.0.1.13       kind=backend
[…]
```

Please have a look at the [fleet](https://coreos.com/fleet/docs/latest/) and [etcd2](https://coreos.com/etcd/docs/latest/) documentation for further information.
