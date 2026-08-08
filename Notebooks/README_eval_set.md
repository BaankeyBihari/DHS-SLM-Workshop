# MediLearn Workshop — Shared Evaluation Set (60 questions)

This is the **one fixed eval set** to be loaded, unmodified, into Modules 1, 2, 3, 4, and 6. Same 60 questions, same scoring, every time — only the model/pipeline changes between modules. That's what makes the "it gets better at each stage" story credible.

## Files
- `medilearn_eval_60.json` — primary source of truth (load this in every notebook)
- `medilearn_eval_60.csv` — same data, spreadsheet-friendly for manual review

## Schema
| Field | Purpose |
|---|---|
| `id` | Q001–Q060, stable across all modules |
| `category` | Cardiology, Neurology, Respiratory, Endocrine, Critical Care, Pharmacology (10 each) |
| `difficulty` | L1 / L2 / L3 — see below |
| `question` | The prompt sent to the model |
| `key_terms` | Lowercase terms a correct answer should contain — used for keyword/term-coverage scoring (works even without an embedding model, so it's usable in Module 1 and Module 2) |
| `reference_answer` | Short ideal answer — used for semantic similarity / ROUGE scoring where an embedding model is already loaded (Modules 3, 4, 6) |

## Difficulty levels — and why they matter for the workshop narrative
- **L1 (18 questions)** — single-fact recall, flashcard-style. A fine-tuned model should already do well here; this is the floor.
- **L2 (24 questions)** — clinical scenario requiring one guideline or protocol fact. This is where RAG (Module 3) should show its biggest lift, since the knowledge base directly supplies the missing fact.
- **L3 (18 questions)** — multi-step reasoning, differential diagnosis, or "explain why" mechanism questions. This is where Agentic RAG (Module 4) should pull ahead of passive RAG, since it requires reasoning over retrieved context rather than just relaying it.

Running the same 60 questions at every stage and slicing by `difficulty` is what lets you show, with one consistent chart, that each module's added capability (fine-tuning → RAG → agentic reasoning → edge quantization) helps with a different part of the difficulty curve — not just "the numbers went up."

## Recommended use per module
| Module | What's evaluated | Subset |
|---|---|---|
| 1 | Base, un-fine-tuned SLMs (TinyLlama/SmolLM/Qwen) | All 60 — establishes the baseline before any domain work |
| 2 | Base vs. fine-tuned SmolLM-135M | All 60 — same questions as Module 1's baseline run, for a clean before/after |
| 3 | Fine-tuned SLM vs. fine-tuned SLM + RAG vs. GPT-4o + RAG | All 60 |
| 4 | Module 3 passive RAG vs. Module 4 agentic RAG | All 60 |
| 6 | Full-precision fine-tuned model vs. GGUF/quantized edge model | All 60 (or a fast 20-question stratified sample if Colab CPU time is tight — keep the same 20 IDs every run) |

## Metrics to keep constant across every module (Step 3)
To make cross-module comparison valid, every module's evaluation section should report the **same metric set**, computed the same way:
1. **Keyword/term coverage** — fraction of `key_terms` present in the response (works everywhere, no embedding model needed)
2. **Semantic relevance** — cosine similarity between response and `reference_answer` embeddings (Modules 3, 4, 6 already load `sentence-transformers`; Module 1/2 should adopt the same embedding model for comparability)
3. **Latency** — seconds per response (already tracked in most modules; just needs the same eval set behind it)
4. **Score by difficulty tier** — mean of metric 1/2 broken out by L1/L2/L3, not just an overall average

Step 3 will add a standardized evaluation section to each notebook implementing exactly this.
