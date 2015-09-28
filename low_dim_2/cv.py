import numpy as np
import subprocess
import sys
import os
import glob
import shutil
import time

## cross validation
def one_fold(task, C, path_train, path_test):
    # try:
    #     shutil.rmtree("./eval/")
    # except:
    #     pass
    # try:
    #     shutil.rmtree("./models/")
    # except:
    #     pass
    # try:
    #     shutil.rmtree("./work/")
    # except:
    #     pass
    # try:
    #     shutil.rmtree("./results_all/")
    # except:
    #     pass


    p = subprocess.call(
        ['./baseline_generic.sh', task, str(C), path_train, path_test]
    )

    if not p == 0:
        raise('baseline_generic failed!')

    UAR = 0
    name = path_train.split('/')[-1].split('.arff')[0]
    result_folder = "results_all/*{}*.result".format(name)
    print 'Searching result in folder: ' + result_folder
    fname = glob.glob(result_folder)[0]
    with open(fname) as f:
        for l in f.readlines():

            if 'UAR' in l and '=' in l:
                UAR = float(l.split('=')[-1].split('%')[0])
            elif 'UAR' in l:
                UAR = float(l.split(':')[-1]) * 100.0
            else:
                pass

    pred = []
    pred_folder = "results_all/*{}*.pred".format(name)
    fname = glob.glob(pred_folder)[0]
    with open(fname) as f:
        bData = False
        for l in f.readlines():
            data = [p for p in l.split(' ') if p != '' and p != "\n" and p != "+"]

            if bData and len(data):
                confidence = np.sort([float(d) for d in (data[-1].replace("*","").split(','))])
                data[-1] = confidence[0] if len(confidence) == 1 else confidence[-1] - confidence[-2]
                data[0] = int(data[0])
                pred.append(data)

            if len(data) and not bData and 'inst' in data[0]:
                bData = True


    return UAR, pred

def cross_validation(task, C, path_data, nfold=5):
    # Seperate data
    headers,data,nData = loadArff(path_data)
    # temp directory
    directory = './.cv'
    if not os.path.exists(directory):
        os.makedirs(directory)

    pathTrains = []
    pathTests = []
    chuckSize = nData / nfold
    random_id = int(time.time()) + np.random.randint(20000)
    fTrains = [open('{}/training_{}_{}_{}.arff'.format(directory,task,random_id,i), 'w+') for i in range(nfold)]
    fTests = [open('{}/testing_{}_{}_{}.arff'.format(directory,task,random_id,i), 'w+') for i in range(nfold)]

    # write headers
    for f1,f2 in zip(fTrains, fTests):
        for h in headers:
            f1.write(h)
            f2.write(h)

    # write datas
    for i, d in enumerate(data):

        fTests[i % nfold].write(d)

        for j in range(nfold-1):
            fTrains[(i + 1 + j) % nfold].write(d)


    # close files
    for f1,f2 in zip(fTrains, fTests):
        f1.close()
        f2.close()

    uars = []
    for i in range(nfold):
        uar, _ = one_fold(task,C,'{}/training_{}_{}_{}.arff'.format(directory,task,random_id,i),'{}/testing_{}_{}_{}.arff'.format(directory,task,random_id,i))
        uars.append(uar)

    return np.mean(uars)

def parameter_tunnig(task, path_data, nfold=5, CList=[0.0001, 0.001, 0.01, 0.1]):
# def parameter_tunnig(task, path_data, nfold=2, CList=[0.0001, 0.001]):
    bestC = 0
    bestUAR = 0
    for C in CList:
        UAR = cross_validation(task, C, path_data, nfold)
        if UAR > bestUAR:
            bestUAR = UAR
            bestC = C

    return bestC, bestUAR

## invoke weka
def resample(trainArff, ustrainArff, cindex, wekaPath='./weka-3-6-12/weka.jar', smpRate=200.0):

    cmd = "java -Xmx4096m -classpath {} weka.filters.supervised.instance.Resample -B 1.0 -S 1 -Z {} -i {} -o {} -c {}".format(
        wekaPath, smpRate, trainArff, ustrainArff, cindex
    );

    p = subprocess.call(
        cmd.split(' ')
    )
    if p:
        print "Can't resample $trainArff. Error: $!";

