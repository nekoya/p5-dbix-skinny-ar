package Mock::Language;
use Any::Moose;
extends 'Mock::AR';

sub table { 'languages' }

__PACKAGE__->mk_accessors;

sub validation {
    [
        id   => [ qw/UINT/ ],
        name => [ qw/NOT_BLANK ASCII/ ],
        kana => [ qw/KATAKANA/ ],
        { uname => [ qw/id name/ ] } => [ [ 'DBIC_UNIQUE', __PACKAGE__, '!id', 'name' ] ],
    ];
}

1;
