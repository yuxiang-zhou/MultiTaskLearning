#!/bin/bash
# rm -r ./cl/ ./cv/ ./work/ ./results_all/
# python cv.py cl openness "./LowDimData/low.dim.personality.train.arff" "./LowDimData/low.dim.likability.train.arff" "./LowDimData/low.dim.likability.train.arff"
# rm -r ./cl/ ./cv/ ./work/ ./results_all/
# python cv.py cl openness "./LowDimData/low.dim.personality.train.arff" "./LowDimData/low.dim.emotion.train.arff" "./LowDimData/low.dim.emotion.train.arff"
# rm -r ./cl/ ./cv/ ./work/ ./results_all/
# python cv.py cl conscientiousness "./LowDimData/low.dim.personality.train.arff" "./LowDimData/low.dim.likability.train.arff" "./LowDimData/low.dim.likability.train.arff"
# rm -r ./cl/ ./cv/ ./work/ ./results_all/
# python cv.py cl conscientiousness "./LowDimData/low.dim.personality.train.arff" "./LowDimData/low.dim.emotion.train.arff" "./LowDimData/low.dim.emotion.train.arff"
# rm -r ./cl/ ./cv/ ./work/ ./results_all/
# python cv.py cl extraversion "./LowDimData/low.dim.personality.train.arff" "./LowDimData/low.dim.likability.train.arff" "./LowDimData/low.dim.likability.train.arff"
# rm -r ./cl/ ./cv/ ./work/ ./results_all/
# python cv.py cl extraversion "./LowDimData/low.dim.personality.train.arff" "./LowDimData/low.dim.emotion.train.arff" "./LowDimData/low.dim.emotion.train.arff"
# rm -r ./cl/ ./cv/ ./work/ ./results_all/
# python cv.py cl agreeableness "./LowDimData/low.dim.personality.train.arff" "./LowDimData/low.dim.likability.train.arff" "./LowDimData/low.dim.likability.train.arff"
# rm -r ./cl/ ./cv/ ./work/ ./results_all/
# python cv.py cl agreeableness "./LowDimData/low.dim.personality.train.arff" "./LowDimData/low.dim.emotion.train.arff" "./LowDimData/low.dim.emotion.train.arff"
# rm -r ./cl/ ./cv/ ./work/ ./results_all/
# python cv.py cl neuroticism "./LowDimData/low.dim.personality.train.arff" "./LowDimData/low.dim.likability.train.arff" "./LowDimData/low.dim.likability.train.arff"
# rm -r ./cl/ ./cv/ ./work/ ./results_all/
# python cv.py cl neuroticism "./LowDimData/low.dim.personality.train.arff" "./LowDimData/low.dim.emotion.train.arff" "./LowDimData/low.dim.emotion.train.arff"
rm -r ./cl/ ./cv/ ./work/ ./results_all/
python cv.py cl arousal "./LowDimData/low.dim.emotion.train.arff" "./LowDimData/low.dim.personality.train.arff" "./LowDimData/low.dim.personality.train.arff"
rm -r ./cl/ ./cv/ ./work/ ./results_all/
python cv.py cl arousal "./LowDimData/low.dim.emotion.train.arff" "./LowDimData/low.dim.likability.train.arff" "./LowDimData/low.dim.likability.train.arff"
rm -r ./cl/ ./cv/ ./work/ ./results_all/
python cv.py cl valence "./LowDimData/low.dim.emotion.train.arff" "./LowDimData/low.dim.personality.train.arff" "./LowDimData/low.dim.personality.train.arff"
rm -r ./cl/ ./cv/ ./work/ ./results_all/
python cv.py cl valence "./LowDimData/low.dim.emotion.train.arff" "./LowDimData/low.dim.likability.train.arff" "./LowDimData/low.dim.likability.train.arff"
# rm -r ./.cl/ ./.cv/ ./work/ ./results_all/
# python cv.py cl likability "./LowDimData/low.dim.likability.train.arff" "./LowDimData/low.dim.personality.train.arff" "./LowDimData/low.dim.personality.train.arff"
# rm -r ./.cl/ ./.cv/ ./work/ ./results_all/
# python cv.py cl likability "./LowDimData/low.dim.likability.train.arff" "./LowDimData/low.dim.emotion.train.arff" "./LowDimData/low.dim.emotion.train.arff"
