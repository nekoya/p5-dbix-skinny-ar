use lib './t';
use FindBin::libs;
use Test::More tests => 27;
use Test::Exception;

use Mock::SQLite;
use Mock::Book;
{
    note "lack of parameter";
    throws_ok { Mock::Book->find_all({}, { page => 1 }) } qr/^Need rows/, 'need rows';
    throws_ok { Mock::Book->find_all({}, { rows => 1 }) } qr/^Need page/, 'need page';

    note "ignore 0";
    ok my $books = Mock::Book->find_all({}, { page => 0 }), 'page 0 is ignore';
    is scalar @$books, 3, 'all books found';
    ok my $books = Mock::Book->find_all({}, { rows => 0 }), 'rows 0 is ignore';
    is scalar @$books, 3, 'all books found';

    note "empty";
    ok $books = Mock::Book->find_all({}, { page => 2, rows => 20 }), 'get empty page';
    is_deeply $books, [], 'got empty arrayref';
}
{
    note "without pager, only paged objects";
    ok my $books = Mock::Book->find_all({}, { page => 1, rows => 2 }), 'first page';
    is scalar @$books, 2, 'all books found';
    isa_ok $books->[0], 'Mock::Book';
    isa_ok $books->[1], 'Mock::Book';
    is $books->[0]->title, 'book1', 'first  book name';
    is $books->[1]->title, 'book2', 'second book name';

    ok $books = Mock::Book->find_all({}, { page => 2, rows => 2 }), 'first page';
    is scalar @$books, 1, 'all books found';
    isa_ok $books->[0], 'Mock::Book';
    is $books->[0]->title, 'book3', 'first  book name';
}
{
    note "with pager";
    ok my ($books, $pager) = Mock::Book->find_all({}, { page => 2, rows => 2 }), 'first page';
    is scalar @$books, 1, 'all books found';
    isa_ok $books->[0], 'Mock::Book';
    is $books->[0]->title, 'book3', 'first  book name';

    isa_ok $pager, 'Data::Page';
    is $pager->total_entries, '3', 'assert total_entries';
    is $pager->first_page, '1', 'assert first_page';
    is $pager->last_page, '2', 'assert last_page';
    is $pager->current_page, '2', 'assert current_page';
}
