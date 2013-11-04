use strict;
use HTML::TreeBuilder 5 -weak;

# Count occurences of $c in string $s
sub count {
	my ( $s, $c ) = @_;
	my $n = 0;
	my $pos = index( $s, $c );
	while ( $pos >= 0 ) {
		$n++;
		$pos = index( $s, $c, $pos + 1 );
	}
	return $n;
}

# Scan the list of nodes looking for <a> nodes outside '(' ')'
sub scan {
	my $c = shift;
	foreach my $n (@_) {
		if ( ref($n) eq '' ) {
			$c->[0] += count( $n, '(' ) - count( $n, ')' );
		} else {
			return $n if $n->tag() eq "a" && $c->[0] == 0;
			my $a = scan( $c, $n->content_list() );
		}
	}
	return undef;
}

my %pages = map { '/wiki/' . $_ => $_ } qw'Philosophy Fact Argument Logic';

my $page = '/wiki/Special:Random';

#my $page = '/wiki/Feminist';
for ( my $i = 0 ; $i < 40 ; $i++ ) {
	my $tree =
	  HTML::TreeBuilder->new_from_url( "http://en.wikipedia.org" . $page );
	my $title = $tree->find_by_tag_name('title');
	unless ( defined $title ) {
		print "No title in $page\n";
		exit 1;
	}
	$title = $title->as_text();
	$title =~ s/ - Wikipedia.*//;
	$pages{$page} = $title;
	print $title, "\n";

	my $doc = $tree->look_down( id => 'mw-content-text' );

	# consider only the first paragraph
	my @list = $doc->content_list();
	while ( $list[0]->tag() ne "p" ) {
		my $n = shift @list;
	}
	my $p = shift @list;

# Strip the following nodes as we are not interested in <a> tags contained in them.
	$_->detach() foreach $p->look_down( class      => qr'^IPA' );
	$_->detach() foreach $p->look_down( 'xml:lang' => qr'.+' );
	$_->detach() foreach $p->look_down( class      => 'nowrap' );
	$_->detach() foreach $p->find_by_tag_name( 'sup', 'i' );
	$p->normalize_content();

	my $a = scan [0], $p->content_list();
	if ($a) {
		$page = $a->attr('href');

		#print $a->as_text(), ' => ', $page, "\n";
		next unless $pages{$page};
		print $pages{$page}, "\n";
	} else {
		print "No link found in $page\n";
		$p->dump;
	}
	last;
}
