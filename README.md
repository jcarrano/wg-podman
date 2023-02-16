# Example init-scripts for Podman and Wireguard

This is a simple example of how to set up a rootless Podman container with
Wireguard-only connectivity, without user-space networking (i.e. without
`slirp`).

It is implemented as a pair of OpenRC init scripts.

## Requirements

- OpenRC
- Podman
- iproute2
- Wireguard
- jq

Optionally, `su-exec` can replace su.

## Quickstart

The scripts use OpenRC Multi-service functionality. Configuration is in /etc/config.d.

First you should create a podman pod as a normal user. The pod networking must be
set to `none`. You must tell podman to create a pidfile at
`/home/<podusr>/<podname>.pid`. Example:

```sh
podman pod create --network=none --infra-conmon-pidfile=/home/<podusr>/<podname>.pid --name <podname>
```

Replace `<podusr>` and `<podname>` with the real user and pod names. Populate
the pod with containers (this can be done at any time).

Then create two services by symlinking to the base init scripts:

```sh
cd /etc/init.d
ln -s userpodman userpodman.myservice
ln -s podwg podwg.myservice
```

The service name `<myservice>` is arbitrary but must match for both services.

Those scripts will take the configuration variables from `/etc/conf.d/{userpodman.myservice, podwg.myservice}`
respectively but since those have some variables in common, it is better to have only one
actual file and symlink the other:

```sh
cd /etc/conf.d
nano userpodman.myservice # fill in the variables, see example
ln -s userpodman.myservice podwg.myservice
```

Finally, add `podwg.myservice` to the default runlevel.

## How it works

### 1 Create pod

Unfortunately, the choices of networking setups when creating a rootless container
are limited. We can work around it by creating the a pod first and then
setting up the networking as root.

The first init script (`userpodman`) starts a pod (as a regular user) which has
`--network=none`. Podman will create an empty network namespace (with only a
loopback interface).

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

## Shared mounts and rootless podman.

If you are using Alpine Linux or any other distros that do not mount root as a
shared mount by default, you will experience problems when trying to run a rootless
podman instance. See the following issues:

- https://gitlab.alpinelinux.org/alpine/tsc/-/issues/42
- https://github.com/OpenRC/openrc/issues/525

The workaround provided here is an additional init script `mount-rshared` which shares
the mount and is depended on by the userpodman script.

## Other

Also included is a couple of scripts to automate creating WG configs and new users/peers. Modify
the scripts as you see fit.

### wg_server_init

```
wg_server_init <wgconf> <server_ip> <server_fqdn>
```

Create a new server configuration file. The IP refers to the IP on the VPN. The FQDN and IP are not
used by wireguard itself but are needed for the other scripts.

### wg_newuser

```
wg_newuser <wgconf> <client_conf>
```

Creates a new user, Adds the user to the server config file and creates a client configuration with
a PRIVATE key that must be PRIVATELY sent to the user. See the "note regarding security" below.

### wg_importuser

```
wg_importuser <wgconf> <client_frag> [<client_name>]
```

Import a client fragment created with the [Wireguard Key Generator](https://github.com/jcarrano/wg-keygen-notrust)
tool. This is a safer alternative to wg_newuser, since only the PUBLIC key needs to be transmitted.

### wg_getlink

```
wg_getlink <wgconf> [<client_name>]
```

Generate a hyperlink for use with the [Wireguard Key Generator](https://github.com/jcarrano/wg-keygen-notrust). Upon
opening the link, the fields will be populated with the right parameters.

### Important note regarding security

The user-add script will create a public/private key pair. The private key is bundled with the server's
public key in a wireguard config file which you are supposed to send to the user. This is sub-optimal from
a security point of view and the best thing would be if the user's private key never leaves their computer.

If the user generates their own key pair they only send the public key to the server admin over an
authenticated (not necessarily private) channel. This is not easy to do for non tech-savy users using the
command line but the [Wireguard Key Generator](https://github.com/jcarrano/wg-keygen-notrust) was created to
solve that issue.

## To do

- The WG config-creation scripts leave much to be desired.
- The init script should probably use `su-exec` instead of `su`.
- Add administrator email field so that wg_getlink can populate that field.
