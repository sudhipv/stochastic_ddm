#!/bin/bash
#SBATCH --account=def-asarkar
#SBATCH --time=00:10:00
#SBATCH --mem-per-cpu=7700M
#SBATCH --nodes=70
#SBATCH --tasks-per-node=16

# For Global PETSC with different compiler versions
#module load nixpkgs/16.09  intel/2017.1  openmpi/2.0.2  petsc/3.7.5
#module load nixpkgs/16.09  intel/2017.1  openmpi/2.0.2 
#module load nixpkgs/16.09  gcc/5.4.0  openmpi/2.1.1

#For locally compiled PETSc
module load nixpkgs/16.09  intel/2016.4  openmpi/2.1.1

## execute using PETSc-MPIEXEC :: named here as 'petscexec'
make all
mpiexec -np 1000 ./a.out

##  -log_summary                    ## PETSc Log summary
##  -ksp_monitor                    ## PETSc KSP iteration
##  -mat_view ::ascii_info          ## PETSc Mat mallocs
##  -mat_view draw -draw_pause 10   ## Mat sparsity pattern
##  -ksp_converged_reason	        ## print reason for converged or diverged
##  -ksp_monitor_solution	        ## plot solution at each iteration
##  -ksp_max_it                     ## maximum number of linear iterations
##  -ksp_rtol rtol	                ## default relative tolerance used for convergence

exit
