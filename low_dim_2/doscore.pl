

# binomial coefficient:
# binc "n over k" 
# ( n )
# ( k )
sub binc {
  my $n = shift;
  my $k = shift;

  my $i; my $bc=1;
  for ($i=$k; $i>0; $i--) {
    $bc *= ($n-$i+1.0)/$i;
  }
  return $bc;
}

sub bincMod {
  my $n = shift;
  my $k = shift;

  $n++;
  my $i; my $bc=1;
  for ($i=$k; $i>0; $i--) {
    $bc *= ($n-$i)/($i*2.0);
  }
  return $bc*(0.5**($n-1.0-$k));
}

# transcriptions must contain label for one instance per line
# pred and ref must be in the same order and must contain the same number of lines!
# score, compute conf matrix, significance (McNemar), and UAR, WAR, UAP, WAP, UAF, WAF measures
sub score { #(predicitons, $predReference, $result);
  my $pred = shift;
  my $ref = shift;
  my $res = shift;

  my $signifRef = shift;
  my $signif = shift;
  unless ($signif) { $signif = 0.001; }

  # read pred and translate
  my @pr = @{$pred};
  # load ref and compare translated pred with ref 
  my @refpr = @{$ref};

  if ($#refpr != $#pr) {
    print "ERROR: # of reference predictions ($#refpr) in '$ref' doesn't match # of predictions ($#pr) in '$pred'!\n";
    return;
  }

  my @signiRef; my $chance="";
  if ($signifRef) {
    # load ref for significance test and compare translated pred with ref 
    open(_F,"<$signifRef");
    while(<_F>) {
      chop;
      if ($_) {
        push(@signiRef,$_);
      }
    }
    close(_F);
  } else {
    ## generate reference predictions by always predicting the most likely class
    # 1. find class with most instances:
    my %cnt; my $p;
    foreach $p ( @refpr ) { $cnt{$p}++; }
    my $maxC=0; my $max;
    foreach $p (keys %cnt) { 
      if ($maxC < $cnt{$p}) { $maxC = $cnt{$p}; $max = $p; } 
    }
    my @kcnt = keys %cnt;
    # 2. generate "dummy" predicitions
    foreach $p ( @refpr ) { 
# choosing largest class :
#      push(@signiRef, $max); 
# random distribution :
      push(@signiRef,$kcnt[int(rand($#kcnt+1)-0.001)]);
    }
    $chance = "(comparison with chance: most likely class $max)";
  }
 
  # compute significance:
  my $n00=0; my $n01 = 0;  # a1 is system, a2 is reference  n(a1,a2)
  my $n10=0; my $n11 = 0;

  # save result
  my $i;
  my %cfmat; my %nref; my %npred;
  my $ncorr=0; my $nincorr = 0;
  for ($i=0; $i<=$#refpr; $i++) {
    if ($refpr[$i] eq $signiRef[$i]) {
      if ($refpr[$i] eq $pr[$i]) { $n00++; }
      else { $n10++; } 
    } else {
      if ($refpr[$i] eq $pr[$i]) { $n01++; }
      else { $n11++; } 
    }
    $cfmat{$refpr[$i]}{$pr[$i]}++;
    $nref{$refpr[$i]}++;
    $npred{$pr[$i]}++;
  }

  my @cls = keys %nref; my $c;
  my $uar=0; my $war = 0; 
  my $uap=0; my $wap = 0; my $uaf=0;
  my $clstr = "";
  my %pr_cl, %re_cl, %f_cl;
  foreach $c (@cls) {
    my $r; my $p;
    if ($nref{$c} > 0) {
      $r = $cfmat{$c}{$c} / $nref{$c};
      $uar += $r;
      $re_cl{$c} = $r;
    }
    if ($npred{$c} > 0) {
      $p = $cfmat{$c}{$c} / $npred{$c};
      $uap += $p;
      $pr_cl{$c} = $p;
      $wap += ($cfmat{$c}{$c} / $npred{$c}) * $nref{$c} ;
    }
    if (($r+$p) > 0) {
        my $f = 2*$r*$p/($r+$p);
        $uaf += $f;
        $f_cl{$c} = $f;
    }
    $war += $cfmat{$c}{$c};
    $clstr .= "$c ";
  }
  $uar /= ($#cls)+1;
  $uap /= ($#cls)+1;
  $uaf /= ($#cls)+1;
  $war /= ($#refpr)+1;
  $wap /= ($#refpr)+1;

  open(_F,">$res");

  print _F "class\tREC\tPREC\tF1\n";
  foreach $c (@cls) {
    print _F $c, "\t", $re_cl{$c}, "\t", $pr_cl{$c}, "\t", $f_cl{$c}, "\n";
  }

  print _F "UAR: $uar\n";
  print _F "WAR: $war\n";
  print _F "UAP: $uap\n";
  print _F "WAP: $wap\n";
  print _F "UAF: $uaf\n";
  my $f1 = 2.0 * $wap*$war / ($wap+$war);
  print _F "WAF: $f1\n";

  chop($clstr);
  print _F "CF: (top to bottom) as-> $clstr\n";
  foreach $c1 (@cls) {
   my $ll = "";
   foreach $c2 (@cls) {
     my $st = sprintf("%i",$cfmat{$c1}{$c2});
     $ll .= $st." ";
   }
   chop($ll); 
   print _F $ll."\n";
  }
  print _F "McNemar significance (left: system A1, top reference A2: n(a1,a2)): $chance\n";
  print _F "$n00 ; $n01 \n";
  print _F "$n10 ; $n11 \n";

  my $K = $n10 + $n01; my $P;
  if ($n10 > $K/2) {
    my $sum = 0; my $m;
    for ($m = $n10; $m <= $K; $m++) { $sum += &bincMod($K,$m); }
    $P = 2.0 * $sum;
  } else {
    my $sum = 0; my $m;
    for ($m = 0; $m <= $n10; $m++) { $sum += &bincMod($K,$m); }
    $P = 2.0 * $sum;
  }
  my $si = "FALSE";
  if ($P < $signif) { 
    if ($n10 < $K/2) {
      $si = "TRUE"; 
    } else {
      $si = "TRUE(inv)";
    }
  }

  my $st = sprintf("%.2f",$signif);
  print _F "McNemar significance P=$P for alpha=$st :: $si\n";
  close(_F);
  return $uar;
}

# RESULT:
# UA: #
# WA: #
# confmat

1;


