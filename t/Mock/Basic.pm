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

    $db->do(q{
        CREATE TABLE namecards (
            id        INT,
            member_id INT,
            nick      TEXT
        )
    });

    $db->bulk_insert('languages', [
        {
            id   => 1,
            name => 'perl',
        },
        {
            id   => 2,
            name => 'python',
        },
        {
            id   => 3,
            name => 'ruby',
        },
    ]);

    $db->bulk_insert('members', [
        {
            id        => 1,
            gender_id => 1,
            pref_id   => 2,
            name      => 'taro',
            kana      => 'タロウ',
            },
            {
            id        => 2,
            gender_id => 2,
            pref_id   => 1,
            name      => 'hanako',
            kana      => 'ハナコ',
        },
    ]);

    $db->bulk_insert('genders', [
        {
            id   => 1,
            name => 'male',
        },
        {
            id   => 2,
            name => 'female',
        },
    ]);

    $db->bulk_insert('prefectures', [
        {
            id   => 1,
            name => 'tokyo',
        },
        {
            id   => 2,
            name => 'kyoto',
        },
    ]);

    $db->bulk_insert('namecards', [
        {
            id        => 1,
            member_id => 2,
            nick      => 'nahanaha',
        },
    ]);
}

1;
