use t::Utils;
use Mock::Language;
use Test::Declare;

plan tests => blocks;

describe 'instance object test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'call as class method' => run {
        is(Mock::Language->validate, undef, 'return undef when call validate as class method without args');

        my $result = Mock::Language->validate({});
        isa_ok $result, 'FormValidator::Simple::Results';
        ok $result->has_error, 'validation failed';
        is_deeply [ $result->error ], [ 'name' ], 'validation error happened in name';
        is_deeply [ $result->error('name') ], [ 'NOT_BLANK' ], 'name is required';

        $result = Mock::Language->validate({ name => 'php' });
        isa_ok $result, 'FormValidator::Simple::Results';
        ok $result->success, 'validation succeeded';
    };

    test 'call as instance method' => run {
        my $perl = Mock::Language->find(1);
        ok $perl->validate->success, 'row object validation succeeded';

        ok my $result = $perl->validate({ name => '' }), 'row object validation with args';
        isa_ok $result, 'FormValidator::Simple::Results';
        ok $result->has_error, 'validation failed';
        is_deeply [ $result->error ], [ 'name' ], 'validation error happened in name';
        is_deeply [ $result->error('name') ], [ 'NOT_BLANK' ], 'name is required';

        ok $perl->validate({ id => 1 })->success, 'row object validate based on their own columns (args not contains "name")';
    };

    cleanup {
        unlink './t/main.db';
    };
};

