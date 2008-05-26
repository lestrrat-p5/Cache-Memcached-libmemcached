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

    is( $cache->get_hashing_algorithm,
        Memcached::libmemcached::MEMCACHED_HASH_DEFAULT );

    $cache->set_hashing_algorithm(Memcached::libmemcached::MEMCACHED_HASH_MD5);
    is( $cache->get_hashing_algorithm,
        Memcached::libmemcached::MEMCACHED_HASH_MD5 );

    my $value = "non-block via accessor";
    $cache->remove(__FILE__);
    $cache->set(__FILE__, $value);

    is($cache->get(__FILE__), $value);
}

{
    my $cache = Cache::Memcached::libmemcached->new( {
        servers => [ $ENV{ MEMCACHED_SERVER } ],
        hashing_algorithm => Memcached::libmemcached::MEMCACHED_HASH_MD5(),
    } );
    isa_ok($cache, "Cache::Memcached::libmemcached");

    is( $cache->get_hashing_algorithm,
        Memcached::libmemcached::MEMCACHED_HASH_MD5 );

    $cache->set_hashing_algorithm(Memcached::libmemcached::MEMCACHED_HASH_DEFAULT);
    is( $cache->get_hashing_algorithm,
        Memcached::libmemcached::MEMCACHED_HASH_DEFAULT );

    my $value = "non-block via constructor";
    $cache->remove(__FILE__);
    $cache->set(__FILE__, $value);

    is($cache->get(__FILE__), $value);
}

