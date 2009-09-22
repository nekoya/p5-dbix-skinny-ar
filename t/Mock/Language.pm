package Mock::Language;
use Any::Moose;
extends 'Mock::AR';

__PACKAGE__->table('languages');

has 'id'   => (is => 'rw', isa => 'Int');
has 'name' => (is => 'rw', isa => 'Str');

#__PACKAGE__->many_to_many('members' => { glue => 'member_languages' });

1;
