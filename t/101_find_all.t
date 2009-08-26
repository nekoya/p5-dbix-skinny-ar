use t::Utils;
use Mock::Language;
use Test::Declare;

plan tests => blocks;

describe 'instance object test' => run {
    init {
        Mock::Basic->setup_test_db;
        Mock::Basic->insert('languages',{
            id   => 1,
            name => 'perl',
        });
        Mock::Basic->insert('languages',{
            id   => 2,
            name => 'python',
        });
    };

    test 'no records' => run {
        is_deeply(Mock::Language->find_all({ name => 'ruby' }), [], 'find_all() returns empty arrayref when any records were not exists');
    };

    test 'all records' => run {
        ok my $languages = Mock::Language->find_all, 'find all';
        is scalar @$languages, 2, 'amount of rows';
        is $languages->[0]->name, 'perl', 'first  language name';
        is $languages->[1]->name, 'python', 'second language name';
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

