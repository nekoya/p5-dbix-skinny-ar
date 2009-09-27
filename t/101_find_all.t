use lib './t';
use FindBin::libs;
use Mock::Basic;

BEGIN { Mock::Basic->setup_db }
END   { unlink './t/main.db'  }

use Test::More tests => 34;

{
    note 'call find_all as class method';
    is_deeply(Mock::Book->find_all({ title => 'book0' }), [], 'return empty arrayref when any record were not exists');

    ok my $books= Mock::Book->find_all, 'find all';
    is scalar @$books, 3, 'amount of rows';
    is $books->[0]->title, 'book1', 'first  book title';
    is $books->[1]->title, 'book2', 'second book title';
    is $books->[2]->title, 'book3', 'third  book title';

    ok $books = Mock::Book->find_all({ title => 'book2' }), 'find_all by title';
    is scalar @$books, 1, 'amount of rows';
    is $books->[0]->title, 'book2', 'first  book title';

    ok $books = Mock::Book->find_all(undef, { order_by => { id => 'desc' } }), 'find_all with options';
    is scalar @$books, 3, 'amount of rows';
    is $books->[0]->title, 'book3', 'first  book title';
    is $books->[1]->title, 'book2', 'second book title';
    is $books->[2]->title, 'book1', 'third  book title';
}

{
    note 'call find_all as instance method';
    ok my $model = Mock::Book->new, 'create instance';
    isa_ok $model, 'Mock::Book';

    is_deeply($model->find_all({ title => 'book0' }), [], 'return empty arrayref when any record were not exists');

    ok my $books= $model->find_all, 'find all';
    is scalar @$books, 3, 'amount of rows';
    is $books->[0]->title, 'book1', 'first  book title';
    is $books->[1]->title, 'book2', 'second book title';
    is $books->[2]->title, 'book3', 'third  book title';

    ok $books = $model->find_all({ title => 'book2' }), 'find_all by title';
    is scalar @$books, 1, 'amount of rows';
    is $books->[0]->title, 'book2', 'first  book title';

    ok $books = $model->find_all(undef, { order_by => { id => 'desc' } }), 'find_all with options';
    is scalar @$books, 3, 'amount of rows';
    is $books->[0]->title, 'book3', 'first  book title';
    is $books->[1]->title, 'book2', 'second book title';
    is $books->[2]->title, 'book1', 'third  book title';
}

{
    note 'find_all by custom pk';
    ok my $authors = Mock::Author->find_all('Lisa'), 'find_all by custom pk';
    is scalar @$authors, 1, 'amount of rows';
    isa_ok $authors->[0], 'Mock::Author';
    is $authors->[0]->name, 'Lisa', 'assert name';
}
