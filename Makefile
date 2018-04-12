PROJECT		?= hello

# options: x86 arm
TOOLCHAIN_TARGET    ?= arm

# options: see tool/create_builddir
GENODE_TARGET       ?= focnados_pbxa9

ifneq (,$(findstring if13praktikum, $(shell groups)))
	VAGRANT_BUILD_DIR         ?= $(shell pwd)/build
else
	VAGRANT_BUILD_DIR         ?= /build
endif
VAGRANT_TOOLCHAIN_BUILD_DIR ?= $(VAGRANT_BUILD_DIR)/toolchain-$(TOOLCHAIN_TARGET)
VAGRANT_GENODE_BUILD_DIR    ?= $(VAGRANT_BUILD_DIR)/genode-$(GENODE_TARGET)
VAGRANT_BUILD_CONF           = $(VAGRANT_GENODE_BUILD_DIR)/etc/build.conf
VAGRANT_TOOLS_CONF           = $(VAGRANT_GENODE_BUILD_DIR)/etc/tools.conf

JENKINS_BUILD_DIR           ?= build
JENKINS_TOOLCHAIN_BUILD_DIR ?= $(JENKINS_BUILD_DIR)/toolchain-$(TOOLCHAIN_TARGET)
JENKINS_GENODE_BUILD_DIR    ?= $(JENKINS_BUILD_DIR)/genode-$(GENODE_TARGET)
JENKINS_BUILD_CONF           = $(JENKINS_GENODE_BUILD_DIR)/etc/build.conf
JENKINS_TOOLS_CONF = $(JENKINS_GENODE_BUILD_DIR)/etc/tools.conf

vagrant: ports build_dir

jenkins: foc jenkins_build_dir

# ================================================================
# Genode toolchain. Only needs to be done once per target (x86/arm).
toolchain:
	wget -qO- https://nextcloud.os.in.tum.de/s/oHeGQp3rVk5MPpQ/download | tar xfJ -
#
# ================================================================


# ================================================================
# Download Genode external sources. Only needs to be done once per system.
PORTS_LST = focnados libc lwip stdcxx dde_linux
ports:
ifeq (jenkins, $(USER))
	./tool/ports/prepare_port -j $(PORTS_LST)
else
	./tool/ports/prepare_port -j4 $(PORTS_LST)
endif
#
# ================================================================


# ================================================================
# Genode build process. Rebuild subtargets as needed.

CUSTOM_REPOS = $(wildcard genode-*) $(wildcard ../genode-*) toolchain-host 

build_dir:
#	Create build directory
	tool/create_builddir $(GENODE_TARGET) BUILD_DIR=$(VAGRANT_GENODE_BUILD_DIR)

#	Uncomment libports and dde_linux from etc/build.conf
	for repo in libports dde_linux; do \
		sed -i "/$$repo/s/^#REPOSITORIES/REPOSITORIES/g" $(VAGRANT_BUILD_CONF) ; \
	done

#	Add our custom repositories to etc/build.conf
	for repo in $(CUSTOM_REPOS); do \
		echo "REPOSITORIES += \$$(GENODE_DIR)/../$$repo" >> $(VAGRANT_BUILD_CONF) ; \
	done

#	Speedup of the build process
	echo "MAKE += -j4" >> $(VAGRANT_BUILD_CONF)

#	Add toolchain path to etc/specs.conf
ifneq (,$(findstring if13praktikum, $(shell groups)))
	echo "CROSS_DEV_PREFIX=/var/tmp/usr/local/genode-gcc/bin/genode-arm-" >> $(VAGRANT_TOOLS_CONF)
endif

jenkins_build_dir:
#	Create build directory
	tool/create_builddir $(GENODE_TARGET) BUILD_DIR=$(JENKINS_GENODE_BUILD_DIR)

#	Uncomment libports and dde_linux from etc/build.conf
	for repo in libports dde_linux ; do \
		sed -i "/$$repo/s/^#REPOSITORIES/REPOSITORIES/g" $(JENKINS_BUILD_CONF) ; \
	done

#	Comment defautl start with display from etc/build.conf
	for opt in "-display sdl"; do \
                sed -i "/$$opt/s/^/#/g" $(JENKINS_BUILD_CONF) ; \
        done

#	Add our custom repositories to etc/build.conf
	for repo in $(CUSTOM_REPOS); do \
		echo "REPOSITORIES += \$$(GENODE_DIR)/../$$repo" >> $(JENKINS_BUILD_CONF) ; \
	done

