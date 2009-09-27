package Mock::DB;
use DBIx::Skinny setup => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
};

sub debug {
    my ($class, $debug) = @_;
    $class->attribute->{ profile } = $debug;
}

sub query_log {
    my $class = shift;
    $class->profiler->query_log(@_);
}

sub setup_test_db {
    my $db = shift;
    $db->do(q{
        CREATE TABLE books (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            author_id   INT,
            title       TEXT UNIQUE
        )
    });

    $db->do(q{
        CREATE TABLE authors (
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            gender_name   TEXT,
            name          TEXT
        )
    });

    $db->do(q{
        CREATE TABLE pseudonyms (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            author_id   INT,
            name        TEXT
        )
    });

    $db->do(q{
        CREATE TABLE sexes (
            name   TEXT
        )
    });

    $db->do(q{
        CREATE TABLE categories (
            id     INTEGER PRIMARY KEY AUTOINCREMENT,
            name   TEXT
        )
    });

    $db->do(q{
        CREATE TABLE books_categories (
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id       INTEGER,
            category_id   INTEGER
        )
    });

    $db->do(q{
        CREATE TABLE libraries (
            id     INTEGER PRIMARY KEY AUTOINCREMENT,
            name   TEXT
        )
    });

    $db->do(q{
        CREATE TABLE books_libraries (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id      INTEGER,
            library_id   INTEGER
        )
    });

    $db->bulk_insert('books', [
        { id => 1, author_id => 1, title => 'book1' },
        { id => 2, author_id => 2, title => 'book2' },
        { id => 3, author_id => 1, title => 'book3' },
    ]);

    $db->bulk_insert('authors', [
        { id => 1, gender_name => 'male', name => 'Mike' },
        { id => 2, gender_name => 'female', name => 'Lisa' },
        { id => 3, gender_name => 'male', name => 'John' },
    ]);

    $db->bulk_insert('pseudonyms', [
        { id => 1, author_id => 2, name => 'Miyako' },
    ]);

    $db->bulk_insert('sexes', [
        { name => 'male'   },
        { name => 'female' },
    ]);

    $db->bulk_insert('categories', [
        { id => 1, name => 'novel' },
        { id => 2, name => 'nonfiction' },
        { id => 3, name => 'science' },
    ]);

    $db->bulk_insert('books_categories', [
        { id => 1, book_id => 1, category_id => 1 },
        { id => 2, book_id => 2, category_id => 2 },
        { id => 3, book_id => 3, category_id => 2 },
        { id => 4, book_id => 3, category_id => 3 },
    ]);

    $db->bulk_insert('libraries', [
        { id => 1, name => 'Mitaka' },
        { id => 2, name => 'Chofu' },
    ]);

    $db->bulk_insert('books_libraries', [
        { id => 1, book_id => 1, library_id => 1 },
        { id => 2, book_id => 2, library_id => 2 },
    ]);
}

package Mock::DB::Schema;
use DBIx::Skinny::Schema;

install_table books => schema {
    pk 'id';
    columns qw/id author_id title/;
};

install_table authors => schema {
    pk 'id';
    columns qw/id gender_name name/;
};

install_table pseudonyms => schema {
    pk 'id';
    columns qw/id author_id name/;
};

install_table sexes => schema {
    pk 'name';
    columns qw/name/;
};

install_table categories => schema {
    pk 'id';
    columns qw/id name/;
};

install_table books_categories => schema {
    pk 'id';
    columns qw/id book_id category_id/;
};

install_table libraries => schema {
    pk 'id';
    columns qw/id name/;
};

install_table books_libraries => schema {
    pk 'id';
    columns qw/id book_id library_id/;
};

1;
