#!/bin/bash -e

## fresh clone
git clone --recursive -b 131.regrid-xy.pyrewrite https://gitlab.gfdl.noaa.gov/fre2/workflows/postprocessing.git pp_MR126
cd pp_MR126

# module setups
module load fre/bronx-22 conda
conda activate cylc-8.2.1

## if you don't have netCDF4, pytest, and pylint lying around or in your PATH
#pip install netCDF4 pytest pylint
#export PATH=/home/$USER/.local/bin:$PATH

# change directory name via link for python mod import compatibility
cd app
ln -s regrid-xy regrid_xy

# links for similar reasons: cylc wants stuff in bin/
cd regrid_xy
ln -rs bin/regrid-xy regrid_xy.py
ln -s bin/shared shared

# local pytest, pylint calls
python -m pytest -x $PWD/t/test_regrid_xy.py
python -m pylint --ignored-modules netCDF4,shared regrid_xy.py

# back to base dir to setup workflow for testing live:
cd ../..

# clone snippet rose configs i use for testing workflow
git clone https://gitlab.gfdl.noaa.gov/snippets/41.git MR126_configs
mv -f MR126_configs/rose-suite.conf .
mv -f MR126_configs/opt/rose-suite-c96L65_am5f6b9r0_amip.conf opt/.
mv -f MR126_configs/app/regrid-xy/rose-app.conf app/regrid_xy/.
mv -f MR126_configs/app/remap-pp-components/rose-app.conf app/remap-pp-components/.

# create history manifest, run validation
tar -tf /archive/oar.gfdl.am5/am5/am5f6b9r0/c96L65_am5f6b9r0_amip/gfdl.ncrc5-deploy-prod-openmp/history/19790101.nc.tar | grep -v tile[2-6] | sort > history-manifest
rose macro --validate

# install experiment, launch + watch regrid tasks
bin/install-exp c96L65_am5f6b9r0_amip
cylc play c96L65_am5f6b9r0_amip/run1
watch -n 5 "cylc workflow-state -v c96L65_am5f6b9r0_amip/run1 | grep regrid-xy"
