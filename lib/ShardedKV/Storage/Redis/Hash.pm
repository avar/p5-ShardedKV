package ShardedKV::Storage::Redis::Hash;
use Moose;
# ABSTRACT: Storing hash values in Redis
use Encode;
use Redis;
use Carp ();
use ShardedKV::Error::ReadFail;
use ShardedKV::Error::WriteFail;

extends 'ShardedKV::Storage::Redis';

sub get {
  my ($self, $key) = @_;
  my $redis = $self->redis;
  my $hash;
  eval {
    my %foo = $redis->hgetall($key);
    if(keys %foo) {
      $hash = \%foo;
    }
    1;
  } or do {
    my $endpoint = $self->redis_connect_str;
    ShardedKV::Error::ReadFail->throw({
      endpoint => $endpoint,
      key => $key,
      storage_type => 'redis',
      message => "Failed to fetch key ($key) from Redis ($endpoint): $@",
    });
  };
  return $hash;
}

sub set {
  my ($self, $key, $value_ref) = @_;
  if (ref($value_ref) ne 'HASH') {
    Carp::croak("Value must be a hashref");
  }

  my $r = $self->redis;

  my $rv;
  eval {
    $rv = $r->hmset($key, %$value_ref);
    1;
  } or do {
    my $endpoint = $self->redis_connect_str;
    ShardedKV::Error::WriteFail->throw({
      endpoint => $endpoint,
      key => $key,
      storage_type => 'redis',
      operation => 'set',
      message => "Failed to store key ($key) to Redis ($endpoint): $@",
    });
  };

  my $expire = $self->expiration_time;
  if (defined $expire) {
    eval {
      $r->pexpire(
        $key, int(1000*($expire+rand($self->expiration_time_jitter)))
      );
      1;
    } or do {
      my $endpoint = $self->redis_connect_str;
      ShardedKV::Error::WriteFail->throw({
        endpoint => $endpoint,
        key => $key,
        storage_type => 'redis',
        operation => 'expire',
        message => "Failed to store key ($key) to Redis ($endpoint): $@",
      });
    };
  }

  return $rv;
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 SYNOPSIS

  use ShardedKV;
  use ShardedKV::Storage::Redis::Hash;
  ... create ShardedKV...
  my $storage = ShardedKV::Storage::Redis::Hash->new(
    redis_connect_str => 'redisshard1:679',
    expiration_time => 60*60, #1h
  );
  ... put storage into ShardedKV...
  
  # values are scalar references to strings
  $skv->set("foo", {bar => 'baz', cat => 'dog'});
  my $value_ref = $skv->get("foo");

=head1 DESCRIPTION

This subclass of L<ShardedKV::Storage::Redis> implements
simple string/blob values in Redis. See the documentation
for C<ShardedKV::Storage::Redis> for the interface of this
class.

The values of a C<ShardedKV::Storage::Redis::Hash> are
actually scalar references to strings.

=head1 SEE ALSO

=for :list
* L<ShardedKV>
* L<ShardedKV::Storage>
* L<ShardedKV::Storage::Redis>
* L<ShardedKV::Storage::Redis::String>
=cut
# vim: ts=2 sw=2 et
