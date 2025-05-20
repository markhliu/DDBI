# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""

import tensorflow as tf

from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences

     
import numpy as np
import pandas as pd

#csv needs to be saved in 'utf-8'
dataset = pd.read_csv('BM_patents_all_label_202310.csv')


patnum = dataset['patnum'].tolist()
sentences = dataset['strings'].tolist()
labels = dataset['label'].tolist()


##Take out the labeled patents, shuffle them, and then train model.
labeled_patnum = patnum[0:5904] 
labeled_sentences = sentences[0:5904] 
labeled_labels = labels[0:5904] 
print(labeled_labels[5903])
print(labeled_labels.count(0)) #2943
print(labeled_labels.count(1)) #2961

df = pd.DataFrame(list(zip(labeled_patnum, labeled_sentences, labeled_labels)),
               columns =['patnum', 'strings', 'label'])
df_shuffle = df.sample(frac=1)

##Append with unlabeled patents
unlabeled_patnum = patnum[5904:] 
unlabeled_sentences = sentences[5904:] 
unlabeled_labels = labels[5904:] 
print(unlabeled_labels.count(1))
print(unlabeled_labels.count(0))
df_unlabeled = pd.DataFrame(list(zip(unlabeled_patnum, unlabeled_sentences, unlabeled_labels)),
               columns =['patnum', 'strings', 'label'])


#df = df_shuffle.append(df_unlabeled)

df=pd.concat([df_shuffle, df_unlabeled], axis = 0)



patnum = df['patnum'].tolist()
sentences = df['strings'].tolist()
labels = df['label'].tolist()

training_size = int(5904 * 0.667) # 2/3 of the items will be the training sample

training_sentences = sentences[0:training_size] 
testing_sentences = sentences[training_size:5904]
training_labels = labels[0:training_size] 
testing_labels = labels[training_size:5904]

# Make labels into numpy arrays for use with the network later
training_labels_final = np.array(training_labels)
testing_labels_final = np.array(testing_labels)


"""
Tokenize the dataset, including padding and OOV
Padding: add 0 in front or at the end.
OOV: Out of vocabulary. Add words that are not in the dictionary
"""
vocab_size = 5000
embedding_dim = 100
max_length = 500
trunc_type='post'
padding_type='post'
oov_tok = "<OOV>"


tokenizer = Tokenizer(num_words = vocab_size, oov_token=oov_tok)
tokenizer.fit_on_texts(sentences) # feed the training sample
word_index = tokenizer.word_index
sequences = tokenizer.texts_to_sequences(sentences)
padded = pad_sequences(sequences, maxlen=max_length, padding=padding_type, truncating=trunc_type)


training_sequences = sequences[0:training_size]
training_padded = padded[0:training_size]
testing_sequences = sequences[training_size:5904]
testing_padded = padded[training_size:5904]

"""
Review a Sequence
Let's quickly take a look at one of the padded sequences to ensure everything above worked appropriately.
"""
reverse_word_index = dict([(value, key) for (key, value) in word_index.items()]) # Exchange the places of key and value

#' '.join() means a space between the items that will be joined.
#If a key is not in the dict, return a question mark.
def decode_review(text):
    return ' '.join([reverse_word_index.get(i, '?') for i in text]) 
print(decode_review(padded[1]))
print(training_sentences[1])


"""
Train a Basic Sentiment Model with Embeddings
"""
# Build a basic sentiment network
# Note the embedding layer is first, 
# and the output is only 1 node as it is either 0 or 1 (negative or positive)


model = tf.keras.Sequential([
    tf.keras.layers.Embedding(vocab_size, embedding_dim, input_length=max_length),
    tf.keras.layers.Flatten(),
    tf.keras.layers.Dense(256, activation='relu'),    
    tf.keras.layers.Dense(32, activation='relu'),
    tf.keras.layers.Dense(1, activation='sigmoid')
])
model.compile(loss='binary_crossentropy',
              optimizer=tf.keras.optimizers.Adam(learning_rate=0.00025),
              metrics=['accuracy'])
model.summary()

num_epochs = 100
model.fit(training_padded, training_labels_final, 
          epochs=num_epochs, 
          validation_data=(testing_padded, testing_labels_final))






predictions = model.predict(padded)
print(predictions[15555])

df_predicted = pd.DataFrame(list(zip(patnum, sentences, labels, predictions)),
               columns =['patnum', 'strings', 'label', 'predictions'])
df_predicted.to_excel("prediction_new_allBM_202310.xlsx")  


model.save("leo.h5")







