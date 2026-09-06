# A BPE Tokenizer Is a Learned Rewrite Program

*Training discovers useful joins. Encoding replays them. Decoding puts the bytes back together.*

Most tokenizer explanations begin with a finished vocabulary. They show that a word such as `tokenizer` becomes two or three fragments, then move on to attention and matrix multiplication.

That skips the interesting machine.

A Byte Pair Encoding tokenizer is best understood as a small rewrite program learned from a corpus. Its trainer discovers an ordered list of useful adjacent joins. Its encoder runs those joins on new text. Its decoder does not reverse the training algorithm at all: it looks up the bytes named by each token ID, concatenates them, and turns the bytes back into text.

Those are three different jobs:

1. **Training:** learn the vocabulary and the order in which pieces may be joined.
2. **Encoding:** apply that frozen merge order to a new string and return integer IDs.
3. **Decoding:** map the integer IDs back to stored pieces and join them.

Once those jobs are separated, BPE stops looking mysterious.

## First, Tokens Are Not Vectors

A tokenizer produces integers. The neural network turns those integers into vectors later.

```text
raw text -> tokenizer -> token IDs -> embedding lookup -> vectors -> Transformer

text <- detokenizer <- chosen token IDs <- sampling <- logits <- hidden vector
```

If token ID `7131` enters a model, the embedding layer retrieves row `7131` from an embedding matrix. That row is a learned vector. On the output side, a hidden vector is projected into one score, or logit, for every token in the vocabulary. Sampling or argmax selects another integer ID. Only then does the detokenizer look up the text piece belonging to that ID.

The detokenizer does not invert the embedding vector. It never needs to see it. Even when a model ties its input embedding and output weights, text reconstruction remains an ID-to-bytes operation.

## The TinyStories Clue

Andrej Karpathy's [`tinystories.py`](https://github.com/karpathy/llama2.c/blob/master/tinystories.py#L861-L1003) makes the tokenizer's lifecycle unusually visible.

The script first collects raw TinyStories text. It trains a custom SentencePiece BPE vocabulary on part of that corpus. It then loads the frozen tokenizer, encodes every story into integer IDs, and writes those IDs to binary files for language-model training.

That order matters:

```text
stories -> train tokenizer once -> freeze tokenizer
        -> encode every story -> train the Transformer on token IDs
```

The language model never participates in choosing the BPE merges. Tokenizer training is a separate statistical pass over text.

Karpathy's TinyStories configuration also exposes decisions hidden by many high-level APIs: BPE is selected explicitly; character coverage is complete; digits may be split; byte fallback is enabled; and normalization is set to identity. These choices determine what information reaches the model before the first Transformer weight is updated.

SentencePiece and byte-level GPT tokenizers differ in their exact starting symbols and boundary rules. SentencePiece normally begins from normalized Unicode symbols and represents spaces with a visible marker such as `▁`, while byte fallback guarantees a route for characters outside the learned pieces. A pure byte-level BPE begins with all 256 possible byte values. The pair-merging heart is the same, but these are not identical implementations.

For the clearest mechanical example, we can use the byte-level version from Karpathy's [`minBPE`](https://github.com/karpathy/minbpe).

## Start With An Alphabet That Cannot Fail

Every Unicode string can be encoded as UTF-8 bytes, and every byte is an integer from 0 through 255. A byte-level tokenizer can therefore begin with a complete 256-token vocabulary:

```text
token 0   -> byte 0x00
token 1   -> byte 0x01
...
token 97  -> b"a"
token 98  -> b"b"
...
token 255 -> byte 0xFF
```

Before any training, this is already a lossless tokenizer. It is just inefficient. An English word may require one token for almost every character, and a non-ASCII character may require several UTF-8 byte tokens.

BPE training adds shortcuts. Each shortcut gives a new token ID to a pair of adjacent pieces that occurs often. Later shortcuts may join earlier shortcuts, so the learned vocabulary becomes hierarchical.

## Training, One Merge At A Time

Use Karpathy's deliberately tiny training string:

```text
aaabdaaabac
```

