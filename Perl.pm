package Template::Perl;

use strict;
use Carp;
use vars	qw( @ISA $VERSION );
#use base Parse::Tokens;
use Parse::Tokens;
@ISA = ('Parse::Tokens');

$VERSION = 0.17;

sub new
{
    my( $class, $params ) = @_;
    my $self = $class->SUPER::new;
    $self->delimiters(['[-','-]']);	# default delimiters
    $self->autoflush(1);			# default to no caching
	$self->init($params);
	$self;
}

sub init
{
    my( $self, $params ) = @_;
	no strict 'refs';
	for ( keys %$params )
	{
		my $ref = lc $_;
		$self->$ref($params->{$_});
	}
	use strict;
}

sub hash
{
	my( $self, $hash ) = @_;
	if ( $hash ){
		$self->{HASH} = $hash;
		$self->_install( $self );
	}
	return $self->{HASH};
}

sub package
{
	my( $self, $package ) = @_;
	$self->{PACKAGE} = $package if $package;
	# default to package main
	return $self->{PACKAGE} || 'main';
}

sub file
{
	my( $self, $file ) = @_;
	if( $file )
	{
		$self->{FILE} = $file;
		$self->text( &_get_file( $self->{FILE} ) );
	}
	return $self->{FILE};
}

sub parsed
{
    my( $self ) = @_;
	return $self->{PARSED};
}

# overide SUPER::parse
sub parse
{
	my( $self, $params ) = @_;
	$self->{PARSED} = undef;
	$self->init( $params );
	return unless $self->{TEXT};
	$self->SUPER::parse();
	return $self->{PARSED};
}

# overide SUPER::token
sub token
{
	my( $self, $token) = @_;
	my $package = $self->package();
	no strict 'vars';
	$self->{PARSED} .= eval qq{
		package $package;
		$token->[1];
	};
	carp $@ if $@;
	use strict;
}

# overide SUPER::ether
sub ether
{
	my( $self, $text ) = @_;
	$self->{PARSED} .= $text;
}

# install a given hash in a package for later use
sub _install
{
	my( $self ) = @_;
	my $hash = $self->{HASH};
	$self->package( 'Safe' );		# set package name
	no strict 'refs';
	for( keys %{$hash} )
	{
		next unless defined $hash->{$_};
		*{"Safe::$_"} = \$hash->{$_};
	}
	use strict;
	return 'Safe';
#	die $self->package();
}

sub _get_file
{
	my( $file ) = @_;
	local *IN;
	open IN, $file || return;
   	local $/;
	my $text = <IN>;
	close IN;
	return $text;
}

1;



__END__

=head1 NAME

Template::Perl - a module to evaluate perl code embedded in text.

=head1 SYNOPSIS

  use Template::Perl;
  my $t = Template::Perl->new();

  my $template = q{
    Yo nombre es [- $name -].
    I am [- $age -] years old.    	
  };

  # initialize a couple vars in package 'main'
  my $name = 'Steve';
  my $age  = 31;

  # parse defaults to package 'main' (unless a hash has been loaded)
  print $t->parse({
      TEXT	=> $text
  });

  # or...use a hash ( slower, but easier to work with )

  my %hash = (
    name => 'Steve',
    age  => 31
  );

  print $t->parse({
      TEXT	=> $text,
      HASH	=> \%hash
  });

  # ...or however you like it, as long as text and hash or package name 
 # is loaded before or when parse() is called.

=head1 DESCRIPTION

C<Template::Perl> a module for evaluating perl embedded in text. The perl is evaluated under a package, or under a package built from a hash. This module was built primarily as a demonstration of C<Parse::Tokens>, but it works great.

=head1 FUNCTIONS

=over 10

=item hash()

$t->hash();

Installs values identified by a given hash reference into a package under which to evaluate perl tokens.

=item new()

my $t = Template::Perl->new();

Optionally pass a hash reference of FILE, TEXT, PACKAGE, HASH, or DELIMITERS fields.

FILE = valid path (your template) or...

TEXT = block of text (your template)

PACKAGE = name of a package (your data) or...

HASH = hash reference (your data)

DELIMITERS = array reference to left and right delimiters

=item package()

$t->package('package_name');

Set the package name under which to evaluate extracted perl.

=item parse()

$t->parse();

Runs the parser. Optionally accepts parameters as specified for new();.

=item parsed();

$text = $t->parsed();

Returns the fully parsed and evaluated text.

=back

=head1 AUTHOR

Steve McKay, steve@colgreen.com

=head1 COPYRIGHT

Copyright 2000 Steve McKay. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

C<Parse::Tokens>, C<Text::Template>, C<Text::SimpleTemplate>

=cut
