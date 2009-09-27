package Mock::CustomPK;
use DBIx::Skinny setup => {
    dsn      => 'dbi:SQLite:',
    username => '',
    password => ''
};

sub setup_db {
    my $db = shift;
    $db->do(q{
        CREATE TABLE books (
            author_name  TEXT,
            title        TEXT UNIQUE
        )
    });
    $db->do(q{
        CREATE TABLE authors (
            name  TEXT
        )
    });
    $db->bulk_insert('books', [
        { author_name => 'Mike', title => 'book1' },
        { author_name => 'Lisa', title => 'book2' },
        { author_name => 'Mike', title => 'book3' },
    ]);
    $db->bulk_insert('authors', [
        { name => 'Mike' },
        { name => 'Lisa' },
        { name => 'John' },
    ]);
}


package Mock::CustomPK::Schema;
use DBIx::Skinny::Schema;

install_table books => schema {
    pk 'title';
    columns qw/author_name title/;
};

install_table authors => schema {
    pk 'name';
    columns qw/name/;
};


package Mock::AR;
use Any::Moose;
extends 'DBIx::Skinny::AR';
__PACKAGE__->setup('Mock::CustomPK');


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

1;
