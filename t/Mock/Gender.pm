package Mock::Gender;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
extends 'Mock::AR';

sub table { 'sexes' }

has 'id' => (
    is  => 'rw',
    isa => 'Undef | Int',
);

has 'name' => (
    is  => 'rw',
    isa => enum([ qw/male female/ ]),
);

1;
