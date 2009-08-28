package Mock::Namecard;
use Any::Moose;
extends 'Mock::AR';

sub table { 'namecards' }
sub default_search_column { 'nick' }

__PACKAGE__->mk_accessors;

sub validation {
    [
        id        => [ qw/UINT/ ],
        member_id => [ qw/UINT/ ],
        nick      => [ qw/NOT_BLANK ASCII/ ],
    ];
}

__PACKAGE__->belongs_to('member');

1;
