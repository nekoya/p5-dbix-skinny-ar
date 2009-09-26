#BEGIN { $ENV{'ANY_MOOSE'} = 'Moose' }
use lib './t';
use FindBin::libs;
use Test::More 'no_plan';
use Test::Exception;
use Data::Dumper;
use Perl6::Say;

use Mock::Book;

BEGIN { Mock::DB->setup_test_db }
END   { unlink './t/main.db' }

package Mock::Book;

__PACKAGE__->belongs_to('author');

package main;

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
