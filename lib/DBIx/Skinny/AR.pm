package DBIx::Skinny::AR;
use utf8;

use Any::Moose;
extends any_moose('::Object'), 'Class::Data::Inheritable';

our $VERSION = '0.0.1';

__PACKAGE__->mk_classdata('db');

has 'row' => (
    is      => 'rw',
    isa     => 'DBIx::Skinny::Row',
    trigger => \&_set_columns,
);

sub BUILD {
    my $self = shift;
    for my $attr ( $self->meta->get_all_attributes ) {
        $self->_chk_unique_value($attr->name)
            if $attr->does('DBIx::Skinny::AR::Meta::Attribute::Trait::Unique');
    }
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

use Carp;
use Lingua::EN::Inflect::Number qw/to_S to_PL/;

use DBIx::Skinny::AR::Meta::Attribute::Trait::Unique;

sub setup {
    my ($class, $db_class) = @_;
    $class->_ensure_load_class($db_class);
    __PACKAGE__->db($db_class);
}

sub table {
    my ($self) = @_;
    my $table = ref $self || $self;
    $table =~ s/^.*:://;
    to_PL(lc $table);
}

sub columns {
    my ($self) = @_;
    $self->db->schema->schema_info->{ $self->table }->{ columns };
}

sub pk {
    my ($self) = @_;
    $self->db->schema->schema_info->{ $self->table }->{ pk };
}

sub _set_columns {
    my ($self, $row) = @_;
    for my $col ( @{ $self->columns } ) {
        $self->$col($row->$col) if $self->can($col);
    }
}

sub _get_columns {
    my ($self) = @_;
    my $row;
    for my $col ( @{ $self->columns } ) {
        $row->{ $col } = $self->$col if $self->can($col);
    }
    return $row;
}

sub _chk_unique_value {
    my ($self, $key) = @_;
    my $where = { $key => $self->$key };
    my $pk = $self->pk;
    $where->{ $pk } = { '!=' => $self->$pk } if $self->$pk;
    croak "Attribute ($key) does not pass the type constraint because: ".
        $self->$key. " is not a unique value." if $self->count($where);
}

sub _get_where {
    my ($self, $where) = @_;
    return $where if ref $where eq 'HASH';
    return {} unless $where;
    return { $self->pk => $where } if !ref $where;
    croak 'Invalid where parameter';
}

sub find {
    my ($self, $where, $opt) = @_;
    my $class = ref $self || $self;
    my $row = $self->db->single(
        $self->table,
        $self->_get_where($where),
        $opt
    ) or return;
    $class->new({ row => $row });
}

sub find_all {
    my ($self, $where, $opt) = @_;
    my $class = ref $self || $self;
    my $rs = $self->db->search(
        $self->table,
        $self->_get_where($where),
        $opt
    );
    my @rows;
    while ( my $row = $rs->next ) {
        push @rows, $class->new({ row => $row });
    }
    return \@rows;
}

sub count {
    my ($self, $where) = @_;
    $self->db->count(
        $self->table,
        $self->pk,
        $self->_get_where($where)
    );
}

sub reload {
    my ($self) = @_;
    croak 'Reload not allowed call as class method' unless ref $self;
    my $pk = $self->pk;
    my $row = $self->db->single($self->table, { $pk => $self->$pk })
            or croak 'Record was deleted';
    $self->row($row);
}

sub create {
    my ($self, $args) = @_;
    my $class = ref $self || $self;
    my $obj = $class->new($args);
    my $row = $self->db->insert($self->table, $args);
    $obj->row($row);
    return $obj;
}

sub update {
    my ($self, $args, $where) = @_;
    if ( ref $self && $self->row ) {
        $args = $self->_get_columns unless $args;
        $self->$_($args->{$_}) for keys %$args;
        $self->row->update($args);
    } else {
        croak 'Update needs where sentence' unless $where;
        $self->db->update($self->table, $args, $where);
    }
}

sub delete {
    my ($self, $where) = @_;
    if ( ref $self && $self->row ) {
        $self->row->delete;
    } else {
        croak 'Delete needs where sentence' unless $where;
        $self->db->delete($self->table, $where);
    }
}

sub belongs_to {
    my ($class, $method, $params) = @_;
    croak 'belongs_to needs method name' unless $method;

    my $target_class = $params->{ target_class }
        || $class->_get_namespace . ucfirst $method;
    $class->_ensure_load_class($target_class);
    my $target_key = $params->{ target_key } || $target_class->pk;
    my $self_key = $params->{ self_key } || $method . '_' . $target_class->pk;
    my $clearer = 'clear_' . $method;

    $class->meta->add_attribute(
        $method,
        is       => 'ro',
        isa      => $target_class,
        clearer  => $clearer,
        lazy     => 1,
        default  => sub {
            my $self = shift or return;
            my $target = $self->can($self_key)
                ? $self->$self_key
                : $self->row->$self_key or croak "Couldn't fetch $self_key";
            my $related = $target_class->find({ $target_key => $target })
                or croak "Related row was not found";
        }
    );
    $class->_add_clearer($self_key, $clearer);
}

sub _add_clearer {
    my ($self, $key, $clearer) = @_;
    my $attr = $self->meta->get_attribute($key);
    if ( $attr && $self->can($key) ) {
        $self->meta->add_after_method_modifier($key, sub {
            my $self = shift;
            $self->$clearer if @_;
        });
    }
}

sub has_one {
    my ($class, $method, $params) = @_;
    croak 'has_one needs method name' unless $method;

    my $self_key = $params->{ self_key } || $class->pk;
    my $target_class = $params->{ target_class }
        || $class->_get_namespace . ucfirst $method;
    $class->_ensure_load_class($target_class);
    my $target_key = $params->{ target_key }
        || lc $class->_get_suffix . '_' . $class->pk;

    $class->meta->add_attribute(
        $method,
        is      => 'ro',
        isa     => "Undef | $target_class",
        clearer => 'clear_' . $method,
        lazy    => 1,
        default => sub {
            my $self = shift or return;
            my $ident = $self->can($self_key)
                ? $self->$self_key
                : $self->row->$self_key or croak "Couldn't fetch $self_key";
            $target_class->find({ $target_key => $ident });
        }
    );
}

sub has_many {
    my ($class, $method, $params) = @_;
    croak 'has_many needs method name' unless $method;

    my $self_key = $params->{ self_key } || $class->pk;
    my $target_class = $params->{ target_class }
        || $class->_get_namespace . ucfirst(to_S $method);
    $class->_ensure_load_class($target_class);
    my $target_key = $params->{ target_key }
        || lc $class->_get_suffix . '_' . $class->pk;

    $class->meta->add_attribute(
        $method,
        is       => 'ro',
        isa      => "ArrayRef[$target_class]",
        clearer  => 'clear_' . $method,
        lazy     => 1,
        default  => sub {
            my $self = shift or return;
            my $ident = $self->can($self_key)
                ? $self->$self_key
                : $self->row->$self_key or croak "Couldn't fetch $self_key";
            $target_class->find_all({ $target_key => $ident });
        }
    );
}

sub many_to_many {
    my ($class, $method, $params) = @_;
    croak 'many_to_many needs method name' unless $method;

    my $target = to_S $method;
    my $self_key = $params->{ self_key } || $class->pk;
    my $target_class = $params->{ target_class }
        || $class->_get_namespace . ucfirst $target;
    $class->_ensure_load_class($target_class);
    my $target_key = $params->{ target_key }
        || $target_class->pk;

    $params->{ glue } ||= {};
    my $glue_table = $params->{ glue }->{ table };
    unless ( $glue_table ) {
        my $suffix = to_PL(lc $class->_get_suffix);
        $glue_table = $method . '_' . $suffix;
        unless ( exists $class->db->schema->schema_info->{ $glue_table } ) {
            $glue_table = $suffix . '_' . $method;
        }
    }
    my $glue_self_key = $params->{ glue }->{ self_key }
        || lc $class->_get_suffix . '_' . $class->pk;
    my $glue_target_key = $params->{ glue }->{ target_key }
        || $target . '_' . $target_class->pk;

    $class->meta->add_attribute(
        $method,
        is       => 'ro',
        isa      => "ArrayRef[$target_class]",
        clearer  => 'clear_' . $method,
        lazy     => 1,
        default  => sub {
            my $self = shift or return;
            my $where = shift || {};
            my $ident = $self->can($self_key)
                ? $self->$self_key
                : $self->row->$self_key or croak "Couldn't fetch $self_key";
            my @target_keys;
            my $rs = $self->db->search($glue_table, { $glue_self_key => $ident });
            while ( my $row = $rs->next ) {
                push @target_keys, $row->$glue_target_key;
            }
            $where->{ $target_key } = { IN => \@target_keys };
            return @target_keys ? $target_class->find_all($where) : [];
        }
    );
}

sub _get_namespace {
    my $class = shift;
    $class =~ s/[^:]+$//;
    return $class;
}

sub _get_suffix {
    my $class = shift;
    $class =~ s/^.+:://;
    return $class;
}

sub _ensure_load_class {
    my ($self, $class) = @_;
    Any::Moose::load_class($class)
        unless Any::Moose::is_class_loaded($class);
}

1;
__END__

=head1 NAME

DBIx::Skinny::AR - DBIx::Skinny's wrapper like ActiveRecord

=head1 SYNOPSIS

DBIx::SkinnyをMyApp::DB, MyApp::DB::Schemaでsetupしている場合、まず以下のようにベースクラスを定義します。

  package MyApp::AR;
  use Any::Moose;
  extends 'DBIx::Skinnh::AR';

  __PACKAGE__->setup('MyApp::DB');

  1;

DBのテーブルに対応したモデルクラスを作成します。各モデルクラスはMyApp::ARを継承します。

  package MyApp::Book;
  use Any::Moose;
  extends 'MyApp::AR';

  has 'id' => (
      is  => 'rw',
      isa => 'Undef | Int',
  );

  has 'author_id' => (
      is  => 'rw',
      isa => 'Undef | Int',
  );

  has 'title' => (
      is     => 'rw',
      isa    => 'Str',
      traits => [qw/Unique/],
  );

  __PACKAGE__->belongs_to('author');

  1;


=head1 DESCRIPTION

DBIx::Skinny::ARはAny::Mooseをベースとしたオブジェクトシステムに、
DBIx::Skinnyをバックエンドとして扱うORMの機能を提供するラッパーです。

ActiveRecordのアプローチを参考にしていますが、メソッド名などは
Perlユーザになじみの深いDBIx::Classに基づいている部分もあります。

DBIx::Skinny::ARはデフォルトではMouseオブジェクトとして振る舞いますが、
Any::Mooseを使用していますので、Mooseに切り替えることももちろん可能です。
本文中では「Mouse」と記述しますが、適宜読み替えてください。


=head1 DEFINING CLASSES

=head2 naming rules

必ずしも従う必要はありませんが、各種設定や操作のデフォルト値が適切に設定されるため、
出来るだけこの形式に合わせることをお勧めします。

-クラス名は単数形（MyApp::Bookなど）
-テーブル名は複数形（booksなど）
-primary keyはINT型のid…でなくても構いません

=head2 column attributes

各カラムにSkinny::ARオブジェクトを通してアクセスするには、
それぞれをMouseのアトリビュートとして登録する必要があります。

  has 'id' => (
      is  => 'rw',
      isa => 'Undef | Int',
  );

DBとクラスでそれぞれカラムを定義するのは二度手間に思えるかも知れません。
しかし、DBのスキーマとアプリケーションのモデルは必ずしも一致する物ではありません。
より自由な制御を可能とするため、DBIx::Skinny::ARではオブジェクトを通してアクセスする
アトリビュートは全て記述するように設計しています。

アトリビュートにユニーク制約を適用したい場合は、以下のようにtraisを指定します。

  has 'name' => (
      is      => 'rw',
      isa     => 'Str',
      traits  => [qw/Unique/],
  );

DBからレコードを読み込んだ時、オブジェクトの該当アトリビュートを書き換えた時に
DBを確認して、入力値がユニークであることを確認します。

ユニーク制約に違反した場合は、通常のMouseオブジェクトの型違反と同様のエラーをcroakします。

=head2 relationships

DBIx::Skinny::ARは以下のリレーションをサポートしています。

-belongs_to
-has_one
-has_many
-many_to_many

クラスにリレーションを設定する場合は、

__PACKAGE__->belongs_to('author');

のようにクラスメソッドを呼び出してください。

リレーション設定の詳細については、C<RELATIONSHIPS>を参照してください。


=head1 DB INFORMATION METHODS

DBIx::Skinny::ARを継承したオブジェクトは、DBとオブジェクトを関連付けるための
以下のパブリックメソッドを持ちます。

=head2 table

クラスに紐付いたテーブル名を返します。
デフォルトではクラス名を複数形にした物が適用されます（大文字は小文字に変換されます）。
MyApp::Book->tableはbooksを返します。

  sub table { 'booklist' }
のように独自のtableメソッドをモデルクラスに実装することで、
デフォルトのルールに合致しないテーブル名を使用することができます。

=head2 columns

テーブルが持つカラムの一覧を返します。

=head2 pk

テーブルのprimary keyを返します。

columnsとpkはDBの情報を直接取得するのではなく、DBIx::Skinnyのスキーマが持つ情報を利用します。

=head2 row

DBIx::Skinny::Rowオブジェクトが格納されます。
このアクセサを経由して、直接DBIx::Skinnyの機能を使うことも出来ます。


=head1 DB OPERATION METHODS

具体的なDBの操作には以下のメソッド群を使用してください。

=head2 find

DBからレコードを一件取得します。
クエリに適合するレコードが複数あった場合、最初のレコードを返します。

  my $book = MyApp::Book->find(1);

スカラ値を渡した場合、primary keyで検索します。

WHERE句をHashRefで指定することも出来ます。

  my $book = MyApp::Book->find({ id => 1 });
  my $book = MyApp::Book->find({ author_id => 1, name => 'book1' });

第2引数でORDER_BYなどの条件を指定できます。
この値はDBIx::Skinnyのsearchメソッドにそのまま渡されます。

  my $book = MyApp::Book->find(
      { author_id => 1 },
      { order_by  => { id => 'desc' } },
  );

クラスメソッドとしてではなく、モデルクラスのインスタンスを経由して
findを呼んでも動作します。

  my $model = MyApp::Book->new;
  my $book = $model->find(1);

この場合、$bookは$modelと同一のオブジェクトではなく、
新しく生成されたMyApp::Bookオブジェクトとなります。
ですので、この後に続けて

  my $book2 = $model->find(2);

のように書いても問題なく動作します。

=head2 find_all

find_allは条件に合致するレコードを全て取得し、
対応するモデルオブジェクトを格納したArrayRefを返します。
パラメータの指定などはfindと同様です。

  my $books = MyApp::Book->find_all;
  my $books = MyApp::Book->find_all({ author_id => 1 });

  my $books = MyApp::Book->find_all(
      { author_id => 1 },
      { order_by  => { id => 'desc' } },
  );

find_allは現在のところ、必ず全件取得を行い、
取得したレコードを全てSkinny::ARのオブジェクトに変換します。
イテレータを返す機能は実装されていません。

=head2 count

条件に合致するレコードのcountを取得します。

  my $cnt = MyApp::Book->count;
  my $cnt = MyApp::Book->count({ author_id => 1 });

=head2 reload

オブジェクトが保持しているレコードをDBから読み直します。
後述のupdateでオブジェクト自身を更新する時には不要です。
reloadは外部でDBが更新される可能性がある場合に使用します。

  my $book = MyApp::Book->find(1);
  # DB updated
  $book->reload;

reloadした時にDBからレコードが削除されていた場合はcroakします。

=head2 create

DBに新しいレコードをinsertし、そのオブジェクトを返します。

  my $new_book = MyApp::Book->create({
      author_id => 1,
      name      => 'new book',
  });

=head2 update

DBのレコードを更新します。

インスタンスをupdateすると、そのオブジェクトが持っているレコードを更新します。

  my $book = MyApp::Book->find(1);
  $book->name('name updated');
  $book->update;

パラメータを指定してupdateすることも出来ます。この時、DBより先にオブジェクトの
各アトリビュートが更新されます。ユニーク制約のチェックもDBの更新に前に実行されます。
ですので、以下のコードは上記と同様の意味になります。

  $book->update({ name => 'name updated' });

クラスに対してupdateを実行すると、DBに対して直接更新をかけることが出来ます。

  MyApp::Book->update(
      { name => 'my book' },
      { author_id => 1 }
  );

DBIx::Skinny本体のupdateと同じように使えます（テーブル名は不要です）。
ただし、Skinny::ARではWHERE句が無いとエラーになります。

=head2 delete

deleteもupdateと同様、インスタンスメソッドとしてクラスメソッドで違う振る舞いをします。

  my $book = MyApp::Book->find(1);
  $book->delete;

  MyApp::Book->delete({ id => 1 });


=head1 RELATIONSHIPS

=head2 belongs_to

belongs_toは親テーブルに対する外部キーを持つクラスに対して設定します。

クラスの命名規則に従っていれば、

  __PACKAGE__->belongs_to('author');

のようにbelongs_toに関連するオブジェクトを取得するメソッドの名前を渡してやるだけで、リレーションの設定ができます。

以下のようにオプションを記述することで、リレーションの詳細なパラメータを設定することも可能です。

  __PACKAGE__->belongs_to(
      'author' => {
          self_key     => 'author_id',
          target_class => 'MyApp::Author',
          target_key   => 'id',
      }
  );

self_keyには外部キー名、target_classには対象のクラス名、target_keyには対象クラスのPKを指定します。

オプションを指定しない場合は各項目が以下のように設定されます。

self_key     ... メソッド名_対象クラスのPK
target_class ... 呼び出し元のクラスの名前空間::メソッド名
target_key   ... 対象クラスのPK

アプリケーションでは、以下のように使用します。

  my $book = MyApp::Book->find(1);
  my $author = $book->author;
  warn ref $author # MyApp::Author

$book->authorで読み出したオブジェクトは、$bookのアトリビュートとして保持されます。
言い換えれば、$book内にauthorオブジェクトがキャッシュされた状態です。
再度$book->authorを参照しても、DBに対してSQLが発行されません。

DBからレコードを読み直したい時は、明示的にauthorをクリアした上でauthorメソッドを呼んでください。

  $book->clear_author;
  my $author = $book->author;

このあたりは他のリレーションでも同様でする。

=head2 has_one

一方、has_one, has_manyは親テーブルに対して設定します。
それぞれ1:1, n;1の関係を表すのに使用します。

has_oneは対象のテーブルをfindで、has_manyはfind_allで検索します。

命名規則に従っていれば、

  __PACKAGE__->has_one('book');

とするだけでリレーションの設定は完了です。

設定は以下のようにカスタマイズすることが可能です。

  __PACKAGE__->has_one(
      'book' => {
          self_key     => 'id',
          target_class => 'MyApp::Book',
          target_key   => 'author_id',
      }
  );

self_keyには自身のPK、target_classには対象のクラス名、target_keyには対象クラスのPKを指定します。

各項目のデフォルト値は以下の通りです。

self_key     ... 自身のPK
target_class ... 自身の名前空間::メソッド名
target_key   ... 対象クラスが持つ外部キー名

アプリケーションでの利用はbelongs_toと同じように出来ます。

  my $author = MyApp::Author->find(1);
  my $book = $author->book;

=head2 has_many

has_manyの設定は基本的にhas_oneと同じです。

  __PACKAGE__->has_many('books');

  __PACKAGE__->has_many(
      'books' => {
          self_key     => 'id',
          target_class => 'MyApp::Book',
          target_key   => 'author_id',
      }
  );

has_oneとの違いは、target_classのデフォルト値となるクラス名が自動で単数形に変換されることです。
これは、has_manyがメソッド名として複数形を期待しているためです。

has_manyはオブジェクトを格納したArrayRefを返すので、アプリケーションから利用する場合は以下のようにします。

  my $author = MyApp::Author->find(1);
  my $books = $author->books;
  for my $book ( @$books ) {
      say $book->name;
  }

=head2 many_to_many

+------------------+
|     books        |
+------------------+
| id (PK)          |
| name             |
+------------------+

+------------------+
|    categories    |
+------------------+
| id (PK)          |
| name             |
+------------------+

+------------------+
| books_categories |
+------------------+
| id (PK)          |
| book_id          |
| category_id      |
+------------------+

many_to_manyは、図のように中間テーブルを用いてn:nの関係を表す時に使用します。

現在のところDBIx::Skinnyでは、テーブルに対して必ずPKの指定が必要であり、
また、複合キーには対応していないため、この例では中間テーブルに単一のキーとなる
idカラムを持たせています。

  __PACKAGE__->many_to_many('categories');

  __PACKAGE__->many_to_many(
      'categories' => {
          self_key     => 'id',
          target_class => 'Mock::Category',
          target_key   => 'id',
          glue => {
              table      => 'books_categories',
              self_key   => 'book_id',
              target_key => 'category_id',
          }
      }
  );

many_to_manyのオプションは他の物よりも複雑です。

self_key ... 呼び出し元クラスのPK
target_class ... 取得する対象のクラス名
target_key ... 対象クラスのPK
glue ... 中間テーブルの情報
  table ... テーブル名
  self_key ... 呼び出し元の外部キー
  target_key ... 取得対象の外部キー

中間テーブル名を明示的に指定しなかった場合は、
呼び出し元クラス名と対象クラス名をそれぞれ複数形にして、
アンダースコアで挟んだ物が使用されます。

「呼び出し元_対象」「対象_呼び出し元」の順にテーブルを探して、
見付かった時点でそのテーブルを使用します。

アプリケーションからの利用はhas_manyと同じ感覚でできます。

  my $book = MyApp::Book->find(1);
  my $categories = $book->categories;
  for my $category ( @$categories ) {
      say $category->name;
  }

=head1 AUTHOR

Ryo Miyake  C<< <ryo.studiom@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 SEE ALSO

DBIx::Skinny, DBIx::Skinny::Schema::Loader, Any::Moose
