# AGENTS.md — microbial genome assembly and annotation

Operating notes for an agent running the scripts in this directory. They apply
to any long-read microbial assembly project, whatever the organism, sample
type, sequencing run or barcode layout. Nothing here assumes a particular
dataset.

The nearest repository or subdirectory `AGENTS.md` and any explicit user
instruction take precedence over this file.

## What this directory is

A set of PBS Pro job scripts for NCI Gadi, not a pipeline. They are converted
from the Slurm scripts in `../microbial_genome_annotation_pawsey`:

| stage | script | purpose |
| --- | --- | --- |
| assemble an isolate | `autocycler_run.pbs` | consensus of many assemblers |
| assemble a plasmid prep | `plassembler_run.pbs` | plasmids, `--no_chromosome` |
| reorient | `dnaappler_run.pbs` | put the origin at a sensible place |
| annotate | `bakta_run.pbs` | gene calling and functional annotation |
| improve | `baktfold_run.pbs` | structure-informed refinement, needs a GPU |
| install | `*_install.pbs` | environments and databases |

Each `_run.pbs` takes an input file and an output directory. PBS cannot pass
positional arguments to a job script, so they are given as variables with
`qsub -v` (e.g. `READS=...,OUTDIR=...`); the variable names are documented in
the header of each script. Read the script before running it; several take a
meaningful third argument.

## NCI Gadi specifics

These differ from the Pawsey originals and are easy to get wrong:

- **Conda.** Gadi has mamba 1.1.0, which has no `mamba shell hook`. Scripts use
  `eval "$(conda shell.bash hook)"` then `conda activate`. Environments live in
  `CONDA_ENVS=/g/data/$PROJECT/$USER/conda` (the `envs_dirs` in `~/.condarc`),
  not on `/scratch`, so they are not purged. Every script lets `CONDA_ENVS` be
  overridden with `qsub -v`.
