#!/bin/tcsh -f
#------------------------------------
# MOAB batch directives
#PBS -N frepp.atw_atmos_ts_monthly_sfc_ocean.csh
#PBS -l walltime=18:00:00
#PBS -l size=1
#PBS -j oe
#PBS -o $HOME/msub_output/
#PBS -r y
#------------------------------------
# SGE batch directives
#$ -l h_cpu=18:00:00
#$ -pe ic.postp 2
#$ -j y
#$ -o $HOME/qsub_output
#$ -r y
#------------------------------------
#
#NAME
#   frepp.atw_atmos_ts_monthly_sfc_ocean.csh
#
#SYNOPSIS
#   Use frepp to create figures and statistics from atmospheric data.
#
#DESCRIPTION
#   Creates figures and statistics from atmospheric data.  This script is just
#   a simple wrapper around a more general workhorse script.  Here we eliminate
#   several options of that script by instead relying on frepp to set their
#   values.
#
#   If any arguments are supplied on the command line, those will replace the
#   original frepp-supplied arguments which are stored in ARGU.
#
#   For details: $work_script -h
#
#SOURCE DATA
#   pp/atmos/ts/monthly
#
#OUTPUT
#   Creates figures, statistics, and data in
#      $out_dir/atw_atmos_ts_monthly/sfc_ocean/
#
#AUTHOR
#   Andrew Wittenberg
#
#SAMPLE FREPP USAGE
#
# <component type="atmos">
#    <timeSeries freq="monthly" chunkLength="20yr">
#       <analysis script="script_name options"/>
#    </timeSeries>
# </component>
#
# See also: http://www.gfdl.noaa.gov/fms/fre/#analysis
#
# atw 26nov2014

set name = `basename $0`

# set paths to tools
source /home/atw/.atw_env_vars
set work_script = $ATW_FRE_ANALYSIS/atw/code/atmos_ts_monthly/sfc_ocean/csh/sfc_ocean.csh
set echo2 = $ATW_UTIL/echo2

set echo
# ============== VARIABLES SET BY FREPP =============
# original arguments passed to this script when it was created by frepp
set argu
# path to NetCDF files postprocessed by frepp, as specified in XML
set in_data_dir
# input data file[s], without any path prefix;
# currently only used by timeAverage diagnostics
set in_data_file
# experiment name (as appears in output directory names)
set descriptor
# final output directory for diagnostics generated by this script
set out_dir
# working directory -- do whatever you want in here
# we may have to create this (use "mkdir -p" to be sure)
# and then clean up at end
set WORKDIR
# history directory where the original "*.nc.cpio" files are found
set hist_dir

# actual start/end years of diagnostics (start_year & end_year in XML)
set yr1
set yr2
# alternate way to specify a single year (instead of yr1==yr2)
set specify_year

# Data years, only used in scripts using time series as input, to
# generate a Ferret descriptor file from consecutive NetCDF chunks.
# start year of first chunk
set databegyr
# end year of last chunk
set dataendyr
# chunk length (an integer number), as specified in XML
set datachunk
# first year of integration (4-digits, e.g. the year of initial condition)
set MODEL_start_yr
# a string: "monthly" or "annual" for timeseries data
set freq

# a string to indicate the mode: "batch" or "interactive"
set mode
# Specify MOM version; "om2" or "om3" because some files depend on mom's grid
set mom_version
# full path to the grid specification file, which contains the land/sea mask
set gridspecfile
# atmospheric land mask file
set staticfile

# the following variables are used for model-model comparisons only
set yr1_2
set yr2_2
set descriptor_2
set in_data_dir_2
set databegyr_2
set dataendyr_2
set datachunk_2
set staticfile_2

# ============== END OF VARIABLES SET BY FREPP =============

