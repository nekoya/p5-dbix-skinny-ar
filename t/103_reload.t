use lib './t';
use FindBin::libs;
use Mock::Basic;

BEGIN { Mock::Basic->setup_db }
END   { unlink './t/main.db'  }

use Test::More tests => 13;
use Test::Exception;
{
    note "successful reload";
    my $book1 = Mock::Book->find(1);
    is $book1->title, 'book1', 'assert title';
    ok(Mock::Basic->update('books', { title => 'book0' }, { id => 1 }), 'update DB');
    is $book1->title, 'book1', 'assert title (not modified)';
    ok $book1->reload, 'reload';
    is $book1->title, 'book0', 'assert title (updated)';
}

{
    note "reload row, but it was deleted";
    my $book2 = Mock::Book->find(2);
    is $book2->title, 'book2', 'assert title';
    ok(Mock::Basic->delete('books', { id => 2 }), 'delete from DB');
    is $book2->title, 'book2', 'assert title (not modified)';
    throws_ok { $book2->reload } qr/^Record was deleted/, 'caught exception';
}

{
    note "reload after change pk, instance has another record";
    my $book = Mock::Book->find(3);
    is $book->title, 'book3', 'assert title';
    ok $book->id(4), 'changed id';
    ok $book->reload, 'reloaded';
    is $book->title, 'book4', 'reloaded another record';
}
