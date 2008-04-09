use strict;
use Test::More;

BEGIN
{
    if (! $ENV{ MEMCACHED_SERVER } ) {
        plan(skip_all => "Define MEMCACHED_SERVER (e.g. localhost:11211) to run this test");
    } else {
        eval "use Cache::Memcached";
        if ($@) {
            plan(skip_all => "Cache::Memcached not installed: $@");
        } else {
            plan(tests => 2);
        }
    }
    use_ok("Cache::Memcached::libmemcached");
}

my $cache = Cache::Memcached::libmemcached->new( {
    servers => [ $ENV{ MEMCACHED_SERVER } ]
});

{
    my $h1 = $cache->stats();
    ok( exists $h1->{hosts}{ $ENV{ MEMCACHED_SERVER } }{misc}, "misc for $ENV{MEMCACHED_SERVER} key exists");
}