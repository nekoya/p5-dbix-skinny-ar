package Mock::City;
use Any::Moose;
extends 'Mock::AR';

has 'id' => (
    is  => 'rw',
    isa => 'Undef | Int',
);

has 'p_name' => (
    is  => 'rw',
    isa => 'Undef | Str',
);

has 'name' => (
    is      => 'rw',
    isa     => 'Str',
);

__PACKAGE__->belongs_to(
    'pref' => {
        self_key     => 'p_name',
        target_class => 'Mock::Prefecture',
        target_key   => 'name',
    }
);

1;
