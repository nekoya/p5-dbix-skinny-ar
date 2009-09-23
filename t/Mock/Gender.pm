package Mock::Gender;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
extends 'Mock::AR';

sub table { 'genders' }

subtype 'Gender'
    => as Str
    => where { $_ =~ /^(male|female)$/ }
    => message { "$_ is not a possible gender" };

has 'name' => (is => 'rw', isa => 'Gender');

#__PACKAGE__->has_many('members');

1;
