# Stochastic Two-Level DDM Solver

High Performance Uncertainty Quantification (HPUQ) – StDDM provides deterministic and stochastic finite-element solvers for elliptic PDEs using two-level preconditioned conjugate gradient methods (PCGM) embedded inside a domain-decomposition (DDM) framework. The code couples hand-written FEM assembly routines with PETSc-based sparse blocks, supports both deterministic and stochastic (KLE/PCE) representations of coefficients, and scales to large MPI runs on Compute Canada clusters.

## Highlights
- Hybrid FEM/PETSc workflow: local dense assembly (`assembly.F90`, `variationalform.F90`) feeding sparse PETSc objects built in `PETScAssembly.F90`.
- Multiple DDM solvers: classic implementations in `solvers.F90` plus the PETSc-based two-level NNC PCGM (`PETScSolvers.F90` + `PETScommon.F90`).
- Automated mesh preprocessing (`preprocmesh*.F90`) for global and per-subdomain partitions exported by Gmsh.
- Turnkey scripts under `scripts/` to generate meshes/KLE data (see `data/kle_pce/`), run on desktops (`scripts/run_ddm.sh`) or submit SLURM jobs on Cedar, Graham, or Niagara with matching makefiles.
- Reproducible stochastic data inputs (defaults in `data/stochastic/` plus many higher-order datasets stored under `data/kle_pce/`).

## Repository layout
- `src/`: all Fortran sources. `main.F90` orchestrates MPI, data ingestion, PETSc solver selection, and IO; `common.F90`/`myCommon.F90` expose shared utilities; `variationalform.F90`, `assembly.F90`, `PETScAssembly.F90`, `PETScommon.F90`, and `PETScSolvers.F90` implement the FEM/PETSc solver stack; `solvers.F90` provides legacy DDM solvers; `preprocmesh*_*.F90` extract global/local mesh metadata.
- `data/geometry/square.geo`: sample geometry for partitioning; adjust `lc` for refinement.
- `data/stochastic/{cijk,multipliers,omegas}`: default stochastic data consumed by `main.F90`.
- `data/kle_pce/`: KLE/PCE generators (`KLE_PCE_Data*.F90`) plus all precomputed `cijk****`, `multiIndex****`, `nZijk****`, `multipliers*`, and `omegas*` tables.
- `scripts/`: automation entry points (`generate_data*.sh`, `preprocess.sh`, `run_ddm*.sh`, `clean.sh`, `MeshDataClean.sh`, `NonPCEdatClean.sh`).
- `docs/PETSc_Install.pdf`: walkthrough for compiling PETSc on Compute Canada systems.
- `makefile` and `makefile_{cedar,graham,niagara}`: PETSc-aware build recipes for local and cluster environments.

## Prerequisites
- **Compiler**: GNU Fortran 4.9.2+ (Intel Fortran tested on CC clusters).
- **MPI**: Open MPI 1.8+, or vendor-provided MPI on SLURM systems.
- **PETSc**: >= 3.7.5 (3.9.2 run files included). Define `PETSC_DIR` and `PETSC_ARCH`.
- **Gmsh**: ≥ 2.8.5 for mesh generation. Scripts expect 3.0.4 but accept other versions with matching CLI.
- **ParaView**: ≥ 4.1.0 for VTK visualization.
- **MATLAB/UQTK** (optional): for advanced stochastic post-processing of generated data sets.

Ensure PETSc libraries are visible (module load or manual installation) before invoking `make`.

## Configure your environment
1. Clone the repository and switch into it.
2. Pick the makefile closest to your machine (e.g., `makefile_cedar`, `makefile_graham`, `makefile_niagara`) and copy/rename it to `makefile`. Update `PETSC_DIR`, `PETSC_ARCH`, compiler, BLAS/LAPACK, and optimization flags.
3. Export MPI launchers if PETSc is not on your `PATH`, e.g.:
   ```bash
   export PETSC_DIR=/path/to/petsc
   export PETSC_ARCH=arch-linux2-c-debug
   export PATH=$PETSC_DIR/$PETSC_ARCH/bin:$PATH
   ```

## End-to-end workflow
All script invocations below assume you run them from the repository root so relative paths resolve correctly.
### 1. Mesh and measurement preprocessing
1. Set the number of partitions (`NP`) inside the appropriate `scripts/generate_data*.sh` script and update the absolute path to your Gmsh binary.
2. Run `bash scripts/generate_data.sh` (or the Cedar/Graham/Niagara variants). The script:
   - Invokes `gmsh -2 data/geometry/square.geo -part $NP -o gmsh.msh`.
   - Compiles and runs each `preprocmesh*.F90` program to emit global/local data (`points.dat`, `edges.dat`, `triangles.dat`, `meshdim.dat`, `nbnodes####.dat`, measurement-node lists, etc.).
3. On workstations you can alternatively call `bash scripts/preprocess.sh`, which mirrors the same commands using the system `gmsh`.

