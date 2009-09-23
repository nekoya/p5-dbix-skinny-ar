use lib './t';
use FindBin::libs;
use Test::More 'no_plan';
use Test::Exception;
use Mock::Language;
use Mock::Gender;

BEGIN { Mock::Basic->setup_test_db }
END   { unlink './t/main.db' }

{
    note 'row object update by save method';
    my $before = Mock::Language->find(1);
    is $before->name, 'perl', 'assert name before save';
    $before->name('php');
    ok $before->save, 'update succeeded';

    my $after = Mock::Language->find(1);
    isa_ok $after, 'Mock::Language';
    is $after->id, 1, 'assert id';
    is $after->name, 'php', 'assert name';
}

{
    note 'row object update by update method';
    my $before = Mock::Language->find(1);
    is $before->name, 'php', 'assert name before update';
    ok $before->update({ name => 'perl' }), 'update succeeded';
    is $before->name, 'perl', 'assert name after update';

    my $after = Mock::Language->find(1);
    isa_ok $after, 'Mock::Language';
    is $after->id, 1, 'assert id';
    is $after->name, 'perl', 'assert name';

    $after->name('php');
    ok $after->update, 'update with no args (same as save)';
    is(Mock::Language->find(1)->name, 'php', 'assert name');

    throws_ok { $after->update({ id => 'aaa' }) }
        qr/^Attribute \(id\) does not pass the type constraint/,
        'attribute error';
}

{
    note 'call save not for row';
    throws_ok { Mock::Language->save }
        qr/^Save not allowed call as class method/,
        'not allowed call as class method';

    my $model = Mock::Language->new;
    throws_ok { $model->save }
        qr/^Save needs row object in your instance/,
        'not allowed without row';
}

{
    note 'call update as class method';
    throws_ok { Mock::Language->update }
        qr/^Update needs where sentense/,
        'needs where sentense when call as class method';

    throws_ok { Mock::Language->update({ name => 'perl' }) }
        qr/^Update needs where sentense/,
        'needs where sentense when call as class method';

    ok(Mock::Language->update({ name => 'perl' }, { id => 1 }), 'update succeeded');
    is(Mock::Language->find(1)->name, 'perl', 'assert name');

    my $model = Mock::Language->new;
    throws_ok { $model->update }
        qr/^Update needs where sentense/,
        'needs where sentense when call not for row';

    throws_ok { $model->update({ name => 'perl' }) }
        qr/^Update needs where sentense/,
        'needs where sentense when call not for row';

    ok($model->update({ name => 'php' }, { id => 1 }), 'update succeeded');
    is($model->find(1)->name, 'php', 'assert name');
}
