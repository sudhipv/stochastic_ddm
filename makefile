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

SRC_DIR = src
LIST = $(SRC_DIR)/common.o \
       $(SRC_DIR)/myCommon.o \
       $(SRC_DIR)/variationalform.o \
       $(SRC_DIR)/PETScAssembly.o \
       $(SRC_DIR)/assembly.o \
       $(SRC_DIR)/PETScommon.o \
       $(SRC_DIR)/PETScSolvers.o \
       $(SRC_DIR)/main.o

all : $(LIST) chkopts
	-${FLINKER} -o $(MAIN) $(LIST) ${PETSC_LIB} 

# 	${RM} -f *.o *.mod