At the start, ASCII characters and UTF-8 bytes are the same visible units:

```text
a a a b d a a a b a c
```

The trainer counts every adjacent pair. The pair `a a` occurs four times, more than any other pair, so the trainer creates token `256` for the byte string `aa`. Call it `Z` for readability.

It then replaces non-overlapping occurrences of that pair:

| Merge rank | Winning pair | Adjacent count | New token | Rewritten stream |
|---:|---|---:|---|---|
| 0 | `a` + `a` | 4 | `Z = aa` (`256`) | `Z a b d Z a b a c` |
| 1 | `a` + `b` | 2 | `Y = ab` (`257`) | `Z Y d Z Y a c` |
| 2 | `Z` + `Y` | 2 | `X = aaab` (`258`) | `X d X a c` |

There is a small but useful detail in the first row. The count includes overlapping candidates: `aaa` contains two adjacent `aa` pairs. A left-to-right replacement cannot use the middle `a` twice, so four counted candidates produce two non-overlapping replacements in this corpus.

After three rounds, training has produced this ordered merge table:

```text
rank 0: (97, 97)   -> 256     # a  + a  -> aa
rank 1: (97, 98)   -> 257     # a  + b  -> ab
rank 2: (256, 257) -> 258     # aa + ab -> aaab
```

It has also produced the reverse vocabulary needed for decoding:

```text
256 -> b"aa"
257 -> b"ab"
258 -> b"aaab"
```

The essential training loop is therefore:

1. Represent the corpus as current token IDs.
2. Count adjacent token pairs.
3. Select the most frequent pair, with a deterministic tie rule.
4. Assign its concatenation a new token ID.
5. Replace non-overlapping occurrences of the pair.
6. Record the merge's rank.
7. Repeat until the vocabulary reaches its target size or no useful pairs remain.

The statistics must be recomputed because every accepted merge changes the neighborhood. Joining `a a` does not merely remove one possible pair; it creates new candidates involving `aa`.

This is why BPE training is fun to watch. A flat alphabet grows a construction tree in public. Common bytes become fragments, fragments become syllable-like pieces, pieces become words, and very common words may join surrounding spaces or punctuation. The trainer has no concept of a syllable, word, or meaning. It only rewards reusable adjacency.

## Encoding New Text Is Not Training Again

Now give the frozen tokenizer text it did not train on:

```text
aaabac
```

The encoder starts from bytes, just as the trainer did:

```text
a a a b a c
```

But it does **not** count which pairs are common in this new string. It consults the merge table learned earlier.

```text
apply rank 0: a + a  -> Z       Z a b a c
apply rank 1: a + b  -> Y       Z Y a c
apply rank 2: Z + Y  -> X       X a c
```

The result is:

```text
[258, 97, 99]
```

At each step, the encoder examines adjacent pairs that currently exist and chooses the applicable learned merge with the best priority. In a classic BPE table, that means the earliest training rank. It replaces the pair, checks the new neighbors, and continues until no learned rule applies.

This is not simply "take the longest vocabulary item that matches." The vocabulary alone is insufficient when pieces overlap. If both `ab` and `bc` exist and the input is `abc`, the learned priority decides whether `a+b` or `b+c` happens first. The history that created the vocabulary is part of the tokenizer.

Karpathy's minimal encoder expresses the rule directly: among adjacent pairs, choose the pair with the lowest merge index. SentencePiece stores a score for each BPE piece and uses the highest-priority valid join. Production implementations use heaps and caches rather than repeatedly scanning the whole sequence, but they are executing the frozen tokenizer model, not learning from the prompt.

## A Real Tokenization From One Of My Models

One of my own 8,192-piece SentencePiece BPE models encodes this sentence:

```text
Tokenizer training is fun.
```

as these pieces:

```text
['T', 'ok', 'en', 'iz', 'er', '▁training', '▁is', '▁fun', '.']
```

and these IDs:

```text
[7131, 1301, 286, 635, 298, 4521, 344, 667, 7122]
```

The IDs have no natural meaning. They are stable addresses in this tokenizer's vocabulary. A different tokenizer could assign entirely different IDs and boundaries to the same sentence.

