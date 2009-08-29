package Mock::Language;
use Any::Moose;
extends 'Mock::AR';

sub table { 'languages' }

__PACKAGE__->mk_accessors;

sub validation {
    [
        id   => [ qw/UINT/ ],
        name => [ qw/NOT_BLANK ASCII/ ],
        { name => [ qw/id name/ ] } => [ [ 'DBIC_UNIQUE', __PACKAGE__, '!id', 'name' ] ],
    ];
}

__PACKAGE__->many_to_many('members' => { glue => 'member_languages' });

1;
