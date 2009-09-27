use lib './t';
use FindBin::libs;
use Test::More tests => 34;
use Test::Exception;
use Mock::DB;

BEGIN { Mock::DB->setup_test_db }
END   { unlink './t/main.db'  }

use Mock::Book;
use Mock::Gender;
{
    note "find_all";
    ok my $books = Mock::Book->find_all, 'find_all';
    is scalar @$books, 3, 'amount of rows';
    isa_ok $books->[0], 'Mock::Book';
    isa_ok $books->[1], 'Mock::Book';
    isa_ok $books->[2], 'Mock::Book';
    is $books->[0]->title, 'book1', 'first  book name';
    is $books->[1]->title, 'book2', 'second book name';
    is $books->[2]->title, 'book3', 'third  book name';
}
{
    note "find_all by pk";
    ok my $books = Mock::Book->find_all(2), 'find_all by pk';
    is scalar @$books, 1, 'amount of rows';
    isa_ok $books->[0], 'Mock::Book';
    is $books->[0]->title, 'book2', 'assert name';
}
{
    note "find_all by hashref";
    ok my $books = Mock::Book->find_all({ title => 'book3' }), 'find_all by hashref';
    is scalar @$books, 1, 'amount of rows';
    isa_ok $books->[0], 'Mock::Book';
    is $books->[0]->title, 'book3', 'assert name';
}
{
    note "no record";
    ok my $books = Mock::Book->find_all({ title => 'none' }), 'find_all';
    is_deeply $books, [], 'return empty arrayref';
}
{
    note "find_all with additional options";
    ok my $books = Mock::Book->find_all(undef, { order_by => { id => 'desc' } }), 'find_all';
    is scalar @$books, 3, 'amount of rows';
    isa_ok $books->[0], 'Mock::Book';
    isa_ok $books->[1], 'Mock::Book';
    isa_ok $books->[2], 'Mock::Book';
    is $books->[0]->title, 'book3', 'first  book name';
    is $books->[1]->title, 'book2', 'second book name';
    is $books->[2]->title, 'book1', 'third  book name';
}
{
    note "call find as instance method";
    my $model = Mock::Book->new;
    ok my $books = $model->find_all({ title => 'book3' }), 'find_all by hashref';
    is scalar @$books, 1, 'amount of rows';
    isa_ok $books->[0], 'Mock::Book';
    is $books->[0]->title, 'book3', 'assert name';
}
{
    note "find_all from custom table name, pk is not id";
    ok my $genders = Mock::Gender->find_all('female'), 'find_all';
    is scalar @$genders, 1, 'amount of rows';
    isa_ok $genders->[0], 'Mock::Gender';
    is $genders->[0]->name, 'female', 'assert name';
}