def labelling(sourceArff, targetArff, result, cindex, wekaPath='./weka-3-6-12/weka.jar'):
    cmd = "java -Xmx4096m -classpath {} weka.classifiers.functions.SMO -v -o -no-cv -C {} -L 0.0010 -P 1.0E-12 -N 0 -V -1 -W 1 -M -K \"weka.classifiers.functions.supportVector.PolyKernel -C 250007 -E 1.0\" -t {} -T {} -p 0 -c {} > {}".format(
        wekaPath, 0.05, sourceArff, targetArff, cindex, result
    );

    p = subprocess.call(
        cmd.split(' ')
    )
    if p:
        print "Can't do labelling";

## cross_labelling

def loadArff(arff):
    headers = []
    data = []
    bData = False
    with open(arff) as f:
        for l in f.readlines():
            if not bData:
                headers.append(l)
            elif len(l) > 10:
                data.append(l)

            if '@data' in l:
                bData = True

    nData = len(data)
    return headers, data, nData

def getTaskIndex(task, header):
    attrs = [h for h in header if 'attribute' in header]
    index = np.inf
    for i, a in enumerate(attrs[-1::-1]):
        if task in a:
            index = len(attrs) - i - 1
            break
    return index

def saveArff(arff, header, data):

    f = open(arff, 'w+')

    # write headers
    for h in header:
        f.write(h)

    # write datas
    for i, d in enumerate(data):
        f.write(d)

    # close files
    f.close()

def updateArff(task, header, data, pred):
    attrs = [h for h in header if 'attribute' in h]
    index = np.inf
    for i, a in enumerate(attrs[-1::-1]):
        if task in a:
            index = len(attrs) - i - 1
            break

    newdata = []
    for d, p in zip(data, pred):
        td = d.strip().split(',')
        td[index] = p[2].split(':')[-1]
        newdata.append(','.join(td)+'\n')
    return newdata


def cross_labelling(task, sourceArff, targetArff, outArff, topRatio=0.3, bottomLimit=20):
    print 'Started cross labelling for task: {}\nStoring at: {}'.format(task, outArff)
    nTarget = np.inf
    directory = './.cl'
    if not os.path.exists(directory):
        os.makedirs(directory)

    predictedArff = []
    while nTarget > 0:
        print 'Labelling {} Targets...'.format(nTarget)

        targetHeader, targetData, nTarget = loadArff(targetArff)
        sourceHeader, sourceData, nSource = loadArff(sourceArff)

        print 'Finding Best Parameters...'
        bestC = parameter_tunnig(task, sourceArff)

        print 'Cross Labelling...'
        _, pred = one_fold(task, bestC, sourceArff, targetArff)
        sort_pred = sorted(pred,key=lambda x: x[-1])
        nPred = len(sort_pred)
        nTop = int(nPred*topRatio)

        print 'Added {} Training Data'.format(nTop)
        top_pred = []
        bottom_pred = []
        if nPred < bottomLimit:
            top_pred = sort_pred
        else:
            top_pred = sort_pred[-1:nPred-nTop-1:-1]
            bottom_pred = sort_pred[:nPred-nTop]

        nTarget = len(bottom_pred)
        targetData = updateArff(task, targetHeader, targetData, pred)

        # Add New Source
        newSource = [targetData[i[0]-1] for i in top_pred]
        newTarget = [targetData[i[0]-1] for i in bottom_pred]

        predictedArff += newSource
        random_id = int(time.time()) + np.random.randint(20000)
        sourceArff = directory + '/temp_source_{}_{}.arff'.format(task, random_id)
        targetArff = directory + '/temp_target_{}_{}.arff'.format(task, random_id)
        saveArff(sourceArff, sourceHeader, newSource + sourceData)
        saveArff(targetArff, targetHeader, newTarget)

    saveArff(outArff, sourceHeader, predictedArff)

# main
if __name__ == '__main__':
    # main program

    argc = len(sys.argv)
    help = 'Invalid Command! Please follow the format:\n - python cv.py base <task> <C> <path_in> <path_out>\n - python cv.py cv <task> <path_in>\n - python cv.py cl <task> <path_source> <path_target> <path_out>\n   - base: baseline_generic\n   - cv: cross validation\n   - cl: cross labelling\n'


    if argc > 3:
        if sys.argv[1] == 'base':
            if argc > 3:
                print one_fold(sys.argv[2],sys.argv[3],sys.argv[4], sys.argv[5])
                exit()
        elif sys.argv[1] == 'cv':
            if argc > 3:
                print parameter_tunnig(sys.argv[2],sys.argv[3])
                exit()
        elif sys.argv[1] == 'cl':
            if argc > 5:
                print cross_labelling(sys.argv[2],sys.argv[3],sys.argv[4], sys.argv[5])
                exit()
    print help
