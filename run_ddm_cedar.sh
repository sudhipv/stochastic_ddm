#!/bin/bash
#SBATCH --account=def-asarkar
#SBATCH --time=00:10:00
#SBATCH --mem-per-cpu=7700M
#SBATCH --nodes=3
#SBATCH --tasks-per-node=16

#module load nixpkgs/16.09  intel/2017.1  openmpi/2.0.2  petsc/3.7.5

# For PETSc 3.9.2 local installation
module load nixpkgs/16.09  intel/2016.4  openmpi/2.1.1 gmsh/3.0.6

# Commands to run the preprocessing also in compute nodes

# sh generate_data.sh
# cd klePceData
# gfortran KLE_PCE_Data.F90
# ./a.out
# cd ..

###############

## execute using PETSc-MPIEXEC :: named here as 'petscexec'
make all
mpiexec -np 48 ./a.out

##  -log_summary                    ## PETSc Log summary
##  -ksp_monitor                    ## PETSc KSP iteration
##  -mat_view ::ascii_info          ## PETSc Mat mallocs
##  -mat_view draw -draw_pause 10   ## Mat sparsity pattern
##  -ksp_converged_reason	        ## print reason for converged or diverged
##  -ksp_monitor_solution	        ## plot solution at each iteration
##  -ksp_max_it                     ## maximum number of linear iterations
##  -ksp_rtol rtol	                ## default relative tolerance used for convergence

exit
