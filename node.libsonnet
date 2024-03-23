function(name)
  {
    [name]: {
      command: [
        'sleep',
        'inf',
      ],
      hostname: '%s' % name,
      image: 'docker.io/alpine:latest',
    },
    ['%s-haproxy' % name]: {
      image: 'docker.io/haproxy:2.9',
      network_mode: 'service:%s' % name,
      pid: 'service:%s' % name,
      volumes: [
        './haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg',
      ],
    },
    ['%s-vrrpd' % name]: {
      build: {
        context: '.',
      },
      environment: {
        KEEPALIVED_STATE: 'MASTER',
      },
      image: 'keepalived',
      network_mode: 'service:%s' % name,
      pid: 'service:%s' % name,
      privileged: true,
      volumes: [
        './keepalived.conf:/config/keepalived.conf',
      ],
    },
    ['%s-whoami' % name]: {
      environment: {
        WHOAMI_PORT_NUMBER: 5000,
      },
      image: 'docker.io/traefik/whoami',
      network_mode: 'service:%s' % name,
      pid: 'service:%s' % name,
    },
  }
