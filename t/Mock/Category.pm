package Mock::Category;
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
);

__PACKAGE__->many_to_many(
    'goods' => {
        self_key     => 'name',
        target_class => 'Mock::Book',
        target_key   => 'title',
        glue => {
            table      => 'book_categ',
            self_key   => 'c_name',
            target_key => 'b_titl',
        }
    }
);

1;
