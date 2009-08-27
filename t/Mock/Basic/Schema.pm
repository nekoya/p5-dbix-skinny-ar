package Mock::Basic::Schema;
use utf8;
use DBIx::Skinny::Schema;

install_table languages => schema {
    pk 'id';
    columns qw/
        id
        name
        kana
    /;
};

1;
