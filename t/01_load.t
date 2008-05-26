use strict;
use Test::More (tests => 18);

use_ok("Cache::Memcached::libmemcached");
can_ok("Cache::Memcached::libmemcached", (
    qw(new get get_multi set stats disconnect_all set_servers flush_all),
    qw(is_no_block set_no_block get_distribution_method set_distribution_method get_hashing_algorithm set_hashing_algorithm),
) );

package DummyOne;
Test::More::use_ok("Cache::Memcached::libmemcached", ":defines");
Test::More::can_ok(__PACKAGE__,
    qw( MEMCACHED_DEFAULT_PORT MEMCACHED_DEFAULT_TIMEOUT MEMCACHED_MAX_BUFFER MEMCACHED_MAX_HOST_LENGTH MEMCACHED_MAX_KEY MEMCACHED_STRIDE MEMCACHED_VERSION_STRING_LENGTH ) );

package DummyTwo;
Test::More::use_ok("Cache::Memcached::libmemcached", ":memcached_allocated");
Test::More::can_ok(__PACKAGE__,
    qw( MEMCACHED_ALLOCATED MEMCACHED_NOT_ALLOCATED MEMCACHED_USED ));

package DummyThree;
Test::More::use_ok("Cache::Memcached::libmemcached", ":memcached_behavior");
Test::More::can_ok(__PACKAGE__,
    qw( MEMCACHED_BEHAVIOR_BUFFER_REQUESTS MEMCACHED_BEHAVIOR_CACHE_LOOKUPS MEMCACHED_BEHAVIOR_CONNECT_TIMEOUT MEMCACHED_BEHAVIOR_DISTRIBUTION MEMCACHED_BEHAVIOR_HASH MEMCACHED_BEHAVIOR_KETAMA MEMCACHED_BEHAVIOR_NO_BLOCK MEMCACHED_BEHAVIOR_POLL_TIMEOUT MEMCACHED_BEHAVIOR_SOCKET_RECV_SIZE MEMCACHED_BEHAVIOR_SOCKET_SEND_SIZE MEMCACHED_BEHAVIOR_SORT_HOSTS MEMCACHED_BEHAVIOR_SUPPORT_CAS MEMCACHED_BEHAVIOR_TCP_NODELAY MEMCACHED_BEHAVIOR_VERIFY_KEY) );

package DummyFour;
Test::More::use_ok("Cache::Memcached::libmemcached", ":memcached_callback");
Test::More::can_ok(__PACKAGE__,
    qw(
         MEMCACHED_CALLBACK_CLEANUP_FUNCTION
         MEMCACHED_CALLBACK_CLONE_FUNCTION
         MEMCACHED_CALLBACK_FREE_FUNCTION
         MEMCACHED_CALLBACK_MALLOC_FUNCTION
         MEMCACHED_CALLBACK_REALLOC_FUNCTION
         MEMCACHED_CALLBACK_USER_DATA
    )
);

package DummyFive;
Test::More::use_ok("Cache::Memcached::libmemcached", ":memcached_connection");
Test::More::can_ok(__PACKAGE__,
    qw(
         MEMCACHED_CONNECTION_TCP
         MEMCACHED_CONNECTION_UDP
         MEMCACHED_CONNECTION_UNIX_SOCKET
         MEMCACHED_CONNECTION_UNKNOWN
    )
);

package DummySix;
Test::More::use_ok("Cache::Memcached::libmemcached", ":memcached_hash");
Test::More::can_ok(__PACKAGE__,
    qw(
         MEMCACHED_HASH_CRC
         MEMCACHED_HASH_DEFAULT
         MEMCACHED_HASH_FNV1A_32
         MEMCACHED_HASH_FNV1A_64
         MEMCACHED_HASH_FNV1_32
         MEMCACHED_HASH_FNV1_64
         MEMCACHED_HASH_HSIEH
         MEMCACHED_HASH_MD5
    )
);

package DummySeven;
Test::More::use_ok("Cache::Memcached::libmemcached", ":memcached_return");
Test::More::can_ok(__PACKAGE__,
    qw(
         MEMCACHED_BAD_KEY_PROVIDED
         MEMCACHED_BUFFERED
         MEMCACHED_CLIENT_ERROR
         MEMCACHED_CONNECTION_BIND_FAILURE
         MEMCACHED_CONNECTION_FAILURE
         MEMCACHED_CONNECTION_SOCKET_CREATE_FAILURE
         MEMCACHED_DATA_DOES_NOT_EXIST
         MEMCACHED_DATA_EXISTS
         MEMCACHED_DELETED
         MEMCACHED_END
         MEMCACHED_ERRNO
         MEMCACHED_FAILURE
         MEMCACHED_FAIL_UNIX_SOCKET
         MEMCACHED_FETCH_NOTFINISHED
         MEMCACHED_HOST_LOOKUP_FAILURE
         MEMCACHED_MAXIMUM_RETURN
         MEMCACHED_MEMORY_ALLOCATION_FAILURE
         MEMCACHED_NOTFOUND
         MEMCACHED_NOTSTORED
         MEMCACHED_NOT_SUPPORTED
         MEMCACHED_NO_KEY_PROVIDED
         MEMCACHED_NO_SERVERS
         MEMCACHED_PARTIAL_READ
         MEMCACHED_PROTOCOL_ERROR
         MEMCACHED_READ_FAILURE
         MEMCACHED_SERVER_ERROR
         MEMCACHED_SOME_ERRORS
         MEMCACHED_STAT
         MEMCACHED_STORED
         MEMCACHED_SUCCESS
         MEMCACHED_TIMEOUT
         MEMCACHED_UNKNOWN_READ_FAILURE
         MEMCACHED_VALUE
         MEMCACHED_WRITE_FAILURE
    )
);

package DummyEight;
Test::More::use_ok("Cache::Memcached::libmemcached", ":memcached_server_distribution");
Test::More::can_ok(__PACKAGE__,
    qw(
         MEMCACHED_DISTRIBUTION_CONSISTENT
         MEMCACHED_DISTRIBUTION_MODULA
    )
);
