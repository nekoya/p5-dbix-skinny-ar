package Mock::Member;
use Any::Moose;
extends 'Mock::AR';

sub table { 'members' }

__PACKAGE__->mk_accessors;

sub validation {
    [
        id        => [ qw/UINT/ ],
        gender_id => [ qw/UINT/ ],
        pref_id   => [ qw/UINT/ ],
        name      => [ qw/NOT_BLANK ASCII/ ],
        kana      => [ qw/KATAKANA/ ],
        { name => [ qw/id name/ ] } => [ [ 'DBIC_UNIQUE', __PACKAGE__, '!id', 'name' ] ],
    ];
}

__PACKAGE__->belongs_to('gender');
__PACKAGE__->belongs_to('gen' => 'gender_id', 'Mock::Gender');
__PACKAGE__->belongs_to('prefecture' => 'pref_id');

1;
