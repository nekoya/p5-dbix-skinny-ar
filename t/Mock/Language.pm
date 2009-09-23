package Mock::Language;
use Any::Moose;
extends 'Mock::AR';

use Carp;

has 'id'   => (is => 'rw', isa => 'Undef | Int');
has 'name' => (is => 'rw', isa => 'Str');

#__PACKAGE__->many_to_many('members' => { glue => 'member_languages' });

1;
