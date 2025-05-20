Definition of data-driven business innovation.
To classify patents into either data-driven business innovation (DDBI) or non-DDBI, we implement a comprehensive, multi-stage pipeline that blends textual analysis, machine learning, and rigorous sampling. This approach builds upon established methods in the finance literature (see Chen et al., 2019; Li et al., 2021), adapting them to the unique challenges posed by patent classification. Here’s how the process works:

Step 1: Selecting business-method patents
Our starting point is the entire population of patents filed by Compustat firms. We restrict our sample to business method patents only. Business method patents are a specific category of patents that protect novel ways of conducting business, including innovative processes, systems, and techniques in fields such as commerce, finance, and management.

Step 2. Building domain-specific glossaries
We curate two sets of glossaries to identify data-analytics related patents and business related patents, respectively. The data analytics glossaries are aggregated from Lean Methods Group, Statistics.com, and KDnuggets. These glossaries include terms such as big data, statistics, data analysis, machine learning, and data visualization. The business glossaries are compiled from Cambridge International Education and Liveabout.com. These glossaries include business-centric terms like return on investment, B2B, matrix management, and decentralization.

Step 3. Textual preprocessing and vectorization
Each patent’s title and abstract are combined to form a single text field representing the patent’s content. We preprocess this text using standard natural language processing techniques. First, stop words and common terms (such as “and”, “or”, “the”) are removed. The text is tokenized and vectorized using TF-IDF (Term Frequency-Inverse Document Frequency), which quantifies the importance of each term within the corpus relative to its frequency across all documents.

Step 4. Calculating similarity scores
For every business method patent, we compute two cosine similarity scores. The first measures similarity to the data analytics glossaries, and the second measures similarity to the business glossaries. Cosine similarity quantifies how closely the language of a patent aligns with the language of each glossary. This provides a pair of numerical indicators for each patent, capturing both its “data-drivenness” and “business relevance” based on textual content.

Step 5. Constructing the labeled training set
To develop an accurate classification model, we need labeled data. We create a labeled sample using a systematic approach. Our goal is to select roughly 3000 DDBI patents and 3000 non-DDBI patents with high confidence based on the two similarities scores from Step 4. We find that if we use the bottom 5% of patents by similarity to both glossaries, we have about 2,943 patents. We label them as non-DDBI patents: These patents are not data-driven nor strongly business-related. We also find that we have 2,961 patents if we use the top 11% of patents by similarity to both glossaries: these patents are highly relevant to both data analytics and business, and are labeled as DDBI.
This yields a balanced, clearly differentiated set of labeled examples to train the classifier.

Step 6. Training the classification model based on deep neural networks
With our labeled sample in hand, we build a machine learning model to classify all business method patents as DDBI or non-DDBI. The steps include the following substeps.
First, each patent’s text is tokenized, padded to a fixed length of 5000 tokens, and encoded for model input. Second, we use a neural network classifier implemented in TensorFlow. The network includes an embedding layer, followed by dense (fully connected) layers, and outputs a probability score between 0 (non-DDBI) and 1 (DDBI). In the third substep, the labeled data is split into training and validation sets to optimize and validate model performance. We use binary cross-entropy loss and monitor classification accuracy.

Step 7. Predicting DDBI status for all patents
The trained model generates a prediction score for each patent in the population. This score represents the likelihood that a patent belongs to data-driven business innovation. We classify a patent as DDBI if its prediction score is ≥ 0.99 (main specification). For robustness, we also test a lower threshold (score ≥ 0.90). Secondly, we identify patents that are related to only one of the two criteria: data analytics or business methods. 
