package QFileman;

sub read {

    my %parm = (
	filename => undef,
	datatype => 'text',
    );

    $parm{filename} = shift;
    my $size = -s $parm{filename};
    open TMP,'<',$parm{filename} or die "$parm{filename}: $!\n";

    $parm{datatype} = shift if scalar @_ > 0;
    if ( $parm{datatype} eq 'text' ) {
	my $data;
    	read TMP, $data, $size;
    	close TMP;
	return $data;
    }
    elsif ( $parm{datatype} eq 'bin' ) {
	binmode(TMP);
	my $buf;
	my $count = $size/8;   # number of double 
	seek TMP, 0, 0;
	read TMP, $buf, $size;
	close TMP;
	return (unpack "d[$count]", $buf);
    }
}

1;

