package DBIx::Skinny::AR;

our $VERSION = '0.0.1';

use Carp;
use Lingua::EN::Inflect::Number qw/to_S to_PL/;

use Any::Moose;
extends any_moose('::Object'), 'Class::Data::Inheritable';

__PACKAGE__->mk_classdata('db');
__PACKAGE__->mk_classdata('unique_columns' => []);

has 'row' => (
    is      => 'rw',
    isa     => 'DBIx::Skinny::Row',
    trigger => \&_set_columns,
);

sub BUILD {
    my $self = shift;
    $self->_chk_unique_value($_) for @{ $self->unique_columns };
}

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
    $class->_ensure_load_class($db_class);
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
    my ($self, $where) = @_;
    $self->db->count(
        $self->table,
        $self->_pk,
        $self->_get_where($where)
    );
}

sub reload {
    my ($self) = @_;
    croak 'Reload not allowed call as class method' unless ref $self;
    my $pk = $self->_pk;
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

sub set_unique_columns {
    my ($class, $columns) = @_;
    $columns = [ $columns ] unless ref $columns eq 'ARRAY';
    $class->unique_columns($columns);
    $class->_set_unique_column($_) for @$columns;
}

sub _set_unique_column {
    my ($class, $column) = @_;
    my $attr = $class->meta->get_attribute($column);
    if ( $attr && $class->can($column) ) {
        $class->meta->add_after_method_modifier($column, sub {
            my $self = shift;
            $self->_chk_unique_value($column) if @_;
        });
    }
}

sub _chk_unique_value {
    my ($self, $key) = @_;
    my $where = { $key => $self->$key };
    my $pk = $self->_pk;
    $where->{ $pk } = { '!=' => $self->$pk } if $self->$pk;
    croak "Attribute ($key) does not pass the type constraint because: ".
        $self->$key. " is not a unique value." if $self->count($where);
}

sub belongs_to {
    my ($class, $method, $params) = @_;
    croak 'belongs_to needs method name' unless $method;

    my $target_class = $params->{ target_class }
        || $class->_get_namespace . ucfirst $method;
    $class->_ensure_load_class($target_class);
    my $target_key = $params->{ target_key } || $target_class->_pk;
    my $self_key = $params->{ self_key } || $method . '_' . $target_class->_pk;
    my $clearer = 'clear_' . $method;

    $class->meta->add_attribute(
        $method,
        is       => 'ro',
        isa      => $target_class,
        #weak_ref => 1,
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

    my $self_key = $params->{ self_key } || $class->_pk;
    my $target_class = $params->{ target_class }
        || $class->_get_namespace . ucfirst $method;
    $class->_ensure_load_class($target_class);
    my $target_key = $params->{ target_key }
        || lc $class->_get_suffix . '_' . $class->_pk;

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

    my $self_key = $params->{ self_key } || $class->_pk;
    my $target_class = $params->{ target_class }
        || $class->_get_namespace . ucfirst(to_S $method);
    $class->_ensure_load_class($target_class);
    my $target_key = $params->{ target_key }
        || lc $class->_get_suffix . '_' . $class->_pk;

    $class->meta->add_attribute(
        $method,
        is       => 'ro',
        isa      => "ArrayRef[$target_class]",
        #weak_ref => 1,
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
    my $self_key = $params->{ self_key } || $class->_pk;
    my $target_class = $params->{ target_class }
        || $class->_get_namespace . ucfirst $target;
    $class->_ensure_load_class($target_class);
    my $target_key = $params->{ target_key }
        || $target_class->_pk;

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
        || lc $class->_get_suffix . '_' . $class->_pk;
    my $glue_target_key = $params->{ glue }->{ target_key }
        || $target . '_' . $target_class->_pk;

    $class->meta->add_attribute(
        $method,
        is       => 'ro',
        isa      => "ArrayRef[$target_class]",
        #weak_ref => 1,
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
