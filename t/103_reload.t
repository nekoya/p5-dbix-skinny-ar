use lib './t';
use FindBin::libs;
use Test::More qw/no_plan/;
use Test::Exception;
use Mock::Book;

BEGIN { Mock::DB->setup_test_db }
END   { unlink './t/main.db' }

{
    note "successful reload";
    my $book1 = Mock::Book->find(1);
    is $book1->title, 'book1', 'assert title';
    ok(Mock::DB->update('books', { title => 'book4' }, { id => 1 }), 'update DB');
    is $book1->title, 'book1', 'assert title (not modified)';
    ok $book1->reload, 'reload';
    is $book1->title, 'book4', 'assert title (updated)';
}

{
    note "reload row, but it was deleted";
    my $book2 = Mock::Book->find(2);
    is $book2->title, 'book2', 'assert title';
    ok(Mock::DB->delete('books', { id => 2 }), 'delete from DB');
    is $book2->title, 'book2', 'assert title (not modified)';
    throws_ok { $book2->reload } qr/^Record was deleted/, 'caught exception';
}

{
    note "reload after change pk, instance has another record";
    my $book = Mock::Book->find(1);
    is $book->title, 'book4', 'assert title';
    ok $book->id(3), 'changed id';
    ok $book->reload, 'reloaded';
    is $book->title, 'book3', 'reloaded another record';
}