- **Databases** live under `/g/data/$PROJECT/$USER/databases/<tool>` (replacing
  Pawsey's `~/Databases` and `/scratch/.../Databases`). `$HOME` on Gadi is only
  10 GB. The PLSDB database stays inside the env at
  `$CONDA_PREFIX/plassembler/`, as on Pawsey.
- **No internet on compute nodes.** Every `_install.pbs` runs on `copyq`
  (1 CPU, at most 10 h). Anything a `_run.pbs` would download must be staged by
  an install job first.
- **Temporary files go to `$PBS_JOBFS`**, with an explicit `-l jobfs=` request.
  The default jobfs is 100 MB. Inodes are the binding quota for project ob80
  (scratch was at 94% and gdata at 83% of their inode allocations on
  2026-10-06; check with `nci_account -P ob80`), and assemblers write many
  small files, so never put their working directories on `/scratch` or
  `/g/data`. Results are `rsync`ed out before the job ends.
- **`$PBS_JOBFS` is node-local and deleted when the job ends.** A job killed at
  walltime loses everything in it, so size the walltime generously.
- **Threads** come from `$PBS_NCPUS`.
- **Logs.** Scripts set `-j oe` but no `-o`, because one fixed `-o` path would
  collide between samples. Always give `-o <sample>_<step>.log` on the `qsub`
  command line, or PBS writes `<jobname>.o<jobid>` into the submission
  directory. The test project keeps them in `logs/`.
- **Relative paths** in `qsub -v` resolve against the directory `qsub` was run
  from (`-l wd`). `qsub -v` splits on commas, so paths must not contain commas.
- **Queues.** `normal` is 48 cores / 190 GB per node, charged at 2 SU per
  CPU-hour. Job scripts are copied at submission, so editing one does not
  change jobs already queued.
- **Job state after it finishes:** `qstat -xf <jobid>` gives `Exit_status`,
  `resources_used.mem` and `resources_used.walltime`.

## Conversion status

Update this table as each script is converted and tested. "Tested" means run on
Gadi to completion on the AB5075 test case (`bacteria_fastq/AB5075.fastq.gz`
in `/g/data/ob80/re3494/Projects/Acinetobacter`), with the job id.

| Pawsey script | NCI script | status |
| --- | --- | --- |
| `autocycler.yaml` | `autocycler.yaml` | copied unchanged |
| `autocycler_install.slurm` | `autocycler_install.pbs` | converted; creates `microbial_annotations` (Pawsey created `autocycler`, but every run script uses `microbial_annotations`) |
| `autocycler_run.slurm` | `autocycler_run.pbs` | converted; Pawsey version rejected the optional third argument (`$# != 2`), fixed via `READ_TYPE` |
| `dnaappler_install.slurm` | `dnaappler_install.pbs` | converted; creates a separate `dnaapler` env with dnaapler >=1.4. plassembler pulls dnaapler 0.8.1 into `microbial_annotations`, and a dry-run upgrade to >=1.4 there fails (pysam needs openssl >=3.5.6). Independent of `bakta_install.pbs`, so the two can run at once |
| `dnaappler_run.slurm` | `dnaappler_run.pbs` | converted; activates the `dnaapler` env (not `microbial_annotations`); variables `INPUT`, `OUTDIR`, `PREFIX` |
| `bakta_install.slurm` + `bakta_db_resume.slurm` | `bakta_install.pbs` | merged: installs bakta into `microbial_annotations`, resumable `wget --continue` of db v6.0 (Zenodo 14916843) with md5 check, then `bakta_db install` |
| `bakta_run.slurm` | `bakta_run.pbs` | converted; adds `--tmp-dir $PBS_JOBFS` |
| `baktfold_install.slurm` | `baktfold_install.pbs` | rewritten. Pawsey built a pip venv against ROCm (AMD). Gadi is NVIDIA, so: bioconda `baktfold` + `pytorch=*=cuda*` + `cuda-version=12.6` in a `baktfold` env, with `CONDA_OVERRIDE_CUDA` because copyq has no GPU. V100 is sm_70 and CUDA 13 dropped Volta; the job fails unless `torch._C._cuda_getArchFlags()` contains sm_70 (`get_arch_list()` is empty without a GPU). Foldseek comes from conda, no aria2c build |
| `baktfold_download.slurm` | `baktfold_download.pbs` | `baktfold install -d /g/data/$PROJECT/$USER/databases/baktfold_db`. The `--foldseek-gpu` padding is **not** done: UNCONFIRMED whether Foldseek-GPU supports the V100 |
| `baktfold_run.slurm` | `baktfold_run.pbs` | gpuvolta, 1 GPU / 12 CPUs / 90 GB (Pawsey used 8 GPUs exclusive; baktfold uses one). Sets `HF_HUB_OFFLINE=1`, logs `nvidia-smi` and the torch arch list. No `--foldseek-gpu` |
| `phispy_install.slurm` | `phispy_install.pbs` | copyq; env named **`phispy5`** (PhiSpy >=5; 5.0.10 installed). An older, separately managed `phispy` env (PhiSpy 4.2.21) exists in `/g/data/ob80/re3494/conda`; the script removes and recreates its target, so it must not point at that one |
| `phispy_run.slurm` | `phispy_run.pbs` | variables `INPUT` (bakta .gbff), `OUTDIR`, `TRAIN`; activates `phispy5`. There is no Acinetobacter training set, so the default generic set is used |
| (README 1c) | `dnaappler_run.pbs` `CONTIG_PREFIX=` | renaming folded into dnaapler so the whole chain can run under `-W depend=afterok`; the renamed copy is made on jobfs (dnaapler creates OUTDIR itself) and copied into OUTDIR |
| `plassembler_install.slurm` | `plassembler_install.pbs` | copyq; installs into `microbial_annotations` only if missing, then (re)downloads PLSDB into `$CONDA_PREFIX/plassembler/`. Not needed when `autocycler_install.pbs` has run |
| `plassembler_run.slurm` | `plassembler_run.pbs` | variables `READS`, `OUTDIR`, `CHROMOSOME` (bp lower bound, or `none` for `--no_chromosome`); works on jobfs |
| `padloc_install.slurm` | `padloc_install.pbs` | copyq; `padloc` env, database in `/g/data/$PROJECT/$USER/databases/padloc` (`--data` before `--db-update`, padloc#31) |
| `padloc_run.slurm` | `padloc_run.pbs` | variables `FAA` + `GFF` (bakta pair), or `FNA` (prodigal fallback), and `OUTDIR`. Keeps the GFF clean-up (strip `##FASTA`, drop `pseudo=`; padloc#8); works on jobfs |
| `defensefinder_install.slurm` | `defensefinder_install.pbs` | copyq; `defensefinder` env (python 3.11 + hmmer from conda, `mdmparis-defense-finder` from pip, which pins its own macsyfinder, so no conda macsyfinder); models in `/g/data/$PROJECT/$USER/databases/defensefinder` |
| `defensefinder_run.slurm` | `defensefinder_run.pbs` | variables `INPUT` (bakta .faa), `OUTDIR`; copies the .faa to jobfs, because DefenseFinder writes an index beside its input |
| `install_all.slurm` | — | not converted; superseded by the per-step install scripts |
| everything else | — | not yet converted |

### AB5075 test run

Working directory `/g/data/ob80/re3494/Projects/Acinetobacter`, logs in
`logs/`. Input `bacteria_fastq/AB5075.fastq.gz`: gzip-valid, 60,964 reads,
266.6 Mbp, mean read length 4,372 (about 65x of a ~4 Mb genome). Other files
in `bacteria_fastq/` were still being copied in on 2026-10-06; check them with
`gzip -t` before use.

| date | job id | script | outcome |
| --- | --- | --- | --- |
| 2026-10-06 | 180571716 | `autocycler_install.pbs` | exit 0, 10 min, 8.6 GB, 2.8 SU. autocycler 0.8.0, canu 2.3, flye 2.9.6, metamdbg 1.4, miniasm 0.3, minimap2 2.31, minipolish 0.2.1, myloasm 0.7.0, necat 0.0.1_update20200803, nextdenovo 2.5.2, plassembler 1.8.5, racon 1.5.0, raven 1.8.3, wtdbg 2.5; PLSDB `plsdb_2023_11_03_v2` (414 MB .msh). NECAT's binary is `necat`, not `necat.pl`. libmamba "invalid repodata_record.json" warnings about the shared package cache are harmless |
| 2026-10-06 | 180572347 | `bakta_install.pbs` | submitted, `afterok:180571716` |
| 2026-10-06 | 180572348 | `dnaappler_install.pbs` (old version, into `microbial_annotations`) | deleted while held, superseded by 180590059 |
| 2026-10-06 | 180573528 | `autocycler_run.pbs` `READS=bacteria_fastq/AB5075.fastq.gz,OUTDIR=AB5075` | exit 0, gate PASS. 36 min, 38.8 GB of 190 GB, 2.5 GB jobfs, 57 SU. Estimated genome 4,072,471; consensus 4,074,487 bp (fraction 1.0005), fully resolved, 4 circular contigs: 3,980,185 / 83,604 / 8,731 / 1,967. All 36 input jobs exit 0, but `necat_04` wrote no FASTA (35 inputs). Non-plassembler inputs all 3.96–4.08 Mb. Provenance: **automated consensus**. Memory and jobfs requests can be reduced for genomes of this size |
| 2026-10-06 | — | README 1c rename, login node | `AB5075_consensus_assembly.fasta`, headers `AB5075_1`..`AB5075_4` |
| 2026-10-06 | 180577481, 180577482 | dnaapler and bakta runs | deleted while held (they held old script copies), resubmitted below |
| 2026-10-06 | 180572347 | `bakta_install.pbs` progress | at 2.5 h: 13.8 of 31.9 GB downloaded, ~1.25 MB/s from Zenodo; expected to finish within the 10 h limit. If it times out, resubmit it (resumes) and resubmit 180590062 with the new id |
| 2026-10-06 | 180590059 | `dnaappler_install.pbs` (separate `dnaapler` env) | exit 0, 4 min, 0.5 SU. dnaapler 1.4.0 (python 3.13, MMseqs2 18.8cc5c, pyrodigal 3.7.1) |
| 2026-10-06 | 180590061 | `dnaappler_run.pbs` `INPUT=AB5075_consensus_assembly.fasta,OUTDIR=AB5075_dnaappler` | exit 0, 33 s, 1.3 GB. Total length unchanged (4,074,487). AB5075_1 on dnaA (100% id, 100% cov), AB5075_2 and AB5075_3 on repA (100%/100%). **AB5075_4 (1,967 bp) on a weak repA hit: 39% identity, 83% coverage, hit overlaps the contig end, no valid start codon so pyrodigal picked the CDS** — treat its start position as arbitrary |
| 2026-10-06 | 180590062 | `bakta_run.pbs` `INPUT=AB5075_dnaappler/dnaapler_reoriented.fasta,OUTDIR=AB5075_bakta` | submitted, `afterok:180590061:180572347` |
| 2026-10-06 | 180606035 | `baktfold_install.pbs` | exit 0, 17 min, 17.6 GB RAM, 13.3 GB jobfs, 4.5 SU. baktfold 0.3.0, pytorch 2.7.1 cuda126 (conda-forge), python 3.13.15, foldseek 10.941cd33, transformers 5.18.0. Compiled archs include sm_70. transformers 5.x is a major version above baktfold's `>=4.34` floor; if ProstT5 loading fails in the run, pin `transformers<5` |
| 2026-10-06 | 180606036 | `baktfold_download.pbs` | exit 0, 10 min, 1.3 SU, but **14.5 GB of 16 GB RAM** (request raised to 32 GB). 22 GB in `/g/data/ob80/re3494/databases/baktfold_db`: swissprot, pdb, cath, AFDBClusters (Zenodo 17347516, md5 OK per baktfold) and ProstT5_fp16 (5.6 GB weights) in the HF cache layout |
| 2026-10-06 | 180572347 | `bakta_install.pbs` outcome | **exit 8** after 5 h 47 min, 46 SU. Zenodo closed the connection at 30,172,994,400 of 31,921,769,288 bytes (94.5%); wget's immediate retry got HTTP 503 and wget gave up. Dependents 180590062 and 180606044 were deleted by PBS. Partial tarball kept; wget now retries 429/5xx with backoff (`--tries=50 --waitretry=300 --retry-on-http-error=...`). Old log kept as `logs/bakta_install.180572347.log` |
| 2026-10-06 | 180613053 | `bakta_install.pbs` (resume) | exit 0, 58 min, 7.8 SU. Resumed from byte 30,172,994,400, md5 matched, `bakta_db install` OK. db v6.0 full, 84 GB at `/g/data/ob80/re3494/databases/bakta/db` (tarball deleted). Used the full 16 GB (page cache from md5/xz), so the request was raised to 32 GB |
| 2026-10-06 | 180613054 | `bakta_run.pbs` AB5075 | exit 0, 8 min 47 s, 54.8 of 64 GB, 4.7 SU. bakta 1.12.1, db v6.0 full. 4 contigs, 4,074,487 bp, GC 39.0%, coding density 88.5%. 3,882 CDS (953 per Mb), 6 pseudogenes, 255 hypotheticals (6.6%), 2 sORFs, 74 tRNA + 1 tmRNA, 18 rRNA, 32 ncRNA, 1 CRISPR array. Checks: rRNA balanced at 6x 16S / 6x 23S / 6x 5S, all on the chromosome; tRNAs cover all 20 amino acids plus initiator fMet. Memory is 85% of the request; raise it if a larger genome fails |
| 2026-10-06 | 180613055 | `baktfold_run.pbs` AB5075 | exit 0, 5 min, 17.4 GB, 3.0 SU. Tesla V100-SXM2-32GB, driver 580.178.04, capability 7.0; ProstT5 ran on `cuda:0`. PBS reported "GPU Utilisation 0%" with 6.76 GB GPU memory used: its sampling misses a ~2 min job, not a sign of CPU fallback. baktfold 0.3.0, db v0.1.0. Of 255 hypotheticals, 71 got a database hit and 12 a function; 243 remain hypothetical. transformers 5.18 worked, so no pin is needed |

| 2026-10-07 | 180670058 | `phispy_install.pbs` | exit 0, 2.6 min. PhiSpy 5.0.10 (python 3.13) in `phispy5` |
| 2026-10-07 | 180670059 | `phispy_run.pbs` AB5075 | exit 0, 34 s. 6 prophages, all on AB5075_1: 557,049-580,123; 739,593-792,121; 1,290,337-1,338,107; 1,395,372-1,432,352; 2,555,744-2,578,762; 2,657,658-2,688,477 (23-53 kb). The filamentous phage arrays at 1.989-2.026 Mb are **not** called: PhiSpy targets tailed prophages |

AB5075 has been through steps 1–5 of the README.

### Batch of 10 mutants (2026-10-07)

`bacteria_fastq/AB5075_{AdeB,AdeC102,AdeC189,AdeH124,AdeH134,AdeJ,AdeK164,AdeK188,AdeN,wzc}`,
all gzip-valid. Per the `agent-handoffs` Acinetobacter project these are T26
transposon insertion mutants of AB5075 (e.g. `wzc::T26`); the numbers
distinguish different insertion alleles in the same gene. Expected targets in
the AB5075 annotation: adeB JGHGPE_01955 (1,976,840-1,979,950), adeC
JGHGPE_01956 (1,980,027-1,981,424), adeH JGHGPE_01323, adeJ JGHGPE_00839,
adeK JGHGPE_00838, adeN JGHGPE_01712, wzc JGHGPE_03810 ("polysaccharide
biosynthesis tyrosine autokinase", 3,907,363-3,909,549). adeB/adeC are ~8 kb
from phage array A.

Low depth: wzc 33.4 Mbp (~8x, below autocycler's `MINREADDEPTH=10`);
AdeK188 91.3 Mbp (~22x) but mean read length 567 bp. Expect these two to
fail or fragment.

Each sample was submitted as autocycler -> dnaapler (`CONTIG_PREFIX=<sample>`)
-> bakta -> {baktfold, phispy}. Job ids are in
`logs/batch_jobs.tsv` (sample, autocycler, dnaapler, bakta, baktfold, phispy).

The comparison with the parent is done by
`genome_comparison/compare_to_parent.py`, run per sample by
`genome_comparison/compare_sample.pbs` (both in the project directory, not this
repo). It compares assembly to assembly (minimap2 asm5, SNPs/indels/structural
differences annotated with parent genes and the genes inside any insertion)
and reads to parent (high-frequency SNPs/indels and soft-clip clusters). Each
difference is checked against the sample's reads and against the parent's
own reads (`genome_comparison/AB5075/reads_vs_parent.bam`, the within-run
control).

2026-10-07: plassembler (1d), PADLOC and DefenseFinder (6) converted. Installs
180696909 (padloc) and 180696910 (defensefinder); PADLOC and DefenseFinder on
the 10 bakta genomes (all but wzc) and plassembler (`CHROMOSOME=2000000`) on all
11 read sets. Job ids in `logs/defence_plassembler_jobs.tsv`. Outcomes:

- `defensefinder_install.pbs` 180696910: exit 0, 5 min. DefenseFinder 3.0.0,
  MacSyFinder 2.1.4, python 3.11. Runs ~45 s each, all exit 0.
- `padloc_install.pbs` 180696909: exit 0 but **left an empty database**. padloc
  runs `mkdir -p <env>/data` on every invocation, so the Pawsey
  relocate-and-symlink guard (`[[ -d $ENV/data && ! -L ... ]]`) always fired:
  it deleted the correctly placed database and moved the empty directory into
  its place. All 10 runs then failed with `HMM file ... padlocdb.hmm not found`
  (logs kept as `logs/*_padloc.dbmissing.log`). The guard now tests for
  `hmm/padlocdb.hmm`, and both scripts check that file. The Pawsey script has
  the same bug. Rerun: 180700913 exit 0 (PADLOC 2.0.0, padloc-db 2.0.0, no
  relocation), runs 180700914-25 all exit 0, ~3.7 min each.
- `plassembler_run.pbs` (plassembler 1.8.5, PLSDB 2023_11_03_v2,
  `CHROMOSOME=2000000`): 10 of 11 exit 0 in 5-42 min; wzc exits 1, "No
  chromosome was identified" (8x of ~105 bp reads), as expected.
- Results are summarised in `genome_comparison/extras/` in the project
  directory. Defence systems are identical in all 10 genomes (DefenseFinder 8,
  PADLOC 7, 9 distinct; PADLOC's PDC-S33 is DefenseFinder's CapRel); the
  single-assembler drafts AdeH124/AdeK188 gain one extra gene in RosmerTA or RM
  type III, consistent with draft indels splitting a gene. plassembler found an
  89 kb amplification in AdeC102 (as a 91,222 bp circle; read-validated, but
  tandem vs free circle is unresolved) and an 80 kb phage in AdeK188 (the
  assay phage bb02), both missed by the consensus assemblies.

Comparison completed 2026-10-08: AdeC189 180689771 exit 0 (4 h 17 min).
AdeK164 at 460x did not finish its pure-Python read pass inside 12 h
(180689767); it was compared on a 35% read subsample instead
(`genome_comparison/compare_subsampled.pbs`, seed 42, 180745574, 1 h 21 min),
which `make_table.py` reads via `COMPARISON_DIR`. For very deep samples,
subsample to ~150x up front. The table was posted to agent-handoffs
`projects/Acinetobacter/shared/genomes/` (commits 398ba75, 6ae8b05).
| 2026-10-06 | 180606044 | `baktfold_run.pbs` `INPUT=AB5075_bakta/dnaapler_reoriented.json,OUTDIR=AB5075_baktfold` | submitted, `afterok:180590062:180606036`. Dependency recorded, but it showed `Q`/`Hold_Types = n` while still in the `gpuvolta` routing queue; confirmed held (`H`, `Hold_Types = s`) after routing to `gpuvolta-exec` |

Comparison with the published AB5075-UW genome (NCBI CP008706.1 chromosome,
CP008707-9.1 plasmids, fetched 2026-10-06 to `reference/AB5075-UW_NCBI.fasta`;
minimap2 `-x asm5`, PAF in `reference/AB5075_vs_ref.paf`):

- p2AB5075 (8,731) and p3AB5075 (1,967): identical, 100% identity.
- p1AB5075: 83,604 vs 83,610, 1 SNP and 6 bp of small deletions.
- Chromosome: 3,980,185 vs 3,972,672. It is colinear end to end, with 0 SNPs
  and 9 bp / 6 bp of small indels, plus **one 7,510 bp insertion** at
  1,989,018-1,996,527 in the dnaapler/bakta coordinates (reference
  CP008706.1:1,989,106). It is a **filamentous prophage** (Rep, HTH cro/C1
  repressor, Zonular occludens toxin), and the flanking gene runs
  JGHGPE_01963-01968 and 01977-01982 repeat. So the assembly has **two tandem
  copies where the reference has one**.
- Self-alignment shows this is tandem array **A** (copy 1 at 0-based
  1,989,017, unit 7,510 bp, 12 bp shared at the boundary, array ends at
  2,004,049). It sits directly beside a second tandem array **B** at
  2,004,043-2,025,714 (unit 6,477 bp, ~3.35 copies), which matches the
  reference, plus a 96%-similar 1.7 kb element at 2,027,842. Array B's copy
  number has not been tested by reads.
- **Confirmed real, 2026-10-07, job 180669858** (`phage_copy_check/`, 0.2 SU).
  Reads: N50 11.4 kb, 3,389 of 17 kb or more. Candidate sequences with
  identical 25 kb flanks and 1, 2 or 3 copies of A; minimap2 map-ont; a read
  counts only if it aligns through the window at >=85% identity with no
  indel >=500 bp:
  - 0 reads support 1 copy (flank -> copy -> B);
  - 19 reads go from unique sequence through a full copy into a second copy;
  - 5 reads span the whole 2-copy array end to end; 0 span a 3-copy array.
  Depth (MAPQ 0 kept): left unique flank 44.6, copy 1 48.2, copy 2 45.1 (an
  artefact would give about 22 per copy). The whole region is ~0.7x the
  genome median of 64, including its unique flank. That is consistent with
  the region being near the replication terminus, not with copy number. No
  depth excess, so no evidence of a large free (episomal) phage population.
- Conclusion: this culture carries **two tandem copies**; the published
  AB5075-UW sequence carries one. Whether that is a difference between
  stocks or a collapsed repeat in the 2014 reference cannot be decided from
  these data. Provenance of the AB5075 assembly remains **automated
  consensus**, now read-validated at this locus.

## Before you run anything

**Verify the environment and databases actually exist.** Do not trust that a
previous install succeeded. On a purged filesystem an environment can lose
most of its files while still looking installed, and a `conda-meta` record is
not evidence that the binaries are present. Check the specific executables and
database files you are about to use:

```bash
for x in autocycler flye canu raven myloasm plassembler dnaapler bakta; do
    printf '%-12s ' "$x"; command -v "$x" >/dev/null && echo OK || echo MISSING
done
```

Databases are equally fragile. Confirm the expected files and sizes, not just
that the directory exists. A reference database that has been reduced to a
fraction of its size will fail deep inside a run, after hours of compute.

**Check tool/database version compatibility.** A bundled database can be older
than the binary that reads it will accept. Where a tool wraps another tool and
passes it a database path, that inner pair can be mismatched even when the
outer tool is fine. Resolve it before submitting a fleet of jobs, not after
they all fail identically.

**Record versions and database releases** for anything that reaches a result.
On a purged filesystem the environment is not reproducible from the filesystem
alone, so provenance has to be written down.

## Read handling

**Establish what the reads are before merging anything.** When additional
sequencing arrives, do not assume it is a separate batch. Compare file names,
sizes and checksums against what you already have. A "new" directory is
frequently a re-export that *contains* the old data, and concatenating the two
then duplicates every original read.

Duplicated reads are not a harmless inflation. They corrupt k-mer genome-size
estimation, break read subsampling, roughly double apparent depth and give
every duplicated position false support. The resulting assembly can look
better while being worse.

Verify containment programmatically and make the merge refuse to proceed if the
relationship does not hold, so the check cannot rot:

```bash
for f in "$OLD"/*.fastq.gz; do
    n="$NEW/$(basename "$f")"
    [[ -f "$n" && "$(stat -c %s "$f")" == "$(stat -c %s "$n")" ]] || echo "NOT CONTAINED: $f"
done
```

**Snapshot the read inventory before and after new data arrives** — per unit
file count, bytes, reads, bases, read-length distribution and quality — plus a
file-level manifest so an added chunk is identifiable by name rather than only
as a larger total.

**Subsample plasmid preparations.** Plasmid assembly of a small molecule needs
a tiny fraction of a modern library. Feeding the whole thing in can take orders
of magnitude longer *and produce a worse result*, because read-correction steps
degrade or fail outright at extreme depth and the assembler then proceeds with
uncorrected reads. A few hundred Mbp is already tens of thousands of fold
coverage for a few-kb plasmid. Record the sampling fraction and seed.

## Judging an assembly

**Never use contig or cluster count as the quality criterion.** A consensus
assembler emits whatever passed its internal QC. If the chromosome fails QC and
only a small plasmid survives, the output is a tidy, fully-resolved, one-contig
assembly containing a fraction of a percent of the genome. Any rule of the form
"fewer than N contigs, therefore annotate" will pass exactly that case and
reject genuinely closed genomes whose extra replicons push them over N.

Use the size-completeness gate built into `autocycler_run.pbs`:

```text
recovered_fraction = consensus_assembly_bases / estimated_genome_size
```

and require **both** that the assembly is fully resolved **and** that the
fraction lies inside an explicit interval (default 0.75–1.25, overridable via
`MIN_RECOVERED_FRACTION` / `MAX_RECOVERED_FRACTION`). The gate writes
`autocycler_out/assembly_gate.tsv` and **exits 3** on failure so that a
downstream job chained with `qsub -W depend=afterok:<jobid>` will not annotate an
incomplete assembly.

A closed genome should ordinarily be far closer to the estimate than the gate
demands. The interval exists to stop catastrophic output being accepted
automatically, not to define acceptable quality.

Report clusters and unitigs separately. One unresolved cluster can contribute
thousands of unitigs, so a raw sequence count conflates a closed replicon with
a fragmented one.

## When a consensus assembly fails

Consensus-of-assemblers methods are conservative by construction: material the
input assemblies do not agree on is discarded rather than reported. So assembly
failure usually means "not agreed", not "not present". Establish which before
concluding anything.

1. **Ask whether the data are there.** Tabulate contig count and total length
   for every input assembly. If they independently recover a consistent total
   close to the genome-size estimate, the genome exists and the consensus step
   discarded it. Compare against the assemblies that *succeeded* in the same
   run — that is the only calibration available.
2. **Inventory what was rejected.** Report the largest rejected cluster, how
   many assemblies contributed, and their contig lengths. Several assemblers
   agreeing closely on a near-complete chromosome is strong evidence.
3. **Check structural concordance, not just length.** Agreement in length says
   little. Align the candidates pairwise and require high identity, near-total
   mutual coverage and no translocations. Note that comparing circular contigs
   with different start points reports one relocation as an artefact; that is
   not a rearrangement.
4. **Beware the longest contig.** The longest candidate is not automatically
   the most complete — it may be a chimera that has concatenated a second
   replicon onto the chromosome. Always check whether a smaller replicon maps
   inside it at high identity. Curating around an unchecked chimera bakes a
   misassembly into the final result.
5. **Rule out a mixed or non-clonal sample** before promoting anything: mapped
   coverage uniformity, variant density, and taxonomic composition of the
   reads.
6. **Curate the input set, do not lower the support threshold globally.**
   Retain the assemblies carrying a concordant chromosome, drop the fragmented
   contributions, preserve independently validated smaller replicons, and rerun
   `compress → cluster → trim → resolve → combine`. Restricting the input set
   is not the same as relaxing `--min_assemblies`, which also admits fragmented
   and contaminant clusters.

## Distinguishing real variation from sequencing error

Long-read basecalling error is not random, so a frequency cutoff alone will not
separate signal from noise.

**Use a within-run control.** Take a sample that assembled cleanly through the
normal path, run the identical analysis on it, and treat its variant density as
the error floor for that run. Absolute counts are uninterpretable without it —
a number that looks alarming may be below what a genome you fully trust
produces.

**Look at the spatial distribution, not just the count.** Compute an index of
dispersion in fixed windows. Variants scattered genome-wide look like a mixed
sample; variants concentrated in a small number of loci look like collapsed
repeats. These have completely different consequences, and the raw density does
not distinguish them. Report density inside and outside hotspot windows
separately.

**Take strand bias from the observation that drives the call** — the sample
with the strongest signal. Taking a maximum across samples lets one with a
couple of stray reads, where strand balance is extreme by chance, veto a site
that is cleanly supported elsewhere.

**Separate "detectable" from "carrying".** A sample sitting near the error
floor is background, not a carrier. Using one threshold for both makes a real
difference between samples look like an error shared by all of them.

**Exploit recurrence across samples.** Where the same molecule appears in
several samples, a systematic basecalling error should appear at the same
position in all of them, while genuine variation is restricted to a subset.
Map every sample to one common reference *including the sample the reference
came from*: that self-mapping is the control, since at a truly variable site
the reference sample's own reads agree with its own assembly.

## Testing whether two contigs are one molecule

Test the junctions **where the sequences actually meet**, not merely the ends
of the contigs as assembled. An element integrated internally has its real
junctions in the middle of a contig, and a test built from contig ends will
find no support for joins that genuinely do not exist while saying nothing
about the joins that do.

Build candidate constructs that share identical flanks and differ only in the
sequence between them, map all reads, and count only reads anchored well on
both sides. Then compare support across the alternatives.

Expect the answer to be "both". A mobile element can be integrated in most
molecules and excised and circularised in a minority, and both states will show
read support. That is a biological result, not an assembly error, and it should
be reported as such rather than forced into one representation.

## Manual graph correction

Only correct an assembly graph when the read evidence clearly supports one
path. Enumerate the alternatives from the graph topology first: dead-end tips
cannot lie on a circular path regardless of how much read support they attract,
and that is a topological fact worth establishing before measuring anything.

Get the GFA link convention right. `L a oa b ob` joins the **end** of `a` in
orientation `oa` to the **beginning** of `b` in orientation `ob`. For the
from-segment `+` means its right end; for the to-segment `+` means its **left**
end. Reading the to-segment backwards turns dead-end tips into bridges and
invents circular paths that do not exist. Verify any hand-derived topology with
a script.

Where a correction is applied, use the tool's supported mechanism, record
exactly which sequences were removed and why, and classify the result as
manually curated rather than automated.

## Provenance classification

Every assembly that reaches a result needs a stated classification, because
these are not equivalent and must not be reported as though they were:

- **automated consensus** — produced by the normal pipeline, gate passed;
- **curated consensus** — input set restricted by hand, with the evidence
  recorded;
- **read-validated single-assembler assembly** — only one assembler, or several
  subsamples of one assembler, supported the structure. This *looks* like a
  consensus once it has been through the consensus tool but has no independent
  corroboration, and must be reported as single-assembler;
- **validated draft** — genuinely this organism and well supported, but not
  closed. Usable for gene-level work with caveats, not a genome to close;
- **unresolved / draft only** — recovered but not resolvable on current
  evidence. Do not annotate as a closed genome.

Distinguish "several assemblies" from "several assemblers". Multiple subsamples
of one assembler are one algorithm, and that limits what the agreement is worth.

## Annotation checks

Annotation will run happily on a fragmentary or chimeric assembly and produce
confident, wrong gene calls. Gate on assembly quality first, then sanity-check
the output before drawing conclusions:

- **rRNA operon balance.** rRNA genes occur in operons, so 16S, 23S and 5S
  counts should match. An imbalance indicates a collapsed repeat or a genuine
  orphan gene; either way it needs explaining. A high operon count also
  explains, independently, why a genome was hard to assemble — rRNA operons are
  the classic long-read breakpoint.
- **Coding density and genes per Mb** against normal ranges for the organism
  group.
- **tRNA count**, which should cover the amino acids.
- **Hypothetical protein fraction**, as an outlier signal rather than a
  threshold.

Prefix contig headers with the sample identifier before annotating and use
`--keep-contig-headers`, or provenance is lost in the output.

## Failure modes that look like results

- **A gate failure is not a crash.** `autocycler_run.pbs` exits 3 when the
  completeness gate fails, so `qstat -xf` reports `Exit_status = 3`. Check the exit code and
  the gate file before diagnosing a fault.
- **An out-of-memory kill can be reported as a biological finding.** When an
  inner assembler is killed, the wrapper may observe "assembled 0 contigs" and
  conclude the sample has none. Check `resources_used.mem` (`qstat -xf <jobid>`) against the request before
  believing a negative result.
- **A read-correction step can fail and be continued past.** Warnings about
  failing to correct reads mean the assembler proceeded with uncorrected input.
  That is a quality problem, not just a warning.
- **`SIGPIPE` under `pipefail`.** Piping a long-running producer into `head`
  fails the whole pipeline. Write to a file, then take the head.
- **Interactive aliases.** `cp` and `rm` may be aliased to prompt, which in a
  non-interactive context hangs or silently skips. Use `/bin/cp`, `/bin/rm` or
  explicit flags in scripts.
- **A read that spans an insertion shows it as `I`, not as a soft clip.**
  Counting "reads across the site without a long clip" as wild type counts the
  insertion carriers too: this made a clean T26 insertion (396 of 398 reads)
  look like a 27% subpopulation. Count reads with a large `I`/`D` at the site
  separately, or test competing constructs with identical flanks.
- **A consensus assembly can collapse an amplification to one copy.** A
  sample whose assembly lacks a known insertion, or shows "mixed" junction
  support, may carry a tandem array or circle. Check read depth along the
  region against its flanks and where the clipped reads' supplementary
  alignments land before calling it a mixed culture.

## Compute

Run everything substantial through the scheduler; never assemble or annotate on
a login node. Derive thread counts from the allocation (`PBS_NCPUS`) rather
than hardcoding them — a tool defaulting to one thread will run for hours
inside a large allocation doing nothing with it.

Use `qsub -W block=true` when the next decision depends on inspecting the
result, and `qsub -W depend=afterok:<jobid>` when the next step is already
known (`qsub` prints the job id on stdout, so `JOB=$(qsub ...)` captures it).
On Gadi an array job is limited to 10 subjobs and must be submitted with
`#PBS -r y`; query arrays with `qstat -t '<jobid>[]'`, because a bare
`qstat <jobid>` on an array reports `Unknown Job Id`.

Diagnose before escalating resources. Increase memory in response to an
observed `resources_used.mem`, not as a guess, and consider whether less input
would be better than more memory. Check the SU balance and the days left in the
quarter with `nci_account -P <project>` before planning many jobs.

## Definition of done

- Every sample has a stated outcome, backed by evidence, including the ones
  that failed.
- Assembly quality is judged on recovered fraction and resolution, never on
  sequence count.
- Every assembly carries a provenance classification.
- Consequential decisions and their evidence are recorded, including decisions
  not to promote something.
- Negative and inconclusive results are reported rather than omitted.
- Tool and database versions behind any result are written down.

Working code and completed jobs are not completion.
