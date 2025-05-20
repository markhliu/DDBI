# -*- coding: utf-8 -*-
"""
Created on June 15 2023

@author: angli
"""

pip install textract
pip install scikit-learn

import math
import string
import sys
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.feature_extraction.text import TfidfTransformer
from sklearn.feature_extraction.text import TfidfVectorizer
import pandas as pd
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np
from pandas import DataFrame as df

patent_data = pd.read_csv('C:/Users/angli/OneDrive - Lingnan University/Data_driven_innovation/Stata/dta/business_method_patents_all192k.csv')
abstract = patent_data['abstract'].tolist()
patnum = patent_data['patnum'].tolist()
title = patent_data['title'].tolist()
##Create a new column in the dataframe that includes patent title and abstract.
patent_data['patent'] = patent_data['title'] + patent_data['abstract']
patent_data['patent'] = patent_data['patent'].astype('unicode')
patent_data['patent'][2]

patent = patent_data['patent'].tolist()
patent[2]


f = open("C:/Users/angli/OneDrive - Lingnan University/Data_driven_innovation/Glossaries/LeanMethod - Data analytics glossary.txt", 'r')
content1 = f.read()
print(content1)
f = open("C:/Users/angli/OneDrive - Lingnan University/Data_driven_innovation/Glossaries/Statistics_com - Terminology in Data Analytics.txt", 'r')
content2 = f.read()
f = open("C:/Users/angli/OneDrive - Lingnan University/Data_driven_innovation/Glossaries/KDnuggets - Glossary of Big Data Terminology.txt", 'r')
content3 = f.read()

f = open("C:/Users/angli/OneDrive - Lingnan University/Data_driven_innovation/Glossaries/Business_glossary_Cambridge.txt", 'r')
content4 = f.read()
f = open("C:/Users/angli/OneDrive - Lingnan University/Data_driven_innovation/Glossaries/Business_glossary_liveabout.txt", 'r')
content5 = f.read()

glossary_data =content1 + content2 +content3
glossary_business =content4 + content5

tfidf_vectorizer = TfidfVectorizer(stop_words='english', token_pattern="(?u)\\b\\w\\w+\\b")

##Similarity to Data glossary
sparse_matrix = tfidf_vectorizer.fit_transform([glossary_data]+patent)
cosine = cosine_similarity(sparse_matrix[0,:],sparse_matrix[1:,:])
Cosine_patents_data = pd.DataFrame({'cosine':cosine[0],'strings':patent,'patnum':patnum}).sort_values('cosine',ascending=False)

Cosine_patents_data.to_excel('C:/Users/angli/OneDrive - Lingnan University/Data_driven_innovation/Python/Cosine_bm_patents_data_202310.xlsx') 

##Similarity to Business glossary
sparse_matrix = tfidf_vectorizer.fit_transform([glossary_business]+patent)
cosine = cosine_similarity(sparse_matrix[0,:],sparse_matrix[1:,:])
Cosine_patents_business = pd.DataFrame({'cosine':cosine[0],'strings':patent,'patnum':patnum}).sort_values('cosine',ascending=False)

Cosine_patents_business.to_excel('C:/Users/angli/OneDrive - Lingnan University/Data_driven_innovation/Python/Cosine_bm_patents_business_202310.xlsx') 





















Cosine_patents.groupby(['Data_dummy']).agg('mean')