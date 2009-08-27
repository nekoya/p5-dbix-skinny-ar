use t::Utils;
use Mock::Language;
use Test::Declare;

plan tests => blocks;

describe 'instance object test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'create' => run {
        ok my $ruby = Mock::Language->create({ id => 4, name => 'php' }), 'create ruby';
        isa_ok $ruby, 'Mock::Language';
        is $ruby->id, 4, 'assert id';
        is $ruby->name, 'php', 'assert ruby';
    };

    test 'create failed' => run {
        throws_ok { Mock::Language->create({ id => 4, name => 'テスト' }) } 'FormValidator::Simple::Results';
        my $result = $@;
        ok $result->has_error, 'validation failed';
        is_deeply [ $result->error ], [ 'name' ], 'validation error happened in name';
        is_deeply [ $result->error('name') ], [ 'ASCII' ], 'error is ASCII';
    };

    cleanup {
        unlink './t/main.db';
    };
};

