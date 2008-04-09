use strict;
use inc::Module::Install;

name('Cache-Memcached-libmemcached');
all_from('lib/Cache/Memcached/libmemcached.pm');

requires('Memcached::libmemcached', '0.1901');
requires('Storable');
requires('Carp');

recommends('Compress::Zlib');

build_requires('Test::More');

auto_include;
WriteAll;