# If any arguments were supplied on the command line, then those
# will replace the original frepp-supplied arguments.
if ($#argv) set argu = ($argv:q)

# =============== START BODY OF SCRIPT ==============

if ($yr1_2 == "") then
   set ref_opt
else
   set ref_opt = (-r gfdl_model,$yr1_2,$yr2_2,$descriptor_2,$in_data_dir_2,$databegyr_2,$dataendyr_2,$datachunk_2,$staticfile_2)
endif


#$work_script -o $out_dir $ref_opt \
#   -m gfdl_model,$yr1,$yr2,$descriptor,$in_data_dir,$databegyr,$dataendyr,$datachunk,$staticfile \
#   $argu:q || goto err


# =============== START BODY OF SCRIPT ==============
set pregrid_opt   = "-g g1x1,fill,nolabel,x=0:360:1,y=-90:90:1"
set shared_opt    = "-V2 -P ps.gz -s" 
set x_global      = "-d x,25,385,60,2"
set y_tropics     = "-d y,-20,20,10,4"
set y_subpolar    = "-d y,-60,60,20,1"
set y_global      = "-d y,-90,90,20,1"
set default_region = "-N tropics $x_global $y_tropics"


set argu_test1 = "$shared_opt $pregrid_opt -n -r oisst_v2 -A globe -N subpolar $y_subpolar plot_clim"
$work_script -o $out_dir $ref_opt \
   -m gfdl_model,$yr1,$yr2,$descriptor,$in_data_dir,$databegyr,$dataendyr,$datachunk,$staticfile \
   $argu_test1 || goto err

set argu_test2 = "$shared_opt $pregrid_opt -n -r oisst_v2 -T all,mam,son,jja,djf $default_region plot_clim"
$work_script -o $out_dir $ref_opt \
   -m gfdl_model,$yr1,$yr2,$descriptor,$in_data_dir,$databegyr,$dataendyr,$datachunk,$staticfile \
   $argu_test2 || goto err

set argu_test3 = "$shared_opt $pregrid_opt -n -r oisst_v2 -C clim -f12 -F0 $default_region plot_std plot_anom_std plot_anom_regr_nino3"
$work_script -o $out_dir $ref_opt \
   -m gfdl_model,$yr1,$yr2,$descriptor,$in_data_dir,$databegyr,$dataendyr,$datachunk,$staticfile \
   $argu_test3 || goto err




set argu_test4 = "$shared_opt $pregrid_opt -n -r gpcp_v2p3 -T all,mam,son,jja,djf $default_region plot_clim"
$work_script -o $out_dir $ref_opt \
   -m gfdl_model,$yr1,$yr2,$descriptor,$in_data_dir,$databegyr,$dataendyr,$datachunk,$staticfile \
   $argu_test4 || goto err

set argu_test5 = "$shared_opt $pregrid_opt -n -r gpcp_v2p3 -C clim -f 12,0 -F 0,12 $default_region plot_anom_regr_nino3 plot_std plot_anom_std"
$work_script -o $out_dir $ref_opt \
   -m gfdl_model,$yr1,$yr2,$descriptor,$in_data_dir,$databegyr,$dataendyr,$datachunk,$staticfile \
   $argu_test5 || goto err




set argu_test6 = "$shared_opt $pregrid_opt -n -r tropflux_v1 -T all,mam,son,jja,djf $default_region plot_clim"
$work_script -o $out_dir $ref_opt \
   -m gfdl_model,$yr1,$yr2,$descriptor,$in_data_dir,$databegyr,$dataendyr,$datachunk,$staticfile \
   $argu_test6 || goto err

set argu_test7 = "$shared_opt $pregrid_opt -n -r tropflux_v1 -v tau_x,tau_y -C clim -f 12,0 -F 0,12 $default_region plot_std plot_anom_std"
$work_script -o $out_dir $ref_opt \
   -m gfdl_model,$yr1,$yr2,$descriptor,$in_data_dir,$databegyr,$dataendyr,$datachunk,$staticfile \
   $argu_test7 || goto err

set argu_test8 = "$shared_opt $pregrid_opt -n -r tropflux_v1 $default_region plot_anom_regr_nino3"
$work_script -o $out_dir $ref_opt \
   -m gfdl_model,$yr1,$yr2,$descriptor,$in_data_dir,$databegyr,$dataendyr,$datachunk,$staticfile \
   $argu_test8 || goto err



set argu_test9 = "$shared_opt $pregrid_opt -n -r oaflux_v3_ceres_ebaf_ed2p8 -T all,mam,son,jja,djf $default_region plot_clim"
$work_script -o $out_dir $ref_opt \
   -m gfdl_model,$yr1,$yr2,$descriptor,$in_data_dir,$databegyr,$dataendyr,$datachunk,$staticfile \
   $argu_test9 || goto err

set argu_test10 = "$shared_opt $pregrid_opt -n -r oaflux_v3_ceres_ebaf_ed2p8 $default_region plot_anom_regr_nino3"
$work_script -o $out_dir $ref_opt \
   -m gfdl_model,$yr1,$yr2,$descriptor,$in_data_dir,$databegyr,$dataendyr,$datachunk,$staticfile \
   $argu_test10 || goto err



set argu_test11 = "$shared_opt $pregrid_opt -n -r era_interim -v t_surf,ps -N globe $y_global plot_clim"
$work_script -o $out_dir $ref_opt \
   -m gfdl_model,$yr1,$yr2,$descriptor,$in_data_dir,$databegyr,$dataendyr,$datachunk,$staticfile \
   $argu_test11 || goto err

set argu_test12 = "$shared_opt $pregrid_opt -n -r era_interim -T all,mam,son,jja,djf $default_region plot_clim"
$work_script -o $out_dir $ref_opt \
   -m gfdl_model,$yr1,$yr2,$descriptor,$in_data_dir,$databegyr,$dataendyr,$datachunk,$staticfile \
   $argu_test12 || goto err

set argu_test13 = "$shared_opt $pregrid_opt -n -r era_interim -v tau_x,tau_y,t_surf -C clim -f 12,0 -F 0,12 $default_region plot_std plot_anom_std"
$work_script -o $out_dir $ref_opt \
   -m gfdl_model,$yr1,$yr2,$descriptor,$in_data_dir,$databegyr,$dataendyr,$datachunk,$staticfile \
   $argu_test13 || goto err

set argu_test14 = "$shared_opt $pregrid_opt -n -r era_interim $default_region plot_anom_regr_nino3"
$work_script -o $out_dir $ref_opt \
   -m gfdl_model,$yr1,$yr2,$descriptor,$in_data_dir,$databegyr,$dataendyr,$datachunk,$staticfile \
   $argu_test14 || goto err


# ================ END BODY OF SCRIPT ===============
unset echo

exit 0

err:
   $echo2 "$name aborted on error."
   exit 1
