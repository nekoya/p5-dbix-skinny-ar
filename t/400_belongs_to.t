use lib './t';
use FindBin::libs;
use Test::More tests => 17;
use Test::Exception;
use Mock::DB;

BEGIN { Mock::DB->setup_test_db }
END   { unlink './t/main.db'  }

use Mock::Book;
use Mock::Gender;
{
    note "belongs_to default settings";
    my $book = Mock::Book->find({ title => 'book1' });
    is $book->author_id, 1, 'assert author_id';
    ok my $author = $book->author, 'get related object';
    isa_ok $author, 'Mock::Author';
    is $author->id, 1, 'assert author id';

    note "get new related object after modify foreign_key";
    ok $book->author_id(2), 'change author_id';
    ok $author = $book->author, 'get related object again';
    is $author->id, 2, 'assert new author id';

    ok $book->author_id(99), 'set invalid author_id';
    throws_ok { $book->author } qr/^Related row was not found/, 'caught exception';
}
{
    note "get new related object after update row";
    my $book = Mock::Book->find({ title => 'book2' });
    is $book->author_id, 2, 'assert author_id';
    ok $book->update({ author_id => 1 }), 'update DB';
    ok my $author = $book->author, 'get related object';
    isa_ok $author, 'Mock::Author';
    is $author->id, 1, 'assert author id';
}
{
    note "auto detect not id PK";
    my $author = Mock::Author->find(1);
    ok my $gender = $author->gender, 'get related object';
    isa_ok $gender, 'Mock::Gender';
    is $gender->id, 1, 'assert id';
}
