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

    test 'find, but record not found' => run {
        is(Mock::Language->find({ name => 'ruby' }), undef, 'find() returns undef when record was not exists');
    };

    test 'find by default column' => run {
        ok my $perl = Mock::Language->find(1), 'find by default column(id)';
        isa_ok $perl, 'Mock::Language';
        is $perl->name, 'perl', 'name is perl';
    };

    test 'find by hashref' => run {
        ok my $python = Mock::Language->find({ name => 'python' }), 'find by name';
        isa_ok $python, 'Mock::Language';
        is $python->name, 'python', 'name is python';
    };

    cleanup {
        unlink './t/main.db';
    };
};

