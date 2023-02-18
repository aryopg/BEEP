import sys
import csv
import pickle
import os

admnote_folder = sys.argv[1]

note_texts = {}
for file in os.listdir(admnote_folder):
    reader = csv.reader(open(os.path.join(admnote_folder, file)))
    next(reader, None)
    for row in reader:
        note_texts[int(row[0])] = row[1]

pmv_labels = pickle.load(open('pmv_labels.pkl', 'rb'))
if not os.path.isdir('mechanical_ventilation'):
    os.mkdir('mechanical_ventilation')
train_file = open('mechanical_ventilation/pmv_train.csv', 'w')
dev_file = open('mechanical_ventilation/pmv_dev.csv', 'w')
test_file = open('mechanical_ventilation/pmv_test.csv', 'w')
train_writer = csv.writer(train_file)
dev_writer = csv.writer(dev_file)
test_writer = csv.writer(test_file)
train_writer.writerow(['id', 'text', 'label'])
dev_writer.writerow(['id', 'text', 'label'])
test_writer.writerow(['id', 'text', 'label'])

train_ids_not_exist = []
dev_ids_not_exist = []
test_ids_not_exist = []
for note in pmv_labels:
    if pmv_labels[note][-1] == 'train':
        try:
            train_writer.writerow([note, note_texts[note], pmv_labels[note][0]])
        except KeyError:
            train_ids_not_exist += [note]
    if pmv_labels[note][-1] == 'val':
        try:
            dev_writer.writerow([note, note_texts[note], pmv_labels[note][0]])
        except KeyError:
            dev_ids_not_exist += [note]
    if pmv_labels[note][-1] == 'test':
        try:
            test_writer.writerow([note, note_texts[note], pmv_labels[note][0]])
        except KeyError:
            test_ids_not_exist += [note]

train_file.close()
dev_file.close()
test_file.close()

print(f"IDs not found in train: {train_ids_not_exist}")
print(f"IDs not found in dev: {dev_ids_not_exist}")
print(f"IDs not found in test: {test_ids_not_exist}")