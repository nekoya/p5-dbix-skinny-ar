use lib './t';
use FindBin::libs;
use Mock::Basic;

BEGIN { Mock::Basic->setup_db }
END   { unlink './t/main.db'  }

use Test::More tests => 31;

{
    note 'call find as class method';
    is(Mock::Book->find({ id => 99 }), undef, 'return undef when record was not exists');

    ok my $book1 = Mock::Book->find(1), 'find by id';
    isa_ok $book1, 'Mock::Book';
    is $book1->title, 'book1', 'assert title';

    ok my $book2 = Mock::Book->find({ title => 'book2' }), 'find by hashref';
    isa_ok $book2, 'Mock::Book';
    is $book2->title, 'book2', 'assert title';

    ok my $first = Mock::Book->find, 'find no args';
    isa_ok $first, 'Mock::Book';
    is $first->title, 'book1', 'assert title';

    ok my $last = Mock::Book->find(undef, { order_by => { id => 'desc' } }), 'find last row';
    isa_ok $last, 'Mock::Book';
    is $last->title, 'book3', 'assert title';
}

{
    note 'call find as instance method';
    ok my $model = Mock::Book->new, 'create instance';
    isa_ok $model, 'Mock::Book';

    is($model->find({ id => 99 }), undef, 'return undef when record was not exists');

    ok my $book1 = $model->find(1), 'find by id';
    isa_ok $book1, 'Mock::Book';
    is $book1->title, 'book1', 'assert title';

    ok my $book2 = $model->find({ title => 'book2' }), 'find by hashref';
    isa_ok $book2, 'Mock::Book';
    is $book2->title, 'book2', 'assert title';

    ok my $first = $model->find, 'find no args';
    isa_ok $first, 'Mock::Book';
    is $first->title, 'book1', 'assert title';

    ok my $last = $model->find(undef, { order_by => { id => 'desc' } }), 'find last row';
    isa_ok $last, 'Mock::Book';
    is $last->title, 'book3', 'assert title';
}

{
    note 'find by custom table name and custom(not id) pk';
    ok my $john = Mock::Author->find('John'), 'find by pk (name)';
    isa_ok $john, 'Mock::Author';
    is $john->name, 'John', 'assert name';
}
