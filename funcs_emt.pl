# 
use File::Basename;
use Cwd;
$BaseDir = dirname($0);
require "$BaseDir/config.inc"; 


#my $pos="SL";
#my $neg="NSL";

######################################################################################
###This function used for processing numbers
sub round {
	my ($number) = shift;
	return int($number + .5);
}
sub floor {
	my ($number) = shift;
	return int($number);
}
sub ceil {
	my ($number) = shift;
	my $number_int = int($number);
	if ($number_int == $number){
		return $number_int;
	} else {
		return $number_int+1;
	}
}

#######################################################################################
# this fuction used for select the instances randomly
# return a instance IDs array.
# use: &inst_slt_rdm ($featurefile, $SltInstNr)
sub SltID_rdm {
	my $featfl = shift(@_);
	my $SltInstNr = shift(@_);
	# caculate the total instance Nr.
	open (FF, "<$featfl");
	my $TlInstNr = 0;
	while (<FF>){
		if (($_ =~ /^[0-9]/)||($_ =~ /\'(.*)\'/)){
			$TlInstNr++;
		}
	}
	print "Total instance Nr. is $TlInstNr\n";
	close FF;
	
	# generate a random array
	unless ($SltInstNr <= $TlInstNr){$SltInstNr = $TlInstNr; print "The select nr. is replaced by total instance Nr.\n ";}
	my $i=0;   
	my %rand;
	while   (1)   { 
		srand();
        my $no   =   int(rand($TlInstNr)) +1;
        if   (!$rand{$no})   {   $rand{$no}=1;   $i++;  }
        last   if   ($i >= $SltInstNr); 
	} 
	my @SltInsts  =   keys   %rand;
	# print "@SltInsts\n\n\n";
	return @SltInsts;
}


#######################################################################################
# Active learning: for select instances with lowest score based on prediction result
# input prediction file and instance selected nr., return the instance IDs array.

sub SltID_actv_l{
my $pred = $_[0];  # input prediction file
my $sltNr = $_[1];    # input the selected instance nr.
print "The selected instance Nr. is $sltNr\n";

open (PD, "<$pred");
my %ID_score;
my $n = 0;

# read the prediction file
while (<PD>){
    if ($_ =~ /\:/){
        my @infs = split(" ", $_);
        if ($infs[1] eq $infs[2]){$ID_score{$infs[0]} = $infs[3];}
        else {$ID_score{$infs[0]} = $infs[4];}
        $n++;
    }
}
print "The total instance Nr is $n\n";
close PD;

# select the instance ID based on lower score
my @sltInsts;
my @insts = sort { $ID_score{$a} <=> $ID_score{$b} or $a <=> $b } keys %ID_score; # from low score to high score
#my @insts = sort { $ID_score{$b} <=> $ID_score{$a} or $a <=> $b } keys %ID_score; # from high score to low score

# foreach (@insts){
	# print "$_ => $ID_score{$_}\n";
# }

unless ($sltNr <= $n){$sltNr = $n; print "The select nr. is replaced by total instance Nr.\n ";}
foreach (0..$sltNr-1){$sltInsts[$_] = $insts[$_];}
return @sltInsts;
}

#######################################################################################
# Active learning: for select instances based on co-Testing  (predict different and with high confidence)
# input: prediction file and instance selected nr., 
# Output: Instance IDs array.

sub SltID_actv_coTest{
	my $pred1 = $_[0];  # input the first view
	my $pred2 = $_[1];	# input the second view
	my $sltNr = $_[2];    # input the selected instance nr.
	print "The selected instance Nr. is $sltNr\n";

	my %ID_score;
	my %ID_score1;
	my %ID_score2;
	
	open (PD1, "<$pred1");
	open (PD2, "<$pred2");
	my $n = 0;
	my $m = 0;
	# read the prediction file
	while (<PD1>){
		if ($_ =~ /\:/){
			my @infs1 = split(" ", $_);
			if ($infs1[1] eq $infs1[2]){$ID_score1{$infs1[0]} = $infs1[3];}
			else {$ID_score1{$infs1[0]} = $infs1[4];}
			if ($infs1[2] =~ /$neg/){$ID_score1{$infs1[0]} = -$ID_score1{$infs1[0]};}
			$n++;
		}
	}
	while (<PD2>){
		if ($_ =~ /\:/){
			my @infs2 = split(" ", $_);
			if ($infs2[1] eq $infs2[2]){$ID_score2{$infs2[0]} = $infs2[3];}
			else {$ID_score2{$infs2[0]} = $infs2[4];}
			if ($infs2[2] =~ /$neg/){$ID_score2{$infs2[0]} = -$ID_score2{$infs2[0]};}
			$m++;
		}
	}
	print "The total instance Nr is $n\n";
	close PD1;
	close PD2;
	
	if ($n == $m){
		foreach (1..$n){
			# my $diff = abs($ID_score1{$_} - $ID_score2{$_});
			my $diff = abs(abs($ID_score1{$_} - $ID_score2{$_}) - 1);
			$ID_score{$_} = $diff;
		}
	}else 
	{
		print "The instances number of two predition files is not same.\n";
		return 0;
	}


	# select the instance ID based on lower score
	my @sltInsts;
	my @insts = sort { $ID_score{$a} <=> $ID_score{$b} or $a <=> $b } keys %ID_score; # from low score to high score
	# my @insts = sort { $ID_score{$b} <=> $ID_score{$a} or $a <=> $b } keys %ID_score; # from high score to low score

	# foreach (@insts){
		# print "$_ => $ID_score{$_}\n";
	# }

	unless ($sltNr <= $n){$sltNr = $n; print "The select nr. is replaced by total instance Nr.\n ";}
	foreach (0..$sltNr-1){$sltInsts[$_] = $insts[$_];}
	return @sltInsts;
}


#######################################################################################
# Active learning: for select instances with middlest score based on prediction result
# input prediction file and instance selected nr., return the instance IDs array.

sub SltID_actv_m{
	my $pred = $_[0];  # input prediction file
	my $sltNr = $_[1];    # input the selected instance nr.
	print "The selected instance Nr. is $sltNr\n";
	my $iter = $_[2];	# input the iteration nr.
	my $i = $_[3];	# thisis the ith iteration

	open (PD, "<$pred");
	my %ID_score;
	my $n = 0;

	# read the prediction file
	while (<PD>){
		if ($_ =~ /\:/){
			my @infs = split(" ", $_);
			if ($infs[1] eq $infs[2]){
				$ID_score{$infs[0]} = $infs[3];
			}
			else {
				$ID_score{$infs[0]} = $infs[4];
			}
			$n++;
		}
	}
	print "The total instance Nr is $n\n";
	close PD;

	# select the instance ID based on lower score
	my @sltInsts;
	my %ID_pred; 
	#my @insts = sort { $ID_score{$a} <=> $ID_score{$b} or $a <=> $b } keys %ID_score; # from low score to high score
	my @insts = sort { $ID_score{$b} <=> $ID_score{$a} or $a <=> $b } keys %ID_score; # from high score to low score

	# foreach (@insts){
		# print "$_ => $ID_score{$_}\n";
	# }

	# consider the following three situations
	my $start;
	my $end;
	if ($n <= $sltNr){$start = 0; $end = $n -1; print "Active learning: Total N is <= $sltNr. Start: $start, End: $end \n";} 
	if ($n > $sltNr) {$start = &floor($n/2) - $sltNr/2; $end = &floor($n/2) + $sltNr/2 -1; }
	
	foreach ($start..$end){$sltInsts[$_-$start] = $insts[$_];}
	return @sltInsts;
}



#######################################################################################
# Active learning: for select instances based on co-Testing  (predict different and with high confidence)
# input: prediction file and instance selected nr., 
# Output: Instance IDs array.

sub SltID_actv_coActv{
	my $pred1 = $_[0];  # input the first view
	my $pred2 = $_[1];	# input the second view
	my $sltNr = $_[2];    # input the selected instance nr.
	print "The selected instance Nr. is $sltNr\n";
	
	my @array1 = &SltID_actv_m($pred1, $sltNr/2);
	my @array2 = &SltID_actv_m($pred2, $sltNr/2);
	my @sltInsts;
	push (@sltInsts, @array1);
	push (@sltInsts, @array2);	
	return @sltInsts;
}


#######################################################################################
# semi-supervise learning:  for selecting instances with highest score based on prediction result
# input prediction file and instance selected nr., returning back a hash $hash{$ID} = $pred.

sub SltID_smsp{
	my $pred = $_[0];  # input prediction file
	my $sltNr = $_[1];    # input the selected instance nr.
	#print "The selected instance Nr. is $sltNr\n";
	my $iter = $_[2];	# input the iteration nr.
	my $i = $_[3];	# thisis the ith iteration

	open (PD, "<$pred");
	my %ID_score;
	my %ID_pred_all;
	my $n = 0;

	# read the prediction file
	while (<PD>){
		if ($_ =~ /\:/){
			my @infs = split(" ", $_);
			my ($c, $pred) = split ("\:", $infs[2]);
			$ID_pred_all{$infs[0]} = $pred;
			if ($infs[1] eq $infs[2]){
				$ID_score{$infs[0]} = $infs[3];
			}
			else {
				$ID_score{$infs[0]} = $infs[4];
			}
			$n++;
		}
	}
	#print "The total instance Nr is $n\n";
	close PD;

	# select the instance ID based on lower score
	my @sltInsts;
	my %ID_pred; 
	#my @insts = sort { $ID_score{$a} <=> $ID_score{$b} or $a <=> $b } keys %ID_score; # from low score to high score
	my @insts = sort { $ID_score{$b} <=> $ID_score{$a} or $a <=> $b } keys %ID_score; # from high score to low score

	# foreach (@insts){
		# print "$_ => $ID_score{$_}\n";
	# }
	
	if ($n <= $sltNr){$sltNr = $n; print "Total N is <= $sltNr. \n";}
	foreach (0..$sltNr-1){$ID_pred{$insts[$_]} = $ID_pred_all{$insts[$_]};}
	return \%ID_pred;
}


#######################################################################################
# semi-supervise learning:  for selecting instances with highest confidence score and ratio of positive:all 
# input: prediction file and instance selected nr., 
# output: $hash{$ID} = $pred

sub SltID_smsp_ratio{
	my $pred = $_[0];  # input prediction file
	my $sltNr = $_[1];    # input the selected instance nr.
	my $ratio = $_[2];	# input percent of postive:all

	open (PD, "<$pred");
	my %ID_score;
	my %ID_pred_all;
	my $n = 0;

	# read the prediction file
	while (<PD>){
		if ($_ =~ /\:/){
			my @infs = split(" ", $_);
			my ($c, $pred) = split ("\:", $infs[2]);
			$ID_pred_all{$infs[0]} = $pred;
			if ($infs[1] eq $infs[2]){
				$ID_score{$infs[0]} = $infs[3];
			}
			else {
				$ID_score{$infs[0]} = $infs[4];
			}
			$n++;
		}
	}
	#print "The total instance Nr is $n\n";
	close PD;

	# select the instance ID based on lower score
	my @sltInsts;
	my %ID_pred; 
	#my @insts = sort { $ID_score{$a} <=> $ID_score{$b} or $a <=> $b } keys %ID_score; # from low score to high score
	my @insts = sort { $ID_score{$b} <=> $ID_score{$a} or $a <=> $b } keys %ID_score; # from high score to low score

	# foreach (@insts){
		# print "$_ => $ID_score{$_}\n";
	# }
	my $p = 0;
	my $n = 0;
	foreach (0..$#insts){
		if (($p < $sltNr*$ratio) && ($ID_pred_all{$insts[$_]} =~ /$pos/)) {
			$ID_pred{$insts[$_]} = $ID_pred_all{$insts[$_]};
			$p++;
		}
		if (($n < $sltNr*(1-$ratio)) && ($ID_pred_all{$insts[$_]} =~ /$neg/)){
			$ID_pred{$insts[$_]} = $ID_pred_all{$insts[$_]};
			$n++;
		}
	}
	return \%ID_pred;
}

###################################################################################
### Mixing semi-supervise and active learning: for selecting instances based on certainty (Former: high confidence; Later: middle confidence)
### input prediction file and instance selected nr., returning back a hash $hash{$ID} = $pred.

sub SltID_ActvSmsp_smsp{
	my $pred = $_[0];  # input prediction file
	my $sltNr = $_[1];    # input the selected instance nr.
	#print "The selected instance Nr. is $sltNr\n";
	my $iter = $_[2];	# input the iteration nr.
	my $i = $_[3];	# thisis the ith iteration

	open (PD, "<$pred");
	my %ID_score;
	my %ID_pred_all;
	my $n = 0;

	# read the prediction file
	while (<PD>){
		if ($_ =~ /\:/){
			my @infs = split(" ", $_);
			my ($c, $pred) = split ("\:", $infs[2]);
			$ID_pred_all{$infs[0]} = $pred;
			if ($infs[1] eq $infs[2]){
				$ID_score{$infs[0]} = $infs[3];
			}
			else {
				$ID_score{$infs[0]} = $infs[4];
			}
			$n++;
		}
	}
	#print "The total instance Nr is $n\n";
	close PD;

	# select the instance ID based on lower score
	my @sltInsts;
	my %ID_pred; 
	#my @insts = sort { $ID_score{$a} <=> $ID_score{$b} or $a <=> $b } keys %ID_score; # from low score to high score
	my @insts = sort { $ID_score{$b} <=> $ID_score{$a} or $a <=> $b } keys %ID_score; # from high score to low score

	# foreach (@insts){
		# print "$_ => $ID_score{$_}\n";
	# }

	if ($n <= 2 * $sltNr){$sltNr = &floor($n/2); print "Active: Total N is <= 2*$sltNr. \n";}
	foreach (0..$sltNr-1){$ID_pred{$insts[$_]} = $ID_pred_all{$insts[$_]};}
	return \%ID_pred;
}

###################################################################################
### Active learning: for seleceting instances with middle score
### input prediction file and instance selected nr., returning back a array

sub SltID_ActvSmsp_actv{
	my $pred = $_[0];  # input prediction file
	my $sltNr = $_[1];    # input the selected instance nr.
	print "The selected instance Nr. is $sltNr\n";
	my $iter = $_[2];	# input the iteration nr.
	my $i = $_[3];	# thisis the ith iteration

	open (PD, "<$pred");
	my %ID_score;
	my $n = 0;

	# read the prediction file
	while (<PD>){
		if ($_ =~ /\:/){
			my @infs = split(" ", $_);
			if ($infs[1] eq $infs[2]){
				$ID_score{$infs[0]} = $infs[3];
			}
			else {
				$ID_score{$infs[0]} = $infs[4];
			}
			$n++;
		}
	}
	print "The total instance Nr is $n\n";
	close PD;

	# select the instance ID based on lower score
	my @sltInsts;
	my %ID_pred; 
	#my @insts = sort { $ID_score{$a} <=> $ID_score{$b} or $a <=> $b } keys %ID_score; # from low score to high score
	my @insts = sort { $ID_score{$b} <=> $ID_score{$a} or $a <=> $b } keys %ID_score; # from high score to low score

	# foreach (@insts){
		# print "$_ => $ID_score{$_}\n";
	# }

	# consider the following three situations
	my $start;
	my $end;
	if ($n <= 2*$sltNr){$start = &floor($n/2); $end = $n -1; print "Semi-supervise: Total N is <= 2*$sltNr. Start: $start, End: $end \n";} 
	if (($n > 2*$sltNr) && ($n <= 3*$sltNr)){$start = $sltNr; $end = 2*$sltNr - 1; print "Semi-supervise: Total N is <= 3*$sltNr and > 2*$sltNr. Start: $start, End: $end \n";}
	if ($n > 3*$sltNr) {$start = &floor($n/2) - $sltNr/2; $end = &floor($n/2) + $sltNr/2 -1; }
	
	foreach ($start..$end){$sltInsts[$_-$start] = $insts[$_];}
	return @sltInsts;
}

#######################################################################################
# this fuction used for selecting the instance IDs based on class
# input prediction file and instance selected nr., return the instance IDs array.

sub SltID_ActvSmsp_actv_inst{
	my $pred = $_[0];  # input prediction file
	my $SltInstNr = $_[1];    # input the selected instance nr.
	my $SmspSlt = $_[2];	# input hash which displays the instances selected by semi-supervise learning

	open (PD, "<$pred");
	my @Insts_class;
	my $TlInstNr = 0;
	my $totalNEG = 0;
	my $rn;
	# read the prediction file
	while (<PD>){
		if ($_ =~ /\:/){
			my @infs = split(" ", $_);
			# select the instance ID which were predicted to a fixed class, like NEG
			if ($infs[2] =~ /$neg/){
				push (@Insts_class, "$infs[0]");
				if ($infs[2] eq $infs[1]){$rn++;} # this is used to caculate the accuracy
				$totalNEG++;
			}
			$TlInstNr++;
		}
	}
	print "The right NEG nr is $rn; total NEG is $totalNEG\n";
	print "The total instances Nr is $TlInstNr;\n";
	close PD;

	# select the instance ID array randomly within a given class
	my @SltInsts;

	if (2*$SltInstNr <= ($#Insts_class+1)){
	    my $i=0;   
	    my %rand;
	    while   (1)   { 
		srand();
		my $no   =   int(rand($#Insts_class+1));
		my $ID = $Insts_class[$no]; if ($SmspSlt->{$ID}){print ".....$ID\n";}
		if   (!$rand{$no})  {   
		      $rand{$no}=1;    
		      if(!$SmspSlt->{$ID}) { $i++; push (@SltInsts, $Insts_class[$no]);}
		      
		}
		last   if   ($i >= $SltInstNr); 
	    } 
	    return @SltInsts;
	}
	elsif (2*$SltInstNr > ($#Insts_class+1)){
	    my $r=0;
	    foreach my $instID (keys %$SmspSlt){
		if ($SmspSlt->{$instID} =~ /$neg/){$r++;}
            }
print "There is $r instances in semi-supervised learning area.\n";
	    if (($r + $SltInstNr) > ($#Insts_class+1)){$SltInstNr = $#Insts_class + 1 - $r; print "Nr. choiced is $SltInstNr Less than defined instances Nr.\n";}
	    my $i=0;   
	    my %rand;
	    while   (1)   { 
		srand();
		my $no   =   int(rand($#Insts_class+1));
		my $ID = $Insts_class[$no]; if ($SmspSlt->{$ID}){print ".....$ID\n";}
		if   (!$rand{$no})  {   
		      $rand{$no}=1;    
		      if(!$SmspSlt->{$ID}) { $i++; push (@SltInsts, $Insts_class[$no]);}
		      
		}
		last   if   ($i >= $SltInstNr); 
	    } 
	    return @SltInsts;
	}

}

#######################################################################################
# this fuction used for selecting the instance IDs based on class
# input prediction file and instance selected nr., return the instance IDs array.

sub SltID_inst{
	my $pred = $_[0];  # input prediction file
	my $SltInstNr = $_[1];    # input the selected instance nr.
	print "This step wants to select $sltNr instances.\n";


	open (PD, "<$pred");
	my @Insts_class;
	my $TlInstNr = 0;
	my $totalNEG = 0;
	my $rn;
	# read the prediction file
	while (<PD>){
		if ($_ =~ /\:/){
			my @infs = split(" ", $_);
			# select the instance ID which were predicted to a fixed class, like NEG
			if ($infs[2] =~ /$neg/){
				push (@Insts_class, "$infs[0]");
				if ($infs[2] eq $infs[1]){$rn++;} # this is used to caculate the accuracy
				$totalNEG++;
			}
			$TlInstNr++;
		}
	}
	print "The right NEG nr is $rn; total NEG is $totalNEG\n";
	print "The total instances Nr is $TlInstNr;\n";
	close PD;

	# select the instance ID array randomly within a given class
	my @SltInsts;
	unless ($SltInstNr <= ($#Insts_class+1)){$SltInstNr = ($#Insts_class+1); print "The select nr. is replaced by total instance Nr.\n ";}
	my $i=0;   
	my %rand;
	while   (1)   { 
		srand();
        my $no   =   int(rand($#Insts_class+1));
        if   (!$rand{$no})   {   $rand{$no}=1;   $i++;  push (@SltInsts, $Insts_class[$no]);}
        last   if   ($i >= $SltInstNr); 
	} 
	return @SltInsts;

}


########################################################################################
####This function is used for selecting instance based on most different voting
####useage: instID_slt_vote($predPath, $i, $pn, $InstNr)
sub SltID_vote{
	my $predPath = $_[0];	# path of prediction files
	my $i = $_[1];	# Nr. of the present iteration
	my $pn = $_[2];	# Nr. of the total isolated part
	my $sltNr = $_[3];	# Nr. of the seperated instance 
	my $train = $_[4];	# train name
	my %ID_vote;
	# iniate hash and caculate the total Nr of prediction instances
	open (PF1, "<$predPath/$train.$i.p1.pred");
	my $tn = 0;
	while (<PF1>){
		if ($_ =~ /:/){
			my @infs = split(" ", $_);
			$ID_vote{$infs[0]} = 0;
			$tn++;
		}
	}
	close PF1;
	# get hash (instance ID vs. nr. of NSL)
	foreach my $p(1..$pn){
		my $predF = "$predPath/$train.$i.p$p.pred";
		open (PF, "<$predF");
		my $n = 0;
		while (<PF>){
			if ($_ =~ /\:/){
				my @infs = split(" ", $_);
				if ($infs[2] =~ /1\:NSL/){$ID_vote{$infs[0]}++;}
				$n++;
			}
		}
		if ($n != $tn){print "Error: instance Nr is not same between different prediction files.\n";}
		close PF;		
	}
	foreach my $key (keys %ID_vote){
		$ID_vote{$key} = abs($ID_vote{$key} - $pn/2);
	}
	
	# select the instance ID based on most different voting
	my @sltInsts;
	my @insts = sort { $ID_vote{$a} <=> $ID_vote{$b} or $a <=> $b } keys %ID_vote;
	# foreach (@insts){	
		# print "$_ => $ID_vote{$_}\n";
	# }
	unless ($sltNr <= $tn){$sltNr = $tn; print "The select nr. is replaced by total instance Nr.\n ";}
	foreach (0..$sltNr-1){$sltInsts[$_] = $insts[$_];}
	return @sltInsts;
}


########################################################################################
#########This fuction used for select the feature vector based on a instance IDs array
#########Two split arff feature files will be produced 
#########use: &split_featfile($featurefile, @instsArray, $PartFeatfile1, $PartFeatfile2)

sub split_featfile {
	my $featfl = shift(@_);
	my $instsArray = shift(@_);
	my @insts = @$instsArray;
	my $outFeatfl1 = shift(@_);
	my $outFeatfl2 = shift(@_);
	unlink ($outFeatfl1);
	unlink ($outFeatfl2);
	my %split_insts;
	foreach (@insts){
		$split_insts{$_} = 1;
	}
	
	#read input feature file, and split it into two feature file based on the given instance ID array
	open (OUTF1, ">>$outFeatfl1");
	open (OUTF2, ">>$outFeatfl2");
	my $i = 0;
	open (INF, "<$featfl");
	while (<INF>){
		if (($_ =~ /^[0-9]/)||($_ =~ /\'(.*)\'/)){
			$i++;
			if ($split_insts{$i}){print OUTF1 "$_";}
			else {print OUTF2 "$_";}
		}else {
			print OUTF1 "$_";
			print OUTF2 "$_";
		}
	}
	close INF;
	close OUTF1;
	close OUTF2;
}


###################################################################################################
###this function is used for selecting features based on a given instance ID array
###useage: &slt_feat($inArff, \@pArray, $outFeat)
sub slt_feat{
	my $inArff = shift(@_);
	my $array = shift(@_);
	my $outFeat = shift(@_);
	my @pArray = @$array;
	my %insts;
	foreach (@pArray){
		$insts{$_} = 1;
	}
	unlink ($outFeat);
	open (OUTF, ">>$outFeat");
	my $i = 0;
	open (INF, "<$inArff");
	while (<INF>){
		if (($_ =~ /^[0-9]/)||($_ =~ /\'(.*)\'/)){
			$i++;
			if ($insts{$i}){print OUTF "$_";}
		}else {
			print OUTF "$_";
		}
	}
	close INF;
	close OUTF;
}


#########################################################################################################
########This function is used for splitting training feature file into $pn parts equably and randomly
########use: &split_feat_E_R ($trainArff, $pn, $outPath)

sub split_feat_E_R {
	my $inArff = $_[0]; # input feature file need to be splitted
	my $pn = $_[1];	# input the total part Nr. 
	my $outPath = $_[2];	#output path
	
	my $basenm = basename($inArff, ".arff");
	# caculate the total instance nr. 
	open (FF, "<$inArff");
	my $TlInstNr = 0;
	while (<FF>){
		if (($_ =~ /^[0-9]/)||($_ =~ /\'(.*)\'/)){
			$TlInstNr++;
		}
	}
	print "Total instance Nr. is $TlInstNr\n";
	close FF;	
	# generate a random array 
	my $i=0;   
	my %rand;
	while   (1)   { 
		srand();
        my $no   =   int(rand($TlInstNr)) +1;
		# print "$no\n";
        if   (!$rand{$no})   {   $rand{$no}=1;   $i++;  }
        last   if   ($i >= $TlInstNr); 
	} 
	my @SltInsts  =   keys   %rand;
	# caculate the average nr 
	my $avgNr = &ceil($TlInstNr/$pn);
	# split the feature file into $pn parts
	foreach my $p(1..$pn){
		my $outFeat = "$outPath/$basenm.p$p.arff";	print "$outFeat\n";
		my $start = $avgNr*($p-1); print "start: $start\n";
		my $end = $avgNr*$p-1;	print "end: $end\n";
		unless ($end <= $TlInstNr){$end = $TlInstNr;}
		my @pArray;
		foreach ($start..$end){push (@pArray, $SltInsts[$_]);}
		# foreach (@pArray){print "$_\n";};
		&slt_feat($inArff, \@pArray, $outFeat);
	}
}


###################################################################################
### this function used for combining n feature files (!!!make sure the feature dimension is the same!!!)
### usage: &comb ($input1, $input2, ..., $output)

sub comb{
	my @arffs = @_;
	if ($#arffs < 2){print "Error: At least two input features, the last one should be output file.\n";}
	my $outArff = $arffs[-1];
	unlink ($outArff);
	my $inArff1 = $arffs[0];
	open (OUTF, ">>$outArff");
	open (IN1, "<$inArff1");
	while (<IN1>){
		print OUTF $_;
	}
	close IN1;

	foreach my $inArff(1..$#arffs-1){
		open (INF, "<$arffs[$inArff]");
		while (<INF>){
			my $line;
			if (($_ =~ /^\d/)||($_ =~ /^\'/)){
				$line = $_;
				print OUTF $line;
			} 
		}
		close INF;
	}
	close OUTF;
}




###################################################################################
### this function used for generating feature file given instance IDs
### usage: &feat_insts ($develArff, \@array, $UpdateDvArff, $v);
sub feat_insts{
	my $featfl = $_[0];
	my $instsArray = $_[1];
	my @insts = @$instsArray;
	my $outFeatfl = $_[2];
	my $v = 0;  
	if ($_[3]){$v = $_[3];} # if set to 1, to select the instances are not in the array
	
	unlink ($outFeatfl);

	my %split_insts;
	foreach (@insts){
		$split_insts{$_} = 1;
	}
	
	#read input feature file, and split it into two feature file based on the given instance ID array
	open (OUTF, ">>$outFeatfl");
	my $i = 0;
	open (INF, "<$featfl");
	while (<INF>){
		if (($_ =~ /^[0-9]/)||($_ =~ /\'(.*)\'/)){
			$i++;
			if ($v == 0){
				if ($split_insts{$i}){
					print OUTF "$_";
				} 	
			}elsif ($v == 1){
				unless ($split_insts{$i}){
					print OUTF "$_";
				} 
			}
		}else {
			print OUTF "$_";
		}
	}
	close INF;
	close OUTF;
}
	
###################################################################################
### this function used for generating feature file given hash (instance IDs and corresponding predictions)
### usage: &feat_insts_pred ($develArff, $SmspArff, \%ID_pred)
	
sub feat_insts_pred{
	my $inf = $_[0];
	my $outf = $_[1];
	my $idpred = $_[2];
	my %ID_pred = %$idpred;
	unlink ($outf);


	#read input feature file and produce the feature file givn instance IDs and corresponding predictions
	open (OUTF, ">>$outf");
	my $i = 0;
	open (INF, "<$inf");
	while (<INF>){
		if (($_ =~ /^[0-9]/)||($_ =~ /\'(.*)\'/)){
			$i++;
			if ($ID_pred{$i}){
				my $tmp = $_;
				chomp ($tmp);
				my @data = split ("\,", $tmp);
				$data[-1] = $ID_pred{$i};
				$tmp = join ("\,", @data);
				print OUTF "$tmp\n";
			} 	
		}else {
			print OUTF "$_";
		}
	}
	close INF;
	close OUTF;
}

### this function used for generating feature file given hash (instance IDs and corresponding predictions)
### usage: &feat_insts_pred ($develArff, $SmspArff, \%ID_pred, $index)

sub feat_insts_pred_index{
	my $inf = $_[0];
	my $outf = $_[1];
	my $idpred = $_[2];
	my $index = $_[3]-1;
	my %ID_pred = %$idpred;
	unlink ($outf);


	#read input feature file and produce the feature file givn instance IDs and corresponding predictions
	open (OUTF, ">>$outf");
	my $i = 0;
	open (INF, "<$inf");
	while (<INF>){
		if (($_ =~ /^[0-9]/)||($_ =~ /\'(.*)\'/)){
			$i++;
			if ($ID_pred{$i}){
				my $tmp = $_;
				chomp ($tmp);
				my @data = split ("\,", $tmp);
				$data[$index] = $ID_pred{$i};
				$tmp = join ("\,", @data);
				print OUTF "$tmp\n";
			} 	
		}else {
			print OUTF "$_";
		}
	}
	close INF;
	close OUTF;
}



1;



