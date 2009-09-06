
package Cache::Memcached::libmemcached;
use strict;
use warnings;
use base qw(Memcached::libmemcached);
use Carp qw(croak);
use Scalar::Util qw(weaken);
use Storable ();

our $VERSION = '0.02010';

use constant HAVE_ZLIB    => eval { require Compress::Zlib } && !$@;
use constant F_STORABLE   => 1;
use constant F_COMPRESS   => 2;
use constant OPTIMIZE     => $ENV{PERL_LIBMEMCACHED_OPTIMIZE} ? 1 : 0;

BEGIN
{
    # Make sure to load bytes.pm if HAVE_ZLIB is enabled
    if (HAVE_ZLIB) {
        require bytes;
    }

    # accessors
    foreach my $field qw(compress_enable compress_threshold compress_savings) {
        eval sprintf(<<"        EOSUB", $field, $field, $field, $field);
            sub set_%s { \$_[0]->{%s} = \$_[1] }
            sub get_%s { \$_[0]->{%s} }
        EOSUB
        die if $@;
    }

    if (OPTIMIZE) {
        # If the optimize flag is enabled, we do not support master key
        # generation, cause we really care about the speed.
        foreach my $method qw(get set add replace prepend append cas delete) {
            eval <<"            EOSUB";
                sub $method {
                    my \$self = shift;
                    my \$key  = shift;
                    if (\$self->{namespace}) {
                        \$key = "\$self->{namespace}\$key";
                    }
                    \$self->SUPER::memcached_${method}(\$key, \@_)
                }
            EOSUB
            die if $@;
        }
    } else {
        # Regular case.
        # Mental note. We only do this cause while we're faster than
        # Cache::Memcached::Fast, *even* when the above optimization isn't
        # toggled.
        foreach my $method qw(get set add replace prepend append cas delete) {
            eval <<"            EOSUB";
                sub $method { 
                    my \$self = shift;
                    my \$key  = shift;
                    my \$master_key;
                    if (ref \$key eq 'ARRAY') {
                        (\$master_key, \$key) = @\$key;
                    }

                    if (\$self->{namespace}) {
                        \$key = "\$self->{namespace}\$key";
                    }
                    if (\$master_key) {
                        \$self->SUPER::memcached_${method}_by_key(\$master_key, \$key, \@_);
                    } else {
                        \$self->SUPER::memcached_${method}(\$key, \@_);
                    }
                }
            EOSUB
            die if $@;
        }
    }
}

sub import
{
    my $class = shift;
    Memcached::libmemcached->export_to_level(1, undef, @_) ;
}

sub new
{
    my $class = shift;
    my $args  = shift || {};

    $args->{servers} || die "No servers specified";

    my $self = $class->SUPER::new();

    $self->{compress_threshold} = $args->{compress_threshold};
    $self->{compress_savingsS}   = $args->{compress_savings} || 0.20;
    $self->{compress_enable}    =
        exists $args->{compress_enable} ? $args->{compress_enable} : 1;

    # servers 
    $self->set_servers($args->{servers});

    # Set compression/serialization callbacks
    $self->set_callback_coderefs(
        # Closures so we have reference to $self
        $self->_mk_callbacks()
    );

    # behavior options
    foreach my $option qw(no_block hashing_algorithm distribution_method binary_protocol) {
        my $method = "set_$option";
        $self->$method( $args->{$option} ) if exists $args->{$option};
    }

    $self->{namespace} = $args->{namespace} || '';

    return $self;
}

sub set_servers
{
    my $self = shift;
    my $servers = shift || [];
    foreach my $server (@$servers) {
        $self->server_add($server);
    }
}

sub server_add
{
    my $self = shift;
    my $server = shift;

    if (! defined $server) {
        Carp::confess("server is not defined");
    }
    if ($server =~ /^([^:]+):([^:]+)$/) {
        my ($hostname, $port) = ($1, $2);
        $self->memcached_server_add($hostname, $port );
    } else {
        $self->memcached_server_add_unix_socket( $server );
    }
}

