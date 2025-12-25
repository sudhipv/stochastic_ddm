#!/bin/bash

## select the number of partitions
NP=48

## create mesh file::
$HOME/project/sudhipv/packages/gmsh/gmsh-3.0.4-Linux/bin/./gmsh -2 square.geo -part $NP -o gmsh.msh

# If using the global GMSH build by sending preprocessing to compute nodes
#gmsh -2 square.geo -part $NP -o gmsh.msh

## create mesh data::
gfortran preprocmesh1_AD.F90 -O2 -o ./a.out;./a.out
gfortran preprocmesh2_AD.F90 -O2 -o ./a.out;./a.out
gfortran preprocmesh_meas1.F90 -O2 -o ./a.out;./a.out
gfortran preprocmesh_meas2.F90 -O2 -o ./a.out;./a.out

## mesh visualization::
# gmsh gmsh.msh


