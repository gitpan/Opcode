package Opcode;

$VERSION = "1.00";

require 5.002;

use Carp;
use Exporter ();
use DynaLoader ();
@ISA = qw(Exporter DynaLoader);

BEGIN {
    @EXPORT_OK = qw(
	ops_to_opset
	opset_to_ops opset_to_hex invert_opset
	empty_opset full_opset
	opdesc opcodes opmask define_optag
	opmask_add
    );
}

use subs @EXPORT_OK;


# Todo (maybe)
#	$yes = opset_can($opset, @ops)	true if $opset has all @ops set
#	@diff = opset_diff($opset1, $opset2) => ('foo', '!bar', ...)


sub opset_to_hex {
    return "(invalid opset)" unless verify_opset($_[0]);
    unpack("h*",$_[0]);
}


sub _init_optags {
    my(%all, %seen);
    @all{opset_to_ops(full_opset)} = (); # keys only

    local($/) = "\n=cut"; # skip to optags definition section
    <DATA>;
    $/ = "\n=";		# now read in pod section chunks
    while(<DATA>) {
	next unless m/^item\s+(:\w+)/;
	my $tag = $1;

	# Split into lines, keep only indented lines
	my @lines = grep { m/^\s/    } split(/\n/);
	foreach (@lines) { s/--.*//  } # delete comments
	my @ops   = map  { split ' ' } @lines; # get op words

	foreach(@ops) {
	    warn "$tag - $_ already tagged in $seen{$_}\n" if $seen{$_};
	    $seen{$_} = $tag;
	    delete $all{$_};
	}
	# ops_to_opset will croak on invalid names
	define_optag($tag, ops_to_opset(@ops));
    }
    close(DATA);
    warn "Untagged opnames: ".join(' ',keys %all)."\n" if %all;
}

bootstrap Opcode $VERSION;

_init_optags();

1;

__DATA__

=head1 NAME

Opcode - Disable named opcodes when compiling perl code

=head1 SYNOPSIS

  use Opcode;


=head1 DESCRIPTION

=item an operator mask

Each compartment has an associated "operator mask". Recall that
perl code is compiled into an internal format before execution.
Evaluating perl code (e.g. via "eval" or "do 'file'") causes
the code to be compiled into an internal format and then,
provided there was no error in the compilation, executed.
Code evaulated in a compartment compiles subject to the
compartment's operator mask. Attempting to evaulate code in a
compartment which contains a masked operator will cause the
compilation to fail with an error. The code will not be executed.

By default, the operator mask for a newly created compartment masks
out all operations which give "access to the system" in some sense.
This includes masking off operators such as I<system>, I<open>,
I<chown>, and I<shmget> but does not mask off operators such as
I<print>, I<sysread> and I<E<lt>HANDLE<gt>>. Those file operators
are allowed since for the code in the compartment to have access
to a filehandle, the code outside the compartment must have explicitly
placed the filehandle variable inside the compartment.

(Note: the definition of the default ops is not yet finalised.)

Since it is only at the compilation stage that the operator mask
applies, controlled access to potentially unsafe operations can
be achieved by having a handle to a wrapper subroutine (written
outside the compartment) placed into the compartment. For example,

    $cpt = new Opcode;
    sub wrapper {
        # vet arguments and perform potentially unsafe operations
    }
    $cpt->share('&wrapper');


Confusingly the term 'operator mask' is used to refer to the 'masking
out' of operators during compilation and also to a value defining a set
of operators. The term 'opset' is being more widely used to refer to
the latter but you may still come across mask being used instead.


=head2 Operator Names and Operator Lists

XXX

The canonical list of operator names is the contents of the array
op_name defined and initialised in file F<opcode.h> of the Perl
source distribution (and installed into the perl library).

Each operator has both a terse name and a more verbose or recognisable
descriptive name. The opdesc function can be used to return a list of
descriptions for a list of operators.

Many of the functions and methods listed below take a lists of
operators as parameters. Operator lists can be made up of several
types of elements. Each element can be one of

=over 8

=item an operator name (opname)

XXX

=item an operator tag name (optag)

Operator tags can be used to refer to groups (or sets) of operators.
Tag names always being with a colon. The Opcode module defines several
optags and the user can define others using the define_optag function.

=item a negated opname or optag

XXX

=item an operator set (opset)

An I<opset> as an opaque binary string of approximately 43 bytes which
holds a set or zero or more operators.

The ops_to_opset and opset_to_ops functions can be used to convert from
a list of operators to an opset (and I<vice versa>).

Wherever a list of operators can be given you can use one or more opsets.

=back



=head2 Subroutines in package Opcode

The Opcode package contains subroutines for manipulating operator names
tags and sets. All are available for export by the package.

=over 8

=item ops_to_opset (OP, ...)

This takes a list of operators and returns an opset representing
precisely those operators.

=item opset_to_ops (OPSET)

This takes an opset and returns a list of operator names corresponding
to those operators in the set.

=item full_opset

This just returns opset which includes all operators.

=item empty_opset

This just returns an opset which contains no operators.

This is useful if you want a compartment to make use of the namespace
protection features but do not want the default restrictive mask.

=item define_optag (OPTAG, OPSET)

Define OPTAG as a symbolic name for OPSET. Optag names always start
with a colon C<:>. The optag name used must not be defined already
(define_optag will croak if it is already defined). Optag names are
global to the perl process and optag definitions cannot be altered or
deleted once defined.

It is strongly recommended that applications using Opcode should use a
leading capital letter on their tag names since lowercase names are
reserved for use by the Opcode module. If using Opcode within a module
you should prefix your tags names with the name of your module to
ensure uniqueness.


=item opdesc (OP, ...)

This takes a list of operator names and returns the corresponding list
of operator descriptions.

=item opcodes

In a scalar context opcodes returns the number of opcodes in this
version of perl.

In a list context it returns a list of all the operator names.

=back


=head2 Some Safety Issues

This section is currently just an outline of some of the things code in
a compartment might do (intentionally or unintentionally) which can
have an effect outside the compartment.

=over 8

=item State Changes

Ops such as chdir obviously effect the process as a whole and not just
the code in the compartment. Ops such as rand and srand have a similar
but more subtle effect.

=back

=cut

# the =cut above is used by _init_optags()

=head1 Predefined Opcode Tags

=over 5

=item :base_core

    null stub scalar pushmark wantarray const defined undef

    rv2sv sassign

    rv2av aassign aelem aelemfast aslice

    rv2hv helem hslice each values keys exists -- no delete here

    preinc i_preinc predec i_predec postinc i_postinc postdec i_postdec
    int hex oct abs pow multiply i_multiply divide i_divide modulo
    i_modulo add i_add subtract i_subtract

    left_shift right_shift bit_and bit_xor bit_or negate i_negate
    not complement

    lt i_lt gt i_gt le i_le ge i_ge eq i_eq ne i_ne ncmp i_ncmp
    slt sgt sle sge seq sne scmp

    substr vec stringify study pos length index rindex ord chr

    ucfirst lcfirst uc lc quotemeta trans chop schop chomp schomp

    splice push pop shift unshift reverse

    cond_expr flip flop andassign orassign and or xor

    warn die lineseq nextstate unstack scope enter leave

    entersub leavesub return method -- XXX loops via recursion?

    leaveeval -- needed for Safe to operate, is safe without entereval

=item :base_mem

These memory related ops are not included in :base_core because they
can easily be used to implement a resource attack (e.g., consume all
available memory).

    concat repeat join

    anonlist anonhash

Note that despite the existance of this optag a memory resource attack
may still be possible using only :base_core ops.

Disabling these ops is a I<very> heavy handed way to attempt to prevent
a memory resource attack. It's probable that a specific memory limit
mechanism will be added to perl in the near future.

=item :base_loop

These loop ops are not included in :base_core because they can easily be
used to implement a resource attack (e.g., consume all available CPU time).

    grepstart grepwhile
    mapstart mapwhile
    enteriter iter
    enterloop leaveloop
    last next redo

=item :base_orig

These are a hotchpotch of opcodes still waiting to be considered

    gvsv gv gelem

    padsv padav padhv padany

    pushre

    rv2gv av2arylen rv2cv anoncode prototype refgen
    srefgen ref bless

    glob readline rcatline

    regcmaybe regcomp match subst substcont

    sprintf formline

    crypt

    delete -- hash elem

    split list lslice

    range

    reset

    caller dbstate goto

    tie untie

    dbmopen dbmclose sselect select getc read enterwrite leavewrite
    prtf print sysread syswrite send recv eof tell seek truncate fcntl
    sockpair bind connect listen accept shutdown gsockopt
    getsockname

    ftrwrite ftsvtx

    open_dir readdir closedir telldir seekdir rewinddir

    getppid getpgrp setpgrp getpriority setpriority localtime gmtime

    entertry leavetry

    ghbyname ghbyaddr ghostent gnbyname gnbyaddr gnetent gpbyname
    gpbynumber gprotoent gsbyname gsbyport gservent shostent snetent
    sprotoent sservent ehostent enetent eprotoent eservent

    gpwnam gpwuid gpwent spwent epwent ggrnam ggrgid ggrent sgrent
    egrent


=item :base_math

These ops are not included in :base_core because of the risk of them being
used to generate floating point exceptions (which would have to be caught
using a $SIG{FPE} handler).

    atan2 sin cos exp log sqrt

These ops are not included in :base_core because they have an effect
beyond the scope of the compartment.

    rand srand

=item :default

The default set of ops allowed in a compartment.  (The current ops
allowed are unstable while development continues. It will change.)

    :base_core :base_mem :base_loop :base_orig

=item :subprocess

    backtick system

    fork

    wait waitpid

=item :ownprocess

    exec exit dump syscall kill

    time tms -- could be used for timing attacks (paranoid?)

=item :filesys_open

    sysopen open close umask

=item :filesys_read

    stat lstat readlink

    ftatime ftblk ftchr ftctime ftdir fteexec fteowned fteread
    ftewrite ftfile ftis ftlink ftmtime ftpipe ftrexec ftrowned
    ftrread ftsgid ftsize ftsock ftsuid fttty ftzero

    fttext ftbinary

    fileno

=item :filesys_write

    link unlink rename symlink

    mkdir rmdir

    utime chmod chown

=item :others

This tag holds groups of assorted specialist opcodes that don't warrant
having optags defined for them.

SystemV Interprocess Communications:

    msgctl msgget msgrcv msgsnd

    semctl semget semop

    shmctl shmget shmread shmwrite

=item :still_to_be_decided

    chdir
    chroot
    require dofile 
    binmode
    flock ioctl
    getlogin
    pipe_op socket getpeername ssockopt 
    sleep alarm
    sort
    tied
    pack unpack
    entereval -- can be used to hide code

=item :foo

Just an example to show and test negation

    :default !spwent !sgrent

=back

=cut

###END### special marker for automatic opcode extraction

=head2 AUTHOR

Originally designed and implemented by Malcolm Beattie,
mbeattie@sable.ox.ac.uk as part of Safe version 1.

Split out from Safe module version 1, Optags and other changes added by
Tim Bunce <Tim.Bunce@ig.co.uk>.

=cut

