use strict;
use Test::More;

BEGIN
{
    if (! $ENV{ MEMCACHED_SERVER } ) {
        plan(skip_all => "Define MEMCACHED_SERVER (e.g. localhost:11211) to run this test");
    } else {
        plan(tests => 8);
    }
    use_ok("Cache::Memcached::LibMemcached");
}

my $cache = Cache::Memcached::LibMemcached->new( {
    servers => [ $ENV{ MEMCACHED_SERVER } ]
} );
isa_ok($cache, "Cache::Memcached::LibMemcached");

my @keys = ('a' .. 'z');
foreach my $key (@keys) {
    $cache->set($key, $key);
}

my $h = $cache->get_multi(@keys);
ok($h);
isa_ok($h, 'HASH');

my %expected = map { ($_ => $_) } @keys;
is_deeply( $h, \%expected, "got all the expected values");

$cache->flush_all;
$h = $cache->get_multi(@keys);
ok($h);
isa_ok($h, 'HASH');

is(scalar keys %$h, 0);
