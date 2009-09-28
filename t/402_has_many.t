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
        { id => 2, author_id => 1, title => 'book2' },
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
__PACKAGE__->has_many('books');

package Mock::Book;
use Any::Moose;
extends 'Mock::AR';
has 'id'        => ( is => 'rw', isa => 'Undef | Int' );
has 'author_id' => ( is => 'rw', isa => 'Int' );
has 'title'     => ( is => 'rw', isa => 'Str' );

package main;

Mock::Basic->setup_db;
END   { unlink './t/main.db'  }

use Test::More tests => 14;
use Test::Exception;
{
    my $lisa = Mock::Author->find(2);
    is_deeply $lisa->books, [], 'return empty arrayref';
}

{
    my $mike = Mock::Author->find(1);
    ok my $books = $mike->books, 'get related objects';
    is scalar @$books, 2, 'amount of rows';
    isa_ok $books->[0], 'Mock::Book';
    isa_ok $books->[1], 'Mock::Book';
    is $books->[0]->title, 'book1', 'first  book name';
    is $books->[1]->title, 'book2', 'second book name';
}

{
    my $mike = Mock::Author->find(1);
    ok my $books = $mike->books({ order_by => { id => 'desc' } }), 'get related objects';
    is scalar @$books, 2, 'amount of rows';
    isa_ok $books->[0], 'Mock::Book';
    isa_ok $books->[1], 'Mock::Book';
    is $books->[0]->title, 'book2', 'first  book name';
    is $books->[1]->title, 'book1', 'second book name';
}
