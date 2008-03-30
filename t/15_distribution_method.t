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

    is( $cache->get_distribution_method,
        Memcached::libmemcached::MEMCACHED_DISTRIBUTION_MODULA );

    $cache->set_distribution_method(Memcached::libmemcached::MEMCACHED_DISTRIBUTION_CONSISTENT);
    is( $cache->get_distribution_method,
        Memcached::libmemcached::MEMCACHED_DISTRIBUTION_CONSISTENT );

    my $value = "non-block via accessor";
    $cache->remove(__FILE__);
    $cache->set(__FILE__, $value);

    is($cache->get(__FILE__), $value);
}

{
    my $cache = Cache::Memcached::libmemcached->new( {
        servers => [ $ENV{ MEMCACHED_SERVER } ],
        distribution_method => Memcached::libmemcached::MEMCACHED_DISTRIBUTION_CONSISTENT(),
    } );
    isa_ok($cache, "Cache::Memcached::libmemcached");

    is( $cache->get_distribution_method,
        Memcached::libmemcached::MEMCACHED_DISTRIBUTION_CONSISTENT );

    $cache->set_distribution_method(Memcached::libmemcached::MEMCACHED_DISTRIBUTION_MODULA);
    is( $cache->get_distribution_method,
        Memcached::libmemcached::MEMCACHED_DISTRIBUTION_MODULA );

    my $value = "non-block via constructor";
    $cache->remove(__FILE__);
    $cache->set(__FILE__, $value);

    is($cache->get(__FILE__), $value);
}

