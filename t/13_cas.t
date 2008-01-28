use strict;
use Test::More;

plan(skip_all => "cas() unimplemented");
#BEGIN
#{
#    eval "use Cache::Memcached";
#    if ($@) {
#        plan( skip_all => "Cache::Memcached not available" );
#    } elsif (! $ENV{ MEMCACHED_SERVER } ) {
#        plan(skip_all => "Define MEMCACHED_SERVER (e.g. localhost:11211) to run this test");
#    } else {
#        plan(tests => 7);
#    }
#    use_ok("Cache::Memcached::libmemcached");
#}
#
#my $cache = Cache::Memcached::libmemcached->new( {
#    servers => [ $ENV{ MEMCACHED_SERVER } ],
#    support_cas => 1,
#} );
#
#isa_ok($cache, "Cache::Memcached::libmemcached");
#
## XXX The stats() method is half baked, and you should NOT be using it 
## in your code! DON'T TRUST THIS CODE!
#
#my $cm = Cache::Memcached->new( {
#    servers => [ $ENV{ MEMCACHED_SERVER } ],
#} );
#my $h = $cm->stats();
#my $version = $h->{hosts}->{ $ENV{ MEMCACHED_SERVER } }->{misc}->{version};
#my ($major, $minor, $micro) = split(/\./, $version);
#my $numified = $major + $minor / 1_000 + $micro / 1_000_000;
#
#SKIP: {
#    if ($numified < 1.002004) {
#        skip("Remote memcached version is $version, need at least 1.2.4 to run this test", 1);
#    }
#
#    my @keys = ('a' .. 'z');
#    $cache->set($_, $_) for @keys;
#    my $cas = $cache->get_cas('a');
#    ok($cas);
#
#    my $h = $cache->get_cas_multi(@keys);
#    ok($h);
#    isa_ok($h, 'HASH');
#
#    is($h->{a}, $cas);
#
#    TODO: {
#        local $TODO = "cas() unconfirmed";
#        my $newvalue = 'this used to be a';
#        $cache->cas('a', $cas, $newvalue);
#        is($cache->get('a'), $newvalue);
#    }
#}