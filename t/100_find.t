use lib './t';
use FindBin::libs;
use Test::More 'no_plan';
use Mock::Language;

BEGIN { Mock::Basic->setup_test_db }
END   { unlink './t/main.db' }

{
    note 'call find as class method';
    is(Mock::Language->find({ name => 'php' }), undef, 'return undef when record was not exists');

    ok my $perl = Mock::Language->find(1), 'find by id';
    isa_ok $perl, 'Mock::Language';
    is $perl->name, 'perl', 'assert name';

    ok my $python = Mock::Language->find({ name => 'python' }), 'find by hashref';
    isa_ok $python, 'Mock::Language';
    is $python->name, 'python', 'assert name';

    ok my $first = Mock::Language->find, 'find no args';
    isa_ok $first, 'Mock::Language';
    is $first->name, 'perl', 'assert name';

    ok my $ruby = Mock::Language->find(undef, { order_by => { id => 'desc' } }), 'find last row';
    isa_ok $ruby, 'Mock::Language';
    is $ruby->name, 'ruby', 'name is ruby';
}

{
    note 'call find as instance method';
    my $model = Mock::Language->new;

    is($model->find({ name => 'php' }), undef, 'return undef when record was not exists');

    ok my $perl = $model->find(1), 'find by id';
    isa_ok $perl, 'Mock::Language';
    is $perl->name, 'perl', 'assert name';

    ok my $python = $model->find({ name => 'python' }), 'find by hashref';
    isa_ok $python, 'Mock::Language';
    is $python->name, 'python', 'assert name';
    is $perl->name, 'perl', 'assert former object name';

    ok my $first = $model->find, 'find no args';
    isa_ok $first, 'Mock::Language';
    is $first->name, 'perl', 'assert name';

    ok my $ruby = $model->find(undef, { order_by => { id => 'desc' } }), 'find last row';
    isa_ok $ruby, 'Mock::Language';
    is $ruby->name, 'ruby', 'name is ruby';
}
