#!/usr/bin/perl
##################################################################################
##### This script is used for cross_labelling of multiple databases by predicting 
##### missing labels with semi-supervised learning techniques
##################################################################################
use Switch;
use Cwd;
use File::Basename;

my $BaseDir = dirname($0);

require "$BaseDir/funcs_emt.pl";

my $source = $corpus;
my $target = $target;
my @cindexes = (6374,6375,6376);
my $basePath = "$BaseDir/smsp_us";
my $predPath = "$basePath/pred";
my $resPath = "$basePath/res";
my $tmpFeatPath = "$basePath/tmp";  # to restore the temp feature files

unless (-d $basePath){system("mkdir $basePath");}
unless (-d $predPath){system("mkdir $predPath");}
unless (-d $resPath){system("mkdir $resPath");}
unless (-d $tmpFeatPath){system("cp -r $BaseDir/tmp $basePath");}

while (my $arg = shift) {
    switch($arg){
       case "-s"         { $source = shift; }
       case "-t"         { $target = shift; }
       case "-c"         { @cindexes = split("\,", shift); }
       else              { print "Args not valid: $arg\n"; exit 2; }
    }
}

print "Cross Labelling Started ...\n";

my $sourceBase = "$tmpFeatPath/$source.tr.arff";
my $targetBase = "$tmpFeatPath/$target.tr.arff";
my $emptyFeature = "$tmpFeatPath/empty.arff";

foreach my $cindex (@cindexes) {

    print "Preparing Data for Index $cindex ...\n";
    system("cp $sourceBase $tmpFeatPath/$source.tr.1.arff");
    system("cp $targetBase $tmpFeatPath/$target.tr.1.arff");
    system("cp $emptyFeature $tmpFeatPath/bk.1.arff");

    my $testArff = "$tmpFeatPath/$source.tx.arff";
    my $index = 0;
    foreach my $i (1..$iter){

        print "\n----> $i interation\n";

        my $trainArff = "$tmpFeatPath/$source.tr.$i.arff";
        my $develArff = "$tmpFeatPath/$target.tr.$i.arff";

        ###step 1: prediction and resulting
        ### using training feature file (train.i-1.arff) to predict devel feature file (devel.high.i-1.arff) with random forest, also recognize the test feature file

        my $pred = "$predPath/$source.$i.pred";
        my $res = "$resPath/$source.$i.res";

        print "------> Resampling\n";
        my $ustrainArff = "$tmpFeatPath/$source.tr.$i.us.arff";
        my $cmd0 = "java -Xmx4096m -classpath $wekaPath weka.filters.supervised.instance.Resample -B 1.0 -S 1 -Z $smpRate -i $trainArff -o $ustrainArff -c $cindex";
        # print "$cmd0\n\n";
        !system($cmd0) or warn "Can't resample $trainArff. Error: $!\n";


        print "------> Labelling\n";
        my $cmd1 = "java -Xmx4096m -classpath $wekaPath weka.classifiers.functions.SMO -v -o -no-cv -C $c2 -L 0.0010 -P 1.0E-12 -N 0 -V -1 -W 1 -M -K \"weka.classifiers.functions.supportVector.PolyKernel -C 250007 -E 1.0\" -t $ustrainArff -T $develArff -p 0 -c $cindex > $pred";
        # print "$cmd1\n\n";
        !system($cmd1) or warn "Can't produce the prediction of $develArff. Error: $!\n";


        # print "------> Testing\n";
        # my $cmd2 = "java -Xmx4096m -classpath $wekaPath weka.classifiers.functions.SMO -v -o  -C $c -L 0.0010 -P 1.0E-12 -N 0 -V -1 -W 1 -K \"weka.classifiers.functions.supportVector.PolyKernel -C 250007 -E 1.0\" -t $ustrainArff -T $testArff -i -c $cindex > $res";
        # # print "$cmd2\n\n";
        # !system($cmd2) or warn "Can't produce the result of $testArff. Error: $!\n";

        ###step 2: selecting instance ID
        ### based on the prediction file (pred.i-1.txt), generate a hash ($ID_pred{$ID} = $pred) (for semi-supervised learning)
        my $locate= &SltID_smsp($pred, $InstNr, $iter, $i);
        my %ID_pred = %$locate;
        my @array = keys (%ID_pred);
        my $Nr = $#array+1;
        print "The semi-supervise learning Nr is $Nr.\n";

        ###step 3: generate selected feature files for active learning and semi-supervised learning, and update the new devel feature file
        my $ii = $i + 1;
        my $SmspArff = "$tmpFeatPath/$source.dv.$i.smsp.arff";
        my $NewDevelArff = "$tmpFeatPath/$target.tr.$ii.arff";
        ### for semi-supervised learning based on hasd %ID_pred
        &feat_insts_pred_index ($develArff, $SmspArff, \%ID_pred, $cindex);
        ### the rest features
        my $v = 1;
        &feat_insts ($develArff, \@array, $NewDevelArff, $v);


        ###step 4: combining  training files
        ### combine the former training feature file (train.i-1.arff) and the new selected low score feature file (devel.low.i.arff) into (train.i.arff)
        my $newTrainArff = "$tmpFeatPath/$source.tr.$ii.arff";
        &comb($trainArff, $SmspArff, $newTrainArff);
        &comb("$tmpFeatPath/bk.$i.arff", $SmspArff, "$tmpFeatPath/bk.$ii.arff");

        # unlink ($ustrainArff);
        # unlink ($SmspArff);
        # unlink ($trainArff);
        # unlink ($develArff);
        # unlink ("$tmpFeatPath/bk.$i.arff");

        $index = $i;
        if ($Nr <= 0) { last; }

    }

    my $last = $index + 1;
    unlink ($targetBase);
    system("cp $tmpFeatPath/bk.$last.arff $targetBase");
    # unlink "$tmpFeatPath/$target.tr.$last.arff";
    # unlink "$tmpFeatPath/$source.tr.$last.arff";
    # unlink ("$tmpFeatPath/bk.$last.arff");
    # unlink $testArff;

}

1;
