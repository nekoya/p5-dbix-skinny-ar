use lib './t';
use FindBin::libs;
use Test::More 'no_plan';
use Mock::Language;
use Mock::Gender;

BEGIN { Mock::Basic->setup_test_db }
END   { unlink './t/main.db' }

{
    note 'call create as class method';
    ok my $php = Mock::Language->create({ name => 'php' }), 'create php';
    isa_ok $php, 'Mock::Language';
    is $php->id, 4, 'assert id';
    is $php->name, 'php', 'assert name';
}

{
    note 'call create as instance method';
    my $model = Mock::Language->new;
    ok my $scala = $model->create({ name => 'scala' }), 'create scala';
    isa_ok $scala, 'Mock::Language';
    is $scala->id, 5, 'assert id';
    is $scala->name, 'scala', 'assert name';
}

{
    note 'create validation failed';
    my $model = Mock::Gender->new;
    throws_ok { $model->create({ name => 'man' }) };
    is $model->find({ name => 'man' }), undef, 'record not inserted';
}
