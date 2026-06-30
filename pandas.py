import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.naive_bayes import MultinomialNB
from sklearn.svm import LinearSVC
from sklearn.metrics import classification_report, accuracy_score
import re
'''nltk.download('stopwords')
from nltk.corpus import stopwords
# Sample data loading
df = pd.read_csv("test_data.txt")  # should contain 'plot' and 'genre' columns

# Drop missing values
df.dropna(subset=["plot", "genre"], inplace=True)

# Preprocessing function
def clean_text(text):
    text = text.lower()
    text = re.sub(r'[^a-zA-Z\s]', '', text)  # Remove special characters
    tokens = text.split()
    tokens = [word for word in tokens if word not in stopwords.words('english')]
    return ' '.join(tokens)

df["clean_plot"] = df["plot"].apply(clean_text)
tfidf = TfidfVectorizer(max_features=5000)
X = tfidf.fit_transform(df["clean_plot"])

y = df["genre"]  # Assuming single-label classification
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
model = LogisticRegression(max_iter=1000)
model.fit(X_train, y_train)
y_pred = model.predict(X_test)

print("Accuracy:", accuracy_score(y_test, y_pred))
print("\nClassification Report:\n", classification_report(y_test, y_pred))'''



class Node:
    def __init__(self, data):
        self.data=data
        self.next=None
a=Node(5)
b=Node(3)
c=Node(7)

a.next=b
b.next=c
c.next=a
head=a
print(head.data)