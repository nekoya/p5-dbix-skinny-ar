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
    };

    test 'query_log' => run {
        Mock::Language->debug(1);
        my $perl = Mock::Language->find(1);
        my $log = Mock::Language->query_log;
        is_deeply $log, [ "SELECT id, name FROM languages WHERE (id = ?) LIMIT 1 :binds 1" ], 'query_log';
    };

    cleanup {
        unlink './t/main.db';
    };
};

