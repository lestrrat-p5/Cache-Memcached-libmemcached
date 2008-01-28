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
    use_ok("Cache::Memcached::libmemcached");
}

my $cache = Cache::Memcached::libmemcached->new( {
    servers => [ $ENV{ MEMCACHED_SERVER } ]
} );
isa_ok($cache, "Cache::Memcached::libmemcached");

my $cm = Cache::Memcached->new( {
    servers => [ $ENV{ MEMCACHED_SERVER } ]
} );

my $h = $cm->stats();
my $version = $h->{hosts}->{ $ENV{ MEMCACHED_SERVER } }->{misc}->{version};
my ($major, $minor, $micro) = split(/\./, $version);
my $numified = $major + $minor / 1_000 + $micro / 1_000_000;

SKIP: {
    if ($numified < 1.002004) {
        skip("Remote memcached version is $version, need at least 1.2.4 to run this test", 1);
    }

    $cache->set("foo", "abc");
    $cache->prepend("foo", "0123");
    is($cache->get("foo"), "0123abc");
}