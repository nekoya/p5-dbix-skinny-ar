package Mock::Gender;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
extends 'Mock::AR';

__PACKAGE__->table('genders');

subtype 'Gender'
    => as Str
    => where { $_ =~ /^(male|female)$/ }
    => message { "$_ was not a possible gender" };

has 'name' => (is => 'rw', isa => 'Gender');

#__PACKAGE__->has_many('members');

1;
