#!/bin/bash
# ========================================================================
# Initialization of IIC Open-Source EDA Environment for Ubuntu WSL2 and Mac M core Series
# This script is for use with SKY130.
# ========================================================================

# Define setup environment
# ------------------------
export PDK_ROOT="$HOME/pdk"
export MY_STDCELL=sky130_fd_sc_hd
export SRC_DIR="$HOME/src"
my_path=$(realpath "$0")
my_dir=$(dirname "$my_path")
export SCRIPT_DIR="$my_dir"
export PDK=sky130A
export VOLARE_H=bdc9412b3e468c102d01b7cf6337be06ec6e9c9a

# for Mac
# ------------------------
if [ "$(uname)" == 'Darwin' ]; then
  VER=`sw_vers -productVersion | awk -F. '{ print $1 "." $2 }'`
  case $VER in
    "14.0")
      export MAC_OS_NAME=Sonoma
      ;;
    "15.0")
      export MAC_OS_NAME=Sequoia
      ;;
    *)
      echo "Your Mac OS Version ($VER) is not supported."
      exit 1
      ;;
  esac
fi

# --------
echo ""
echo ">>>> Initializing..."
echo ""

# Copy KLayout Configurations
# ----------------------------------
if [ ! -d "$HOME/.klayout" ]; then
	# cp -rf klayout $HOME/.klayout
	mkdir $HOME/.klayout
	cp -f sky130/klayoutrc $HOME/.klayout
	cp -rf sky130/macros $HOME/.klayout/macros
	cp -rf sky130/drc $HOME/.klayout/drc
	cp -rf sky130/lvs $HOME/.klayout/lvs
	cp -rf sky130/pymacros $HOME/.klayout/pymacros
	mkdir $HOME/.klayout/libraries
fi

# Delete previous PDK
# ---------------------------------------------
if [ -d "$PDK_ROOT" ]; then
	echo ">>>> Delete previous PDK"
	sudo rm -rf "$PDK_ROOT"
	sudo mkdir "$PDK_ROOT"
	sudo chown "$USER:staff" "$PDK_ROOT"
fi

# Install GDSfactory and PDK
# -----------------------------------
if [ "$(uname)" == 'Darwin' ]; then
	OS='Mac'
	python3 -m pip install sky130 flayout pip-autoremove --break-system-packages
#	python3 -m pip install gdsfactory pip-autoremove --break-system-packages
	volare enable --pdk sky130 $VOLARE_H
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
	OS='Linux'
	pip install sky130 flayout
#	pip install gdsfactory
	volare enable --pdk sky130 $VOLARE_H
elif [ "$(expr substr $(uname -s) 1 10)" == 'MINGW32_NT' ]; then
	OS='Cygwin'
	echo "Your platform ($(uname -a)) is not supported."
	exit 1
else
	echo "Your platform ($(uname -a)) is not supported."
	exit 1
fi



# Create .spiceinit
# -----------------
{
	echo "set num_threads=$(nproc)"
	echo "set ngbehavior=hsa"
	echo "set ng_nomodcheck"
} > "$HOME/.spiceinit"

# Create iic-init.sh
# ------------------
if [ ! -d "$HOME/.xschem" ]; then
	mkdir "$HOME/.xschem"
fi
{
	echo "export PDK_ROOT=$PDK_ROOT"
	echo "export PDK=$PDK"
	echo "export STD_CELL_LIBRARY=$MY_STDCELL"
} >> "$HOME/.bashrc"

# Copy various things
# -------------------
export PDK_ROOT=$PDK_ROOT
export PDK=$PDK
export STD_CELL_LIBRARY=$MY_STDCELL
cp -f $PDK_ROOT/$PDK/libs.tech/xschem/xschemrc $HOME/.xschem
cp -f $PDK_ROOT/$PDK/libs.tech/magic/$PDK.magicrc $HOME/.magicrc
# cp -rf $PDK_ROOT/$PDK/libs.tech/klayout/drc $HOME/.klayout/drc
# cp -rf $PDK_ROOT/$PDK/libs.tech/klayout/lvs $HOME/.klayout/lvs
# cp -rf $PDK_ROOT/$PDK/libs.tech/klayout/pymacros $HOME/.klayout/pymacros
# cp -rf $PDK_ROOT/$PDK/libs.tech/klayout/scripts $HOME/.klayout/scripts
mkdir $HOME/.klayout/tech/
mkdir $HOME/.klayout/tech/sky130
cp -f $PDK_ROOT/$PDK/libs.tech/klayout/tech/$PDK.lyp $HOME/.klayout/tech/sky130/sky130.lyp
cp -f $PDK_ROOT/$PDK/libs.tech/klayout/tech/$PDK.lyt $HOME/.klayout/tech/sky130/sky130.lyt
cp -f $PDK_ROOT/$PDK/libs.tech/klayout/tech/$PDK.map $HOME/.klayout/tech/sky130/sky130.map
cp -f $PDK_ROOT/$PDK/libs.ref/sky130_fd_pr/gds/sky130_fd_pr.gds $HOME/.klayout/libraries/
cp -f $PDK_ROOT/$PDK/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds $HOME/.klayout/libraries/
cp -f $PDK_ROOT/$PDK/libs.ref/sky130_fd_sc_hvl/gds/sky130_fd_sc_hvl.gds $HOME/.klayout/libraries/

# Fix paths in xschemrc to point to correct PDK directory
# -------------------------------------------------------
if [ "$(uname)" == 'Darwin' ]; then
	OS='Mac'
	sed -i -e'' 's/^set SKYWATER_MODELS/# set SKYWATER_MODELS/g' "$HOME/.xschem/xschemrc"
	echo 'set SKYWATER_MODELS $env(PDK_ROOT)/$env(PDK)/libs.tech/ngspice' >> "$HOME/.xschem/xschemrc"
	sed -i -e '' 's/^set SKYWATER_STDCELLS/# set SKYWATER_STD_CELLS/g' "$HOME/.xschem/xschemrc"
	echo 'set SKYWATER_STDCELLS $env(PDK_ROOT)/$env(PDK)/libs.ref/sky130_fd_sc_hd/spice' >> "$HOME/.xschem/xschemrc"
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
	OS='Linux'
	sed -i -e 's/^set SKYWATER_MODELS/# set SKYWATER_MODELS/g' "$HOME/.xschem/xschemrc"
	echo 'set SKYWATER_MODELS $env(PDK_ROOT)/$env(PDK)/libs.tech/ngspice' >> "$HOME/.xschem/xschemrc"
	sed -i -e 's/^set SKYWATER_STDCELLS/# set SKYWATER_STD_CELLS/g' "$HOME/.xschem/xschemrc"
	echo 'set SKYWATER_STDCELLS $env(PDK_ROOT)/$env(PDK)/libs.ref/sky130_fd_sc_hd/spice' >> "$HOME/.xschem/xschemrc"
elif [ "$(expr substr $(uname -s) 1 10)" == 'MINGW32_NT' ]; then
	OS='Cygwin'
	echo "Your platform ($(uname -a)) is not supported."
	exit 1
else
	echo "Your platform ($(uname -a)) is not supported."
	exit 1
fi


# Finished
# --------
echo ""
echo ">>>> All done. Please restart or re-read .bashrc"
echo ""
