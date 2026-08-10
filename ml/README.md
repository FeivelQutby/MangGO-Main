# ml — model training

Produces `MangoDefect.mlpackage` for `Core/Vision/Resources/`.

Two notebooks, same result. Pick one.

| | Where | Setup | Speed |
|---|---|---|---|
| `train_mango_defect_colab.ipynb` | Google Colab, free T4 GPU | none | ~20 min |
| `train_mango_defect.ipynb` | This Mac, Apple Silicon MPS | venv, ~3 GB download | 30–90 min |

Colab is the easier start — PyTorch is already installed there, so nothing large
gets downloaded. Core ML conversion works on Colab too; the model only needs
Apple hardware to *run*, not to be built.

The local notebook is worth setting up later, once you are retraining often on
your own box images.

## Why not train on Roboflow

Roboflow's own training produces a hosted model. Downloading the weights needs a
paid Core plan, and there is no Core ML export path — their iOS story is an SDK
that calls their runtime over the network. That conflicts with the offline
requirement.

So Roboflow is used as the dataset source only. Training and export happen here.

## Colab

Upload `train_mango_defect_colab.ipynb` to <https://colab.research.google.com>
(File → Upload notebook), set Runtime → Change runtime type → **T4 GPU**, fill in
the two values below, Run all.

It downloads `MangoDefect.zip` at the end. Unzip it and drag the
`MangoDefect.mlpackage` folder into `MangGO/MangGO/Core/Vision/Resources/`.

## Local setup (optional)

Once, from this folder:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install ultralytics roboflow coremltools ipykernel
```

Then open `train_mango_defect.ipynb` in VS Code and pick `.venv` as the kernel
(top right → Select Kernel → Python Environments → `.venv`).

If `coremltools` refuses to install, your Python is likely too new. Rebuild with
`python3.12 -m venv .venv`.

## Run

Fill in two values in the download cell, then run all cells:

- `API_KEY` — <https://app.roboflow.com/settings/api>
- `VERSION` — from the dataset page: **Download Dataset** → **Show download
  code** → the number inside `version(...)`

The last cell installs the model into `Core/Vision/Resources/`. No Swift changes
are needed beyond switching the detector in `iPhoneView.swift`.

Expect 30–90 minutes on Apple Silicon, depending on the chip.

`export_coreml.sh` performs the same conversion standalone, for the case where a
`.pt` comes from somewhere other than this notebook.

## Expected accuracy

The public dataset is 401 images with a single `defect` class. Published baseline
is mAP@50 38.2%, precision 43.6%, recall 42.0%. Training YOLO11n on it lands in
the same range.

That is enough to prove the pipeline works end to end. It is not enough to grade
fruit for real, for two reasons:

- **Size.** 401 images is small for object detection.
- **Domain shift.** These are varied photos. The box has fixed lighting, a fixed
  camera distance, and a plain background — a model trained on internet photos
  behaves differently inside it.

Both are fixed the same way: once the box exists, photograph 200–300 mangoes in
it, annotate them in Roboflow, merge with the public dataset, retrain with this
same notebook. The controlled environment that makes the setup harder to source
data for is also what makes a modest dataset go a long way.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `version not found` | Wrong `VERSION` — recopy from the download code |
| Authentication error | `API_KEY` still the placeholder |
| Training hangs at epoch 1 | Set `workers=0` (already the default here) |
| Out of memory | Lower `BATCH` to 4 |
| Export fails on coremltools | Python too new — rebuild the venv with 3.12 |
| `repository root not found` | Notebook running outside the repo |
