use strict;
use warnings;

use QFileman;
use QChemConst;

package Molecule;

sub new {

    my $class = shift;	# Get the class name

    my %parm = @_; 

    my $self = {
	'totatm'=> 0,
	'atm'   => [],
	'x'     => [],
	'y'     => [],
	'z'     => [],
	'num'   => [],
	'ff'	=> [],
	'cn'	=> []
    };

    my $xyzdata = 0;
    my $g03data = 0;
    my $gmxXYZ  = 0;

    $xyzdata = $parm{'geom'} if defined $parm{'geom'};
    $xyzdata = QFileman::read($parm{'xyzfile'}) if defined $parm{'xyzfile'};
    $g03data = $parm{'g03opt'} if defined $parm{'g03opt'};
    $gmxXYZ  = $parm{'gmxXYZ'} if defined $parm{'gmxXYZ'};

    if ( $xyzdata ) {
	#^\s+\d+\s+[a-zA-Z]+?\s+[-]?(?:\d?|\d+)[.]?\d+\s+[-]?(?:\d?|\d+)[.]?\d+\s+[-]?(?:\d?|\d+)[.]?\d+(?:\n|\r\n?)
	#\s?[a-zA-Z]+?\s+[-]?(?:\d?|\d+)[.]?\d+\s+[-]?(?:\d?|\d+)[.]?\d+\s+[-]?(?:\d?|\d+)[.]?\d+\s?(?:\n|\r\n?)
    	my @lines = $xyzdata =~ m{
#	    \s?[a-zA-Z]+?\s+[-]?(?:\d?|\d+)[.]?\d+\s+[-]?(?:\d?|\d+)[.]?\d+\s+[-]?(?:\d?|\d+)[.]?\d+\s*(?:\n|\r\n?)
 	    \s?(?:[a-zA-Z]+?|\d+)\s+[-]?(?:\d?|\d+)[.]?\d+\s+[-]?(?:\d?|\d+)[.]?\d+\s+[-]?(?:\d?|\d+)[.]?\d+\s*(?:\n|\r\n?)
    	}smxg;
       
	foreach (@lines) {
    	    s/^\s*//g;
	    #my ($atnum,$atrep,$x,$y,$z) = split /\s+/, $_;
	    my ($atrep,$x,$y,$z) = split /\s+/, $_;
    	    push @{$self->{atm}}, $atrep;
    	    push @{$self->{x}}, $x;
    	    push @{$self->{y}}, $y;
    	    push @{$self->{z}}, $z;
	}
    	$self->{'totatm'} = scalar @{$self->{atm}};
    }
    elsif ( $g03data ) {
	# Center     Atomic      Atomic             Coordinates (Angstroms)
	# Number     Number       Type             X           Y           Z
	# ---------------------------------------------------------------------
	#      1          6           0       -2.844782   -0.315827   -0.329722
    	my @lines = $g03data =~ m{
	    .*?(?:\n|\r\n?)
    	}smxg;

	foreach (@lines) {
    	    s/^\s*//g;
	    my ($num,$atnum,$atyp,$x,$y,$z) = split /\s+/, $_;
    	    push @{$self->{atm}}, $QChemConst::ELEMENTS[$atnum];
    	    push @{$self->{x}}, $x;
    	    push @{$self->{y}}, $y;
    	    push @{$self->{z}}, $z;
	}
    	$self->{'totatm'} = scalar @{$self->{atm}};
    }
    elsif ( $gmxXYZ ) {
	# frame t= 0.000
        # 1530
	# 1        O       11.400000       14.420000       19.060000
        # ....
        # 2.5 2.5 2.5
	#my @lines = $gmxXYZ =~ m{
	#    \s?\d+\s+[a-zA-Z]+?\s+[-]?(?:\d?|\d+)[.]?\d+\s+[-]?(?:\d?|\d+)[.]?\d+\s+[-]?(?:\d?|\d+)[.]?\d+\s*(?:\n|\r\n?)
	#}smxg;
	my @lines = $gmxXYZ =~ m{
	    .*?(?:\n|\r\n?)
	}smxg;

	splice @lines, 0 ,2;
	splice @lines, -1;
	### DEBUG
	#print $_ foreach (@lines);

	foreach (@lines) {
    	    s/^\s*//g;
	    my ($atnum,$atyp,$x,$y,$z,@mm) = split /\s+/, $_;
    	    push @{$self->{num}}, $atnum;
    	    push @{$self->{atm}}, $atyp;
    	    push @{$self->{x}}, $x;
    	    push @{$self->{y}}, $y;
    	    push @{$self->{z}}, $z;
    	    push @{$self->{ff}}, (splice @mm, 0, 1);
    	    push @{$self->{cn}}, (sprintf "%6d %6d %6d %6d", @mm);
	}
    	$self->{'totatm'} = scalar @{$self->{atm}};
    }
    
    bless $self, $class;
    return $self;
}

