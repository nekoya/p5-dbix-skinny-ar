use lib './t';
use FindBin::libs;
use Test::More 'no_plan';
use Test::Exception;
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
    throws_ok { Mock::Language->create({ id => 6, name => 'perl' }) }
        qr/^Attribute \(name\) does not pass the type constraint/,
        'failed create with not unique name';

    throws_ok { Mock::Language->create({ name => 'perl' }) }
        qr/^Attribute \(name\) does not pass the type constraint/,
        'failed create with not unique name (id auto)';

    my $model = Mock::Gender->new;
    throws_ok { $model->create({ name => 'man' }) }
        qr/^Attribute \(name\) does not pass the type constraint/,
        'attribute error';
    is $model->find({ name => 'man' }), undef, 'record not inserted';
}
