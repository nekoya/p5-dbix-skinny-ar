package Mock::Language;
use Any::Moose;
extends 'Mock::AR';

sub table { 'languages' }

__PACKAGE__->mk_accessors;

sub validation {
    [
        id   => [ qw/UINT/ ],
        name => [ qw/NOT_BLANK ASCII/ ],
    ];
}

1;
