use strict;
use Test::More (skip_all => 'stat() is not implemented');

#BEGIN
#{
#    if (! $ENV{ MEMCACHED_SERVER } ) {
#        plan(skip_all => "Define MEMCACHED_SERVER (e.g. localhost:11211) to run this test");
#    } else {
#        eval "use Cache::Memcached";
#        if ($@) {
#            plan(skip_all => "Cache::Memcached not installed: $@");
#        } else {
#            plan(tests => 2);
#        }
#    }
#    use_ok("Cache::Memcached::LibMemcached");
#}
#
#my $cache = Cache::Memcached::LibMemcached->new( {
#    servers => [ $ENV{ MEMCACHED_SERVER } ]
#});
#my $vanilla = Cache::Memcached->new( {
#    servers => [ $ENV{ MEMCACHED_SERVER } ]
#} );
#
#{
#    my $h1 = $cache->stats();
#    my $h2 = $vanilla->stats();
#
#    is_deeply($h1, $h2);
#}