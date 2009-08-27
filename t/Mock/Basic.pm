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
            id   INT,
            name TEXT,
            kana TEXT
        )
    });
}

1;
