#!/bin/bash -l        
#PBS -l walltime=0:30:00,nodes=1:ppn=128,mem=2000gb 
#PBS -m abe 
#PBS -M crou0048@umn.edu 
#PBS -N lethal
#PBS -q amd2tb
Desktop/NetLogo\ 6.1.1-64/NetLogo\ 6.1.1/netlogo-headless.sh --model Desktop/LethalGeometry2/code/LethalGeometry.nlogo --experiment Lethal_Experiment
