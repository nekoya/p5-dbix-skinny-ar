use lib './t';
use FindBin::libs;
use Test::More 'no_plan';
use Mock::Language;

BEGIN { Mock::Basic->setup_test_db }
END   { unlink './t/main.db' }

{
    note 'call find as class method';
    is_deeply(Mock::Language->find_all({ name => 'php' }), [], 'return empty arrayref when any record were not exists');

    ok my $languages = Mock::Language->find_all, 'find all';
    is scalar @$languages, 3, 'amount of rows';
    is $languages->[0]->name, 'perl', 'first  language name';
    is $languages->[1]->name, 'python', 'second language name';
    is $languages->[2]->name, 'ruby', 'third language name';

    ok $languages = Mock::Language->find_all({ name => 'python' }), 'find_all by name';
    is scalar @$languages, 1, 'amount of rows';
    is $languages->[0]->name, 'python', 'first  language name';

    ok my $languages = Mock::Language->find_all(undef, { order_by => { id => 'desc' } }), 'find all order by desc';
    is scalar @$languages, 3, 'amount of rows';
    is $languages->[0]->name, 'ruby', 'first language name';
    is $languages->[1]->name, 'python', 'second language name';
    is $languages->[2]->name, 'perl', 'third  language name';
}

{
    note 'call find as instance method';
    my $model = Mock::Language->new;

    is_deeply($model->find_all({ name => 'php' }), [], 'return empty arrayref when any record were not exists');

    ok my $languages = $model->find_all, 'find all';
    is scalar @$languages, 3, 'amount of rows';
    is $languages->[0]->name, 'perl', 'first  language name';
    is $languages->[1]->name, 'python', 'second language name';
    is $languages->[2]->name, 'ruby', 'third language name';

    ok $languages = $model->find_all({ name => 'python' }), 'find_all by name';
    is scalar @$languages, 1, 'amount of rows';
    is $languages->[0]->name, 'python', 'first  language name';

    ok my $languages = $model->find_all(undef, { order_by => { id => 'desc' } }), 'find all order by desc';
    is scalar @$languages, 3, 'amount of rows';
    is $languages->[0]->name, 'ruby', 'first language name';
    is $languages->[1]->name, 'python', 'second language name';
    is $languages->[2]->name, 'perl', 'third  language name';
}
