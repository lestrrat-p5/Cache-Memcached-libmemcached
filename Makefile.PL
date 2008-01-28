use strict;
use inc::Module::Install;

name('Cache-Memcached-LibMemcached');
all_from('lib/Cache/Memcached/LibMemcached.pm');

requires('Memcached::libmemcached', '0.1402');
requires('Storable');
requires('Carp');

recommends('Compress::Zlib');

build_requires('Test::More');

auto_install;
WriteAll;