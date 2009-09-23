package DBIx::Skinny::AR;

our $VERSION = '0.0.1';

use Carp;
use UNIVERSAL::require;
use Lingua::EN::Inflect::Number qw/to_S to_PL/;

use Any::Moose;
extends any_moose('::Object'), 'Class::Data::Inheritable';

__PACKAGE__->mk_classdata('db');

has 'row' => (
    is      => 'rw',
    isa     => 'DBIx::Skinny::Row',
    trigger => \&_set_columns,
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub table {
    my ($self) = @_;
    my $table = ref $self || $self;
    $table =~ s/^.*:://;
    to_PL(lc $table);
}

sub _columns {
    my ($self) = @_;
    $self->db->schema->schema_info->{ $self->table }->{ columns };
}

sub _pk {
    my ($self) = @_;
    $self->db->schema->schema_info->{ $self->table }->{ pk };
}

sub _set_columns {
    my ($self, $row) = @_;
    for my $col ( @{ $self->_columns } ) {
        $self->$col($row->$col) if $self->can($col);
    }
}

sub _get_columns {
    my ($self) = @_;
    my $row;
    for my $col ( @{ $self->_columns } ) {
        $row->{ $col } = $self->$col if $self->can($col);
    }
    return $row;
}

sub setup {
    my ($class, $db_class) = @_;
    $db_class->require;
    __PACKAGE__->db($db_class);
}

sub debug {
    my ($self, $debug) = @_;
    $self->db->attribute->{ profile } = $debug;
}

sub query_log {
    my ($self) = @_;
    $self->db->profiler->query_log(@_);
}

sub _get_where {
    my ($self, $where) = @_;
    return $where if ref $where eq 'HASH';
    return {} unless $where;
    return { $self->_pk => $where } if !ref $where;
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
    my ($self, $args) = @_;
    $self->db->count($self->table, $self->_pk, $args);
}

sub create {
    my ($self, $args) = @_;
    my $class = ref $self || $self;
    my $obj = $class->new($args);
    my $row = $self->db->insert($self->table, $args);
    $obj->row($row);
    return $obj;
}

sub save {
    my ($self) = @_;
    croak 'Save not allowed call as class method' unless ref $self;
    croak 'Save needs row object in your instance' unless $self->row;
    $self->update;
}

sub update {
    my ($self, $args, $where) = @_;
    if ( ref $self && $self->row ) {
        $args = $self->_get_columns unless $args;
        $self->$_($args->{$_}) for keys %$args;
        $self->row->update($args);
    } else {
        croak 'Update needs where sentense' unless $where;
        $self->db->update($self->table, $args, $where);
    }
}

sub delete {
    my ($self, $args) = @_;
    if ( ref $self ) {
        croak 'Row object is not loaded' unless $self->row;
        $self->row->delete;
    } else {
        croak 'Delete needs args' unless $args;
        $self->db->delete($self->table, $args);
    }
}

=head
sub belongs_to {
    my ($class, $method, $params) = @_;
    croak 'belongs_to needs method name' unless $method;
    $params ||= {};
    my $target = $class->_prepare_target_class($method, $params->{ class });
    my $column = $params->{ key } || $method . '_id';
    {
        no strict 'refs';
        *{"$class\::$method"} = sub {
            my $self = shift or return;
            return unless $self->$column;
            my $related = $target->find({ id => $self->$column })
                or croak "related row was not found";
        }
    }
}

sub has_one {
    my ($class, $method, $params) = @_;
    croak 'has_one needs method name' unless $method;
    my ($target, $column) = $class->_prepare_related_params($method, $params);
    {
        no strict 'refs';
        *{"$class\::$method"} = sub {
            my $self = shift or return;
            return $target->find({ $column => $self->id });
        }
    }
}

sub has_many {
    my ($class, $method, $params) = @_;
    croak 'has_many needs method name' unless $method;
    my ($target, $column) = $class->_prepare_related_params(to_S($method), $params);
    {
        no strict 'refs';
        *{"$class\::$method"} = sub {
            my $self = shift or return;
            my $where = shift || {};
            $where->{ $column } = $self->id;
            return $target->find_all($where);
        }
    }
}

sub many_to_many {
    my ($class, $method, $params) = @_;
    croak 'many_to_many needs method name' unless $method;
    $params ||= {};
    my $glue = $params->{ glue } or croak 'many_to_many needs glue class name';
    my $target = $params->{ target }
        || $class->_get_namespace . ucfirst to_S($method);
    my $foreign_key = $params->{ key } || to_S($method) . '_id';
    my $self_key = $params->{ self } || lc $class->_get_suffix . '_id';
    {
        no strict 'refs';
        *{"$class\::$method"} = sub {
            my $self = shift or return;
            my $where = shift || {};
            my @ids;
            my $rs = $self->db->search($glue, { $self_key => $self->id });
            while ( my $row = $rs->next ) {
                push @ids, $row->$foreign_key;
            }
            $where->{ id } = { IN => \@ids };
            return @ids ? $target->find_all($where) : [];
        }
    }
}

sub _prepare_target_class {
    my ($self, $method, $target) = @_;
    my $class = ref $self || $self;
    $target ||= $class->_get_namespace . ucfirst $method;
    $target->require or croak "cannot require $target";
    return $target;
}

sub _prepare_related_params {
    my ($class, $method, $params) = @_;
    $params ||= {};
    my $target = $class->_prepare_target_class($method, $params->{ class });
    my $column = $params->{ key } || lc $class->_get_suffix . '_id';
    return ($target, $column);
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
=cut

1;
__END__

=head1 NAME

DBIx::Skinny::AR - DBIx::Skinny's wrapper like ActiveRecord


=head1 SYNOPSIS

setup your ar model (DBIx::Skinny already setup as MyApp::DB and MyApp::DB::Schema)

    package MyApp::DB::AR;
    use Any::Moose;
    extends 'DBIx::Skinny::AR';

    __PACKAGE__->setup({
        db => 'MyApp::DB',
        validator => {
            module  => 'FormValidator::Simple',
            plugins => [qw(
                FormValidator::Simple::Plugin::DBIC::Unique
                FormValidator::Simple::Plugin::Japanese
                FormValidator::Simple::Plugin::NetAddr::IP
            )],
        },
    });

    1;

create each model class

    package MyApp::Book;
    use Any::Moose;
    extends 'MyApp::DB::AR';

    __PACKAGE__->mk_accessors;

    sub table { 'books' }

    sub default_search_column { 'name' }

    sub validation {
        [
            id           => [ qw/UINT/ ],
            author_id    => [ qw/NOT_BLANK UINT/ ],
            name         => [ qw/NOT_BLANK ASCII/, [ qw/LENGTH 0 255/ ] ],
            { name => [ qw/id name/ ] } => [ [ 'DBIC_UNIQUE', __PACKAGE__, '!id', 'name' ] ],
        ];
    }

    __PACKAGE__->belongs_to('author');

    1;

in your apps

    use MyApp::Book;
    my $book = MyApp::Book->find($book_name);
    $book->name('new name');
    $book->update;

    my $books = MyApp::Book->find_all;

    my $author = $book->author;


=head1 DESCRIPTION

DBIx::Skinny::AR provides some interfaces like ActiveRecord.

 - find/find_all by any conditions
 - return object wrapped DBIx::Skinny::Row
 - validate before create/update
 - support belongs_to/has_one/has_many/many_to_many relationships


=head1 BUGS AND LIMITATIONS

No bugs have been reported.


=head1 AUTHOR

Ryo Miyake  C<< <ryo.studiom@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Ryo Miyake C<< <ryo.studiom@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 SEE ALSO

DBIx::Skinny