sub _mk_callbacks
{
    my $self = shift;

    weaken($self);
    my $inflate = sub {
        my ($key, $flags) = @_;
        if ($flags & F_COMPRESS) {
            if (! HAVE_ZLIB) {
                croak("Data for $key is compressed, but we have no Compress::Zlib");
            }
            $_ = Compress::Zlib::memGunzip($_);
        }

        if ($flags & F_STORABLE) {
            $_ = Storable::thaw($_);
        }
        return ();
    };

    my $deflate = sub {
        # Check if we have a complex structure
        if (ref $_) {
            $_ = Storable::nfreeze($_);
            $_[1] |= F_STORABLE;
        }

        # Check if we need compression
        if (HAVE_ZLIB && $self->{compress_enable} && $self->{compress_threshold}) {
            # Find the byte length
            my $length = bytes::length($_);
            if ($length > $self->{compress_threshold}) {
                my $tmp = Compress::Zlib::memGzip($_);
                if (1 - bytes::length($tmp) / $length < $self->{compress_savingsS}) {
                    $_ = $tmp;
                    $_[1] |= F_COMPRESS;
                }
            }
        }
        return ();
    };
    return ($deflate, $inflate);
}

sub incr
{
    my $self = shift;
    my $key  = shift;
    my $offset = shift || 1;
    if ($self->{namespace}) {
        $key = "$self->{namespace}$key";
    }
    my $val = 0;
    $self->memcached_increment($key, $offset, $val);
    return $val;
}

sub decr
{
    my $self = shift;
    my $key  = shift;
    my $offset = shift || 1;
    if ($self->{namespace}) {
        $key = "$self->{namespace}$key";
    }
    my $val = 0;
    $self->memcached_decrement($key, $offset, $val);
    return $val;
}

sub get_multi {
    my $self = shift;

    my $namespace = $self->{namespace};
    my @keys = $namespace ? map { "$namespace$_" } @_ : @_;
    my $hash = $self->SUPER::get_multi(@keys);
    return $namespace ? +{ map { ($_ => $hash->{"$namespace$_"}) } @_ } : $hash;
}

sub flush_all
{
    $_[0]->memcached_flush(0);
}

*remove = \&delete;

sub disconnect_all {
    $_[0]->memcached_quit();
}

sub version {
    $_[0]->memcached_version();
}

sub stats
{
    my %h;
    my %misc_keys = map { ($_ => 1) }
      qw/ bytes bytes_read bytes_written
          cmd_get cmd_set connection_structures curr_items
          get_hits get_misses
          total_connections total_items
        /; 
    my $code = sub {
        my($key, $value, $hostport, $type) = @_;

        # XXX - This is hardcoded in the callback cause r139 in perl-memcached
        # removed the magic of "misc"
        $type ||= 'misc';
        $h{hosts}{$hostport}{$type}{$key} = $value;
        if ($type eq 'misc') {
            if ($misc_keys{$key}) {
                $h{total}{$key} ||= 0;
                $h{total}{$key} += $value;
            }
        } elsif ($type eq 'malloc') {
            $h{total}{"malloc_$key"} ||= 0;
            $h{total}{"malloc_$key"} += $value;
        }
        return ();
    };
    $_[0]->walk_stats($_, $code) for ('', qw(malloc sizes self));
    return \%h;
}