#	Add costum repos within Genode repos
	for repo in hello_tutorial; do \
                echo "REPOSITORIES += \$$(GENODE_DIR)/repos/$$repo" >> $(JENKINS_BUILD_CONF) ; \
        done

#	Speedup of the build process
ifeq (jenkins, $(USER))
	echo "MAKE += -j" >> $(JENKINS_BUILD_CONF)
else
	echo "MAKE += -j4" >> $(JENKINS_BUILD_CONF)
endif

#	Add toolchain path to etc/specs.conf
	echo "CROSS_DEV_PREFIX=$(shell pwd)/usr/local/genode-gcc/bin/genode-arm-" >> $(JENKINS_TOOLS_CONF)


# Delete build directory for all target systems. In some cases, subfolders in the contrib directory might be corrupted. Remove manually and re-prepare if necessary.
clean:
	$(MAKE) -C $(VAGRANT_GENODE_BUILD_DIR) cleanall

jenkins_clean:
	$(MAKE) -C $(JENKINS_GENODE_BUILD_DIR) cleanall
#
# ================================================================


# ================================================================
# Run Genode with an active dom0 server.
run:
	$(MAKE) -C $(VAGRANT_GENODE_BUILD_DIR) run/$(PROJECT) #declare which run file to run
	rm -f /var/lib/tftpboot/image.elf
	rm -f /var/lib/tftpboot/modules.list
	rm -rf /var/lib/tftpboot/genode
	cp $(VAGRANT_GENODE_BUILD_DIR)/var/run/$(PROJECT)/image.elf /var/lib/tftpboot/
	cp $(VAGRANT_GENODE_BUILD_DIR)/var/run/$(PROJECT)/modules.list /var/lib/tftpboot/
	cp -R $(VAGRANT_GENODE_BUILD_DIR)/var/run/$(PROJECT)/genode /var/lib/tftpboot/

jenkins_run:
	$(MAKE) -C $(JENKINS_GENODE_BUILD_DIR) run/$(PROJECT) #declare which run file to run
	rm -f /var/lib/tftpboot/image.elf
	rm -f /var/lib/tftpboot/modules.list
	rm -rf /var/lib/tftpboot/genode
	cp $(JENKINS_GENODE_BUILD_DIR)/var/run/$(PROJECT)/image.elf /var/lib/tftpboot/
	cp $(JENKINS_GENODE_BUILD_DIR)/var/run/$(PROJECT)/modules.list /var/lib/tftpboot/
	cp -R $(JENKINS_GENODE_BUILD_DIR)/var/run/$(PROJECT)/genode /var/lib/tftpboot/

#
# ================================================================

# ================================================================
# Requiered packages for relaunched systems
packages:
	sudo apt-get update -qq
	sudo apt-get install -qq libncurses5-dev texinfo autogen autoconf2.64 g++ libexpat1-dev \
			     flex bison gperf cmake libxml2-dev libtool zlib1g-dev libglib2.0-dev \
			     make pkg-config gawk subversion expect git libxml2-utils syslinux \
			     xsltproc yasm iasl lynx unzip qemu tftpd-hpa isc-dhcp-server
#
# ================================================================

# ================================================================
# VDE setup. Do once per system session. DHCP is optional.
vde: vde-stop
	@vde_switch -d -s /tmp/switch1 -M /tmp/mgmt
	@sudo vde_tunctl -u $(USER) -t tap0
	@sudo ip link set dev tap0 address 76:5e:06:6a:7e:87
	@sudo ifconfig tap0 10.200.40.10 up
	@vde_plug2tap --daemon -s /tmp/switch1 tap0
	@sudo cp config-data/dhcpd.conf /etc/dhcp/dhcpd.conf
	@sudo cp config-data/isc-dhcp-server /etc/default/isc-dhcp-server
	@sudo service isc-dhcp-server start

vde-stop:
	@-pkill vde_switch
	@-sudo vde_tunctl -d tap0
	@-rm -rf /tmp/switch1
	@sudo service isc-dhcp-server stop

#Needs rework to use isc-dhcp instead
dhcp: dhcp-stop
	@slirpvde -d -s /tmp/switch1 -dhcp

dhcp-stop:
	@-pkill slirpvde

# Cleanup network shenanigans.
clean-network: dhcp-stop vde-stop
#
# ================================================================

# ================================================================
# Compile task for toolchain host
tasks:
	for task in cond_42 cond_mod hey idle linpack namaste pi tumatmul ; do \
		$(MAKE) -C $(JENKINS_GENODE_BUILD_DIR) $$task ; \
		cp $(JENKINS_GENODE_BUILD_DIR)/$$task/$$task toolchain-host/host_dom0 ; \
	done

