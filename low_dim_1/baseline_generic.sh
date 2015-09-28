#!/bin/sh


set -x

# USAGE: sh baseline_generic.sh <task> <complexity> <train_arff> <test_arff>
# e.g.
# sh baseline_generic.sh arousal 0.01 "./arff/Emotion.ComParE.all.train.arff" "./arff/Emotion.ComParE.all.devel.arff"
# sh baseline_generic.sh likability 0.0001 "./arff/Likability.ComParE.all.train.arff" "./arff/Likability.ComParE.all.devel.arff"
# sh baseline_generic.sh openness 0.01 "./arff/Personality.ComParE.all.train.arff" "./arff/Personality.ComParE.all.devel.arff"


########### I/O ##################

# path to Weka's jar file
weka_jar=../weka-3-6-12/weka.jar
test -f $weka_jar || exit -1

# memory to allocate for the JVM
jvm_mem=2048m

# path to your feature directory (ARFF files)
#feat_dir=$1
train_arff=$3
test -f $train_arff || exit -1
test_arff=$4
test -f $test_arff || exit -1

# SVM complexity constant
C=$2

# directory where results will be stored
res_dir=results_all
[ -d $res_dir ] || mkdir -p $res_dir

# target variable (task)
task=$1

# determine list of attributes to ignore and index of target attribute
case $task in
    likability) sh baseline_likability.sh $1 $2 $3 $4 ;;
#   personality) sh baseline_personality.sh $1 $2 $3 $4 ;;
    openness) sh baseline_personality.sh $1 $2 $3 $4 ;;
    conscientiousness) sh baseline_personality.sh $1 $2 $3 $4 ;;
    extraversion) sh baseline_personality.sh $1 $2 $3 $4 ;;
    agreeableness) sh baseline_personality.sh $1 $2 $3 $4 ;;
    neuroticism) sh baseline_personality.sh $1 $2 $3 $4 ;;
    arousal) sh baseline_emotion.sh $1 $2 $3 $4 ;;
    valence) sh baseline_emotion.sh $1 $2 $3 $4 ;;
        *) exit 1 ;;
esac

find ./work -name '*.result' -exec sh -c 'cp "$@" "$0"' $res_dir {} +
find ./work -name '*.pred' -exec sh -c 'cp "$@" "$0"' $res_dir {} +
