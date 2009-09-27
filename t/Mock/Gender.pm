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

__PACKAGE__->has_one('author');
__PACKAGE__->has_many('authors');

1;