### 2. Stochastic data (KLE/PCE)
1. Enter `data/kle_pce/`.
2. Decide the stochastic dimension (`nDim`) and polynomial order (`nOrd`) and edit `KLE_PCE_Data*.F90` accordingly (or choose the pre-generated dataset that matches your case, e.g., `multiIndex00030025.dat`).
3. Run `gfortran KLE_PCE_Data.F90 -O2 -o kle_gen && ./kle_gen`.
4. Copy or link the produced `cijk****`, `multiIndex****`, `nZijk****`, `multipliers*`, and `omegas*` files expected by `main.F90`. Global defaults in `data/stochastic/` (`cijk`, `multipliers`, `omegas`) cover 9 KLE modes; override them if you use larger tables.

### 3. Build the solver
```bash
make all            # builds a.out by linking PETSc libraries listed in the makefile
```
The top-level makefile defines `LIST` with all Fortran objects and reuses PETSc’s `variables`/`rules`. Ensure PETSc’s `bin/mpiexec` is in `PATH` before building on shared clusters where login nodes restrict custom MPI binaries.

### 4. Run the solver
Pass the number of MPI ranks (`NP`, must match the number of subdomains) to `scripts/run_ddm.sh` or the cluster-specific launch script.

#### Local workstation
```bash
bash scripts/preprocess.sh        # if not already done
make all
$PETSC_DIR/$PETSC_ARCH/bin/mpiexec -np $NP ./a.out [-ksp_monitor ...]
```
Enable PETSc diagnostics by appending options shown at the bottom of each `scripts/run_ddm*.sh`.

#### Compute Canada clusters
- **Cedar & Graham**: Copy `scripts/generate_data_{cedar,graham}.sh` to `scripts/generate_data.sh`, run it in `$SCRATCH`, then adjust `scripts/run_ddm_{cedar,graham}.sh` (account, walltime, nodes, tasks, PETSc modules). Submit with `sbatch scripts/run_ddm_cedar.sh` or `sbatch scripts/run_ddm_graham.sh`. Both scripts load `nixpkgs/16.09` and `intel/2016.4` + OpenMPI 2.1.1 by default.
- **Niagara**: Files must reside in `$SCRATCH`. Load `CCEnv` and `StdEnv`, then `module load nixpkgs/16.09 intel/2016.4 openmpi/2.1.1`. Submit `sbatch scripts/run_ddm_niagara.sh`. Niagara nodes expose 40 cores, so choose NP in multiples of 40.

`scripts/run_ddm.sh` remains a template for other SLURM/PBS systems; adapt walltime, modules, and `mpiexec` arguments as needed.

### 5. Output and visualization
- Solution vectors per subdomain plus assembled global data are written as `*.dat` and `out_deterministic.vtk`. Load the VTK file with `paraview out_deterministic.vtk`.
- Measurement files (`measnodes*.dat`, `measlocs.dat`) are produced by `preprocmesh_meas*.F90` for Bayesian filtering or Kalman updates downstream.

## Data file reference
- **Mesh**: `points.dat`, `edges.dat`, `triangles.dat`, per-domain `nodes####.dat`, `tri####.dat`, `bnodes####.dat`, etc.
- **Boundary metadata**: `boundary_nodes.dat`, `meshdim.dat`, `dbounds.dat`, `nbnodes####.dat`, `corn####.dat`, `rema####.dat`.
- **Stochastic inputs**: defaults in `data/stochastic/` (`cijk`, `multipliers`, `omegas`) plus the high-order tables under `data/kle_pce/` (`multiIndex****.dat`, `nZijk****.dat`, `multipliers*`, `omegas*`, `params.dat`).
- **Measurement**: `measnodes####.dat`, `nmeas####.dat`, `measlocs.dat`.
- **Solver outputs**: `Ui`, `Ub`, `Ub_g`, `out_deterministic.vtk`, PETSc log files if `-log_summary` is enabled.

## Cleaning scripts
- `scripts/clean.sh`: removes compiled objects, modules, `.msh`, `.vtk`, `.dat`, and binaries.
- `scripts/MeshDataClean.sh`: deletes mesh-related `.dat` files when regenerating partitions.
- `scripts/NonPCEdatClean.sh`: extends the mesh clean to PCE/KLE-specific files so stochastic datasets can be re-derived safely.

Always clean stale mesh data before re-running `scripts/generate_data*.sh` with a different `NP`.

## Troubleshooting and tips
- **MPI rank mismatch**: Ensure `NP` used in mesh partitioning matches `mpiexec -np`. Otherwise `main.F90` will fail when trying to open per-domain files.
- **PETSc paths**: `scripts/run_ddm.sh` expects `${PETSC_ARCH}/bin/mpiexec`; set `PETSC_ARCH` accordingly or edit the script to use `mpiexec` on `PATH`.
- **Memory footprint**: Large `NP` × `npceout` combinations raise the size of PETSc vectors. Monitor `--mem-per-cpu` in SLURM scripts.
- **KLE/PCE selection**: When changing `nDim`/`nOrd`, regenerate both the triplet products and multi-index files inside `data/kle_pce/` and update filenames consumed in `main.F90`.
- **Documentation**: For PETSc installation hints see `docs/PETSc_Install.pdf`. For algorithmic details refer to the CMAME article cited below.

## References
- Ajit Desai et al., *Scalable Domain Decomposition Solvers for Stochastic PDEs in High Performance Computing*, CMAME, 2016. (Link included in earlier README; keep handy for derivations.)

## Contact
Sudhi Sharma P V — sudhisharmapadillath@gmail.com
