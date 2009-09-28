package Mock::Library;
use Any::Moose;
extends 'Mock::AR';

use Carp;

has 'id' => (
    is  => 'rw',
    isa => 'Undef | Int',
);

has 'name' => (
    is      => 'rw',
    isa     => 'Str',
    trigger => sub { shift->chk_unique('name') },
);

__PACKAGE__->many_to_many('books');

1;
