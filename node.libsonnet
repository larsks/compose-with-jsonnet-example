local partof(name) = {
  network_mode: 'service:%s' % name,
  pid: 'service:%s' % name,
};

function(name, keepalived_vip, keepalived_interface='eth0', keepalived_state='BACKUP')
  {
    [name]: {
      command: [
        'sleep',
        'inf',
      ],
      hostname: '%s' % name,
      image: 'docker.io/alpine:latest',
      networks: [
        'private',
        'public',
      ],
    },
    ['%s-haproxy' % name]: {
      image: 'docker.io/haproxy:2.9',
      volumes: [
        './%s/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg' % name,
      ],
    } + partof(name),
    ['%s-vrrpd' % name]: {
      build: {
        context: '.',
      },
      image: 'keepalived',
      privileged: true,
      environment: {
        KEEPALIVED_VIP: keepalived_vip,
        KEEPALIVED_INTERFACE: keepalived_interface,
        KEEPALIVED_STATE: keepalived_state,
      },
      volumes: [
        './keepalived.conf:/config/keepalived.conf',
      ],
    } + partof(name),
    ['%s-whoami' % name]: {
      environment: {
        WHOAMI_PORT_NUMBER: 5000,
      },
      image: 'docker.io/traefik/whoami',
    } + partof(name),
  }
