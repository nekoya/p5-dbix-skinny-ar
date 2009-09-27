use lib './t';
use FindBin::libs;
use Test::More tests => 13;
use Test::Exception;
use Mock::DB;

BEGIN { Mock::DB->setup_test_db }
END   { unlink './t/main.db'  }

use Mock::Book;
{
    note "successful reload";
    my $book = Mock::Book->find(1);
    is $book->title, 'book1', 'assert title';
    ok(Mock::DB->update('books', { title => 'book0' }, { id => 1 }), 'update DB');
    is $book->title, 'book1', 'assert title (not modified)';
    ok $book->reload, 'reload';
    is $book->title, 'book0', 'assert title (updated)';
}

{
    note "reload row, but it was deleted";
    my $book = Mock::Book->find(1);
    isa_ok $book, 'Mock::Book';
    ok(Mock::DB->delete('books', { id => 1 }), 'delete from DB');
    is $book->id, 1, 'assert id (still alived)';
    throws_ok { $book->reload } qr/^Record was deleted/, 'caught exception';
}

{
    note "reload after change pk, instance has another record";
    my $book = Mock::Book->find(2);
    is $book->title, 'book2', 'assert title';
    ok $book->id(3), 'changed id';
    ok $book->reload, 'reloaded';
    is $book->title, 'book3', 'reloaded another record';
}
