use strict;
use warnings;

use QParseLib;

package QParse;

sub new {
    my $class = shift;	# Get the class name
    my $self = {
	'data' => undef,
	'batch' => 0
    };

    my $qcout = shift;
    my $data; 
    my $size = -s $qcout;
    open TMP,'<',$qcout or die "Failed to create the object\n$qcout: $!\n";
    read TMP, $data, $size;
    close TMP;
    $self->{'data'} = $data;

    bless $self, $class;
    return $self;
}

sub molecules {
    
    my $self = shift;

    my @geometries = $self->{'data'} =~ m{
    	Standard\ Nuclear\ Orientation.*?----
    	(?:\n|\r\n?)    # looking forward to newline character
    	(.*?)           # coordinate block
    	\ ----
    }smxg;

    my @mol_array = ();
    foreach (@geometries) {
	push @mol_array, Molecule->new( 'geom' => $_ );
    }

    return @mol_array;

}

sub jobs {

    my $self = shift;
    my %parm = @_;
    my @jobs;

	@jobs = $self->{'data'} =~ m{
	    ^\s+?Welcome\ to\ Q-Chem
	    .*?             # coordinate block
	    ^\s+?\*{61}.*?
	    ^\s+?\*\ \ Thank\ you\ very\ much\ for\ using\ Q-Chem.*?
    	    ^\s+?\*{61}.*?
	    (?:\n|\r\n?)    # looking forward to newline character
        }smxg;

    return @jobs;
}

sub charges {
    
    my $self = shift;
    my %parm = @_;
    my @mullcharges;

    if ( defined $parm{'becke'} )
    {
	@mullcharges = $self->{'data'} =~ m{
	    CDFT\ Becke\ Populations.*?----.*?
	    (?:\n|\r\n?)    # looking forward to newline character
	    (.*?)           # coordinate block
	    ----
	}smxg;
    } ## ?? Lowdin ??
    else
    {
    	@mullcharges = $self->{'data'} =~ m{
    	    Mulliken\ Net\ Atomic\ Charges
    	    (?:\n|\r\n?)    # looking forward to newline character
    	    (.*?)           # coordinate block
    	    \s+Sum\ of\ atomic\ charges
	}smxg;
    }

    my @mull_array = ();
    foreach (@mullcharges) {
	push @mull_array, MullChgSpin->new( 'mull' => $_ );
    }

    return @mull_array;

}

sub times {
    
    my $self = shift;
    
    my @times = $self->{'data'} =~ m/
        ^\ Q-[cC]hem\ begins\ on\ (.*?\d\d:\d\d:\d\d\s+\d\d\d\d)
        .*?
        ^\s*?Host:\s+?(.*?)(?:\n|\r\n?)
        .*
        ^\ Total\ job\ time.*?(?:\n|\r\n?)
        ^\ (.*?\d\d:\d\d:\d\d\s+\d\d\d\d)
    /smxg;

    # return time string
    #print $_,"\n" foreach @times;
    return @times;
}

sub moeng {

    my $self = shift;
    
    my @moeng = $self->{'data'} =~ m/
       Orbital\ Energies\ \(a\.u\.\).*?----.*?
       (?:\n|\r\n?)    # looking forward to newline character
       (.*?)           # coordinate block
       ----
    /smxg;

    return @moeng;
}

1;
