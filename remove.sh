#!/bin/sh

# determine list of attributes to ignore and index of target attribute
lab=6384
rlab=6375-6383

train_arff="./Likability.ComParE.all.train.arff"

# path to Weka's jar file
weka_jar=../weka-3-6-12/weka.jar

# memory to allocate for the JVM
jvm_mem=2048m

# directory where SVM models will be stored
model_dir=models
mkdir -p $model_dir

# model file name
svm_model_name=$model_dir/emotion.SMO.C$C.model

# train SVM using Weka's SMO, using FilteredClassifier wrapper to ignore unused class labels
java -Xmx$jvm_mem -classpath $weka_jar weka.classifiers.meta.FilteredClassifier -v -o -no-cv -c $lab -t $train_arff -d $svm_model_name -F "weka.filters.MultiFilter -F \"weka.filters.unsupervised.attribute.Remove -R 1,$rlab\" -F \"weka.filters.unsupervised.instance.RemoveWithValues -C last -L last\""

 
