use strict;
use File::Basename;

no warnings 'experimental::smartmatch';

#require "upsample.pl";
require "load_pred.pl";
require "doscore.pl";


sub array2R
{
    my ($name, $ref) = @_;
    my $str = "$name <- c(";
    for my $i (0..$#{$ref}) {
        my $v = $ref->[$i];
        if ($v =~ /^[\+\-]?\d+(\.\d+)?(e[\+\-]?\d+)?$/) {
            $str .= $v;
        }
        else {
            $str .= "\"$v\"";
        }
        if ($i < $#{$ref}) {
            $str .= ", ";
        }
    }
    $str .= ")\n";
    return $str;
}


# remove attribute 1 (file name) and unused regression attributes
sub preprocess
{
    #our ($remove_2, $remove_N, $overwrite);
    our ($work_dir, $target_attr, $overwrite, $ntarget_attrs, $target_is_numeric, $silent);
    #print "remove 2: $remove_2\nremove N: $remove_N\n";
    my $output_arff = basename($_[0]);
    my $remove1 = $_[1];
    my $rm_list = $remove1;


    $output_arff =~ s/\.arff$/.$target_attr.arff/;
    if ($remove1) {
        $output_arff =~ s/\.arff$/.r1.arff/;
    }

    $output_arff = "$work_dir/$output_arff";
    if (-s $output_arff && !$overwrite) {
        return $output_arff;
    }
    print F 'after return';
    my $nattr = 0;
    print "reading from $_[0]\n" unless ($silent);
    open(FILE1, "<$_[0]");
    while(<FILE1>) {
        chomp;
        if (/^\@attribute/) {
            ++$nattr;
        }
        if (/^\@data/) {
            last;
        }
    }
    print "nattr = $nattr\n" unless ($silent);
    open(FILE2, ">$output_arff");
    seek(FILE1, 0, 0);
    my $ai = 0;
    my @indices = ();
    my $target_idx = -1;
    while(<FILE1>) {
        chomp;
        if (/^@/) {
            if (my ($attr_name, $attr_type) = /^\@attribute\s+(\S+)\s+(\S+)/) {
                ++$ai;

#                 if ($ai == $remove1) {

#                 }
#                 elsif ($ai <= $nattr - $ntarget_attrs) {
#                     print FILE2;
#                     print FILE2 "\n";
#                     push(@indices, $ai - 1);
#                 }
#                 elsif ($attr_name eq $target_attr) {
#                     print FILE2;
#                     print FILE2 "\n";
#                     push(@indices, $ai - 1);
#                     $target_idx = $ai - 1;
# #                    if ($attr_type eq "numeric") {
# #                        print "Target is numeric!";
# #                        $target_is_numeric = 1;
# #                    }
#                 }
                if ($ai ~~ $rm_list && $attr_name ne $target_attr) {
                    print F 'Removed index: ';
                    print F $ai;
                    print F "\n";
                } else {

                    push(@indices, $ai - 1);
                    print FILE2;
                    print FILE2 "\n";
                }
            }
            else {
                print FILE2;
                print FILE2 "\n\n";
            }

            if (/^\@data/) {
                last;
            }
        }
    }

    seek(FILE1, 0, 0);
    my $i = 0;
    while(<FILE1>) {
        unless (/^@/ || /^$/) {
            $i++;
            my (@els) = $_ =~ m/('[^']+'|[^,]+)/g;
#            if ($target_is_numeric) {
#                $els[$target_idx] *= 1000; # Promille ;-)
#            }
            # print @els[@indices];
            # print "\n";
            print FILE2 join(",", @els[@indices]);
            print FILE2 "\n";
        }
    }
    close(FILE1);
    close(FILE2);

    return $output_arff;
}

