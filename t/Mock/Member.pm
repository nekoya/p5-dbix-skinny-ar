package Mock::Member;
use Any::Moose;
extends 'Mock::AR';

sub table { 'members' }
sub default_search_column { 'name' }

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
__PACKAGE__->belongs_to('prefecture' => { key => 'pref_id' });
__PACKAGE__->belongs_to('gen' => {
        key   => 'gender_id',
        class => 'Mock::Gender',
    });

__PACKAGE__->has_one('namecard');
__PACKAGE__->has_one('nc' => {
        key   => 'member_id',
        class => 'Mock::Namecard',
    });

__PACKAGE__->many_to_many('languages' => {
        glue   => 'member_languages',
        target => 'Mock::Language',
        key    => 'language_id',
        self   => 'member_id',
    });

1;
