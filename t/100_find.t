use t::Utils;
use Mock::Language;
use Mock::Member;
use Test::Declare;

plan tests => blocks;

describe 'instance object test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'find, but record not found' => run {
        is(Mock::Language->find({ name => 'php' }), undef, 'find() returns undef when record was not exists');
    };

    test 'find by default column' => run {
        ok my $perl = Mock::Language->find(1), 'find by default column(id)';
        isa_ok $perl, 'Mock::Language';
        is $perl->name, 'perl', 'name is perl';
    };

    test 'find by custom default column' => run {
        ok my $taro = Mock::Member->find('taro'), 'find by default column(name)';
        isa_ok $taro, 'Mock::Member';
        is $taro->name, 'taro', 'assert name';
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