sub target_stat {
    my ($arff, $idx) = @_;

    if ($idx == 0) { die("Invalid index: $idx"); }

    my $nattr = 0;
    open(ARFF, $arff);
    while (<ARFF>) {
        if (/^\@attribute/) {
            ++$nattr;
        }
        if (/^\@data/) {
            last;
        }
    }
    close(ARFF);

    if ($idx < 0) { $idx = $nattr + $idx; }
    else { $idx--; }

    open(ARFF, $arff);
    my $data = 0;
    my $sum = 0;
    my $sumsq = 0;
    my $cnt = 0;
    while (<ARFF>) {
        if (/^\@data/) {
            $data = 1;
        }
        elsif ($data && !/^\s+$/) {
            chomp;
            my (@els) = $_ =~ m/('[^']+'|[^,]+)/g;
            my $v = $els[$idx];
            #print "v = $v\n";
            $sum   += $v;
            $sumsq += $v * $v;
            ++$cnt;
        }
    }
    close(ARFF);

    return (
        $sum / $cnt,                                  # E[X]
        $sumsq / $cnt - ($sum / $cnt) * ($sum / $cnt) # E[X^2] - E[X]^2
    );
}


our $train = "train";
our $test  = "devel";

our $overwrite = 0;

our $remove_2 = 1;
our $remove_N = 1;

our $base_dir = dirname($0);
our $feat_dir = "$base_dir/cl";
our $feature_set = "ComParE";
our $target_attr = "class";
our $ntarget_attrs = 1;
our $target_is_numeric = 0; # will be determined automatically
our $svm_complexity = 0.1;

our $arff_prefix = "personality.";

our $train_arff = "$feat_dir/${arff_prefix}.$train.arff";
our $test_arff  = "$feat_dir/${arff_prefix}.$test.arff";

our $smote = 1; # only for nominal targets ...

our $classifier = "svm";
our $classif_attrib = "last";
our %classif_class = (
    "reptree" => "weka.classifiers.meta.RandomSubSpace",
    "svr"     => "weka.classifiers.functions.SMOreg",
    "svm"     => "weka.classifiers.functions.SMO"
);


our $work_dir = "$base_dir/work";
system("[ -d $work_dir ] || mkdir -p $work_dir");

our $wekacmd = "java -classpath ../weka-3-6-12/weka.jar -Xmx4096m";
our $model_dir = "$work_dir/models";
system("mkdir -p $model_dir");
our $result_dir = "$work_dir/results";
system("mkdir -p $result_dir");

our $silent = 0;

#our $all_results_file_nom = "/home/semaine5/workstud/wen/IS2012Challenge/personality/results.csv";


# parse command line options
foreach (@ARGV) {
    if (my ($v) = $_ =~ /^--classifier=(.+)$/) {
        if (defined $classif_class{$v}) {
            $classifier = $v;
        }
        else {
            print "Invalid classifier: $v\n";
            exit 1;
        }
    }
    elsif (my ($v) = $_ =~ /^--target=(.+)$/) {
        $target_attr = $v;
    }
    elsif (my ($v) = $_ =~ /^--feature-set=(.+)$/) {
        $feature_set = $v;
    }
    elsif (my ($v) = $_ =~ /^--train_arff=(.+)$/) {
        $train_arff = $v;
    }
    elsif (my ($v) = $_ =~ /^--test_arff=(.+)$/) {
        $test_arff = $v;
    }
    elsif ($_ eq "--overwrite" || $_ eq "-o") {
        $overwrite = 1;
    }
    elsif (my ($v) = $_ =~ /^--svm-complexity=(.+)$/) {
        $svm_complexity = $v;
    }
    elsif (my ($v) = $_ =~ /^--smote=(0|1)$/) {
        $smote = $v;
    }
    elsif (/--silent/) {
        $silent = 1;
    }
    else {
        print "Invalid option: $_\n";
        print "Usage: $0 [options]\n";
        print "Options:\n";
        print " --classifier=" . join("|", keys %classif_class) . "      Sets the classifier to use.\n";
        print " --target=<varx>            Regression target\n";
        print "                            [default: cha_mean]\n";
        print " --feature-set=<name>       Feature set [default: IS09]\n";
        print " --train=<set>              Training set (train or traindevel)\n";
        print "                            whereby traindevel is union of train+devel\n";
        print "                            [default: traindevel]\n";
        print " --test=<set>               Test set (devel or test)\n";
        print "                            [default: test]\n";
        print " --overwrite                Overwrites ARFF files, models, etc.\n";
        print "                            [default: no]\n";
        print "                            Otherwise models for the same set of parameters\n";
        print "                            are re-used\n";
        exit 1;
    }
}


