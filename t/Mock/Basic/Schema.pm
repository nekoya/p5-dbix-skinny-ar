package Mock::Basic::Schema;
use utf8;
use DBIx::Skinny::Schema;

install_table languages => schema {
    pk 'id';
    columns qw/
        id
        name
    /;
};

install_table members => schema {
    pk 'id';
    columns qw/
        id
        gender_id
        pref_id
        name
        kana
    /;
};

install_table member_languages => schema {
    pk 'id';
    columns qw/
        id
        member_id
        language_id
    /;
};

install_table genders => schema {
    pk 'id';
    columns qw/
        id
        name
    /;
};

install_table prefectures => schema {
    pk 'id';
    columns qw/
        id
        name
    /;
};

install_table namecards => schema {
    pk 'id';
    columns qw/
        id
        member_id
        nick
    /;
};

1;
