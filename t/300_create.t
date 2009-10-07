use lib './t';
use FindBin::libs;
use Test::More tests => 12;
use Test::Exception;

use Mock::SQLite;
use Mock::Book;
use Mock::Gender;
{
    note 'call create as class method';
    ok my $book4 = Mock::Book->create({ title => 'book4' }), 'create book4';
    isa_ok $book4, 'Mock::Book';
    is $book4->id, 4, 'assert id';
    is $book4->title, 'book4', 'assert title';
}

{
    note 'call create as instance method';
    my $model = Mock::Book->new;
    ok my $book5 = Mock::Book->create({ title => 'book5' }), 'create book5';
    isa_ok $book5, 'Mock::Book';
    is $book5->id, 5, 'assert id';
    is $book5->title, 'book5', 'assert title';
}

{
    note 'create validation failed';
    throws_ok { Mock::Book->create({ id => 7, title => 'book1' }) }
        qr/^Attribute \(title\) does not pass the type constraint/,
        'failed create with not unique title';

    throws_ok { Mock::Book->create({ title => 'book2' }) }
        qr/^Attribute \(title\) does not pass the type constraint/,
        'failed create with not unique title (id auto)';

    my $model = Mock::Gender->new;
    throws_ok { $model->create({ name => 'man' }) }
        qr/^Attribute \(name\) does not pass the type constraint/,
        'attribute error';
    is $model->find({ name => 'man' }), undef, 'record not inserted';
}
