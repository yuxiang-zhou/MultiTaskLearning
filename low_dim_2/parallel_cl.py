from cv import *

import threading
import time
import numpy as np

def mergeArff(tasks, files, outfile):

    mergedheader, mergedData, mergedNData = loadArff(files[0])

    for t,f in zip(tasks[1:], files[1:]):
        _, data, _ = loadArff(f)
        index = getTaskIndex(t, mergedheader)
        newMergedData = []
        for d, md in zip(data, mergedData):
            tmd = md.strip().split(',')
            td = d.strip().split(',')
            tmd[index] = td[index]
            newMergedData.append(','.join(tmd)+'\n')
        mergedData =newMergedData
    
    saveArff(outfile, mergedheader, mergedData)

if __name__ == '__main__':
    batch = [
        # {
        #     "file_source": './cl/emotion.train.arff',
        #     "file_target": './cl/likability.train.arff',
        #     "file_out": './labelled/el.arff',
        #     "tasks":['arousal', 'valence']
        # },
        # {
        #     "file_source": './cl/emotion.train.arff',
        #     "file_target": './cl/personality.train.arff',
        #     "file_out": './labelled/ep.arff',
        #     "tasks":['arousal', 'valence']
        # },
        # {
        #     "file_source": './cl/likability.train.arff',
        #     "file_target": './cl/emotion.train.arff',
        #     "file_out": './labelled/le.arff',
        #     "tasks":['likability']
        # },
        # {
        #     "file_source": './cl/likability.train.arff',
        #     "file_target": './cl/personality.train.arff',
        #     "file_out": './labelled/lp.arff',
        #     "tasks":['likability']
        # },
        {
            "file_source": './cl/personality.train.arff',
            "file_target": './cl/likability.train.arff',
            "file_out": './labelled/pl.arff',
            "tasks":['openness', 'conscientiousness', 'extraversion', 'agreeableness', 'neuroticism']
        },
        {
            "file_source": './cl/personality.train.arff',
            "file_target": './cl/emotion.train.arff',
            "file_out": './labelled/pe.arff',
            "tasks":['openness', 'conscientiousness', 'extraversion', 'agreeableness', 'neuroticism']
        }
    ]
    
    directory = './.batch'
    if not os.path.exists(directory):
        os.makedirs(directory)

    for b in batch:
        threads = []
        random_id = int(time.time()) + np.random.randint(20000)
        tempFiles = []

        for t in b['tasks']:
            print 'Starting task: ' + t
            tempFile = '{}/{}_{}.arff'.format(directory,t,random_id)
            tempFiles.append(tempFile)
            th = threading.Thread(
                target=cross_labelling, args = (
                    t,b['file_source'],b['file_target'], tempFile
                )
            )
            th.daemon = True
            th.start()
            threads.append(th)

        for t in threads:
            t.join()

        mergeArff(b['tasks'], tempFiles, b['file_out'])

    

    print 'done'