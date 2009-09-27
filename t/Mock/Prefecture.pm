package Mock::Prefecture;
use Any::Moose;
extends 'Mock::AR';

use Carp;

has 'code' => (
    is  => 'rw',
    isa => 'Undef | Int',
);

has 'name' => (
    is      => 'rw',
    isa     => 'Str',
);

1;
