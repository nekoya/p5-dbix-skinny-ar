package Mock::Prefecture;
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

__PACKAGE__->has_one(
    'town' => {
        self_key     => 'name',
        target_class => 'Mock::City',
        target_key   => 'p_name',
    }
);

1;
