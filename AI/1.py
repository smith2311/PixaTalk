import torch
import torch.nn as nn
import torchvision.utils as vutils
import nltk
from nltk.tokenize import word_tokenize
from torchvision import transforms
import matplotlib.pyplot as plt
import numpy as np

# ✅ Download the punkt tokenizer if not already available
nltk.download('punkt')  # <--- This line fixes the error you got

# Pretrained text encoder (simple word embedding)
class TextEncoder(nn.Module):
    def __init__(self, vocab_size, embedding_dim):
        super(TextEncoder, self).__init__()
        self.embedding = nn.Embedding(vocab_size, embedding_dim)

    def forward(self, tokens):
        return self.embedding(tokens).mean(dim=1)  # mean pooling

# Generator
class Generator(nn.Module):
    def __init__(self, noise_dim, embedding_dim):
        super(Generator, self).__init__()
        self.fc = nn.Sequential(
            nn.Linear(noise_dim + embedding_dim, 256),
            nn.ReLU(True),
            nn.Linear(256, 512),
            nn.ReLU(True),
            nn.Linear(512, 28 * 28),
            nn.Tanh()
        )

    def forward(self, noise, text_embed):
        x = torch.cat((noise, text_embed), dim=1)
        out = self.fc(x)
        return out.view(-1, 1, 28, 28)

# Simple tokenizer + vocab
def get_token_ids(text, vocab):
    tokens = word_tokenize(text.lower())
    return torch.tensor([[vocab.get(t, 0) for t in tokens]])

# Dummy vocab
vocab = {'a': 1, 'cat': 2, 'on': 3, 'mat': 4}
vocab_size = len(vocab) + 1
embedding_dim = 10
noise_dim = 100

# Initialize
text_encoder = TextEncoder(vocab_size, embedding_dim)
generator = Generator(noise_dim, embedding_dim)

# Inference
text = "a cat on mat"
tokens = get_token_ids(text, vocab)
text_embed = text_encoder(tokens)

noise = torch.randn(1, noise_dim)
with torch.no_grad():
    fake_img = generator(noise, text_embed)

# Plot output
plt.imshow(fake_img.squeeze().detach().numpy(), cmap='gray')
plt.title(text)
plt.axis('off')
plt.show()
