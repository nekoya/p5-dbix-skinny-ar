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
        Mock::Basic->insert('languages',{
            id   => 3,
            name => 'ruby',
        });
    };

    test 'update succeeded' => run {
        my $perl = Mock::Language->find(1);
        ok $perl->update({ name => 'php' }), 'update succeeded';

        my $ruby = Mock::Language->find(1);
        isa_ok $ruby, 'Mock::Language';
        is $ruby->id, 1, 'assert id';
        is $ruby->name, 'php', 'assert name';
    };

    test 'update failed' => run {
        my $python = Mock::Language->find(2);
        throws_ok { $python->update({ name => 'ruby' }) } 'FormValidator::Simple::Results';
        my $result = $@;
        ok $result->has_error, 'validation failed';
        is_deeply [ $result->error ], [ 'name' ], 'validation error happened in name';
        is_deeply [ $result->error('name') ], [ 'DBIC_UNIQUE' ], 'error is DBIC_UNIQUE';
    };

    cleanup {
        unlink './t/main.db';
    };
};

