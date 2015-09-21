#!/usr/bin/perl


use strict;


sub load_predictions {
    my $fname = $_[0]; # weka output
 
    my @predictions = ();
    my @actual = ();
    
    open(FFILE,"<$fname");
    my $header;
    while (<FFILE>) { 
        chomp;
        $header = $_;
        last if ($header =~ /inst/);
    }
    $header =~ s/^\s+//; 
    $header =~ s/\s+$//;
    my @attrs = split(/\s+/,$header);
    my $pred_index = 0;
    my $act_index  = 0;
    for (my $i=0; $i <= $#attrs; $i++) { 
        if ($attrs[$i] =~ /^predicted/i && !$pred_index) {
            $pred_index = $i; 
        }
        if ($attrs[$i] =~ /^actual/i && !$act_index) {
            $act_index = $i; 
        }
    }
    if (!$pred_index || !$act_index) {
        print "Parse error in $fname!";
    }
    else {
        while(<FFILE>) {
            chomp;
            my $line = $_;
            #my $line=&chop_newline($_);
            $line =~ s/^\s+//; 
            $line =~ s/\s+$//;
            my @els = split(/\s+/,$line);
            if (($#els > 0) && ($els[$pred_index]) && ($els[$act_index]) && ($els[0] =~ /^\d+$/)) {
                push(@predictions, $els[$pred_index]);
                push(@actual,      $els[$act_index]);
            #    print "pred = $els[$pred_index]\n";
            #    print "act  = $els[$act_index]\n";
            }
        }
        close(FFILE);
    }
    
    return (\@predictions, \@actual);
}


1;
