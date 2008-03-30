use strict;
use Test::More;

BEGIN
{
    if (! $ENV{ MEMCACHED_SERVER } ) {
        plan(skip_all => "Define MEMCACHED_SERVER (e.g. localhost:11211) to run this test");
    } else {
        plan(tests => 9);
    }
    use_ok("Cache::Memcached::libmemcached");
}

{
    my $cache = Cache::Memcached::libmemcached->new( {
        servers => [ $ENV{ MEMCACHED_SERVER } ]
    } );
    isa_ok($cache, "Cache::Memcached::libmemcached");

    ok( ! $cache->is_no_block );

    $cache->set_no_block(1);
    ok( $cache->is_no_block );

    my $value = "non-block via accessor";
    $cache->remove(__FILE__);
    $cache->set(__FILE__, $value);

    is($cache->get(__FILE__), $value);
}

{
    my $cache = Cache::Memcached::libmemcached->new( {
        servers => [ $ENV{ MEMCACHED_SERVER } ],
        no_block => 1,
    } );
    isa_ok($cache, "Cache::Memcached::libmemcached");

    ok( $cache->is_no_block );

    $cache->set_no_block(0);
    ok( !$cache->is_no_block );

    my $value = "non-block via constructor";
    $cache->remove(__FILE__);
    $cache->set(__FILE__, $value);

    is($cache->get(__FILE__), $value);
}

