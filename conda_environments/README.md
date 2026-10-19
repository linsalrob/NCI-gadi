# Retired conda environments

These are the specifications of conda environments (and two Python venvs) that were deleted from
Gadi on 2026-10-19 to free inodes. Each one is recorded here so it can be rebuilt if needed. None of
them was claimed as "needed" by any active project on
[agent-handoffs#26](https://github.com/linsalrob/agent-handoffs/issues/26), the register of
environments in use. Scratch had gone over its inode quota, which put queued jobs on hold.

A conda environment costs 10,000–70,000 inodes. These files cost one each.

## Files

For each conda environment `<name>` there are three files, listed here from most portable to most
exact:

| File | What it is | When to use it |
|---|---|---|
| `<name>.yml` | The packages that were explicitly asked for (`conda env export --from-history`), each pinned to the version that was installed, plus every pip package with its exact version. Dependencies are left to the solver. | **Start here.** Rebuilds the same tool versions on a current solver. |
| `<name>.lock.yml` | Full `conda env export`: every package with its version and build string. | When the `.yml` solve drifts and you need the identical stack. |
| `<name>.explicit.txt` | `conda list --explicit --md5`: exact package URLs. linux-64 only. Contains conda packages only, no pip packages. | A byte-for-byte rebuild with no solver at all, provided the URLs still resolve. |

The two venvs (`ccvenv`, `ccvenv2`) have `<name>.requirements.txt` instead. These are
`pip freeze --local` outputs, and a header records the original `pyvenv.cfg`.

## Rebuilding

Environments live in `/g/data/$PROJECT/$USER/conda`. Build them on a login node or in `copyq`,
because compute nodes have no network access. First check
[agent-handoffs#26](https://github.com/linsalrob/agent-handoffs/issues/26), and post there when you
recreate an environment.

```bash
eval "$(conda shell.bash hook)"
NAME=eggnog
mamba env create -p /g/data/$PROJECT/$USER/conda/$NAME -f $NAME.yml

# exact rebuild instead:
mamba create -p /g/data/$PROJECT/$USER/conda/$NAME --file $NAME.explicit.txt
conda activate /g/data/$PROJECT/$USER/conda/$NAME
# then pip-install the `pip:` block of $NAME.yml, if it has one
```

The `.yml` files say `bioconda, conda-forge, defaults`, because that is how the base conda was
configured. Remove `defaults` if Anaconda licensing matters to you.

For a venv:

```bash
/g/data/$PROJECT/$USER/conda/boltz2/bin/python -m venv [--system-site-packages] <dir>
<dir>/bin/pip install -r ccvenv.requirements.txt
```

## The environments

Inodes were measured with `find -xdev | wc -l` (gdata on 2026-10-16, scratch on 2026-10-19).

| Name | Was at | Inodes | Main contents | Notes |
|---|---|---:|---|---|
| `phynteny` | gdata | 52,494 | `phynteny-transformer` 0.1.3 (pip) | phage_interactions Track-1 annotation; outputs kept |
| `singlem` | gdata | 44,742 | SingleM's *dependencies* only (diamond, hmmer, graftm, pplacer, krona, …) | Built from SingleM's own env file (`mamba create -n singlem -f singlem.yml`). SingleM itself is not in it and was presumably run from a source checkout. |
| `deeptmhmm` | gdata | 43,523 | python 3.9 + pip, torch 2.7.1+cu126 and 55 other pip packages | The DeepTMHMM licensed models are **not** in the env. They are in `/g/data/ob80/re3494/db/deeptmhmm/`, which was not deleted. |
| `tmbed` | gdata | 38,096 | `tmbed` 1.0.2, torch 2.7.1+cu126 (pip) | |
| `eggnog` | gdata | 33,630 | `eggnog-mapper` 2.1.15 | |
| `phispy` | gdata | 29,608 | PhiSpy 4.2.21, snakemake 7.8.0 | The old PhiSpy. The current pipeline uses the separate `phispy5` env, which was kept. |
| `signalp6` | gdata | 23,964 | `signalp6` 6.0+h, torch 1.13.1+cpu (pip) | **Licensed, not on PyPI.** See below. |
| `genbank_to` | gdata | 13,035 | `genbank_to` 0.42 | |
| `spades` | gdata | 12,856 | SPAdes 3.15.5 | |
| `pybiolib` | gdata | 11,178 | `pybiolib` 1.1.450 (pip) | BioLib client, e.g. for DeepTMHMM via BioLib |
| `sra-tools` | gdata | 9,006 | sra-tools 3.0.6 | |
| `buildenv` | gdata | 8,851 | python 3.12 only | Scratch environment with nothing specific in it |
| `foldseek` | gdata | 4,397 | foldseek 10.941cd33 | |
| `entrez` | gdata | 3,687 | entrez-direct 16.2 + perl SSL modules | |
| `mash` | gdata | 674 | mash 2.3 | |
| `pandoc` | gdata | 8 | pandoc 3.11 | |
| `pymol` | scratch | 36,354 | pymol-open-source 3.1.0 | |
| `ccvenv2` | scratch | 28,108 | venv on `boltz2`'s python 3.11 with system site-packages; deepcoil 2.0.1, tensorflow-cpu 2.21.0 | Depends on `boltz2` (kept) |
| `dssp` | scratch | 9,860 | dssp 4.6.1 | |
| `ccvenv` | scratch | 8,161 | venv on `boltz2`'s python 3.11; deepcoil 2.0.1, biopython, numpy, pandas | |
| `dssp3` | scratch | 463 | dssp 3.1.4 | |

## Packages that will not reinstall from the lists alone

- **`signalp6==6.0+h`** is the DTU licensed release, installed from its tarball rather than from
  PyPI. The installed package, including the 1.6 GB `distilled_model_signalp6.pt` weights, was
  archived before deletion to
  `/g/data/ob80/re3494/db/signalp6/signalp6-6.0+h_site-packages.tar`. To rebuild, create the env
  from `signalp6.yml` without the `signalp6` line, then untar that archive into the env's
  `lib/python3.10/site-packages/`.
- **`torch==…+cu126` / `+cpu`** builds come from the PyTorch wheel index, so pip needs
  `--extra-index-url https://download.pytorch.org/whl/cu126` (or `/whl/cpu`). Remember that
  `gpuvolta` V100s need a CUDA build that still ships `sm_70`.
- **SingleM** itself is not in `singlem.yml`. Install it from bioconda or from source.

## Related preservation

phage_interactions read its TMbed and SignalP 6 results from `/scratch`. Before these environments
were removed, those results were copied to
`/g/data/ob80/re3494/Projects/phage_interactions/scratch_copies/tmbed_signalp_outputs_2026-10-19.tar`,
so they no longer depend on scratch surviving.
