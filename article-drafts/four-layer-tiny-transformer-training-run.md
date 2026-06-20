# Four-Layer Tiny Transformer Training Run

## Source Facts

- Public artifact: https://github.com/omnipresentalgorithm/simpler-llama/pull/1
- Raw script/log artifact: https://raw.githubusercontent.com/avesus/llama2.c/e7e79b283a344279d15f7761a525d5da222074e7/train-dali.sh
- PR title: `0.8M parameters model (16,000 times smaller than Vicuna-13B) training...`
- PR state at inspection: open.
- PR created: 2024-06-22T15:56:52Z.
- The PR adds one file: `train-dali.sh`.
- PR body describes a simple 4-layer generative Transformer with 16 attention heads.
- PR body notes one LLaMA tweak: the embedding matrix has a computed pseudo-inverse used as the unembedding, and that unembedding is backpropagated.
- PR body says that after 50,000 iterations it generates wild tiny stories.
- The script includes sample inference parameters and a training run log past 50,000 iterations.

## Training Log Facts

- Inference command uses `python3 sample.py`.
- Inference parameters include `--max_new_tokens=10240`, `--top_k=200`, `--temperature=0.8`, checkpoint `./outminimagic23/ckpt.pt`, tokenizer `./data/tok361.model`, and empty start string.
- Model args shown in the log:
  - `dim=128`
  - `n_layers=4`
  - `n_heads=16`
  - `n_kv_heads=16`
  - `vocab_size=361`
  - `max_seq_len=128`
  - `dropout=0.15`
- Training command uses `python3 train.py`.
- Training parameters include:
  - `out_dir=outminimagic19`
  - `batch_size=64`
  - `max_seq_len=128`
  - `gradient_accumulation_steps=1`
  - `vocab_source=custom`
  - `vocab_size=361`
  - `dim=128`
  - `n_layers=4`
  - `n_heads=16`
  - `n_kv_heads=16`
  - `multiple_of=1`
  - `learning_rate=3e-4`
  - `dropout=0.15`
  - `weight_decay=0.1`
  - `max_iters=100000`
  - `beta2=0.99`
  - `warmup_iters=2500`
  - `eval_interval=5000`
  - `eval_iters=100`
  - `compile=False`
  - `device=cpu`
- Tokens per iteration: 8,192.
- Logged model initialization starts from scratch.
- Logged decayed parameter tensors: 29, with 832,128 parameters.
- Logged non-decayed parameter tensors: 13, with 2,516 parameters.
- Total logged parameters from those two counts: 834,644.
- Log shows step 0 train loss 13.0864 and val loss 13.0707.
- Log excerpt reaches step 53,130.
- Around step 53,130, logged loss is in the approximate 0.75 to 0.86 range.
- The sample output is repetitive and broken in places, but it has recognizable story structure: named characters, actions, dialogue, simple causal turns, and moral-like endings.

## Article Skeleton

### Opening Claim

This is a tiny generative Transformer training artifact: 4 layers, 16 attention heads, 128-dimensional embeddings, 128-token context, a 361-token custom vocabulary, and about 835k logged parameters, trained on CPU past 50,000 iterations until it produced recognizable small-story text.

### Why It Exists

The engineering point is inspection. A small model run like this is large enough to show emergent generative behavior but small enough that its parameter shapes, training command, tokenizer size, context length, and sample behavior fit on one page.

### What The Artifact Shows

The PR is not a polished model release. It is a public training-run artifact. It records the model shape, training command, inference command, sample output, and a long enough loss log to show that the run progressed from initialization into a working tiny-story generator.

### The Model

Use a compact table in the eventual article:

- Layers: 4
- Attention heads: 16
- Key/value heads: 16
- Embedding dimension: 128
- Context length: 128 tokens
- Vocabulary: 361 tokens
- Dropout: 0.15
- Total logged parameters: 834,644
- Training device: CPU
- Tokens per iteration: 8,192

### The Tweak

The PR body says the embedding matrix uses a computed pseudo-inverse as the unembedding, and that the unembedding is backpropagated. The article should present this as an implementation note from the artifact, then explain why it matters only if Brian provides more detail.

### Evidence To Show

- Link the PR.
- Link the raw training script/log.
- Quote only short sample excerpts if needed.
- Show the model args and training command as evidence.
- Summarize the generated text behavior without overclaiming quality.

### Tradeoff

This run is not a benchmark model and should not be sold as one. Its value is that the full setup is small enough to inspect: architecture, vocabulary, context length, loss log, and sample behavior all fit into a concrete artifact.

### Next Article Link

Candidate next read: a future backprop/online-training article, because this run raises the question of how training behavior can be made small and inspectable.

## Open Verification

- Ask Brian for the dataset/tokenizer source and why `vocab_size=361` was chosen.
- Ask whether `outminimagic19` and `outminimagic23` represent different checkpoints/runs or naming drift in the artifact.
- Ask whether there are saved loss curves or checkpoint metadata.
- Ask how much detail to include about the pseudo-inverse unembedding.
- Decide whether to include a very short generated-text excerpt or only summarize the behavior.

