package Mock::Member;
use Any::Moose;
extends 'Mock::AR';

sub table { 'members' }

__PACKAGE__->mk_accessors;

sub validation {
    [
        id   => [ qw/UINT/ ],
        name => [ qw/NOT_BLANK ASCII/ ],
        kana => [ qw/KATAKANA/ ],
        { name => [ qw/id name/ ] } => [ [ 'DBIC_UNIQUE', __PACKAGE__, '!id', 'name' ] ],
    ];
}

1;
