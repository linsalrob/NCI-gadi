# Microbial genome assembly and annotation pipeline

No, its not a pipeline, its a bunch of PBS scripts for [NCI Gadi](https://nci.org.au/our-systems/hpc-systems), but I'm sure you can deal with that!

These were converted from the Slurm scripts written for Pawsey in `../microbial_genome_annotation_pawsey`.

Starting with Nanopore fastq files we:

1. Assemble using [autocycler](https://github.com/rrwick/Autocycler), or [plassembler](https://github.com/gbouras13/plassembler) if the sample is a plasmid prep rather than a whole isolate
2. Rearrange using [dnaapler](https://github.com/gbouras13/dnaapler)
3. Annotate using [bakta](https://github.com/oschwengers/bakta)
4. Improve using [baktfold](https://github.com/gbouras13/baktfold)
5. Optionally, find prophages using [PhiSpy](https://github.com/linsalrob/PhiSpy)
6. Optionally, find antiviral defence systems using [PADLOC](https://github.com/padlocbio/padloc) and [DefenseFinder](https://github.com/mdmparis/defense-finder)


Each of the four steps has two PBS scripts, an `STEP_install.pbs` which will install the software and download any required databases, and a `STEP_run.pbs` that will run the code.

The `_install.pbs` scripts generally require no options. They run on the `copyq` queue, because that is the only queue with internet access. Conda environments are installed into `/g/data/$PROJECT/$USER/conda` and databases into `/g/data/$PROJECT/$USER/databases`, and the `_run.pbs` scripts look for them there (override with `-v CONDA_ENVS=...`).

The `_run.pbs` scripts generally take two options, the name of the input file (fastq file, fasta file, json file, etc.) and the name of the output directory. PBS cannot pass arguments to a job script, so they are given as variables with `qsub -v`; the header of each script lists the names. Run `qsub` from the directory that holds your data, because relative paths are resolved from there.

The scripts do not set an output log name, so always give one with `-o` or PBS will write `<jobname>.o<jobid>` into the current directory. The examples below put them in a `logs/` directory:

```
mkdir -p logs
```

The scripts charge to project `ob80` (`#PBS -P ob80`). Use `qsub -P <project>` to charge somewhere else, and add that project to `-l storage=`.

## 1. Assemble using [autocycler](https://github.com/rrwick/Autocycler)

### 1a. Install

This creates the `microbial_annotations` environment from [autocycler.yaml](autocycler.yaml) (all the assemblers, including plassembler) and downloads the plassembler database into it:

```
qsub -o logs/autocycler_install.log ~/GitHubs/NCI-gadi/microbial_genome_annotation_nci/autocycler_install.pbs
```

### 1b. Run

Requires the input fastq file from nanopore reads, and an output directory name:

e.g.

```
qsub -o logs/AB5075_autocycler.log -v READS=bacteria_fastq/AB5075.fastq.gz,OUTDIR=AB5075 \
    ~/GitHubs/NCI-gadi/microbial_genome_annotation_nci/autocycler_run.pbs
```

Add `READ_TYPE=ont_r9` (or `pacbio_clr`, `pacbio_hifi`) to the `-v` list if the reads are not R10 nanopore reads.

The job uses a whole `normal` node (48 CPUs, 190 GB) and works in `$PBS_JOBFS`, copying the results to `OUTDIR` at the end. The consensus assembly is `OUTDIR/autocycler_out/consensus_assembly.fasta`.

The job checks that the assembly is fully resolved and is 0.75–1.25× the estimated genome size, and writes the result to `OUTDIR/autocycler_out/assembly_gate.tsv`. If that check fails, the job exits with status 3, so any job chained with `-W depend=afterok:` will not run on an incomplete assembly. That is not a crash: read the gate file. Change the limits with `-v MIN_RECOVERED_FRACTION=0.7,MAX_RECOVERED_FRACTION=1.3` if you need to.

### 1c. Optional. Rename the contigs.

We want to rename the contigs all at once, so we can do it for every file:

```
AC=(AB5075 AB5075_AdeB AB5075_AdeC102 AB5075_AdeC189 AB5075_AdeH124 AB5075_AdeH134 AB5075_AdeJ AB5075_AdeK164 AB5075_AdeK188 AB5075_AdeN AB5075_wzc)
for F in ${AC[@]}; do PREFIX=$F perl -pe 's/^>/>$ENV{PREFIX}_/' $F/autocycler_out/consensus_assembly.fasta > ${F}_consensus_assembly.fasta; done
```

_Note:_ Important: there is no `;` between `PREFIX=$F` and `perl -pe` otherwise `PREFIX` is undefined.
_Note2:_ Make sure you run `bakta` with the `--keep-contig-headers` option otherwise this work will be lost!

_Note3:_ This runs on the login node. To keep everything on the scheduler, give `dnaappler_run.pbs` `CONTIG_PREFIX=<sample>` instead, which does the same renaming (see [Running every step for many samples](#running-every-step-for-many-samples)).

### 1d. Optional. Plasmid preps: assemble with [plassembler](https://github.com/gbouras13/plassembler) instead.

Autocycler expects a whole bacterial isolate. If a sample is a plasmid prep, use
`plassembler_run.pbs` instead. It takes the reads, an output directory, and
optionally `CHROMOSOME`, the approximate lower-bound chromosome length. Pass
`none` when the reads contain no chromosome at all, which runs plassembler with
`--no_chromosome`:

```
qsub -o logs/barcode16_plassembler.log -v READS=barcode16.fastq.gz,OUTDIR=barcode16_plassembler,CHROMOSOME=none \
    ~/GitHubs/NCI-gadi/microbial_genome_annotation_nci/plassembler_run.pbs
```

For a normal isolate where you do expect a chromosome, give its approximate
lower-bound length instead (the plassembler default is 1000000). This is also a
useful second look at the small plasmids of an isolate assembled with autocycler:

```
qsub -o logs/AB5075_AdeB_plassembler.log -v READS=bacteria_fastq/AB5075_AdeB.fastq.gz,OUTDIR=AB5075_AdeB_plassembler,CHROMOSOME=2000000 \
    ~/GitHubs/NCI-gadi/microbial_genome_annotation_nci/plassembler_run.pbs
```

The assembled plasmids are written to `<OUTDIR>/plassembler_out/plassembler_plasmids.fasta`,
with a summary of the copy numbers and PLSDB hits in `plassembler_summary.tsv`.

_Note:_ plassembler is already in `autocycler.yaml`, so `autocycler_install.pbs`
installs it, and the PLSDB database, as part of the `microbial_annotations`
environment. `plassembler_install.pbs` only needs to be run if that environment
is missing, or to reinstall the PLSDB database.

## 5. Optional. Find prophages using [PhiSpy](https://github.com/linsalrob/PhiSpy)

### 5a. Install

This installs PhiSpy into its own environment, `phispy5`. It is not called `phispy`, because an older `phispy` environment already exists and the install script deletes its target before creating it:

```
qsub -o logs/phispy_install.log ~/GitHubs/NCI-gadi/microbial_genome_annotation_nci/phispy_install.pbs
```

### 5b. Run

PhiSpy needs gene calls, not just sequence, so run it on the GenBank file bakta
writes rather than on an assembly:

```
qsub -o logs/AB5075_phispy.log -v INPUT=AB5075_bakta/dnaapler_reoriented.gbff,OUTDIR=AB5075_phispy \
    ~/GitHubs/NCI-gadi/microbial_genome_annotation_nci/phispy_run.pbs
```

PhiSpy ships around 140 training sets and recommends the most closely related
one. List them with `PhiSpy.py --list short` and add one to the `-v` list as `TRAIN=`:

```
qsub -o logs/AB5075_phispy.log -v INPUT=AB5075_bakta/dnaapler_reoriented.gbff,OUTDIR=AB5075_phispy,TRAIN=data/trainSet_Saureus.txt \
    ~/GitHubs/NCI-gadi/microbial_genome_annotation_nci/phispy_run.pbs
```

There is no Acinetobacter training set in PhiSpy 5.0.10, so the AB5075 genomes use the default.

The default generic set is built from 48 genomes. It is the right choice when
nothing closely related is available, and also when counts need to be
comparable across genomes of different species -- an organism-specific set can
change the number of regions called, so it is worth running both and reporting
the difference rather than picking one silently.

_Note:_ prophage coordinates are relative to the sequence PhiSpy was given. If
that came through dnaapler, the origin has been rotated, so those coordinates
do not line up with the pre-dnaapler assembly. Map a feature across if you need
to compare.

## Running every step for many samples

Once everything is installed, you can submit the whole chain for each sample at once. Each job waits for the previous one with `-W depend=afterok`, so if a sample fails the assembly check (exit 3), its later jobs are cancelled instead of annotating an incomplete assembly. `CONTIG_PREFIX` makes `dnaappler_run.pbs` do the renaming from step 1c, so no step has to run on the login node:

```
R=~/GitHubs/NCI-gadi/microbial_genome_annotation_nci
for S in AB5075_AdeB AB5075_AdeC102; do
  T=${S#AB5075_}
  A=$(qsub -N ac_$T -o logs/${S}_autocycler.log -v READS=bacteria_fastq/$S.fastq.gz,OUTDIR=$S $R/autocycler_run.pbs)
  D=$(qsub -N dn_$T -W depend=afterok:$A -o logs/${S}_dnaappler.log -v INPUT=$S/autocycler_out/consensus_assembly.fasta,OUTDIR=${S}_dnaappler,CONTIG_PREFIX=$S $R/dnaappler_run.pbs)
  B=$(qsub -N bk_$T -W depend=afterok:$D -o logs/${S}_bakta.log -v INPUT=${S}_dnaappler/dnaapler_reoriented.fasta,OUTDIR=${S}_bakta $R/bakta_run.pbs)
  qsub -N bf_$T -W depend=afterok:$B -o logs/${S}_baktfold.log -v INPUT=${S}_bakta/dnaapler_reoriented.json,OUTDIR=${S}_baktfold $R/baktfold_run.pbs
  qsub -N ps_$T -W depend=afterok:$B -o logs/${S}_phispy.log -v INPUT=${S}_bakta/dnaapler_reoriented.gbff,OUTDIR=${S}_phispy $R/phispy_run.pbs
done
```

## 6. Optional. Find antiviral defence systems

Both tools take bakta's output and both are worth running: they use different
model sets and different naming, and they do not find the same things.

### [PADLOC](https://github.com/padlocbio/padloc)

Needs the proteins AND the feature coordinates, because defence systems are
called from gene content and synteny together:

```
qsub -o logs/padloc_install.log ~/GitHubs/NCI-gadi/microbial_genome_annotation_nci/padloc_install.pbs

qsub -o logs/AB5075_AdeB_padloc.log \
    -v FAA=AB5075_AdeB_bakta/dnaapler_reoriented.faa,GFF=AB5075_AdeB_bakta/dnaapler_reoriented.gff3,OUTDIR=AB5075_AdeB_padloc \
    ~/GitHubs/NCI-gadi/microbial_genome_annotation_nci/padloc_run.pbs
```

The .faa and .gff3 must come from the same bakta run or the coordinates will
not match the proteins. Passing a nucleotide FASTA instead (`FNA=` without `FAA`/`GFF`) makes PADLOC call
genes itself with prodigal, which throws away the bakta annotation.

_Note:_ the run script rewrites the GFF before handing it over, for two
reasons. bakta appends the genome sequence after a `##FASTA` line, which PADLOC
parses as tens of thousands of malformed feature rows. More importantly, PADLOC
replaces a CDS's `ID` with its `Name` whenever the CDS has a `pseudo`
attribute — correct for RefSeq and GenBank GFFs, where `Name` is an
identifier, but bakta puts the **product description** there. The substitution
turns a locus tag into something like `DNA 3'-5' helicase`, which then fails to
match the protein in the .faa and PADLOC aborts with
`N protein sequence IDs are missing from GFF file`. It only fires when a
pseudogene happens to hit a defence HMM, so across a set of genomes it looks
sporadic. The script strips the `pseudo` attribute so the locus tag survives.

This is [padlocbio/padloc#8](https://github.com/padlocbio/padloc/issues/8),
still open; upstream offers a patch that removes the substitution from
`padloc.R`. Stripping the attribute achieves the same thing without modifying
the installed tool, so the environment stays reproducible from the install
script alone.

### [DefenseFinder](https://github.com/mdmparis/defense-finder)

Takes the protein FASTA alone:

```
qsub -o logs/defensefinder_install.log ~/GitHubs/NCI-gadi/microbial_genome_annotation_nci/defensefinder_install.pbs

qsub -o logs/AB5075_AdeB_defensefinder.log \
    -v INPUT=AB5075_AdeB_bakta/dnaapler_reoriented.faa,OUTDIR=AB5075_AdeB_defensefinder \
    ~/GitHubs/NCI-gadi/microbial_genome_annotation_nci/defensefinder_run.pbs
```

DefenseFinder infers gene adjacency from the order of records in the FASTA, so
do not sort or shuffle the .faa — bakta writes it in coordinate order, which is
what is wanted.

### Comparing the two

They report different numbers and use different names for the same systems
(`RM_type_I` against `RM_Type_I`, `AbiO-Nhi_family` against `AbiO`,
`cas_type_III-A` against `Cas`). There is no shared controlled vocabulary, so
any cross-tool agreement count is approximate and should be described as such.

### Databases

`padloc_install.pbs` and `defensefinder_install.pbs` run on `copyq` and put
their databases in `/g/data/$PROJECT/$USER/databases/padloc` and
`/g/data/$PROJECT/$USER/databases/defensefinder`, outside the conda
environments, so rebuilding an environment does not mean re-downloading. PADLOC
parses its options one at a time and acts on the first it recognises, so
`--data` must be given **before** `--db-update` or it is silently ignored and
the database lands in the conda environment
([padlocbio/padloc#31](https://github.com/padlocbio/padloc/issues/31), closed
but still present in v2.0.0). The install script uses the correct order and
keeps a relocate-and-symlink guard in case that behaviour changes. The guard
tests for the compiled `hmm/padlocdb.hmm`, not for the `data` directory:
padloc creates `<env>/data` every time it runs, so a directory test always
fires and replaces a good database with an empty one.

## 2. Rearrange using [dnaapler](https://github.com/gbouras13/dnaapler)

### 2a. Install

This creates a separate `dnaapler` environment. (plassembler drags an old dnaapler, 0.8.1, into `microbial_annotations`, and the current release cannot be installed alongside everything else there.) It takes a few minutes and needs no database, so you can reorient your assemblies while the bakta database is still downloading:

```
qsub -o logs/dnaappler_install.log ~/GitHubs/NCI-gadi/microbial_genome_annotation_nci/dnaappler_install.pbs
```

### 2b. Run

```
qsub -o logs/AB5075_dnaappler.log -v INPUT=AB5075_consensus_assembly.fasta,OUTDIR=AB5075_dnaappler \
    ~/GitHubs/NCI-gadi/microbial_genome_annotation_nci/dnaappler_run.pbs
```

Add `PREFIX=<name>` to the `-v` list to change the output file prefix from `dnaapler`. The steps below assume the default.

## 3. Annotate using [bakta](https://github.com/oschwengers/bakta)

### 3a. Install

`bakta_install.pbs` adds bakta to the `microbial_annotations` environment and downloads the full database (v6.0) into `/g/data/$PROJECT/$USER/databases/bakta/db`. Run it after `autocycler_install.pbs` has finished:

```
qsub -o logs/bakta_install.log ~/GitHubs/NCI-gadi/microbial_genome_annotation_nci/bakta_install.pbs
```

The database is 32 GB and Zenodo sent it to Gadi at about 1.25 MB/s, so expect around 7 hours. The download is tens of GB and `copyq` jobs stop after 10 hours, so the download resumes: if the job runs out of time, submit it again. The download is checked against the md5 that bakta publishes before it is installed.

### 3b. Run

```
BAKTA=$(qsub -o logs/AB5075_bakta.log -v INPUT=AB5075_dnaappler/dnaapler_reoriented.fasta,OUTDIR=AB5075_bakta \
    ~/GitHubs/NCI-gadi/microbial_genome_annotation_nci/bakta_run.pbs)
```

`$BAKTA` holds the job id, so the next step can wait for it with `-W depend=afterok:$BAKTA`.


## 4. Improve using [baktfold](https://github.com/gbouras13/baktfold)

### 4a. Install

baktfold gets its own `baktfold` environment with a CUDA build of PyTorch, then a separate job downloads its databases and the ProstT5 model into `/g/data/$PROJECT/$USER/databases/baktfold_db`:

```
I=$(qsub -o logs/baktfold_install.log ~/GitHubs/NCI-gadi/microbial_genome_annotation_nci/baktfold_install.pbs)
qsub -W depend=afterok:$I -o logs/baktfold_download.log ~/GitHubs/NCI-gadi/microbial_genome_annotation_nci/baktfold_download.pbs
```

Gadi's `gpuvolta` GPUs are V100s, which CUDA 13 no longer supports, so the install pins CUDA 12.6. It fails if the PyTorch it gets was not built for the V100 (`sm_70`).

### 4b. Run

This runs on one V100 in the `gpuvolta` queue, which costs 36 SU an hour. It needs the bakta `.json` file:

```
qsub -W depend=afterok:$BAKTA -o logs/AB5075_baktfold.log -v INPUT=AB5075_bakta/dnaapler_reoriented.json,OUTDIR=AB5075_baktfold \
    ~/GitHubs/NCI-gadi/microbial_genome_annotation_nci/baktfold_run.pbs
```

GPU jobs have no internet access, so the model must already have been downloaded by `baktfold_download.pbs`.



