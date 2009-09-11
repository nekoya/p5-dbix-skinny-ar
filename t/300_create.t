use t::Utils;
use Mock::Language;
use Test::Declare;

plan tests => blocks;

describe 'instance object test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'create' => run {
        ok my $php = Mock::Language->create({ id => 4, name => 'php' }), 'create php';
        isa_ok $php, 'Mock::Language';
        is $php->id, 4, 'assert id';
        is $php->name, 'php', 'assert name';
    };

    test 'validation failed' => run {
        throws_ok { Mock::Language->create({ id => 4, name => 'テスト' }) } 'FormValidator::Simple::Results';
        my $result = $@;
        ok $result->has_error, 'validation failed';
        is_deeply [ $result->error ], [ 'name' ], 'validation error happened in name';
        is_deeply [ $result->error('name') ], [ 'ASCII' ], 'error is ASCII';
    };

    test 'db insert failed' => run {
        throws_ok { Mock::Language->create({ id => 1, name => 'perl6' }) } qr/^failed DB insert/, 'failed DB insert';
    };

    test 'call create as instance method' => run {
        my $model = Mock::Language->new;
        isa_ok $model, 'Mock::Language';
        my $hoge = $model->find(undef, { order_by => { id => 'desc' } });
        ok my $scala = $model->create({ id => 6, name => 'scala' }), 'create scala';
        isa_ok $scala, 'Mock::Language';
        is $scala->id, 6, 'assert id';
        is $scala->name, 'scala', 'assert name';
    };

    cleanup {
        unlink './t/main.db';
    };
};

