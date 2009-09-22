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
            id   INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE
        )
    });

    $db->do(q{
        CREATE TABLE members (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            gender    TEXT,
            pref_id   INT,
            name      TEXT,
            kana      TEXT
        )
    });

    $db->do(q{
        CREATE TABLE member_languages (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            member_id   INT,
            language_id INT
        )
    });

    $db->do(q{
        CREATE TABLE genders (
            name TEXT PRIMARY KEY
        )
    });

    $db->do(q{
        CREATE TABLE prefectures (
            id   INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT
        )
    });

    $db->do(q{
        CREATE TABLE namecards (
            id   INTEGER PRIMARY KEY AUTOINCREMENT,
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
            gender    => 'male',
            pref_id   => 1,
            name      => 'taro',
            kana      => 'タロウ',
        },
        {
            id        => 2,
            gender    => 'female',
            pref_id   => 1,
            name      => 'hanako',
            kana      => 'ハナコ',
        },
    ]);

    $db->bulk_insert('member_languages', [
        {
            member_id   => 1,
            language_id => 1,
        },
        {
            member_id   => 2,
            language_id => 1,
        },
        {
            member_id   => 1,
            language_id => 2,
        },
    ]);

    $db->bulk_insert('genders', [
        { name => 'male'   },
        { name => 'female' },
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
