use strict;
use Test::More;

BEGIN
{
    eval "use Cache::Memcached";
    if ($@) {
        plan( skip_all => "Cache::Memcached not available" );
    } elsif (! $ENV{ MEMCACHED_SERVER } ) {
        plan(skip_all => "Define MEMCACHED_SERVER (e.g. localhost:11211) to run this test");
    } else {
        plan(tests => 3);
    }
    use_ok("Cache::Memcached::LibMemcached");
}

my $memcached = Cache::Memcached->new({
    servers => [ $ENV{ MEMCACHED_SERVER } ],
    compress_threshold => 1_000
});
my $libmemcached = Cache::Memcached::LibMemcached->new( {
    servers => [ $ENV{ MEMCACHED_SERVER } ],
    compress_threshold => 1_000
} );

{
    my $data = "1" x 10_000;

    eval {
        $memcached->set("foo", $data);
        is( $libmemcached->get("foo"), $data, "set via Cache::Memcached, retrieve via Cache::Memcached::LibMemcached");
    };

    eval {
        $libmemcached->set("foo", $data);
        is( $memcached->get("foo"), $data, "set via Cache::Memcached::LibMemcached, retrieve via Cache::Memcached");
    };
}

