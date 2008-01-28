use strict;
use Test::More (tests => 2);

use_ok("Cache::Memcached::libmemcached");
can_ok("Cache::Memcached::libmemcached", 
    qw(new get get_multi set stats disconnect_all set_servers));