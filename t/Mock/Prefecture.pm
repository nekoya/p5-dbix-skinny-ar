package Mock::Prefecture;
use Any::Moose;
extends 'Mock::AR';

sub table { 'prefectures' }

__PACKAGE__->mk_accessors;

sub validation {
    [
        id   => [ qw/UINT/ ],
        name => [ qw/NOT_BLANK ASCII/ ],
        { name => [ qw/id name/ ] } => [ [ 'DBIC_UNIQUE', __PACKAGE__, '!id', 'name' ] ],
    ];
}

__PACKAGE__->has_many('members' => {
        key   => 'pref_id',
        class => 'Mock::Member',
    });

1;
