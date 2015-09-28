#!/bin/bash
# rm -r ./.cl/ ./.cv/ ./work/ ./results_all/
# python cv.py cl openness "./LowDimData2/low.dim.2.personality.train.arff" "./LowDimData2/low.dim.2.likability.train.arff" "./LowDimData2/low.dim.2.likability.train.arff"
# rm -r ./.cl/ ./.cv/ ./work/ ./results_all/
# python cv.py cl openness "./LowDimData2/low.dim.2.personality.train.arff" "./LowDimData2/low.dim.2.emotion.train.arff" "./LowDimData2/low.dim.2.emotion.train.arff"
# rm -r ./.cl/ ./.cv/ ./work/ ./results_all/
# python cv.py cl conscientiousness "./LowDimData2/low.dim.2.personality.train.arff" "./LowDimData2/low.dim.2.likability.train.arff" "./LowDimData2/low.dim.2.likability.train.arff"
# rm -r ./.cl/ ./.cv/ ./work/ ./results_all/
# python cv.py cl conscientiousness "./LowDimData2/low.dim.2.personality.train.arff" "./LowDimData2/low.dim.2.emotion.train.arff" "./LowDimData2/low.dim.2.emotion.train.arff"
# rm -r ./.cl/ ./.cv/ ./work/ ./results_all/
# python cv.py cl extraversion "./LowDimData2/low.dim.2.personality.train.arff" "./LowDimData2/low.dim.2.likability.train.arff" "./LowDimData2/low.dim.2.likability.train.arff"
# rm -r ./.cl/ ./.cv/ ./work/ ./results_all/
# python cv.py cl extraversion "./LowDimData2/low.dim.2.personality.train.arff" "./LowDimData2/low.dim.2.emotion.train.arff" "./LowDimData2/low.dim.2.emotion.train.arff"
# rm -r ./.cl/ ./.cv/ ./work/ ./results_all/
# python cv.py cl agreeableness "./LowDimData2/low.dim.2.personality.train.arff" "./LowDimData2/low.dim.2.likability.train.arff" "./LowDimData2/low.dim.2.likability.train.arff"
# rm -r ./.cl/ ./.cv/ ./work/ ./results_all/
# python cv.py cl agreeableness "./LowDimData2/low.dim.2.personality.train.arff" "./LowDimData2/low.dim.2.emotion.train.arff" "./LowDimData2/low.dim.2.emotion.train.arff"
# rm -r ./.cl/ ./.cv/ ./work/ ./results_all/
# python cv.py cl neuroticism "./LowDimData2/low.dim.2.personality.train.arff" "./LowDimData2/low.dim.2.likability.train.arff" "./LowDimData2/low.dim.2.likability.train.arff"
# rm -r ./.cl/ ./.cv/ ./work/ ./results_all/
# python cv.py cl neuroticism "./LowDimData2/low.dim.2.personality.train.arff" "./LowDimData2/low.dim.2.emotion.train.arff" "./LowDimData2/low.dim.2.emotion.train.arff"
rm -r ./.cl/ ./.cv/ ./work/ ./results_all/
python cv.py cl arousal "./LowDimData2/low.dim.2.emotion.train.arff" "./LowDimData2/low.dim.2.personality.train.arff" "./LowDimData2/low.dim.2.personality.train.arff"
rm -r ./.cl/ ./.cv/ ./work/ ./results_all/
python cv.py cl arousal "./LowDimData2/low.dim.2.emotion.train.arff" "./LowDimData2/low.dim.2.likability.train.arff" "./LowDimData2/low.dim.2.likability.train.arff"
rm -r ./.cl/ ./.cv/ ./work/ ./results_all/
python cv.py cl valence "./LowDimData2/low.dim.2.emotion.train.arff" "./LowDimData2/low.dim.2.personality.train.arff" "./LowDimData2/low.dim.2.personality.train.arff"
rm -r ./.cl/ ./.cv/ ./work/ ./results_all/
python cv.py cl valence "./LowDimData2/low.dim.2.emotion.train.arff" "./LowDimData2/low.dim.2.likability.train.arff" "./LowDimData2/low.dim.2.likability.train.arff"
# rm -r ./.cl/ ./.cv/ ./work/ ./results_all/
# python cv.py cl likability "./LowDimData2/low.dim.2.likability.train.arff" "./LowDimData2/low.dim.2.personality.train.arff" "./LowDimData2/low.dim.2.personality.train.arff"
# rm -r ./.cl/ ./.cv/ ./work/ ./results_all/
# python cv.py cl likability "./LowDimData2/low.dim.2.likability.train.arff" "./LowDimData2/low.dim.2.emotion.train.arff" "./LowDimData2/low.dim.2.emotion.train.arff"
