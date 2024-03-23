local node = import 'node.libsonnet';

{
  services: node('node0') + node('node1'),
}
