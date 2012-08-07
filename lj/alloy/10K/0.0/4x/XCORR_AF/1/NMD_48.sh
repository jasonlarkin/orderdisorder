##/opt/open-mpi/tcp-gnu41/bin/mpirun -np 4 $EXEPATH/lmp_generic < $RUNPATH/LMP_TEMP

#!/bin/bash
cd $PBS_O_WORKDIR
module load openmpi-psm-gcc

RUNPATH=/home/jason/lammps/LJ/alloy/10K/0.0/4x/XCORR_AF/1
EXEPATH=/opt/mcgaugheygroup/matlab_R2011a/bin

mpirun -np `cat $PBS_NODEFILE | wc -l` $EXEPATH/matlab -nojvm -nosplash -nodisplay -r -nodesktop < $RUNPATH/NMD_48.m

