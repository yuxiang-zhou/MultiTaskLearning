#!/bin/sh

# USAGE: sh baseline_personality.sh personality 0.01 "./arff/Personality.ComParE.all.train.arff" "./arff/Personality.ComParE.all.devel.arff" 

fs=ComParE

# SVM complexity constant
C=$2
test -z "$C" && C=0.01

# path to your feature directory (ARFF files)
train_arff=$3
test_arff=$4

# target variable (task)
trait=$1
test -z "$trait" && task=openness

# echo "Train vs. Test"
# echo "smote\t0"
# for trait in openness conscientiousness extraversion agreeableness neuroticism; do
#    echo -n "$trait\t"
#    for smote in 0; do
#        res=`perl recog_personality.pl --target=$trait --train_arff=$train_arff --test_arff=$test_arff --classifier=svm --smote=$smote --feature-set=$fs --svm-complexity=$C | grep UAR | cut "-d " -f2`;
#        echo -n "$res\t"
#    done
#    echo
# done

echo -n "$trait\t"
for smote in 0; do
    res=`perl recog_personality.pl --target=$trait --train_arff=$train_arff --test_arff=$test_arff --classifier=svm --smote=$smote --feature-set=$fs --svm-complexity=$C | grep UAR | cut "-d " -f2`;
    echo -n "$res\t"
done
echo