sub clone {

    my $self = shift;
    return $self;

}

sub move {

    my $self = shift;
    my ($vx,$vy,$vz) = @_;
    for(my $i=0; $i<$self->{totatm}; $i++)
    {
	$self->{x}[$i] += $vx;
	$self->{y}[$i] += $vy;
	$self->{z}[$i] += $vz;
    }
}

sub print {

    my $self = shift;
    my $parm_key = shift;
    my $parm_val = shift;
    my %parm = ();
    if ( defined $parm_key and defined $parm_val ) {
	%parm = ( "$parm_key" => $parm_val );
    }
    my @atmList = @_;

    if ( defined $parm{'gms'} ) {
    	for(my $i=0; $i<$self->{totatm}; $i++)
    	{
	    printf "%3s   %5.2f   %13.8f %13.8f %13.8f\n",
    	    $self->{atm}[$i],$QChemConst::ELEMENTS{uc $self->{atm}[$i]},
	    $self->{x}[$i],$self->{y}[$i],$self->{z}[$i];
	}
    } elsif ( defined $parm{'gmx'} ) {
	if (@atmList)
       	{
            my $j = 0;
            if ($parm{'gmx'} == 1) {
	        foreach (@atmList)
	        {
	 	    $j = $_ - 1;
    	            printf "%3s       %13.8f %13.8f %13.8f\n",
	            $self->{atm}[$j],$self->{x}[$j],$self->{y}[$j],$self->{z}[$j];
	        }
	    } elsif ($parm{'gmx'} == 2) {
	        foreach (@atmList)
	        {
	 	    $j = $_ - 1;
    	            printf "%3s       %13.8f %13.8f %13.8f  %5d   %s\n",
	            $self->{atm}[$j],$self->{x}[$j],$self->{y}[$j],$self->{z}[$j],
		    $self->{ff}[$j],$self->{cn}[$j];
	        }
	    }
	}
       	else
       	{
            if ($parm{'gmx'} == 1) {
                for(my $i=0; $i<$self->{totatm}; $i++)
       	        {
    	            printf "%3s       %13.8f %13.8f %13.8f\n",
	            $self->{atm}[$i],$self->{x}[$i],$self->{y}[$i],$self->{z}[$i];
	        }
	    } elsif ($parm{'gmx'} == 2) {
                for(my $i=0; $i<$self->{totatm}; $i++)
       	        {
    	            printf "%3s       %13.8f %13.8f %13.8f  %5d   %s\n",
	            $self->{atm}[$i],$self->{x}[$i],$self->{y}[$i],$self->{z}[$i],
		    $self->{ff}[$i],$self->{cn}[$i];
	        }
	    }
        } 
    } else {
	if (@atmList)
	{
	    my $j = 0;
	    foreach (@atmList)
	    {
		$j = $_ - 1;
    	        printf "%3s       %13.8f %13.8f %13.8f\n",
	        $self->{atm}[$j],$self->{x}[$j],$self->{y}[$j],$self->{z}[$j];
	    }
	}
	else
	{
	    for(my $i=0; $i<$self->{totatm}; $i++)
 	    {
    	        printf "%3s       %13.8f %13.8f %13.8f\n",
    	        $self->{atm}[$i],$self->{x}[$i],$self->{y}[$i],$self->{z}[$i];
    	    }
        }
    }
}

sub get_moi_tensor {

    my $self = shift;

    # === moments of inertia tensor ===
    my $Ixx = 0, my $Iyy = 0, my $Izz = 0;
    my $Ixy = 0, my $Ixz = 0, my $Iyz = 0;
    my ($Cx,$Cy,$Cz) = $self->get_geom_center();

    my $m, my $x, my $y, my $z;
    for (my $i=0; $i<$self->{totatm}; $i++)
    {
	$m = $QChemConst::AMASS[$QChemConst::ELEMENTS{$self->{atm}[$i]}];
	$x = $self->{x}[$i];
	$y = $self->{y}[$i];
	$z = $self->{z}[$i];

    	$Ixx += $m * (($y-$Cy)**2 + ($z-$Cz)**2);
    	$Iyy += $m * (($x-$Cx)**2 + ($z-$Cz)**2);
    	$Izz += $m * (($x-$Cx)**2 + ($y-$Cy)**2);
    	$Ixy -= $m * ($x-$Cx) * ($y-$Cy);
    	$Ixz -= $m * ($x-$Cx) * ($z-$Cz);
    	$Iyz -= $m * ($y-$Cy) * ($z-$Cz);
    }
    return ($Ixx,$Iyy,$Izz,$Ixy,$Ixz,$Iyz);
}

