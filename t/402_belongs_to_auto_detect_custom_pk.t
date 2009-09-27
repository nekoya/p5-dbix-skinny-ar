#BEGIN { $ENV{'ANY_MOOSE'} = 'Moose' }
use lib './t';
use FindBin::libs;

package Mock::Basic;
use DBIx::Skinny setup => { dsn => 'dbi:SQLite:', username => '', password => '' };

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
            no    INTEGER PRIMARY KEY AUTOINCREMENT,
            name  TEXT
        )
    });
    $db->bulk_insert('books', [
        { id => 1, author_id => 1, title => 'book1' },
    ]);
    $db->bulk_insert('authors', [
        { no => 1, name => 'Mike' },
    ]);
}

package Mock::Basic::Schema;
use DBIx::Skinny::Schema;
install_table books   => schema { pk 'id'; columns qw/id author_id title/ };
install_table authors => schema { pk 'no'; columns qw/no name/ };

package Mock::AR;
use Any::Moose;
extends 'DBIx::Skinny::AR';
__PACKAGE__->setup('Mock::Basic');

package Mock::Author;
use Any::Moose;
extends 'Mock::AR';
has 'no'   => ( is => 'rw', isa => 'Undef | Int' );
has 'name' => ( is => 'rw', isa => 'Str' );

package Mock::Book;
use Any::Moose;
extends 'Mock::AR';
has 'id'        => ( is => 'rw', isa => 'Undef | Int' );
has 'author_id' => ( is => 'rw', isa => 'Int' );
has 'title'     => ( is => 'rw', isa => 'Str' );

__PACKAGE__->belongs_to('author');

package main;

Mock::Basic->setup_db;
END   { unlink './t/main.db'  }

use Test::More tests => 4;
{
    my $book = Mock::Book->find(1);
    ok my $author = $book->author, 'get related object';
    isa_ok $author, 'Mock::Author';
    is $author->_pk, 'no', 'assert pk';
    is $author->name, 'Mike', 'assert author name';
}
