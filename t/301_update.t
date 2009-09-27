use lib './t';
use FindBin::libs;
use Test::More tests => 29;
use Test::Exception;
use Mock::DB;

BEGIN { Mock::DB->setup_test_db }
END   { unlink './t/main.db'  }

use Mock::Book;
{
    note 'row object update by save method';
    my $before = Mock::Book->find(1);
    is $before->title, 'book1', 'assert title before save';
    $before->title('book5');
    ok $before->save, 'update succeeded';

    my $after = Mock::Book->find(1);
    isa_ok $after, 'Mock::Book';
    is $after->id, 1, 'assert id';
    is $after->title, 'book5', 'assert title';

    note 'save is not allowed parameters';
    ok $after->save({ title => 'book0' }), 'call save ok';
    isnt $after->title, 'book0', 'title was not modified';
    isnt(Mock::Book->find(1)->title, 'book0', 'title was not modified');
}

{
    note 'row object update by update method';
    my $before = Mock::Book->find(1);
    is $before->title, 'book5', 'assert title before update';
    ok $before->update({ title => 'book1' }), 'update succeeded';
    is $before->id, '1', 'assert id after update';
    is $before->title, 'book1', 'assert title after update';

    my $after = Mock::Book->find(1);
    isa_ok $after, 'Mock::Book';
    is $after->id, 1, 'assert id';
    is $after->title, 'book1', 'assert title';

    $after->title('book5');
    ok $after->update, 'update with no args (same as save)';
    is(Mock::Book->find(1)->title, 'book5', 'assert title');

    throws_ok { $after->update({ id => 'aaa' }) }
        qr/^Attribute \(id\) does not pass the type constraint/,
        'attribute error';

    throws_ok { $after->update({ title => 'book2' }) }
        qr/^Attribute \(title\) does not pass the type constraint/,
        'failed update with not unique title';
}

{
    note 'call save not for row';
    throws_ok { Mock::Book->save }
        qr/^Save not allowed call as class method/,
        'not allowed call as class method';

    my $model = Mock::Book->new;
    throws_ok { $model->save }
        qr/^Save needs row object in your instance/,
        'not allowed without row';
}

{
    note 'call update as class method';
    throws_ok { Mock::Book->update }
        qr/^Update needs where sentence/,
        'needs where sentence when call as class method';

    throws_ok { Mock::Book->update({ title => 'book1' }) }
        qr/^Update needs where sentence/,
        'needs where sentence when call as class method';

    ok(Mock::Book->update({ title => 'book1' }, { id => 1 }), 'update succeeded');
    is(Mock::Book->find(1)->title, 'book1', 'assert title');

    my $model = Mock::Book->new;
    throws_ok { $model->update }
        qr/^Update needs where sentence/,
        'needs where sentence when call not for row';

    throws_ok { $model->update({ title => 'book1' }) }
        qr/^Update needs where sentence/,
        'needs where sentence when call not for row';

    ok($model->update({ title => 'book5' }, { id => 1 }), 'update succeeded');
    is($model->find(1)->title, 'book5', 'assert title');
}
