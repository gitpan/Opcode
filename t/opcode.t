#!./perl -w
$|=1;
#BEGIN {
#    chdir 't' if -d 't';
#    @INC = '../lib';
#    require Config; import Config;
#    if ($Config{'extensions'} !~ /\bSafe\b/ && $Config{'osname'} ne 'VMS') {
#        print "1..0\n";
#        exit 0;
#    }
#}

# Tests Todo:
#	'main' as root

use Opcode qw(opdesc ops_to_opset opset_to_ops opset_to_hex invert_opset
	opmask_add full_opset empty_opset
		opcodes opmask define_optag);

use strict;

my $t = 1;
my $last_test; # initalised at end
print "1..$last_test\n";

my($m1, $m2, $m3);
my(@o1, @o2, @o3);

# --- opset_to_ops and ops_to_opset

my @empty_l = opset_to_ops(empty_opset);
print @empty_l == 0 ?   "ok $t\n" : "not ok $t\n"; $t++;

my @full_l1  = opset_to_ops(full_opset);
print @full_l1 == opcodes() ? "ok $t\n" : "not ok $t\n"; $t++;

@empty_l = opset_to_ops(ops_to_opset(':none'));
print @empty_l == 0 ?   "ok $t\n" : "not ok $t\n"; $t++;

my @full_l2 = opset_to_ops(ops_to_opset(':all'));
print  @full_l1  ==  @full_l2  ? "ok $t\n" : "not ok $t\n"; $t++;
print "@full_l1" eq "@full_l2" ? "ok $t\n" : "not ok $t\n"; $t++;

die $t unless $t == 6;
$m1 = ops_to_opset(qw(padsv));
$m2 = ops_to_opset($m1, 'padav');
$m3 = ops_to_opset($m2, '!padav');
print $m1 eq $m2 ? "not ok $t\n" : "ok $t\n"; ++$t;
print $m1 eq $m3 ? "ok $t\n" : "not ok $t\n"; ++$t;

# --- define_optag

print eval { ops_to_opset(':_tst_') } ? "not ok $t\n" : "ok $t\n"; ++$t;
define_optag(":_tst_", ops_to_opset(qw(padsv padav padhv)));
print eval { ops_to_opset(':_tst_') } ? "ok $t\n" : "not ok $t\n"; ++$t;

# --- opdesc and opcodes

die $t unless $t == 10;
print opdesc("gv") eq "glob value" ? "ok $t\n" : "not ok $t\n"; $t++;
my @desc = opdesc(':_tst_','stub');
print "@desc" eq "private variable private array private hash stub"
				    ? "ok $t\n" : "not ok $t\n#@desc\n"; $t++;
print opcodes() ? "ok $t\n" : "not ok $t\n"; $t++;
print "ok $t\n"; ++$t;

# --- invert_opset

$m1 = ops_to_opset(qw(fileno padsv padav));
@o2 = opset_to_ops(invert_opset($m1));
print @o2 == opcodes-3 ? "ok $t\n" : "not ok $t\n"; $t++;

# --- opmask

die $t unless $t == 15;
print opmask() eq empty_opset() ? "ok $t\n" : "not ok $t\n"; $t++;	# work
print length opmask() == int(opcodes()/8)+1 ? "ok $t\n" : "not ok $t\n"; $t++;

# --- opmask_add

print 1 ? "ok $t\n" : "not ok $t\n"; $t++;
opmask_add(ops_to_opset(qw(fileno)));	# add to global op_mask
print eval 'fileno STDOUT' ? "not ok $t\n" : "ok $t\n";	$t++; # fail
print $@ =~ /fileno trapped/ ? "ok $t\n" : "not ok $t\n# $@\n"; $t++;

# --- check opname assertions

foreach(@full_l1) {
    die "bad opname: $_" if /\W/ or /^\d/;
}

print "ok $last_test\n";
BEGIN { $last_test = 20 }
