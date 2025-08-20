-- -*- lua -*-
-- Modulefile for my custom OpenMPI build

help([[
This module loads my custom build of OpenMPI 4.1.5
compiled with GCC 12.
Website: https://www.open-mpi.org/
]])

-- Give your module a name and version
local pkgName = "openapi-5.0.8"
local version = "5.0.8"
local compiler = "gcc7.5.0"

-- Set the installation prefix directory
local base = "$HOME/local"

-- Set environment variables
setenv("OMPI_DIR", base)
prepend_path("PATH", pathJoin(base, "bin"))
prepend_path("LD_LIBRARY_PATH", pathJoin(base, "lib"))
prepend_path("MANPATH", pathJoin(base, "share/man"))
prepend_path("PKG_CONFIG_PATH", pathJoin(base, "lib/pkgconfig"))

-- Modulepath for MPI compiler wrappers
setenv("MPIHOME", base)

-- What to show for 'module list'
whatis("Name: " .. pkgName)
whatis("Version: " .. version)
whatis("Description: Custom OpenMPI build")
whatis("Compiler: " .. compiler)
