use t::Utils;
use Mock::Language;
use Test::Declare;

plan tests => blocks;

describe 'instance object test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'instance update succeeded' => run {
        my $perl = Mock::Language->find(1);
        ok $perl->update({ name => 'php' }), 'update succeeded';

        my $php = Mock::Language->find(1);
        isa_ok $php, 'Mock::Language';
        is $php->id, 1, 'assert id';
        is $php->name, 'php', 'assert name';
    };

    test 'instance update by setter' => run {
        my $ruby = Mock::Language->find({ name => 'ruby' });
        $ruby->name('scala');
        is $ruby->name, 'scala', 'updated by setter';
        ok $ruby->update, 'update succeeded';

        my $scala = Mock::Language->find($ruby->id);
        isa_ok $scala, 'Mock::Language';
        is $scala->id, $ruby->id, 'assert id';
        is $scala->name, 'scala', 'assert name (updated)';
    };

    test 'instance update failed' => run {
        my $python = Mock::Language->find(2);
        throws_ok { $python->update({ name => 'scala' }) } 'FormValidator::Simple::Results';
        my $result = $@;
        ok $result->has_error, 'validation failed';
        is_deeply [ $result->error ], [ 'name' ], 'validation error happened in name';
        is_deeply [ $result->error('name') ], [ 'DBIC_UNIQUE' ], 'error is DBIC_UNIQUE';
    };

    test 'static update' => run {
        ok(Mock::Language->update({ name => 'perl' }), 'update called as static');
        my $languages = Mock::Language->find_all;
        is scalar @$languages, 3, 'amount of rows';
        is $languages->[0]->name, 'perl', 'all languages named perl';
        is $languages->[1]->name, 'perl', 'all languages named perl';
        is $languages->[2]->name, 'perl', 'all languages named perl';
    };

    test 'static update with where' => run {
        ok(Mock::Language->update({ name => 'python' }, { id => { '<' => 3 } }), 'update called as static with where');
        my $languages = Mock::Language->find_all;
        is scalar @$languages, 3, 'amount of rows';
        is $languages->[0]->name, 'python', 'fitst name';
        is $languages->[1]->name, 'python', 'second name';
        is $languages->[2]->name, 'perl', 'third name';
    };

    cleanup {
        unlink './t/main.db';
    };
};

