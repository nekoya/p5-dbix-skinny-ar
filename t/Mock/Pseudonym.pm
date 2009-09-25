package Mock::Pseudonym;
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

__PACKAGE__->belongs_to('author');

1;
