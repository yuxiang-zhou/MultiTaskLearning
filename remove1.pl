#!/usr/bin/perl

use strict;
use File::Basename;

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
                if ($ai ~~ $rm_list) {
                    print 'Removed index: ';
                    print $ai;
                    print "\n";
                } else {
                    push(@indices, $ai - 1);
                    print FILE2;
                    print FILE2 "\n";
                }
            }
            else {
                print FILE2;
                print FILE2 "\n";
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
            print FILE2 "\n\n";
        }
    }
    close(FILE1);
    close(FILE2);

    return $output_arff;
}

our $train = "train";

our $overwrite = 1;

our $remove_2 = 1;
our $remove_N = 1;

our $feat_dir = dirname($0);
our $feature_set = "ComParE";
our $target_attr = "likability";
our $ntarget_attrs = 1;
our $target_is_numeric = 0; # will be determined automatically
our $classif_attrib = "last";

our $arff_prefix = "Likability.";

our $train_arff = "$feat_dir/${arff_prefix}${feature_set}.all.$train.arff";

our $smote = 0; # only for nominal targets ...

our $work_dir = "./work";
system("mkdir -p $work_dir");

our $silent = 0;

our $wekacmd = "java -classpath ../weka-3-6-12/weka.jar -Xmx4096m";

print "Preparing ARFFs...\n" unless ($silent);

# remove unused targets and instance name
$train_arff    = preprocess($train_arff, [1,6376,6377,6378,6379,6380,6381,6382,6383,6384]);

