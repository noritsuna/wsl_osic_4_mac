#!/bin/bash
# ========================================================================
# Initialization of IIC Open-Source EDA Environment for Ubuntu WSL2 and macOS.
# This script is for use with GF180MCU.
# ========================================================================

# Define setup environment
# ------------------------
export PDK_ROOT="$HOME/pdk"
export MY_STDCELL=gf180mcu_fd_sc_mcu7t5v0
export SRC_DIR="$HOME/src"
my_path=$(realpath "$0")
my_dir=$(dirname "$my_path")
export SCRIPT_DIR="$my_dir"
export PDK=gf180mcuD
export VOLARE_H=bdc9412b3e468c102d01b7cf6337be06ec6e9c9a

# for Mac
if [ "$(uname)" == 'Darwin' ]; then
  VER=`sw_vers -productVersion | awk -F. '{ print $1 }'`
  case $VER in
    "14")
      export MAC_OS_NAME=Sonoma
      ;;
    "15")
      export MAC_OS_NAME=Sequoia
      ;;
    *)
      echo "Your Mac OS Version ($VER) is not supported."
      exit 1
      ;;
  esac
  export MAC_ARCH_NAME=`uname -m`
fi
export TCL_VERSION=8.6.14
export TK_VERSION=8.6.14
export GTK_VERSION=3.24.42
export CC_VERSION=-14
export CXX_VERSION=-14


# --------
echo ""
echo ">>>> Initializing..."
echo ""

echo ">>>> Installing Volare"
if [ ! -d "$SRC_DIR/volare" ]; then
	git clone https://github.com/efabless/volare.git "$SRC_DIR/volare"
	cd "$SRC_DIR/volare" || exit
else
	echo ">>>> Updating xschem"
	cd "$SRC_DIR/volare" || exit
	git pull
fi
python3 -m pip install --upgrade --no-cache-dir volare


# Copy KLayout Configurations
# ----------------------------------
if [ ! -d "$HOME/.klayout" ]; then
	# cp -rf klayout $HOME/.klayout
	mkdir $HOME/.klayout
	mkdir $HOME/.klayout/libraries
fi
cd $my_dir
cp -f gf180mcu/klayoutrc $HOME/.klayout
cp -rf gf180mcu/macros $HOME/.klayout/macros
cp -rf gf180mcu/tech $HOME/.klayout/tech
cp -rf gf180mcu/lvs $HOME/.klayout/lvs
cp -rf gf180mcu/pymacros $HOME/.klayout/pymacros

# Delete previous PDK
# ---------------------------------------------
if [ -d "$PDK_ROOT" ]; then
	echo ">>>> Delete previous PDK"
	sudo rm -rf "$PDK_ROOT"
	sudo mkdir "$PDK_ROOT"
	sudo chown "$USER:staff" "$PDK_ROOT"
fi

# Install PDK
# -----------------------------------
# pip install gdsfactory
if [ "$(uname)" == 'Darwin' ]; then
	OS='Mac'
	python3 -m pip install gf180 pip-autoremove --break-system-packages
	volare enable --pdk gf180mcu $VOLARE_H
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
	OS='Linux'
	pip install gf180
	volare enable --pdk gf180mcu $VOLARE_H
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
if [ "$(uname)" == 'Darwin' ]; then
	OS='Mac'
	{
		echo "export PDK_ROOT=$PDK_ROOT"
		echo "export PDK=$PDK"
		echo "export STD_CELL_LIBRARY=$MY_STDCELL"
	} >> "$HOME/.zshrc"
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
	OS='Linux'
	{
		echo "export PDK_ROOT=$PDK_ROOT"
		echo "export PDK=$PDK"
		echo "export STD_CELL_LIBRARY=$MY_STDCELL"
	} >> "$HOME/.bashrc"
elif [ "$(expr substr $(uname -s) 1 10)" == 'MINGW32_NT' ]; then
	OS='Cygwin'
	echo "Your platform ($(uname -a)) is not supported."
	exit 1
else
	echo "Your platform ($(uname -a)) is not supported."
	exit 1
fi


# Copy various things
# -------------------
export PDK_ROOT=$PDK_ROOT
export PDK=$PDK
export STD_CELL_LIBRARY=$MY_STDCELL
cp -f $PDK_ROOT/$PDK/libs.tech/xschem/xschemrc $HOME/.xschem
cp -f $PDK_ROOT/$PDK/libs.tech/magic/$PDK.magicrc $HOME/.magicrc
cp -rf $PDK_ROOT/$PDK/libs.tech/klayout/drc $HOME/.klayout/drc
# cp -rf $PDK_ROOT/$PDK/libs.tech/klayout/lvs $HOME/.klayout/lvs
cp -rf $PDK_ROOT/$PDK/libs.tech/klayout/lvs/rule_decks $HOME/.klayout/lvs/rule_decks
# cp -rf $PDK_ROOT/$PDK/libs.tech/klayout/pymacros $HOME/.klayout/pymacros
# cp -rf $PDK_ROOT/$PDK/libs.tech/klayout/scripts $HOME/.klayout/scripts
cp -f $PDK_ROOT/$PDK/libs.ref/gf180mcu_fd_sc_mcu7t5v0/gds/gf180mcu_fd_sc_mcu7t5v0.gds $HOME/.klayout/libraries/
cp -f $PDK_ROOT/$PDK/libs.ref/gf180mcu_fd_sc_mcu9t5v0/gds/gf180mcu_fd_sc_mcu9t5v0.gds $HOME/.klayout/libraries/

# Fix paths in xschemrc to point to correct PDK directory
# -------------------------------------------------------
if [ "$(uname)" == 'Darwin' ]; then
	OS='Mac'
	sed -i '' 's/models\/ngspice/$env(PDK)\/libs.tech\/ngspice/g' "$HOME/.xschem/xschemrc"
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
	OS='Linux'
	sed -i 's/models\/ngspice/$env(PDK)\/libs.tech\/ngspice/g' "$HOME/.xschem/xschemrc"
elif [ "$(expr substr $(uname -s) 1 10)" == 'MINGW32_NT' ]; then
	OS='Cygwin'
	echo "Your platform ($(uname -a)) is not supported."
	exit 1
else
	echo "Your platform ($(uname -a)) is not supported."
	exit 1
fi
# echo 'append XSCHEM_LIBRARY_PATH :${PDK_ROOT}/$env(PDK)/libs.tech/xschem' >> "$HOME/.xschem/xschemrc"
echo 'set 180MCU_STDCELLS ${PDK_ROOT}/$env(PDK)/libs.ref/gf180mcu_fd_sc_mcu7t5v0/spice' >> "$HOME/.xschem/xschemrc"
echo 'puts stderr "180MCU_STDCELLS: $180MCU_STDCELLS"' >> "$HOME/.xschem/xschemrc"


# Finished
# --------
echo ""
echo ">>>> All done. Please restart or re-read .bashrc"
echo ""
