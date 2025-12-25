#!/bin/bash

## select the number of partitions
NP=1000

## create mesh file::
/home/sudhipv/project/sudhipv/packages/gmsh/gmsh-3.0.4-Linux/bin/./gmsh -2 data/geometry/square.geo -part $NP -o gmsh.msh

## create mesh data::
gfortran src/preprocmesh1_AD.F90 -O2 -o ./a.out;./a.out
gfortran src/preprocmesh2_AD.F90 -O2 -o ./a.out;./a.out
gfortran src/preprocmesh_meas1.F90 -O2 -o ./a.out;./a.out
gfortran src/preprocmesh_meas2.F90 -O2 -o ./a.out;./a.out

## mesh visualization::
# gmsh gmsh.msh

