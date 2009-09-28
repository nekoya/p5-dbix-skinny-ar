use lib './t';
use FindBin::libs;
use Test::More tests => 17;
use Test::Exception;
use Mock::DB;

BEGIN { Mock::DB->setup_test_db }
END   { unlink './t/main.db'  }

use Mock::Book;
use Mock::Category;
{
    note "default settings";
    my $book = Mock::Book->find(1);
    ok my $libs = $book->libraries, 'get related objects';
    scalar @$libs, 2, 'amount of rows';
    isa_ok $libs->[0], 'Mock::Library';
    isa_ok $libs->[1], 'Mock::Library';
    is $libs->[0]->name, 'Mitaka', 'assert name';
    is $libs->[1]->name, 'Chofu', 'assert name';

    ok my $books = $libs->[0]->books, 'get related objects';
    scalar @$books, 2, 'amount of rows';
    isa_ok $books->[0], 'Mock::Book';
    isa_ok $books->[1], 'Mock::Book';
    is $books->[0]->title, 'book1', 'assert name';
    is $books->[1]->title, 'book2', 'assert name';
}
{
    note "has norecords";
    my $book = Mock::Book->find(3);
    is_deeply $book->libraries, [], 'return empty arrayref when record not found';
}
{
    note "many_to_many options (related not PK columns)";
    my $categ = Mock::Category->find(1);
    ok my $books = $categ->goods, 'get related objects';
    is scalar @$books, 2, 'amount of rows';
    isa_ok $books->[0], 'Mock::Book';
    isa_ok $books->[1], 'Mock::Book';
    is $books->[0]->title, 'book1', 'assert book title';
    is $books->[1]->title, 'book2', 'assert book title';
}
