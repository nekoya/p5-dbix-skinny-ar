package Mock::AR;
use Any::Moose;
extends 'DBIx::Skinny::AR';

__PACKAGE__->setup('Mock::DB');

1;