The `▁` symbol is SentencePiece's visible representation of whitespace. It allows the model to distinguish `training` at a word boundary from the same letters in another position, while keeping detokenization mechanical. Notice also that the model did not discover an English grammar rule for `tokenizer`; it found reusable corpus fragments: `T`, `ok`, `en`, `iz`, and `er`.

Once language-model training begins, the tokenizer must be frozen. Changing the vocabulary afterward would change what every ID means. Embedding row `7131` cannot continue learning the same thing if `7131` suddenly names a different byte sequence.

## Detokenization Is The Easy Direction

The merge order is needed to choose a segmentation while encoding. It is not needed to decode.

Every ordinary token ID already points to its complete byte string. Decoding the toy result is only:

```text
258 -> b"aaab"
 97 -> b"a"
 99 -> b"c"

b"aaab" + b"a" + b"c" = b"aaabac"
```

In Python, the byte-level core fits on one line plus UTF-8 conversion:

```python
def decode(ids, vocab):
    raw = b"".join(vocab[token_id] for token_id in ids)
    return raw.decode("utf-8", errors="replace")
```

Concatenating bytes before decoding UTF-8 is important. A Unicode character may have been split across several tokens, so decoding each token independently can corrupt text that is perfectly valid after the byte sequences are joined.

SentencePiece makes the same simplicity visible at the piece-string level:

```python
text = "".join(pieces).replace("▁", " ")
```

Real implementations also decide what to do with control tokens such as beginning-of-sequence, end-of-sequence, roles, or padding. And "lossless" is always relative to normalization: if a tokenizer normalizes two different Unicode spellings into one form before encoding, decoding reconstructs that normalized form. Karpathy's TinyStories configuration uses identity normalization, avoiding that particular transformation.

## The Whole Educational Tokenizer

Here is the complete byte-level mechanism without regex boundaries, special tokens, file formats, or performance optimizations:

```python
from collections import Counter


def merge_pair(ids, pair, new_id):
    """Replace non-overlapping occurrences of pair from left to right."""
    out = []
    i = 0
    while i < len(ids):
        if i + 1 < len(ids) and (ids[i], ids[i + 1]) == pair:
            out.append(new_id)
            i += 2
        else:
            out.append(ids[i])
            i += 1
    return out


def train_bpe(text, vocab_size):
    if vocab_size < 256:
        raise ValueError("A byte-level vocabulary needs the 256 base bytes")

    ids = list(text.encode("utf-8"))
    vocab = {i: bytes([i]) for i in range(256)}
    merges = {}  # adjacent pair -> new token ID; ID order is merge rank

    for new_id in range(256, vocab_size):
        counts = Counter(zip(ids, ids[1:]))
        if not counts:
            break

        # Highest frequency, then lexicographically smallest pair on a tie.
        pair = min(counts, key=lambda p: (-counts[p], p))
        ids = merge_pair(ids, pair, new_id)
        merges[pair] = new_id
        vocab[new_id] = vocab[pair[0]] + vocab[pair[1]]

    return merges, vocab


def encode(text, merges):
    ids = list(text.encode("utf-8"))

    while len(ids) >= 2:
        adjacent = set(zip(ids, ids[1:]))
        candidates = [(merges[pair], pair)
                      for pair in adjacent if pair in merges]
        if not candidates:
            break

        new_id, pair = min(candidates)  # earliest learned merge wins
        ids = merge_pair(ids, pair, new_id)

    return ids


def decode(ids, vocab):
    raw = b"".join(vocab[token_id] for token_id in ids)
    return raw.decode("utf-8", errors="replace")
```

And the toy run is:

```python
merges, vocab = train_bpe("aaabdaaabac", vocab_size=259)
ids = encode("aaabac", merges)

print(ids)                 # [258, 97, 99]
print(decode(ids, vocab))  # aaabac
```

This small implementation is enough to expose the invariant. A production tokenizer changes data structures and policy, not the central mechanism.

## What Production Tokenizers Add

