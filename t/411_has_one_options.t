#BEGIN { $ENV{'ANY_MOOSE'} = 'Moose' }
use lib './t';
use FindBin::libs;

package Mock::Basic;
use DBIx::Skinny setup => { dsn => 'dbi:SQLite:', username => '', password => '' };

sub setup_db {
    my $db = shift;
    $db->do(q{
        CREATE TABLE books (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            author_name  TEXT,
            title        TEXT UNIQUE
        )
    });
    $db->do(q{
        CREATE TABLE authors (
            id    INTEGER PRIMARY KEY AUTOINCREMENT,
            name  TEXT
        )
    });
    $db->bulk_insert('books', [
        { id => 1, author_name => 'Lisa', title => 'book1' },
    ]);
    $db->bulk_insert('authors', [
        { id => 1, name => 'Mike' },
        { id => 2, name => 'Lisa' },
    ]);
}

package Mock::Basic::Schema;
use DBIx::Skinny::Schema;
install_table books   => schema { pk 'id'; columns qw/id author_name title/ };
install_table authors => schema { pk 'id'; columns qw/id name/ };

package Mock::AR;
use Any::Moose;
extends 'DBIx::Skinny::AR';
__PACKAGE__->setup('Mock::Basic');

package Mock::Author;
use Any::Moose;
extends 'Mock::AR';
has 'id'   => ( is => 'rw', isa => 'Undef | Int' );
has 'name' => ( is => 'rw', isa => 'Str' );
__PACKAGE__->has_one(
    'book' => {
        self_key     => 'name',
        target_class => 'Mock::Book',
        target_key   => 'author_name',
    }
);

package Mock::Book;
use Any::Moose;
extends 'Mock::AR';
has 'id'          => ( is => 'rw', isa => 'Undef | Int' );
has 'author_name' => ( is => 'rw', isa => 'Str' );
has 'title'       => ( is => 'rw', isa => 'Str' );

package main;

Mock::Basic->setup_db;
END   { unlink './t/main.db'  }

use Test::More tests => 4;
use Test::Exception;
{
    my $lisa = Mock::Author->find({ name => 'Lisa' });
    ok my $book = $lisa->book, 'get related object';
    isa_ok $book, 'Mock::Book';
    is $book->title, 'book1', 'assert book name';
}

{
    my $mike = Mock::Author->find({ name => 'Mike' });
    is $mike->book, undef, 'related object not found';
}
