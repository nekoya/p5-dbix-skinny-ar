package Mock::Gender;
use Any::Moose;
extends 'Mock::AR';

sub table { 'genders' }

__PACKAGE__->mk_accessors;

sub validation {
    [
        id   => [ qw/UINT/ ],
        name => [ qw/NOT_BLANK ASCII/ ],
        { name => [ qw/id name/ ] } => [ [ 'DBIC_UNIQUE', __PACKAGE__, '!id', 'name' ] ],
    ];
}

__PACKAGE__->has_many('members');

1;
