use strict;
use Test::More;

BEGIN
{
    if (! $ENV{ MEMCACHED_SERVER } ) {
        plan(skip_all => "Define MEMCACHED_SERVER (e.g. localhost:11211) to run this test");
    } else {
        plan(tests => 3);
    }
    use_ok("Cache::Memcached::LibMemcached");
}

my $cache = Cache::Memcached::LibMemcached->new( {
    servers => [ $ENV{ MEMCACHED_SERVER } ],
    compress_threshold => 1_000
} );
isa_ok($cache, "Cache::Memcached::LibMemcached");


{
    my $data = "1" x 5_000;
    $cache->set("foo", $data, 30);
    my $val = $cache->get("foo");
    is($val, $data, "simple value");
}