# Stochastic Two-Level DDM Solver

High Performance Uncertainty Quantification (HPUQ) – StDDM provides deterministic and stochastic finite-element solvers for elliptic PDEs using two-level preconditioned conjugate gradient methods (PCGM) embedded inside a domain-decomposition (DDM) framework. The code couples hand-written FEM assembly routines with PETSc-based sparse blocks, supports both deterministic and stochastic (KLE/PCE) representations of coefficients, and scales to large MPI runs on Compute Canada clusters.

## Highlights
- Hybrid FEM/PETSc workflow: local dense assembly (`assembly.F90`, `variationalform.F90`) feeding sparse PETSc objects built in `PETScAssembly.F90`.
- Multiple DDM solvers: classic implementations in `solvers.F90` plus the PETSc-based two-level NNC PCGM (`PETScSolvers.F90` + `PETScommon.F90`).
- Automated mesh preprocessing (`preprocmesh*.F90`) for global and per-subdomain partitions exported by Gmsh.
- Turnkey scripts to generate KLE/PCE data (`klePceData/`), run on desktops (`run_ddm.sh`) or submit SLURM jobs on Cedar, Graham, or Niagara with matching makefiles.
- Reproducible stochastic data inputs (global `cijk`, `multipliers`, `omegas` plus many higher-order datasets inside `klePceData/`).

## Repository layout
- `main.F90`: orchestrates MPI initialization, data ingestion, PETSc solver selection, and IO of stochastic results.
- `common.F90`, `myCommon.F90`: shared utilities (string helpers, restriction matrices, coarse-grid operators, measurement handling).
- `variationalform.F90`: weak-form definitions for diffusion/convection terms and deterministic/stochastic source terms.
- `assembly.F90`: deterministic subdomain assembly targeting `Au=f` with boundary/corner block extraction.
- `PETScAssembly.F90`: sparse vector/matrix builders that expose assembled blocks to PETSc.
- `PETScommon.F90`: wrappers around PETSc KSP/PC, helper routines for sequential/multi-domain vectors, Rs/Rc restriction operators, and PETSc solver glue.
- `PETScSolvers.F90` & `solvers.F90`: NNC-PCGM, WL-PCGM, coarse-grid, Dirichlet-PCGM, and FETI-DP solvers (sequential PETSc and in-house variants).
- `preprocmesh1_AD.F90`, `preprocmesh2_AD.F90`, `preprocmesh_meas1.F90`, `preprocmesh_meas2.F90`: extract global/local geometry, subdomain metadata, and measurement-node locations from `gmsh.msh`.
- `square.geo`: sample geometry; adjust `lc` to refine/coarsen before partitioning.
- `klePceData/`: generators (`KLE_PCE_Data*.F90`) plus precomputed `cijk****`, `multiIndex****`, `nZijk****`, `multipliers*`, and `omegas*` tables.
- `cijk`, `multipliers`, `omegas` (top-level): default stochastic triplet/multiplier/omega data consumed by `main.F90`.
- Scripts: `generate_data*.sh`, `preprocess.sh`, `run_ddm*.sh`, `clean.sh`, `MeshDataClean.sh`, `NonPCEdatClean.sh`, `preprocess.sh`, and HPC-specific `makefile_*`.
- `doc/PETSc_Install.pdf`: walkthrough for compiling PETSc on Compute Canada systems.

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
### 1. Mesh and measurement preprocessing
1. Set the number of partitions (`NP`) inside the appropriate `generate_data*.sh` script and update the absolute path to your Gmsh binary.
2. Run `sh generate_data.sh` (or the Cedar/Graham/Niagara variants). The script:
   - Invokes `gmsh -2 square.geo -part $NP -o gmsh.msh`.
   - Compiles and runs each `preprocmesh*.F90` program to emit global/local data (`points.dat`, `edges.dat`, `triangles.dat`, `meshdim.dat`, `nbnodes####.dat`, measurement-node lists, etc.).
3. On workstations you can alternatively call `sh preprocess.sh`, which mirrors the same commands using the system `gmsh`.

### 2. Stochastic data (KLE/PCE)
1. Enter `klePceData/`.
2. Decide the stochastic dimension (`nDim`) and polynomial order (`nOrd`) and edit `KLE_PCE_Data*.F90` accordingly (or choose the pre-generated dataset that matches your case, e.g., `multiIndex00030025.dat`).
3. Run `gfortran KLE_PCE_Data.F90 -O2 -o kle_gen && ./kle_gen`.
4. Copy or link the produced `cijk****`, `multiIndex****`, `nZijk****`, `multipliers*`, and `omegas*` files expected by `main.F90`. Global defaults in the repo (`cijk`, `multipliers`, `omegas`) cover 9 KLE modes; override them if you use larger tables.

