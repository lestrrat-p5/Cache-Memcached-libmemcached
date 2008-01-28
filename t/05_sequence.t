use strict;
use Test::More;

BEGIN
{
    if (! $ENV{ MEMCACHED_SERVER } ) {
        plan(skip_all => "Define MEMCACHED_SERVER (e.g. localhost:11211) to run this test");
    } else {
        plan(tests => 23);
    }
    use_ok("Cache::Memcached::libmemcached");
}

my $cache = Cache::Memcached::libmemcached->new( {
    servers => [ $ENV{ MEMCACHED_SERVER } ]
} );
isa_ok($cache, "Cache::Memcached::libmemcached");

{
    $cache->set("num", 0);

    for my $i (1..10) {
        my $num = $cache->incr("num");
        is($num, $i);
    }
}

{
    $cache->remove("num");
    ok( ! $cache->incr("num") );
}

{
    $cache->set("num", 10);

    for my $i (reverse (1..9) ){
        my $num = $cache->decr("num");
        is($num, $i);
    }
}

{
    $cache->remove("num");
    ok( ! $cache->decr("num") );
}
