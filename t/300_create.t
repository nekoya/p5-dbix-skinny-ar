use lib './t';
use FindBin::libs;
use Mock::Basic;

BEGIN { Mock::Basic->setup_db }
END   { unlink './t/main.db'  }

use Test::More tests => 12;
use Test::Exception;
{
    note 'call create as class method';
    ok my $book5 = Mock::Book->create({ title => 'book5' }), 'create book5';
    isa_ok $book5, 'Mock::Book';
    is $book5->id, 5, 'assert id';
    is $book5->title, 'book5', 'assert title';
}

{
    note 'call create as instance method';
    my $model = Mock::Book->new;
    ok my $book6 = Mock::Book->create({ title => 'book6' }), 'create book6';
    isa_ok $book6, 'Mock::Book';
    is $book6->id, 6, 'assert id';
    is $book6->title, 'book6', 'assert title';
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