### 3. Build the solver
```bash
make all            # builds a.out by linking PETSc libraries listed in the makefile
```
The top-level makefile defines `LIST` with all Fortran objects and reuses PETSc’s `variables`/`rules`. Ensure PETSc’s `bin/mpiexec` is in `PATH` before building on shared clusters where login nodes restrict custom MPI binaries.

### 4. Run the solver
Pass the number of MPI ranks (`NP`, must match the number of subdomains) to `run_ddm.sh` or the cluster-specific launch script.

#### Local workstation
```bash
sh preprocess.sh        # if not already done
make all
$PETSC_DIR/$PETSC_ARCH/bin/mpiexec -np $NP ./a.out [-ksp_monitor ...]
```
Enable PETSc diagnostics by appending options shown at the bottom of each `run_ddm*.sh`.

#### Compute Canada clusters
- **Cedar & Graham**: Copy `generate_data_{cedar,graham}.sh` to `generate_data.sh`, run it in `$SCRATCH`, then adjust `run_ddm_{cedar,graham}.sh` (account, walltime, nodes, tasks, PETSc modules). Submit with `sbatch run_ddm_cedar.sh` or `sbatch run_ddm_graham.sh`. Both scripts load `nixpkgs/16.09` and `intel/2016.4` + OpenMPI 2.1.1 by default.
- **Niagara**: Files must reside in `$SCRATCH`. Load `CCEnv` and `StdEnv`, then `module load nixpkgs/16.09 intel/2016.4 openmpi/2.1.1`. Submit `sbatch run_ddm_niagara.sh`. Niagara nodes expose 40 cores, so choose NP in multiples of 40.

`run_ddm.sh` remains a template for other SLURM/PBS systems; adapt walltime, modules, and `mpiexec` arguments as needed.

### 5. Output and visualization
- Solution vectors per subdomain plus assembled global data are written as `*.dat` and `out_deterministic.vtk`. Load the VTK file with `paraview out_deterministic.vtk`.
- Measurement files (`measnodes*.dat`, `measlocs.dat`) are produced by `preprocmesh_meas*.F90` for Bayesian filtering or Kalman updates downstream.

## Data file reference
- **Mesh**: `points.dat`, `edges.dat`, `triangles.dat`, per-domain `nodes####.dat`, `tri####.dat`, `bnodes####.dat`, etc.
- **Boundary metadata**: `boundary_nodes.dat`, `meshdim.dat`, `dbounds.dat`, `nbnodes####.dat`, `corn####.dat`, `rema####.dat`.
- **Stochastic inputs**: `cijk`, `multiIndex****.dat`, `nZijk****.dat`, `multipliers*`, `omegas*`, `params.dat`.
- **Measurement**: `measnodes####.dat`, `nmeas####.dat`, `measlocs.dat`.
- **Solver outputs**: `Ui`, `Ub`, `Ub_g`, `out_deterministic.vtk`, PETSc log files if `-log_summary` is enabled.

## Cleaning scripts
- `clean.sh`: removes compiled objects, modules, `.msh`, `.vtk`, `.dat`, and binaries.
- `MeshDataClean.sh`: deletes mesh-related `.dat` files when regenerating partitions.
- `NonPCEdatClean.sh`: extends the mesh clean to PCE/KLE-specific files so stochastic datasets can be re-derived safely.

Always clean stale mesh data before re-running `generate_data*.sh` with a different `NP`.

## Troubleshooting and tips
- **MPI rank mismatch**: Ensure `NP` used in mesh partitioning matches `mpiexec -np`. Otherwise `main.F90` will fail when trying to open per-domain files.
- **PETSc paths**: `run_ddm.sh` expects `${PETSC_ARCH}/bin/mpiexec`; set `PETSC_ARCH` accordingly or edit the script to use `mpiexec` on `PATH`.
- **Memory footprint**: Large `NP` × `npceout` combinations raise the size of PETSc vectors. Monitor `--mem-per-cpu` in SLURM scripts.
- **KLE/PCE selection**: When changing `nDim`/`nOrd`, regenerate both the triplet products and multi-index files inside `klePceData/` and update filenames consumed in `main.F90`.
- **Documentation**: For PETSc installation hints see `doc/PETSc_Install.pdf`. For algorithmic details refer to the CMAME article cited below.

## References
- Ajit Desai et al., *Scalable Domain Decomposition Solvers for Stochastic PDEs in High Performance Computing*, CMAME, 2016. (Link included in earlier README; keep handy for derivations.)

## Contact
Sudhi Sharma P V — sudhisharmapadillath@gmail.com