sub get_mass_center {

    my $self = shift;

    my $Mx = 0, my $My = 0, my $Mz = 0;
    my $MASS = 0, my $m = 0;

    for (my $i=0; $i<$self->{totatm}; $i++) {
	$m = $QChemConst::AMASS[$QChemConst::ELEMENTS{$self->{atm}[$i]}];
        $Mx += $self->{x}[$i]*$m; $My += $self->{y}[$i]*$m; $Mz += $self->{z}[$i]*$m;
        $MASS += $m;
    }
    $Mx /= $MASS; $My /= $MASS; $Mz /= $MASS;
    return ($Mx,$My,$Mz);
}

sub get_geom_center {

    my $self = shift;

    my $Cx = 0, my $Cy = 0, my $Cz = 0;
    for (my $i=0; $i<$self->{totatm}; $i++) {
        $Cx += $self->{x}[$i]; $Cy += $self->{y}[$i]; $Cz += $self->{z}[$i];
    }
    $Cx /= $self->{totatm}; $Cy /= $self->{totatm}; $Cz /= $self->{totatm};
    return ($Cx,$Cy,$Cz);
}

#
# =============================================================================
# 

package MullChgSpin;

sub new {

    my $class = shift;	# Get the class name
    my $self = {
	'mull'  => undef,
	'num'   => 0,
	'chg'   => [],
	'spin'  => [],
    };

    my %parm = @_; 

    if ( defined $parm{'mull'} ) {

	$self->{'mull'} = $parm{'mull'};

        if ($self->{'mull'} =~ /Spin/)
       	{
            @{$self->{chg}} = $self->{'mull'} =~ m{
	        \d+?\s+[a-zA-Z]+?\s+(.*?)\s+.*?(?:\n|\r\n?)
            }smxg;
    	    @{$self->{spin}} = $self->{'mull'} =~ m{
    	        \d+?\s+[a-zA-Z]+?\s+.*?\s+(.*?)(?:\n|\r\n?)
	    }smxg;
    	}
       	else
       	{
    	    @{$self->{chg}} = $self->{'mull'} =~ m{
    		\d+?\s+[a-zA-Z]+?\s+(.*?)(?:\n|\r\n?)
    	    }smxg;
            # DEBUG
	    #print $_,"\n" foreach @{$self->{chg}};
	}

        $self->{'num'} = @{$self->{chg}};

    } else {
	die "No charges/spins data found";
    }

    
    bless $self, $class;
    return $self;
}

#
# =============================================================================
# 

package MOEng;

sub new {

    my $class = shift;	# Get the class name
    my $self = {
	'noccA'  => 0,
	'nvirA'  => 0,
	'noccB'  => 0,
	'nvirB'  => 0,
	'occA'   => [],
	'virA'   => [],
	'occB'   => [],
	'virB'   => [],
    };

    my $modata = shift @_;
    my %parm = @_; 

    if ( $modata ) {
        # alpha orbital energies
	my @lines = $modata =~ m{
	    \ Alpha\ MOs.*?\ --\ Occupied\ --.*?
            (?:\n|\r\n?)    # looking forward to newline character
            (.*?)           # coordinate block
            (?:\n|\r\n?)    # looking forward to newline character
	    \ --\ Virtual.*?
            (?:\n|\r\n?)    # looking forward to newline character
            (.*?)           # coordinate block
	    (?:^\s+$)
	}smxg;
	#print scalar @lines;
	#print $lines[1];
	$lines[0] =~ s/^\s+//g;
	@{$self->{occA}} = (split /\s+/, $lines[0]);
	$self->{noccA} =  scalar @{$self->{occA}};
	$lines[1] =~ s/^\s+//g;
	@{$self->{virA}} = (split /\s+/, $lines[1]);
	$self->{nvirA} =  scalar @{$self->{virA}};
	#print $_,"\n" foreach @{$self->{virA}};

	if ($modata =~ /Beta/) {
	    my @lines = $modata =~ m{
	        \ Beta\ MOs.*?\ --\ Occupied\ --.*?
                (?:\n|\r\n?)    # looking forward to newline character
                (.*?)           # coordinate block
                (?:\n|\r\n?)    # looking forward to newline character
	        \ --\ Virtual.*?
                (?:\n|\r\n?)    # looking forward to newline character
                (.*)            # coordinate block
                (?:\n|\r\n?)    # looking forward to newline character
	    }smxg;
	    #print scalar @lines;
	    #print $lines[1];
	    $lines[0] =~ s/^\s+//g;
	    @{$self->{occB}} = (split /\s+/, $lines[0]);
	    $self->{noccB} =  scalar @{$self->{occB}};
	    $lines[1] =~ s/^\s+//g;
	    @{$self->{virB}} = (split /\s+/, $lines[1]);
	    $self->{nvirB} =  scalar @{$self->{virB}};
	    #print $_,"\n" foreach @{$self->{virB}};
	}

	#printf "NOccA = %d, NVirA = %d\n",$self->{noccA},$self->{nvirA};
	#printf "NOccB = %d, NVirB = %d\n",$self->{noccB},$self->{nvirB};
    }
    
    bless $self, $class;
    return $self;
}

1;