BEGIN
{
    my @boolean_behavior = qw( no_block binary_protocol );
    my %behavior = (
        distribution_method => 'distribution',
        hashing_algorithm   => 'hash'
    );

    foreach my $name (@boolean_behavior) {
        my $code = sprintf(<<'        EOSUB', $name, uc $name, $name, uc $name);
            sub is_%s {
                $_[0]->memcached_behavior_get( Memcached::libmemcached::MEMCACHED_BEHAVIOR_%s() );
            }

            sub set_%s {
                $_[0]->memcached_behavior_set( Memcached::libmemcached::MEMCACHED_BEHAVIOR_%s(), $_[1] );
            }
        EOSUB
        eval $code;
        die if $@;
    }

    while (my($method, $field) = each %behavior) {
        my $code = sprintf(<<'        EOSUB', $method, uc $field, $method, uc $field);
            sub get_%s {
                $_[0]->memcached_behavior_get( Memcached::libmemcached::MEMCACHED_BEHAVIOR_%s() );
            }

            sub set_%s {
                $_[0]->memcached_behavior_set( Memcached::libmemcached::MEMCACHED_BEHAVIOR_%s(), $_[1]);
            }
        EOSUB
        eval $code;
        die if $@;
    }

}

1;

__END__

=head1 NAME

Cache::Memcached::libmemcached - Perl Interface to libmemcached

=head1 SYNOPSIS

  use Cache::Memcached::libmemcached;
  my $memd = Cache::Memcached::libmemcached->new({
    servers => [ "10.0.0.15:11211", "10.0.0.15:11212", "/var/sock/memcached" ],
    compress_threshold => 10_000
  });

  $memd->set("my_key", "Some value");
  $memd->set("object_key", { 'complex' => [ "object", 2, 4 ]});

  $val = $memd->get("my_key");
  $val = $memd->get("object_key");
  if ($val) { print $val->{complex}->[2] }

  $memd->incr("key");
  $memd->decr("key");
  $memd->incr("key", 2);

  $memd->delete("key");
  $memd->remove("key"); # Alias to delete

  my $hashref = $memd->get_multi(@keys);

  # Constants - explicitly by name or by tags
  #    see Memcached::libmemcached::constants for a list
  use Cache::Memcached::libmemcached qw(MEMCACHED_DISTRIBUTION_CONSISTENT);
  use Cache::Memcached::libmemcached qw(
    :defines
    :memcached_allocated
    :memcached_behavior
    :memcached_callback
    :memcached_connection
    :memcached_hash
    :memcached_return
    :memcached_server_distribution
  );

  # Extra constructor options that are not in Cache::Memcached
  # See Memcached::libmemcached::constants for a list of available options
  my $memd = Cache::Memcached::libmemcached->new({
    ...,
    no_block            => $boolean,
    distribution_method => $distribution_method,
    hashing_algorithm   => $hashing_algorithm,
  });

=head1 DESCRIPTION

This is the Cache::Memcached compatible interface to libmemcached,
a C library to interface with memcached.

Cache::Memcached::libmemcached is built on top of Memcached::libmemcached.
While Memcached::libmemcached aims to port libmemcached API to perl, 
Cache::Memcached::libmemcached attempts to be API compatible with
Cache::Memcached, so it can be used as a drop-in replacement.

Note that as of version 0.02000, Cache::Memcached::libmemcached I<inherits>
from Memcached::libmemcached. While you are free to use the 
Memcached::libmemcached specific methods directly on the object, you should
use them with care, as it will mean that your code is no longer compatible
with the Cache::Memcached API therefore losing some of th portability in
case you want to replace it with some other package.

=head1 FOR Cache::Memcached::LibMemcached USERS

Cache::Memcached::libmemcached is a rewrite of Cache::Memcached::LibMemcached,
using Memcached::libmemcached instead of straight XS as its backend.

Therefore you might notice some differences. Here are the ones we are
aware of:

=over 4

=item cas() is not implemented

This was sort of implemented in a previous life, but since 
Memcached::libmemcached is still undecided how to handle it, we don't
support it either.

=item performance is probably a bit different

