package Mock::Gender;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
extends 'Mock::AR';

sub table { 'sexes' }

has 'name' => (
    is  => 'rw',
    isa => enum([ qw/male female/ ]),
);

#__PACKAGE__->has_many('members');

1;
