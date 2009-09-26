use t::Utils;
use Mock::Language;
use Mock::Member;
use Test::Declare;

plan tests => blocks;

describe 'instance object test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'many_to_many' => run {
        my $taro = Mock::Member->find({ name => 'taro' });
        ok my $langs = $taro->languages, 'got many_to_many rows';
        is scalar @$langs, 2, 'amount of languages';
        is $langs->[0]->name, 'perl', 'first language name';
        is $langs->[1]->name, 'python', 'second language name';
    };

    test 'additional where conds' => run {
        my $taro = Mock::Member->find({ name => 'taro' });
        ok my $langs = $taro->languages({ name => 'python' }), 'got many_to_many rows with additional where conditions';
        is scalar @$langs, 1, 'amount of languages';
        is $langs->[0]->name, 'python', 'first language name';
    };

    test 'no option' => run {
        my $perl = Mock::Language->find({ name => 'perl' });
        ok my $members = $perl->members, 'got many_to_many rows';
        is scalar @$members, 2, 'amount of members';
        is $members->[0]->name, 'taro', 'first member name';
        is $members->[1]->name, 'hanako', 'second member name';
    };

    test 'no records' => run {
        my $ruby = Mock::Language->find({ name => 'ruby' });
        ok my $members = $ruby->members, 'got many_to_many rows';
        is_deeply $members, [], 'return empty arrayref if no records';
    };

    cleanup {
        unlink './t/main.db';
    };
};

