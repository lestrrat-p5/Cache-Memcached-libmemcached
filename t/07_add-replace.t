use strict;
use Test::More;

BEGIN
{
    if (! $ENV{ MEMCACHED_SERVER } ) {
        plan(skip_all => "Define MEMCACHED_SERVER (e.g. localhost:11211) to run this test");
    } else {
        plan(tests => 7);
    }
    use_ok("Cache::Memcached::LibMemcached");
}

my $cache = Cache::Memcached::LibMemcached->new( {
    servers => [ $ENV{ MEMCACHED_SERVER } ]
} );
isa_ok($cache, "Cache::Memcached::LibMemcached");

{
    $cache->set("foo", "bar");
    my $val = $cache->get("foo");
    is($val, "bar", "simple value");

    # add() shouldn't update
    $cache->add("foo", "baz");
    is( $cache->get("foo"), "bar", "simple value shouldn't have changed via add()");

    # replace() should update
    $cache->replace("foo", "baz");
    is( $cache->get("foo"), "baz", "simple value should have changed via replace()");

    $cache->delete("foo");

    # add() should update
    $cache->add("foo", "bar", 300);
    is( $cache->get("foo"), "bar", "simple value should have changed via add()");

    $cache->delete("foo");

    # replace() shouldn't update
    $cache->replace("foo", "baz");
    is( $cache->get("foo"), undef, "keys that don't exist on the server shouldn't have changed via replace()");
}