The short implementation above permits merges across every neighboring byte, including spaces, punctuation, and document boundaries. Practical tokenizers add several controls.

**Normalization** decides whether visually or semantically equivalent Unicode forms become the same input. Lowercasing, compatibility normalization, and whitespace cleanup may improve consistency but can destroy exact round trips.

**Pretokenization or boundary rules** divide text into chunks before BPE. GPT-style regex tokenizers separate categories such as letters, numbers, punctuation, and whitespace so that a merge cannot cross a forbidden boundary. SentencePiece instead keeps whitespace visible as a normal symbol and can train directly from raw sentences.

**Base coverage and byte fallback** determine whether every input is representable. A byte-level vocabulary is complete by construction. A Unicode-piece tokenizer needs an unknown-token policy or byte fallback for characters outside its learned inventory.

**Special tokens** carry structure rather than ordinary prose: beginning and end markers, padding, message roles, tool boundaries, or media placeholders. They must be registered and handled atomically so user text cannot accidentally acquire control semantics.

**Tie-breaking and serialization** make the model reproducible. Two trainers that resolve equal pair counts differently may build different later vocabularies even when they read the same corpus.

**Optional sampling** can deliberately vary segmentation during language-model training, as in BPE dropout. Ordinary inference is normally deterministic.

## What BPE Is Actually Optimizing

BPE often discovers pieces that resemble prefixes, suffixes, roots, words, or punctuation patterns. That is an effect of frequency, not linguistic understanding.

Each accepted merge reduces the number of symbols needed to represent occurrences of one adjacent pattern. Repeating that greedy choice tends to create a reusable codebook that shortens sequences on the training distribution. It is compression-like, but it is not a complete file-compression system: language models usually represent token IDs with fixed-width integers internally, and a larger vocabulary also enlarges the embedding table and output projection.

Vocabulary size is therefore a tradeoff:

- A larger vocabulary usually produces shorter token sequences and gives frequent patterns direct IDs.
- A smaller vocabulary produces longer sequences but reduces vocabulary-dependent parameters and retains more compositional reuse.
- A vocabulary trained on the wrong domain may waste entries on irrelevant patterns while fragmenting the text the model actually needs to learn.

Karpathy's TinyStories script captures the practical response: train a compact tokenizer on the kind of text the small model will see, then measure the resulting story lengths before choosing the model's context and storage format.

Useful validation is concrete: test exact round trips, unseen Unicode, whitespace, malformed input policy, atomic special tokens, determinism, and token counts on held-out prose, code, numbers, and every language the model must support. `tokens per word` is not enough across languages; bytes per token and tokens per character expose different failure modes.

## The Mental Model To Keep

A BPE tokenizer is not a dictionary of words, and it is not a neural network.

The trainer is a compiler. It reads a corpus and emits an ordered rewrite program plus a vocabulary.

The encoder is an interpreter. It begins with safe base symbols and executes every learned join that applies, in learned-priority order.

The embedding layer is a separate machine. It turns the encoder's integer IDs into vectors for the Transformer.

The decoder is a table lookup and a join. It does not need pair counts, merge ranks, gradients, or vectors.

Training discovers the joins. Inference obeys their history. Decoding simply puts the pieces back together.

## Sources And Implementations

- Andrej Karpathy, [`llama2.c/tinystories.py`](https://github.com/karpathy/llama2.c/blob/master/tinystories.py#L861-L1003), for the custom TinyStories SentencePiece training and pretokenization pipeline.
- Andrej Karpathy, [`minBPE`](https://github.com/karpathy/minbpe), for a compact byte-level implementation of training, encoding, and decoding.
- Rico Sennrich, Barry Haddow, and Alexandra Birch, [*Neural Machine Translation of Rare Words with Subword Units*](https://aclanthology.org/P16-1162/), for the adaptation of BPE to open-vocabulary neural text processing.
- Taku Kudo and John Richardson, [*SentencePiece: A simple and language independent subword tokenizer and detokenizer for Neural Text Processing*](https://arxiv.org/abs/1808.06226), for direct training from raw sentences and reversible whitespace handling.
