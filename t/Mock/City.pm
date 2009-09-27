package Mock::City;
use Any::Moose;
extends 'Mock::AR';

has 'id' => (
    is  => 'rw',
    isa => 'Undef | Int',
);

has 'p_code' => (
    is  => 'rw',
    isa => 'Int',
);

has 'name' => (
    is      => 'rw',
    isa     => 'Str',
);

1;
