-- -*- lua -*-
-- Modulefile for OpenMPI 5.0.8 built with GCC 7.5.0

help([[
OpenMPI 5.0.8
This module loads a user-compiled version of OpenMPI 5.0.8
built with the system GCC 7.5.0 compiler.
Installed in: $HOME/local

Once loaded, compile with: mpicc, mpic++, mpif90
Run with: mpirun
]])

-- Set the installation prefix directory
local base = os.getenv("HOME") .. "/local"
local version = "5.0.8"
local compiler = "gcc7.5.0"

-- Set core environment variables
setenv("OMPI_DIR", base)
setenv("MPI_HOME", base)
setenv("OPAL_PREFIX", base)

-- Setup PATH for binaries (mpicc, mpirun, etc.)
prepend_path("PATH", pathJoin(base, "bin"))
-- Setup LD_LIBRARY_PATH for shared libraries
prepend_path("LD_LIBRARY_PATH", pathJoin(base, "lib"))
-- Setup MANPATH for manual pages
prepend_path("MANPATH", pathJoin(base, "share/man"))
-- Setup PKG_CONFIG_PATH for build systems that use pkg-config
prepend_path("PKG_CONFIG_PATH", pathJoin(base, "lib/pkgconfig"))

-- Whatis descriptions for 'module list' and 'module avail'
whatis("Name: OpenMPI")
whatis("Version: " .. version)
whatis("Compiler: " .. compiler)
whatis("Category: library, runtime")
whatis("Description: A high-performance message passing library (MPI)")
whatis("URL: https://www.open-mpi.org")
whatis("Installed By: " .. os.getenv("USER"))
whatis("Install Path: " .. base)
