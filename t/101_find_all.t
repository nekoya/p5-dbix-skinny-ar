use t::Utils;
use Mock::Language;
use Test::Declare;

plan tests => blocks;

describe 'instance object test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'no records' => run {
        is_deeply(Mock::Language->find_all({ name => 'php' }), [], 'find_all() returns empty arrayref when any records were not exists');
    };

    test 'all records' => run {
        ok my $languages = Mock::Language->find_all, 'find all';
        is scalar @$languages, 3, 'amount of rows';
        is $languages->[0]->name, 'perl', 'first  language name';
        is $languages->[1]->name, 'python', 'second language name';
        is $languages->[2]->name, 'ruby', 'second language name';
    };

    test 'find_all by hashref' => run {
        ok my $languages = Mock::Language->find_all({ name => 'python' }), 'find_all by name';
        is scalar @$languages, 1, 'amount of rows';
        is $languages->[0]->name, 'python', 'first  language name';
    };

    cleanup {
        unlink './t/main.db';
    };
};

