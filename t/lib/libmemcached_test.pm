package libmemcached_test;

use strict;
use warnings;
use base 'Exporter';

use Cache::Memcached::libmemcached;
use Test::More;

our @EXPORT = qw(
    libmemcached_test_create
    libmemcached_test_key
    libmemcached_version_ge
    libmemcached_test_servers
);

sub libmemcached_test_servers {
    my $servers = $ENV{PERL_LIBMEMCACHED_TEST_SERVERS};
    # XXX add the default port as well to stop uninit
    # warnings from the test suite
    $servers ||= 'localhost:11211';
    return split(/\s*,\s*/, $servers);
}


sub libmemcached_test_create {
    my ($args) = @_;

    $args->{ servers } = [ libmemcached_test_servers() ];

    if ($ENV{LIBMEMCACHED_BINARY_PROTOCOL}) {
        $args->{binary_protocol} = 1;
    }

    my $cache = Cache::Memcached::libmemcached->new($args);
    my $time  = time();
    $cache->set( foo => $time );
    my $value = $cache->get( 'foo' );

    plan skip_all => "Can't talk to any memcached servers"
        if (! defined $value || $time ne $value);

#    plan skip_all => "memcached server version less than $args->{min_version}"
#        if $args->{min_version}
#        && not libmemcached_version_ge($memc, $args->{min_version});

    return $cache;
}

#sub libmemcached_version_ge {
#    my ($memc, $min_version) = @_;
#    my $numify = sub {
#        my $version = shift;
#        my @version = split /\./, $version;
#        return $version[0] + $version[1] / 100 + $version[2] / 100_000;
#    };
#
#    my @memcached_version = memcached_version($memc);
#
#    $min_version = $numify->( $min_version );
#    foreach my $version (map { $numify->($_) } @memcached_version) {
#        return 1 if $version >= $min_version;
#        return 0 if $version <  $min_version;
#    }
#    return 1; # identical versions
#}


sub libmemcached_test_key {
    # return a value suitable for use as a memcached key
    # that is unique for each run of the script
    # but returns the same value for the life of the script
    our $time_rand ||= ($^T + rand());
    return $time_rand;
}

1;
