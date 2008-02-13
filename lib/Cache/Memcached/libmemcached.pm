# $Id$
#
# Copyright (c) 2008 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Cache::Memcached::libmemcached;
use strict;
use warnings;
use base qw(Memcached::libmemcached);
use Carp qw(croak);
use Storable ();

our $VERSION = '0.01000';

use constant HAVE_ZLIB    => eval { require Compress::Zlib } && !$@;
use constant F_STORABLE   => 1;
use constant F_COMPRESS   => 2;

BEGIN
{
    # accessors
    foreach my $field qw(compress_enable compress_threshold compress_savings) {
        eval sprintf(<<"        EOSUB", $field, $field, $field, $field);
            sub set_%s { \$_[0]->{%s} = \$_[1] }
            sub get_%s { \$_[0]->{%s} }
        EOSUB
        die if $@;
    }

    # proxy these methods
    foreach my $method qw(delete set add replace prepend append cas) {
        eval <<"        EOSUB";
            sub $method { shift->memcached_$method(\@_) }
        EOSUB
        die if $@;
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
    $self->set_no_block( $args->{no_block} ) if exists $args->{no_block};

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

    # check for existance of : 
    if (my ($hostname, $port) = split(/:/, $server)) {
        $self->memcached_server_add($hostname, $port );
    } else {
        $self->memcached_server_add_uni( $server );
    }
}

sub _mk_callbacks
{
    my $self = shift;

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
    $_[0] or croak("No key specified in incr");
    $_[1] ||= 1 if @_ < 2;
    my $val = 0;
    $self->memcached_increment(@_[0,1], $val);
    return $val;
}

sub decr
{
    my $self = shift;
    $_[0] or croak("No key specified in decr");
    $_[1] ||= 1 if @_ < 2;
    my $val = 0;
    $self->memcached_decrement(@_[0,1], $val);
    return $val;
}

sub flush_all
{
    $_[0]->memcached_flush(0);
}

*remove = \&delete;

sub disconnect_all
{
    $_[0]->memcached_quit();
}

sub stats { die "stats() not implemented" }

sub is_no_block
{
    shift->memcached_behavior_get( Memcached::libmemcached::MEMCACHED_BEHAVIOR_NO_BLOCK() );
}

sub set_no_block
{
    shift->memcached_behavior_set(
        Memcached::libmemcached::MEMCACHED_BEHAVIOR_NO_BLOCK(),
        $_[0]
    );
}

sub get_distribution_method
{
    shift->memcached_behavior_get( Memcached::libmemcached::MEMCACHED_BEHAVIOR_DISTRIBUTION() );
}

sub set_distribution_method
{
    shift->memcached_behavior_set(
        Memcached::libmemcached::MEMCACHED_BEHAVIOR_DISTRIBUTION(),
        $_[0]
    );
}

sub get_hashing_algorithm
{
    shift->memcached_behavior_get( Memcached::libmemcached::MEMCACHED_BEHAVIOR_HASH() );
}

sub set_hashing_algorithm
{
    shift->memcached_behavior_set(
        Memcached::libmemcached::MEMCACHED_BEHAVIOR_HASH(),
        $_[0]
    );
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

  # Constants
  use Cache::Memcached::libmemcached qw(MEMCACHED_DISTRIBUTION_CONSISTENT);
  $memd->set_distribution_method(MEMCACHED_DISTRIBUTION_CONSISTENT());
  

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

=item cas() and stats() are not implemented

They were sort of implemented in a previous life, but since 
Memcached::libmemcached is still undecided how to handle these, we don't
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

This method is still half-baked. Patches welcome.

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

=head2 Cache::Memcached::XS

Cache::Memcached::XS is a binding for libmemcache (http://people.freebsd.org/~seanc/libmemcache/).
The main memcached site at http://danga.com/memcached/apis.bml seems to 
indicate that the underlying libmemcache is no longer in active development.

=head2 Cache::Memcached::Fast

Cache::Memcached::Fast is a memcached client written in XS from scratch.

=head2 Memcached::libmemcached

Memcached::libmemcached is a straight binding to libmemcached. It has all
of the libmemcached API. If you don't care about a drop-in replacement for
Cache::Memcached, and want to benefit from *all* of libmemcached offers,
this is the way to go.

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