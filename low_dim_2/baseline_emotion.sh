#!/bin/sh

# path to your feature directory (ARFF files)
#feat_dir=$1
train_arff=$3
test_arff=$4

# directory where SVM models will be stored
model_dir=./work/models
mkdir -p $model_dir

# directory where evaluation results will be stored
eval_dir=./work/eval
mkdir -p $eval_dir

# feature file basename
#feat_name=Emotion.ComParE

# path to Weka's jar file
weka_jar=../weka-3-6-12/weka.jar

# memory to allocate for the JVM
jvm_mem=2048m

# SVM complexity constant
C=$2
test -z "$C" && C=0.01

# target variable (task)
task=$1
test -z "$task" && task=arousal

# determine list of attributes to ignore and index of target attribute
case $task in
#    arousal) rlab=6376 ; lab=6375 ;;
#    valence) rlab=6375 ; lab=6376 ;;
    arousal) rlab=518-525,527 ; lab=526 ;;
    valence) rlab=518-526 ; lab=527 ;;

    *) exit 1 ;;
esac

# model file name
svm_model_name=$model_dir/$task.SMO.C$C.model

# train SVM using Weka's SMO, using FilteredClassifier wrapper to ignore first
# attribute (instance name) and unused class labels
# Cascade with RemoveWithValues filter to remove `other` / `undefined`
# instances in training
test -f $svm_model_name || java -Xmx$jvm_mem -classpath $weka_jar weka.classifiers.meta.FilteredClassifier -v -o -no-cv -c $lab -t $train_arff -d $svm_model_name -F "weka.filters.MultiFilter -F \"weka.filters.unsupervised.attribute.Remove -R 1,$rlab\" -F \"weka.filters.unsupervised.instance.RemoveWithValues -C last -L last\"" -W weka.classifiers.functions.SMO -- -M -C $C -L 0.0010 -P 1.0E-12 -N 0 -V -1 -W 1 -K "weka.classifiers.functions.supportVector.PolyKernel -C 250007 -E 1.0"

# evaluate SVM and write predictions
# and using FilteredClassifier wrapper to ignore unused class labels
pred_file=$eval_dir/$task.`basename $train_arff`.SMO.C$C.pred
test -f $pred_file || (java -Xmx$jvm_mem -classpath $weka_jar weka.classifiers.meta.FilteredClassifier -o -c $lab -l "$svm_model_name" -T $test_arff  -p 0 -distribution > $pred_file)

# produce ARFF file in submission format
pred_arff=$eval_dir/`basename $pred_file`.arff
ref_arff=$test_arff
test -f $pred_arff || perl format_pred.pl $ref_arff $pred_file $pred_arff $lab

# calculate detection and classification scores
result_file=$eval_dir/`basename $pred_file .pred`.result
if [ ! -f $result_file ]; then
    perl score.pl $ref_arff $pred_arff $lab last | tee $result_file
else
    cat $result_file
fi
