use strict;
use Test::More;

BEGIN
{
    if (! $ENV{ MEMCACHED_SERVER } ) {
        plan(skip_all => "Define MEMCACHED_SERVER (e.g. localhost:11211) to run this test");
    } else {
        plan(tests => 6);
    }
    use_ok("Cache::Memcached::libmemcached");
}

my $cache = Cache::Memcached::libmemcached->new( {
    servers => [ $ENV{ MEMCACHED_SERVER } ],
    namespace => join('_', 'Cache::Memcached::libmemcached', 'test', rand(), $$)
} );
isa_ok($cache, "Cache::Memcached::libmemcached");


{
    my $key = 'foo';

    {
        $cache->set($key, 0);
        is( $cache->get($key), 0, "value is 0 initially");
    }

    {
        my $rv = $cache->incr($key);
        is( $rv, 1, "return value is $rv");
    }

    {
        my $rv = $cache->incr($key);
        is( $rv, 2, "return value is $rv");
    }

    {
        my $rv = $cache->decr($key);
        is( $rv, 1, "return value is $rv");
    }
}
