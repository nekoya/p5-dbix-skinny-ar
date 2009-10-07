use lib './t';
use FindBin::libs;
use Test::More tests => 19;
use Test::Exception;

use Mock::SQLite;
use Mock::Book;
{
    note 'row object update by update method';
    my $before = Mock::Book->find(1);
    is $before->title, 'book1', 'assert title before update';
    ok $before->update({ title => 'book_01' }), 'update succeeded';
    is $before->id, '1', 'assert id after update';
    is $before->title, 'book_01', 'assert title after update';

    my $after = Mock::Book->find(1);
    isa_ok $after, 'Mock::Book';
    is $after->id, 1, 'assert id';
    is $after->title, 'book_01', 'assert title';

    $after->title('book1');
    ok $after->update, 'update with no args';
    is(Mock::Book->find(1)->title, 'book1', 'assert title');

    throws_ok { $after->update({ id => 'aaa' }) }
        qr/^Attribute \(id\) does not pass the type constraint/,
        'attribute error';

    throws_ok { $after->update({ title => 'book2' }) }
        qr/^Attribute \(title\) does not pass the type constraint/,
        'failed update with not unique title';
}

{
    note 'call update as class method';
    throws_ok { Mock::Book->update }
        qr/^Update needs where sentence/,
        'needs where sentence when call as class method';

    throws_ok { Mock::Book->update({ title => 'book1' }) }
        qr/^Update needs where sentence/,
        'needs where sentence when call as class method';

    ok(Mock::Book->update({ title => 'book_02' }, { id => 2 }), 'update succeeded');
    is(Mock::Book->find(2)->title, 'book_02', 'assert title');

    my $model = Mock::Book->new;
    throws_ok { $model->update }
        qr/^Update needs where sentence/,
        'needs where sentence when call not for row';

    throws_ok { $model->update({ title => 'book1' }) }
        qr/^Update needs where sentence/,
        'needs where sentence when call not for row';

    ok($model->update({ title => 'book_03' }, { id => 3 }), 'update succeeded');
    is($model->find(3)->title, 'book_03', 'assert title');
}
