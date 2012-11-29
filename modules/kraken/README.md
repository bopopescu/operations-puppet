# WMF Kraken Analytics Puppet Module

See: [Kraken Analytics Cluster](https://www.mediawiki.org/wiki/Analytics/Kraken).

The kraken module contains site specific configurations for
the WMF Analytics Kraken cluster.  Each file contains classes for
configuring different pieces of a specific service.  For example,
In order to set up a new Hadoop worker node:

```puppet
node new_worker {
  include kraken::hadoop::worker
}
```

See also operations-puppet/manifests/role/analytics.pp for logical groupings of
different services.


