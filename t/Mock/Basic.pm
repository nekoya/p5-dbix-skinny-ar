package Mock::Basic;
use DBIx::Skinny setup => {
    dsn      => 'dbi:SQLite:',
    username => '',
    password => ''
};

sub setup_db {
    my $db = shift;
    $db->do(q{
        CREATE TABLE books (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            author_id  INTEGER,
            title      TEXT UNIQUE
        )
    });
    $db->do(q{
        CREATE TABLE authors (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            gender_name  TEXT,
            name         TEXT
        )
    });
    $db->do(q{
        CREATE TABLE genders (
            name  TEXT
        )
    });
    $db->bulk_insert('books', [
        { id => 1, author_id => 1, title => 'book1' },
        { id => 2, author_id => 2, title => 'book2' },
        { id => 3, author_id => 1, title => 'book3' },
    ]);
    $db->bulk_insert('authors', [
        { id => 1, name => 'Mike' },
        { id => 2, name => 'Lisa' },
        { id => 3, name => 'John' },
    ]);
    $db->bulk_insert('genders', [
        { name => 'male' },
        { name => 'female' },
    ]);
}


package Mock::Basic::Schema;
use DBIx::Skinny::Schema;

install_table books => schema {
    pk 'id';
    columns qw/id title/;
};

install_table authors => schema {
    pk 'name';
    columns qw/name/;
};

install_table genders => schema {
    pk 'name';
    columns qw/name/;
};


package Mock::AR;
use Any::Moose;
extends 'DBIx::Skinny::AR';
__PACKAGE__->setup('Mock::Basic');


package Mock::Book;
use Any::Moose;
extends 'Mock::AR';

has 'id' => (
    is  => 'rw',
    isa => 'Undef | Int',
);

has 'title' => (
    is  => 'rw',
    isa => 'Str',
    trigger => sub { shift->chk_unique('title') },
);


package Mock::Author;
use Any::Moose;
extends 'Mock::AR';

has 'name' => (
    is  => 'rw',
    isa => 'Str',
);


package Mock::Gender;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
extends 'Mock::AR';

has 'name' => (
    is  => 'rw',
    isa => enum([ qw/male female/ ]),
);

1;
