use strict;
use warnings;
use Test::More;
use ShardedKV;
use ShardedKV::Continuum::Ketama;
use ShardedKV::Storage::MySQL;

use lib qw(t/lib);
use ShardedKV::Test;

subtest "memory storage" => sub {
  extension_test_by_one_server_ketama(sub {ShardedKV::Storage::Memory->new()}, 'memory');
  extension_test_by_multiple_servers_ketama(sub {ShardedKV::Storage::Memory->new()}, 'memory');
};

subtest "mysql storage" => sub {
  my @conn_args = get_mysql_conf();
  if (not @conn_args) {
    plan skip_all => 'No MySQL connection info, skipping mysql tests';
  }
  else {
    pass("Got conn. details");
  }

  extension_test_by_one_server_ketama(\&mysql_storage, 'mysql');
  extension_test_by_multiple_servers_ketama(\&mysql_storage, 'mysql');
};

done_testing();

