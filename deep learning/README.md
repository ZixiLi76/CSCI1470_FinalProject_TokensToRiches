# Life-Course Trajectory Prediction

Authors: Zachk Huang and Zixi Li

This repository predicts later-life earnings, employment, and marriage trajectories from early-adult histories and family background variables using PSID panel data.

## Repository Structure

- `data/raw/`: raw PSID input files and external documentation.
- `data/processed/`: cleaned modeling data, including `psid_panel.csv`.
- `codes/`: modeling, ablation, graph, and cleaning notebooks used for the project.
- `results/`: model outputs, metrics, predictions, checkpoints, and generated figures.
- `reports/poster/`: LaTeX poster source and compiled PDF.
- `docs/`: project writeups and supporting documents.
- `environment.yml`: conda environment exported from the `csci1470` environment.

## Main Poster Pipeline

1. `codes/CSCI1470_Parallel_TaskDecoder_Transformer.ipynb`
2. `codes/CSCI1470_Autoregressive_TaskDecoder_Transformer.ipynb`
3. `codes/CSCI1470_ScheduledSampling_TaskDecoder_Transformer.ipynb`
4. `codes/CSCI1470_TaskDecoder_Input_Ablations.ipynb`
5. `codes/CSCI1470_Autoregressive_Comparison_Graphs.ipynb`
6. `reports/poster/poster.tex`

## Environment

Create the conda environment with:

```bash
conda env create -f environment.yml
conda activate csci1470
```

## Data Flow

The modeling notebooks read:

```text
data/processed/psid_panel.csv
```

and write outputs to:

```text
results/
```

The poster reads generated figures from `results/` and compiles from:

```text
reports/poster/poster.tex
```
