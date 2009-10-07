package Mock::SQLite;
use strict;
use warnings;

use DBI;

sub import {
    my $self = shift;
    my $dbh = DBI->connect('dbi:SQLite:test.db', '', '');
    my @statements = (
        qq{
            CREATE TABLE books (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                author_id   INT,
                title       TEXT UNIQUE
            )
        },
        qq{
            CREATE TABLE authors (
                id            INTEGER PRIMARY KEY AUTOINCREMENT,
                gender_name   TEXT,
                name          TEXT
            )
        },
        qq{
            CREATE TABLE pseudonyms (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                author_id   INT,
                name        TEXT
            )
        },
        qq{
            CREATE TABLE sexes (
                name   TEXT
            )
        },
        qq{
            CREATE TABLE categories (
                id     INTEGER PRIMARY KEY AUTOINCREMENT,
                name   TEXT
            )
        },
        qq{
            CREATE TABLE book_categ (
                id      INTEGER PRIMARY KEY AUTOINCREMENT,
                b_titl  TEXT,
                c_name  TEXT
            )
        },
        qq{
            CREATE TABLE libraries (
                id     INTEGER PRIMARY KEY AUTOINCREMENT,
                name   TEXT
            )
        },
        qq{
            CREATE TABLE books_libraries (
                id           INTEGER PRIMARY KEY AUTOINCREMENT,
                book_id      INTEGER,
                library_id   INTEGER
            )
        },
        qq{
            CREATE TABLE prefectures (
                id    INTEGER PRIMARY KEY AUTOINCREMENT,
                name  INTEGER
            )
        },
        qq{
            CREATE TABLE cities (
                id      INTEGER PRIMARY KEY AUTOINCREMENT,
                p_name  INTEGER,
                name    INTEGER
            )
        },

        q{ INSERT INTO books VALUES (1, 1, 'book1') },
        q{ INSERT INTO books VALUES (2, 2, 'book2') },
        q{ INSERT INTO books VALUES (3, 1, 'book3') },

        q{ INSERT INTO authors VALUES (1, 'male', 'Mike') },
        q{ INSERT INTO authors VALUES (2, 'female', 'Lisa') },
        q{ INSERT INTO authors VALUES (3, 'male', 'John') },

        q{ INSERT INTO pseudonyms VALUES (1, 2, 'Miyako') },

        q{ INSERT INTO sexes VALUES ('male') },
        q{ INSERT INTO sexes VALUES ('female') },

        q{ INSERT INTO categories VALUES (1, 'novel') },
        q{ INSERT INTO categories VALUES (2, 'nonfiction') },

        q{ INSERT INTO book_categ VALUES (1, 'book1', 'novel') },
        q{ INSERT INTO book_categ VALUES (2, 'book2', 'novel') },

        q{ INSERT INTO libraries VALUES (1, 'Mitaka') },
        q{ INSERT INTO libraries VALUES (2, 'Chofu') },

        q{ INSERT INTO books_libraries VALUES (1, 1, 1) },
        q{ INSERT INTO books_libraries VALUES (2, 1, 2) },
        q{ INSERT INTO books_libraries VALUES (3, 2, 1) },

        q{ INSERT INTO prefectures VALUES (1, 'Kyoto') },
        q{ INSERT INTO prefectures VALUES (2, 'Tokyo') },

        q{ INSERT INTO cities VALUES (1, 'Tokyo', 'Mitaka') },
    );
    $dbh->do($_) for @statements;
}

END {
    unlink './test.db';
}

1;
