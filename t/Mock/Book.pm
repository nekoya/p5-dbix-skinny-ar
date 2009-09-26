package Mock::Book;
use Any::Moose;
extends 'Mock::AR';

use Carp;

has 'id' => (
    is  => 'rw',
    isa => 'Undef | Int',
);

has 'author_id' => (
    is  => 'rw',
    isa => 'Undef | Int',
);

has 'title' => (
    is      => 'rw',
    isa     => 'Str',
    trigger => sub { shift->chk_unique('title') },
);

1;
