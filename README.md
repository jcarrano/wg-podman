# Example initscripts for Podman and Wireguard

This is simple example of how to set up a rootless Podman container with
Wireguard-only connectivity, without user-space networking (i.e. without
slirp).

It is written as a couple of OpenRC init scripts.

## Requirements

- OpenRC
- Podman
- iproute2
- Wireguard
- jq

Optionally, `su-exec` can replace su.

## How it works

### 1 Create pod

Unfortunately, the choices of networking setups when creating a rootless container
are limited. We can work around it by creating the a pod first and then
setting up the networking as root.

The first init script (`userpodman`) starts a pod as a user with `--network=none`.
Podman will create an empty network namespace (with only a loopback interface).

### 2 Attach namespace

The namespace is accessible using the PID of the pod's "infra" process. This is
why we use a pod, so that the infra keeps the namespace associated with the pod
while we add or remove containers.

The NS is attached (i.e. given a name) using `ip netns attach`.

### 3 Create WG interface

The second init script (`podwg`) creates a wireguard interface, moves it to the namespace,
and configures it.

Now processes running in the Pod can only communicate through the Wireguard tunnel.
They can also bind to privileged ports on this interface.

## Configuration

The scripts use OpenRC Multi-service functionality. Configuration is in /etc/config.d.

You should create two services by symlinking to the base init scripts:

```sh
cd /etc/init.d
ln -s userpodman userpodman.myservice
ln -s podwg podwg.myservice
```

Those scripts will take the configuration variables from `userpodman.myservice` and `podwg.myservice`,
in the /etc/conf.d but since those have some variables in common, it is better to have only one
actual file and one symlink.

```sh
cd /etc/conf.d
nano userpodman.myservice
ln -s userpodman.myservice podwg.myservice
```

## Other

Also included is a couple of scripts to automate creating WG configs and new users/peers.

### Important note regarding security when using the scripts

The user-add script will create a public/private key pair. The private key is bundled with the server's
public key in a wireguard config file which you are supposed to send to the user. This is sub-optimal from
a security point of view and the best thing would be if the user's private key never leaves their computer.

In an ideal world, the user would send the public key to the server admin over an authenticated (not
necessarily private) channel. Unfortunately, this is not easy to do for non tech-savy users with the command
line tools. I have made a tool for users to create their own key pairs: https://github.com/jcarrano/wg-keygen-notrust

## To do

The WG config-creation scripts leave much to be desired.

The init script should probably use `su-exec` instead of `su`.