our %classif_opt = (
    "reptree" => "-P 0.05 -S 1 -I 500 -W weka.classifiers.trees.REPTree -- -M 2 -V 0.0010 -N 3 -S 1 -L 25 -P",
    "svr"     =>  "-C $svm_complexity -N 0 -I \"weka.classifiers.functions.supportVector.RegSMOImproved -L 0.0010 -W 1 -P 1.0E-12 -T 0.0010 -V\" -K \"weka.classifiers.functions.supportVector.PolyKernel -C 250007 -E 1.0\"",
    "svm"     => " -C $svm_complexity -M -L 0.0010 -P 1.0E-12 -N 0 -V -1 -W 1 -K \"weka.classifiers.functions.supportVector.PolyKernel -C 250007 -E 1.0\""
);


print "Preparing ARFFs...\n" unless ($silent);

# join train+devel if desired
if (($train eq "traindevel" && (!-f $train_arff || $overwrite))) {
    open(FILE1, "<$train_arff");
    open(FILE2, "<$test_arff");
    open(FILE3, ">$feat_dir/${arff_prefix}${feature_set}.all.traindevel.arff");
    while (<FILE1>) {
        print FILE3;
    }
    close(FILE1);
    while (<FILE2>) {
        if (!/^@/) {
            print FILE3;
        }
    }
    close(FILE2);
    close(FILE3);
}

# remove unused targets and instance name
$train_arff    = preprocess($train_arff, [1,795,796,797,798,799,800,801,802,803,804]);
$test_arff     = preprocess($test_arff, [1,795,796,797,798,799,800,801,802,803,804]);

if (!$target_is_numeric && $smote) {
    print "SMOTing...\n" unless ($silent);
    my $train_arff_s = $train_arff;
    $train_arff_s =~ s/\.arff/.SMOTE.arff/;
    if (!-s $train_arff_s || $overwrite) {
        system("$wekacmd weka.filters.supervised.instance.SMOTE -C 0 -K 5 -P 100.0 -S 1 -c $classif_attrib -i $train_arff -o $train_arff_s");
    }
    $train_arff = $train_arff_s;
}

#my ($mean, $stddev) = target_stat($train_arff, -1);
#print "target of training data: mean = $mean, stddev = $stddev\n";

my $model_name = $classif_class{$classifier} . $classif_opt{$classifier};
$model_name =~ s/[^\w\.\-]//g;
#my $model_name = $classifier . "_default";
system("mkdir -p $model_dir/$model_name");
system("mkdir -p $result_dir/$model_name");

my $model_file = "$model_dir/$model_name/" . basename($train_arff, ".arff") . ".model";
my $pred_file   = "$result_dir/$model_name/" . basename($model_file, ".model") . ".pred";
my $result_file = "$result_dir/$model_name/" . basename($model_file, ".model") . ".result";
#print "result_file = $result_file\n";

print "Training classifier ($classifier)...\n" unless ($silent);
if (!-s $model_file || $overwrite) {
    #my $cmd = "$wekacmd $classif_class{$classifier}  -t $train_arff -v -o -no-cv -d $model_file $classif_opt{$classifier}";
    my $cmd = "$wekacmd $classif_class{$classifier}  -t $train_arff -v -no-cv -d $model_file $classif_opt{$classifier} > $model_file.txt";
    print "-> $cmd\n";
    system($cmd);
}


print "Evaluating classifier ...\n" unless ($silent);

my $cmd;
#$cmd = "$wekacmd $classif_class{$classifier} -T $test_arff -v -o -i -l $model_file > $result_file";
#print "-> $cmd\n";
#system($cmd);
#print "Writing predictions ...\n";
$cmd = "$wekacmd $classif_class{$classifier} -T $test_arff -v -o -i -l $model_file -p 0 > $pred_file";
print "-> $cmd\n";
system($cmd);
my ($pred_ref, $corr_ref) = load_predictions($pred_file);
score($pred_ref, $corr_ref, $result_file);
if ($silent) {
    my $ua_tmp = `grep '^UAR' $result_file`;
    my ($ua) = $ua_tmp =~ /([\d\.]+)/;
    print "$ua\n";
}
else {
    system("cat $result_file");
    $cmd = "$wekacmd $classif_class{$classifier} -T $test_arff -v -o -i -l $model_file";
    #print "-> $cmd\n";
    my $output = `$cmd`;
    my ($auc) = $output =~ /^Weighted Avg\..+\s(\S+)\s*$/m;
    print "AUC: $auc\n";
}

#unlink($weka_output);
