use strict;
use Test::More (tests => 2);

use_ok("Cache::Memcached::libmemcached");
can_ok("Cache::Memcached::libmemcached", (
    qw(new get get_multi set stats disconnect_all set_servers flush_all),
    qw(is_no_block set_no_block get_distribution_method set_distribution_method get_hashing_algorithm set_hashing_algorithm),
) );