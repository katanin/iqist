##
##
## Introduction
## ============
##
## Makefile for iqist/src/capi directory.
##
## Usage
## =====
##
## 'make' or 'make clean'
##
## Author
## ======
##
## This building system is designed, created, implemented, and maintained by
##
## Li Huang // email: lihuang.dmft@gmail.com
##
## History
## =======
##
## 05/10/2015 by li huang (created)
## 08/17/2015 by li huang (last modified)
##
##

.SUFFIXES: .f90

include ../../build/make.sys

mod = ctqmc_api.o hfqmc_api.o atomic_api.o

default: all

all: build_mod

build_mod: $(mod)

.f90.o:
	$(F90) $(FFLAGS) $*.f90

clean:
	rm -f *.mod
	rm -f *.o

clean-dat:
	rm -f *.dat
	rm -f *.out

clean-all: clean clean-dat
