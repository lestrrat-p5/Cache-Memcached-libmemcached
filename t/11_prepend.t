use strict;
use lib 't/lib';
use libmemcached_test;
use Test::More;

eval "use Cache::Memcached";
if ($@) {
    plan( skip_all => "Cache::Memcached not available" );
}

my $cache = libmemcached_test_create();
plan tests => 2;

isa_ok($cache, "Cache::Memcached::libmemcached");

my $cm = Cache::Memcached->new( {
    servers => [ libmemcached_test_servers() ]
} );

my $h = $cm->stats();
my $version = $cache->version();
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