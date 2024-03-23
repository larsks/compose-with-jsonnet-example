Configure an environment for testing haproxy and keepalived. Inspired by [this question on servfault.com][question].

[question]: https://serverfault.com/questions/1156761/haproxy-with-keepalived-not-behaving-as-expected

## Usage

To bring up this environment, run:

```
docker compose up
```

## Architecture

This environment brings up two "nodes". Each node consists of several containers:

- `node<N>` -- this container configures the network namespace for the node. All the other containers in the node share this network namespace.
- `node<N>-haproxy` -- This runs `haproxy`.
- `node<N>-vrrpd` -- This runs `keepalived`. The container is privileged because it needs to configure the vip on the public interface.
- `node<N>-whoami` -- `whoami` is a simple web service. This is the backend for the haproxy frontend.

Each node is connected to two networks; the "private" network, which uses an address range configured by Docker, and the "public" network, which uses `100.64.64.0/24`. The vip managed by keepalived is `100.64.64.100`.

## Failover

### Failure of the backend

At startup, one of the nodes will hold the public vip. Assuming that `node1` has the vip, we see:

```
$ curl 100.64.64.100
Hostname: node1
IP: 127.0.0.1
IP: ::1
IP: 100.64.64.2
IP: 100.64.64.100
IP: fe80::42:64ff:fe40:4002
IP: 172.25.0.3
IP: fe80::42:acff:fe19:3
RemoteAddr: 172.25.0.3:49594
GET / HTTP/1.1
Host: 100.64.64.100
User-Agent: curl/8.0.1
Accept: */*
Connection: close
X-Forwarded-For: 100.64.64.1
```

If we stop the `node1-whoami` container:

```
docker compose stop node1-whoami
```

Then haproxy will notice the backend failure and start directing requests to node0:

```
node1-haproxy-1  | [WARNING]  (34) : Server app_servers/haproxy-02 is DOWN, reason: Layer4 connection problem, info: "Connection refused", check duration: 0ms. 0 active and 1 backup servers left. Running on backup. 0 sessions active, 0 requeued, 0 remaining in queue.
```

After a few seconds, we will see:

```
$ curl 100.64.64.100
Hostname: node0
IP: 127.0.0.1
IP: ::1
IP: 172.25.0.2
IP: fe80::42:acff:fe19:2
IP: 100.64.64.3
IP: fe80::42:64ff:fe40:4003
RemoteAddr: 172.25.0.3:54552
GET / HTTP/1.1
Host: 100.64.64.100
User-Agent: curl/8.0.1
Accept: */*
Connection: close
X-Forwarded-For: 100.64.64.1
```

If we bring the backend back up:

```
docker compose up -d node1-whoami
```

Then haproxy will start directing traffic back to the preferred backend:

```
node1-haproxy-1  | Server app_servers/haproxy-02 is UP, reason: Layer4 check passed, check duration: 0ms. 1 active and 1 backup servers online. 0 sessions requeued, 0 total in queue.
```

### Failure of haproxy

If we stop the haproxy container for the node that currently holds the vip:

```
docker compose stop node1-haproxy
```

Then keepalived will notice the failure and the public vip will move to the other node:

```
node1-vrrpd-1    | Sat Mar 23 10:49:22 2024: Script `chk_haproxy` now returning 1
node1-vrrpd-1    | Sat Mar 23 10:49:22 2024: VRRP_Script(chk_haproxy) failed (exited with status 1)
node1-vrrpd-1    | Sat Mar 23 10:49:22 2024: (VI_1) Changing effective priority from 103 to 101
node0-vrrpd-1    | Sat Mar 23 10:49:23 2024: (VI_1) received lower priority (101) advert from 100.64.64.2 - discarding
node0-vrrpd-1    | Sat Mar 23 10:49:24 2024: (VI_1) received lower priority (101) advert from 100.64.64.2 - discarding
node0-vrrpd-1    | Sat Mar 23 10:49:25 2024: (VI_1) received lower priority (101) advert from 100.64.64.2 - discarding
node0-vrrpd-1    | Sat Mar 23 10:49:25 2024: (VI_1) Entering MASTER STATE
node1-vrrpd-1    | Sat Mar 23 10:49:25 2024: (VI_1) Master received advert from 100.64.64.3 with higher priority 103, ours 101
node1-vrrpd-1    | Sat Mar 23 10:49:25 2024: (VI_1) Entering BACKUP STATE
```

If we bring haproxy back up:

```
docker compose up -d node1-haproxy
```

Then keepalived will note the change but will *not* move the public vip until there is a failure on node0:

```
node1-vrrpd-1    | Sat Mar 23 10:50:44 2024: Script `chk_haproxy` now returning 0
node1-vrrpd-1    | Sat Mar 23 10:50:44 2024: VRRP_Script(chk_haproxy) succeeded
node1-vrrpd-1    | Sat Mar 23 10:50:44 2024: (VI_1) Changing effective priority from 101 to 103
```

## Building

To generate `compose.yaml` after making changes to `compose.jsonnet` or `node.libsonnet` you will need `make` and [`jsonnet`][jsonnet].

[jsonnet]: https://jsonnet.org/


## Running tests

The tests are written using [pytest] so you will need a functioning Python environment.

```
pip install pipenv
pipenv install
pipenv run pytest
```

[pytest]: https://docs.pytest.org
