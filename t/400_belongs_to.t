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
            id    INTEGER PRIMARY KEY AUTOINCREMENT,
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
    ]);
}

package Mock::Basic::Schema;
use DBIx::Skinny::Schema;
install_table books   => schema { pk 'id'; columns qw/id author_id title/ };
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

use Test::More tests => 14;
use Test::Exception;
{
    my $book = Mock::Book->find({ title => 'book1' });
    is $book->author_id, 1, 'assert author_id';
    ok my $author = $book->author, 'get related object';
    isa_ok $author, 'Mock::Author';
    is $author->id, 1, 'assert author id';

    ok $book->author_id(2), 'change author_id';
    ok $author = $book->author, 'get related object again';
    is $author->id, 2, 'assert new author id';

    ok $book->author_id(99), 'set invalid author_id';
    throws_ok { $book->author } qr/^Related row was not found/, 'caught exception';
}

{
    my $book = Mock::Book->find({ title => 'book2' });
    is $book->author_id, 2, 'assert author_id';
    ok $book->update({ author_id => 1 }), 'update DB';
    ok my $author = $book->author, 'get related object';
    isa_ok $author, 'Mock::Author';
    is $author->id, 1, 'assert author id';
}
