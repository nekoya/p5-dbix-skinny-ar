package Mock::Basic;
use DBIx::Skinny setup => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
};

sub setup_test_db {
    my $db = shift;
    $db->do(q{
        CREATE TABLE languages (
            id   INT,
            name TEXT
        )
    });

    $db->do(q{
        CREATE TABLE members (
            id        INT,
            gender_id INT,
            pref_id   INT,
            name      TEXT,
            kana      TEXT
        )
    });

    $db->do(q{
        CREATE TABLE genders (
            id   INT,
            name TEXT
        )
    });

    $db->do(q{
        CREATE TABLE prefectures (
            id   INT,
            name TEXT
        )
    });
}

1;