To be honest, we haven't ran benchmarks comparing the two (yet). In general,
you might see a decrease in performance here and there because we've
essentially added another call stack (instead of going straight from perl to
XS, we are now going from perl to perl to XS). But on the other hand, 
Memcached::libmemcached is in the hands of XS gurus like Time Bunce, so
you are probably sparing yourself some accidental hooplas that occasional
C programmers like me might introduce.

=back

=head1 Cache::Memcached COMPATIBLE METHODS

Except for the minor incompatiblities, below methods are generally compatible 
with Cache::Memcached.

=head2 new

Takes on parameter, a hashref of options.

=head2 set_servers

  $memd->set_servers( [ qw(serv1:port1 serv2:port2 ...) ]);

Sets the server list. 

=head2 get

  my $val = $memd->get($key);

Retrieves a key from the memcached. Returns the value (automatically thawed
with Storable, if necessary) or undef.

Currently the arrayref form of $key is NOT supported. Perhaps in the future.

=head2 get_multi

  my $hashref = $memd->get_multi(@keys);

Retrieves multiple keys from the memcache doing just one query.
Returns a hashref of key/value pairs that were available.

=head2 set

  $memd->set($key, $value[, $expires]);

Unconditionally sets a key to a given value in the memcache. Returns true if 
it was stored successfully.

Currently the arrayref form of $key is NOT supported. Perhaps in the future.

=head2 add

  $memd->add($key, $value[, $expires]);

Like set(), but only stores in memcache if they key doesn't already exist.

=head2 replace

  $memd->replace($key, $value[, $expires]);

Like set(), but only stores in memcache if they key already exist.

=head2 append

  $memd->append($key, $value);

Appends $value to whatever value associated with $key. Only available for
memcached > 1.2.4

=head2 prepend

  $memd->prepend($key, $value);

Prepends $value to whatever value associated with $key. Only available for
memcached > 1.2.4

=head2 incr

=head2 decr

  my $newval = $memd->incr($key);
  my $newval = $memd->decr($key);
  my $newval = $memd->incr($key, $offset);
  my $newval = $memd->decr($key, $offset);

Atomically increments or decrements the specified the integer value specified 
by $key. Returns undef if the key doesn't exist on the server.

=head2 delete

=head2 remove

  $memd->delete($key);

Deletes a key.

XXX - The behavior when second argument is specified may differ from
Cache::Memcached -- this hasn't been very well tested. Patches welcome!

=head2 flush_all

  $memd->fush_all;

Runs the memcached "flush_all" command on all configured hosts, emptying all 
their caches. 

=head2 set_compress_threshold

  $memd->set_compress_threshold($threshold);

Set the compress threshold.

=head2 enable_compress

  $memd->enable_compress($bool);

This is actually an alias to set_compress_enable(). The original version
from Cache::Memcached is, despite its naming, a setter as well.

=head2 stats

  my $h = $memd->stats();

This method is still half-baked. It gives you some stats. If the values are
wrong, well, reports, or better yet, patches welcome.

=head2 disconnect_all

Disconnects from servers

=head2 cas

  $memd->cas($key, $cas, $value[, $exptime]);

XXX - This method is still broken.

Sets if $cas matches the value on the server.

=head2 gets

=head2 get_cas

  my $cas = $memd->gets($key);
  my $cas = $memd->get_cas($key);

Get the CAS value for $key

=head2 get_cas_multi

  my $h = $memd->get_cas_multi(@keys)

Gets CAS values for multiple keys

=head1 Cache::Memcached::libmemcached SPECIFIC METHODS

These methods are libmemcached-specific.

=head2 server_add

Adds a memcached server.

=head2 server_add_unix_socket

Adds a memcached server, connecting via unix socket.

=head2 server_list_free

Frees the memcached server list.

=head1 UTILITY METHODS

WARNING: Please do not consider the existance for these methods to be final.
They may be renamed or may entirely disappear from future releases.

=head2 get_compress_threshold

Return the current value of compress_threshold

=head2 set_compress_enable

Set the value of compress_enable

=head2 get_compress_enable

