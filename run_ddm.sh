#!/usr/bin/env bash


PETSC_ARCH=/media/sudhipv/work/Phd/work/PETSc/petsc-3.9.2/arch-linux2-c-debug
#PETSC_ARCH=/media/sudhipv/work/Phd/work/PETSc/petsc-3.6.4/arch-linux2-c-debug

## select the number of partitions
NP=4


make all

## execute using PETSc-MPIEXEC :: named here as 'petscexec'
${PETSC_ARCH}/bin/mpiexec -np $NP ./a.out


##  -log_summary                    ## PETSc Log summary
##  -ksp_monitor                    ## PETSc KSP iteration
##  -mat_view ::ascii_info          ## PETSc Mat mallocs
##  -mat_view draw -draw_pause 10   ## Mat sparsity pattern
##  -ksp_converged_reason	        ## print reason for converged or diverged
                                    ## also prints number of iterations
##  -ksp_monitor_solution	        ## plot solution at each iteration
##  -ksp_max_it                     ## maximum number of linear iterations
##  -ksp_rtol rtol	                ## default relative tolerance used for convergence
