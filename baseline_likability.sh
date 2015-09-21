#!/bin/sh

# USAGE sh baseline_likability.sh likability 0.0001 "./arff/Likability.ComParE.train.arff" "./arff/Likability.ComParE.devel.arff"
# USAGE sh baseline_likability.sh likability 0.0001 "./arff/Likability.ComParE.all.train.arff" "./arff/Likability.ComParE.all.devel.arff"

fs=ComParE

# path to your feature directory (ARFF files)
train_arff=$3
test_arff=$4

# SVM complexity constant
C=$2
test -z "$C" && C=0.0001

# table header ;-)
echo -n "\tUAR / WAR"
echo -n "\t\t"
echo -n "AUC"
echo -n "\t"
echo
echo -n "\t$C\t"
echo -n "\t$C"
echo
trait=$1
echo -n "$trait"
acc=
auc=

# determine list of attributes to ignore and index of target attribute
#lab=6375
#rlab=6376-6384

# path to Weka's jar file
#weka_jar=../weka-3-6-12/weka.jar

# memory to allocate for the JVM
#jvm_mem=2048m

# train SVM using Weka's SMO, using FilteredClassifier wrapper to ignore unused class labels
#java -Xmx$jvm_mem -classpath $weka_jar weka.classifiers.meta.FilteredClassifier -v -o -no-cv -c $lab -t $train_arff -F "weka.filters.unsupervised.attribute.Remove -R $rlab"

perl recog_likability.pl --target=$trait --train_arff=$train_arff --test_arff=$test_arff --classifier=svm --smote=0 --feature-set=$fs --classif-complexity=$C > tmp$$.txt
acc="$acc\t"`grep UAR tmp$$.txt | cut "-d " -f2`"\t"`grep WAR tmp$$.txt | cut "-d " -f2`;
auc="$auc\t"`grep AUC tmp$$.txt | cut "-d " -f2`;
    rm tmp$$.txt
echo "$acc$auc"