Return the current value of compress_enable

=head2 set_compress_savings

Set the value of compress_savings

=head2 get_compress_savings

Return the current value of compress_savings

=head1 BEHAVIOR CUSTOMIZATION

Certain libmemcached behaviors can be configured with the following
methods.

(NOTE: This API is not fixed yet)

=head2 behavior_set

=head2 behavior_get

If you want to customize something that we don't have a wrapper for,
you can directly use these method.

=head2 set_no_block

  Cache::Memcached::libmemcached->new({
    ...
    no_block => 1
  });
  # or 
  $memd->set_no_block( 1 );

Set to use blocking/non-blocking I/O. When this is in effect, get() becomes
flaky, so don't attempt to call it. This has the most effect for set()
operations, because libmemcached stops waiting for server response after
writing to the socket (set() will also always return success)

Please consult the man page for C<memcached_behavior_set()> for details 
before setting.

=head2 is_no_block

Get the current value of no_block behavior.

=head2 set_distribution_method

  $memd->set_distribution_method( MEMCACHED_DISTRIBUTION_CONSISTENT );

Set the distribution behavior.

=head2 get_distribution_method

Get the distribution behavior.

=head2 set_hashing_algorithm

  $memd->set_hashing_algorithm( MEMCACHED_HASH_KETAMA );

Set the hashing algorithm used.

=head2 get_hashing_algorithm

Get the hashing algorithm used.

=head2 set_support_cas

  $memd->set_support_cas($boolean);
  # or
  $memd = Cache::Memcached::libmemcached->new( {
    ...
    support_cas => 1
  } );

Enable/disable CAS support.

=head1 set_binary_protocol

  $memd->set_binary_protocol( 1 );
  $binary = $memd->is_binary_protocol();

Enable/disable binary protocol

=head1 OPTIMIZE FLAG

There's an EXPERIMENTAL optimization available for some corner cases, where
if you know before hand that you won't be using some features, you can
disable them all together for some performance boost. To enable this mode,
set an environment variable named PERL_LIBMEMCACHED_OPTIMIZE to a true value

=head2 NO MASTER KEY SUPPORT

If you are 100% sure that you won't be using the master key support, where 
you provide an arrayref as the key, you get about 4~5% performance boost.

=head1 VARIOUS MEMCACHED MODULES

Below are the various memcached modules available on CPAN. 

Please check tool/benchmark.pl for a live comparison of these modules.
(except for Cache::Memcached::XS, which I wasn't able to compile under my
main dev environment)

=head2 Cache::Memcached

This is the "main" module. It's mostly written in Perl.

=head2 Cache::Memcached::libmemcached

Cache::Memcached::libmemcached, which is the module for which your reading
the document of, is a perl binding for libmemcached (http://tangent.org/552/libmemcached.html). Not to be confused with libmemcache (see below).

=head2 Cache::Memcached::Fast

Cache::Memcached::Fast is a memcached client written in XS from scratch.
As of this writing benchmarks shows that Cache::Memcached::Fast is faster on 
get_multi(), and Cache::Memcached::libmemcached is faster on regular get()/set()

=head2 Memcached::libmemcached

Memcached::libmemcached is a straight binding to libmemcached, and is also
the parent class of this module.

It has most of the libmemcached API. If you don't care about a drop-in 
replacement for Cache::Memcached, and want to benefit from low level API that
libmemcached offers, this is the way to go.

=head2 Cache::Memcached::XS

Cache::Memcached::XS is a binding for libmemcache (http://people.freebsd.org/~seanc/libmemcache/).
The main memcached site at http://danga.com/memcached/apis.bml seems to 
indicate that the underlying libmemcache is no longer in active development.

=head1 CAVEATS

Unless you know what you're getting yourself into, don't try to subclass this 
module just yet. Internal structures may change without notice.

=head1 AUTHOR

Copyright (c) 2008 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut