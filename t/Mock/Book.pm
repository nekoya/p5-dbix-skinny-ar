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
);

__PACKAGE__->set_unique_columns([ qw/title/ ]);

__PACKAGE__->belongs_to('author');
__PACKAGE__->many_to_many('libraries');

1;
