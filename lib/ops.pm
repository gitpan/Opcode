package ops;

use Opcode qw(opmask_add opset invert_opset);

sub import {
    shift;
    # Not that unimport is the prefered form since import's don't
	# accumulate well owing to the 'only ever add opmask' rule.
	# E.g., perl -Mops=:set1 -Mops=:setb is unlikely to do as expected.
    opmask_add(invert_opset opset(@_));
}

sub unimport {
    shift;
    opmask_add(opset(@_));
}

1;

__END__

=head1 NAME

ops - Perl pragma to restrict unsafe operations when compiling
 
=head1 SYNOPSIS  
 
  perl -Mops=:default ...    # only allow reasonably safe operations

  perl -M-ops=system ...     # disable the 'system' opcode
 
=head1 DESCRIPTION

Since the ops pragma currently has an irreversable global effect, it is
only of significant practical use with the C<-M> option on the command line.

See the L<Opcode> module for information about opcodes, optags, opmasks
and important information about safety.

=head1 SEE ALSO

Opcode(3), Safe(3), perlrun(3)
 
=cut

