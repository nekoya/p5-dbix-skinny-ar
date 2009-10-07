use lib './t';
use FindBin::libs;
use Test::More tests => 23;
use Test::Exception;

use Mock::SQLite;
use Mock::Book;
use Mock::Gender;
{
    note "find no args";
    ok my $first = Mock::Book->find, 'find no args';
    isa_ok $first, 'Mock::Book';
    is $first->title, 'book1', 'assert title';
}
{
    note "find by PK";
    ok my $book1 = Mock::Book->find(1), 'find by id';
    isa_ok $book1, 'Mock::Book';
    is $book1->title, 'book1', 'assert title';
}
{
    note "find by hashref";
    ok my $book2 = Mock::Book->find({ title => 'book2' }), 'find by hashref';
    isa_ok $book2, 'Mock::Book';
    is $book2->title, 'book2', 'assert title';
}
{
    note "record not found";
    is(Mock::Book->find({ id => 99 }), undef, 'return undef when record was not exists');
}
{
    note "find with additional options";
    ok my $last = Mock::Book->find(undef, { order_by => { id => 'desc' } }), 'find last row';
    isa_ok $last, 'Mock::Book';
    is $last->title, 'book3', 'assert title';
}
{
    note "call find as instance method";
    my $model = Mock::Book->new;
    ok my $book1 = $model->find(1), 'find from instance';
    isa_ok $book1, 'Mock::Book';
    ok my $book2 = $model->find(2), 'find from instance again';
    isa_ok $book2, 'Mock::Book';
    isnt $book1->id, $book2->id, 'objects are different';
    is $book1->title, 'book1', 'assert title';
    is $book2->title, 'book2', 'assert title';
}
{
    note "find from custom table name, pk is not id";
    ok my $gender = Mock::Gender->find('female'), 'find object';
    isa_ok $gender, 'Mock::Gender';
    is $gender->name, 'female', 'assert name';
}
