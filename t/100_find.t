use lib './t';
use FindBin::libs;
use Test::More 'no_plan';
use Mock::Language;
use Mock::Gender;

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
    is $ruby->name, 'ruby', 'assert name';
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
    is $ruby->name, 'ruby', 'assert name';
}

{
    note 'call find as instance method (custom pk)';
    my $model = Mock::Gender->new;

    is($model->find({ name => 'man' }), undef, 'return undef when record was not exists');

    ok my $male = $model->find('male'), 'find by pk';
    isa_ok $male, 'Mock::Gender';
    is $male->name, 'male', 'assert name';

    ok my $female = $model->find({ name => 'female' }), 'find by hashref';
    isa_ok $female, 'Mock::Gender';
    is $female->name, 'female', 'assert name';

    ok my $first = $model->find, 'find no args';
    isa_ok $first, 'Mock::Gender';
    is $first->name, 'male', 'assert name';

    ok my $ordered = $model->find(undef, { order_by => 'name' }), 'find last row';
    isa_ok $ordered, 'Mock::Gender';
    is $ordered->name, 'female', 'assert name';
}
