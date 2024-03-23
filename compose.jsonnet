local node = import 'node.libsonnet';
local keepalived_vip = '100.64.64.100';
local keepalived_interface = 'eth1';

{
  services:
    node('node0', keepalived_vip, keepalived_interface='eth1', keepalived_state='MASTER') +
    node('node1', keepalived_vip, keepalived_interface='eth1'),
  networks: {
    private: {},
    public: {
      ipam: {
        driver: 'default',
        config: [
          {
            subnet: '100.64.64.0/24',
            ip_range: '100.64.64.0/28',
          },
        ],
      },
    },
  },
}
