use lib './t';
use FindBin::libs;
use Test::More tests => 42;
use Mock::Book;
use Mock::Gender;

BEGIN { Mock::DB->setup_test_db }
END   { unlink './t/main.db' }

{
    note 'call find_all as class method';
    is_deeply(Mock::Book->find_all({ title => 'book0' }), [], 'return empty arrayref when any record were not exists');

    ok my $books= Mock::Book->find_all, 'find all';
    is scalar @$books, 3, 'amount of rows';
    is $books->[0]->title, 'book1', 'first  book title';
    is $books->[1]->title, 'book2', 'second book title';
    is $books->[2]->title, 'book3', 'third book title';

    ok $books = Mock::Book->find_all({ title => 'book2' }), 'find_all by title';
    is scalar @$books, 1, 'amount of rows';
    is $books->[0]->title, 'book2', 'first  book title';

    ok my $books = Mock::Book->find_all(undef, { order_by => { id => 'desc' } }), 'find all order by desc';
    is scalar @$books, 3, 'amount of rows';
    is $books->[0]->title, 'book3', 'first book title';
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
    is $books->[2]->title, 'book3', 'third book title';

    ok $books = $model->find_all({ title => 'book2' }), 'find_all by title';
    is scalar @$books, 1, 'amount of rows';
    is $books->[0]->title, 'book2', 'first  book title';

    ok my $books = $model->find_all(undef, { order_by => { id => 'desc' } }), 'find all order by desc';
    is scalar @$books, 3, 'amount of rows';
    is $books->[0]->title, 'book3', 'first book title';
    is $books->[1]->title, 'book2', 'second book title';
    is $books->[2]->title, 'book1', 'third  book title';
}

{
    note 'call find_all as instance method (custom pk)';
    my $model = Mock::Gender->new;

    is_deeply($model->find_all({ name => 'man' }), [], 'return empty arrayref when any record were not exists');

    ok my $genders = $model->find_all, 'find all';
    is scalar @$genders, 2, 'amount of rows';
    is $genders->[0]->name, 'male', 'first  gender name';
    is $genders->[1]->name, 'female', 'second gender name';

    ok $genders = $model->find_all({ name => 'female' }), 'find_all by name';
    is scalar @$genders, 1, 'amount of rows';
    is $genders->[0]->name, 'female', 'first  gender name';

    ok my $genders = $model->find_all(undef, { order_by => 'name' }), 'find all with opt';
    is scalar @$genders, 2, 'amount of rows';
    is $genders->[0]->name, 'female', 'first gender name';
    is $genders->[1]->name, 'male', 'second gender name';
}
