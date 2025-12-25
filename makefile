LLAPACK = -llapack 
LBLAS = -lblas
MAIN = ./a.out
COMP = gfortran
COMP_OPS = -O2

PETSC_DIR=/media/sudhipv/work/Phd/work/PETSc/petsc-3.9.2
PETSC_ARCH=arch-linux2-c-debug

#PETSC_DIR=/media/sudhipv/work/Phd/work/PETSc/petsc-3.6.4
#PETSC_ARCH=arch-linux2-c-debug

include ${PETSC_DIR}/lib/petsc/conf/variables
include ${PETSC_DIR}/lib/petsc/conf/rules

LIST = common.o myCommon.o variationalform.o PETScAssembly.o assembly.o PETScommon.o PETScSolvers.o main.o

all : $(LIST) chkopts
	-${FLINKER} -o $(MAIN) $(LIST) ${PETSC_LIB} 

# 	${RM} -f *.o *.mod
