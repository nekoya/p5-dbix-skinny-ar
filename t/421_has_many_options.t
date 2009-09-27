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
        { id => 1, author_name => 'Mike', title => 'book1' },
        { id => 2, author_name => 'Mike', title => 'book2' },
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
__PACKAGE__->has_many(
    'goods' => {
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

use Test::More tests => 6;
use Test::Exception;
{
    my $mike = Mock::Author->find(1);
    ok my $books = $mike->goods, 'get related objects';
    is scalar @$books, 2, 'amount of rows';
    isa_ok $books->[0], 'Mock::Book';
    isa_ok $books->[1], 'Mock::Book';
    is $books->[0]->title, 'book1', 'first  book name';
    is $books->[1]->title, 'book2', 'second book name';
}
