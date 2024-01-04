#!/bin/bash
#$t@$h

echo "Checking if running on a hypervisor..."

# Check for hypervisor flags in CPU info
echo "1. Checking CPU info"
grep -o 'hypervisor' /proc/cpuinfo
if [ $? -eq 0 ]; then
    echo "Hypervisor flag found in CPU info."
else
    echo "No hypervisor flag found in CPU info."
fi

echo "-------------------------------------------------"

# Check DMI data
echo "2. Checking DMI data for virtual machine information..."
sudo dmidecode -t system | grep -E 'Manufacturer|Product'
if [ $? -eq 0 ]; then
    echo "DMI data indicates a virtual machine."
else
    echo "DMI data does not indicate a virtual machine."
fi

echo "-------------------------------------------------"

# Check system messages
echo "3. Checking system messages for hypervisor references..."
dmesg | grep -i hypervisor
if [ $? -eq 0 ]; then
    echo "System messages contain hypervisor references."
else
    echo "No hypervisor references in system messages."
fi

echo "-------------------------------------------------"

# Use systemd-detect-virt
echo "4. Using systemd-detect-virt to detect virtualization..."
virt=$(systemd-detect-virt)
if [ "$virt" != "none" ]; then
    echo "Virtualization detected: $virt"
else
    echo "No virtualization detected by systemd-detect-virt."
fi

echo "-------------------------------------------------"

# Use virt-what
echo "5. Using virt-what to detect virtualization..."
virt_what=$(virt-what)
if [ -n "$virt_what" ]; then
    echo "virt-what detected virtualization: $virt_what"
else
    echo "No virtualization detected by virt-what."
fi

echo "-------------------------------------------------"

# Check for VMware specific modules
echo "6. Checking for VMware specific modules..."
if lsmod | grep -q "vmw_vmci"; then
    echo "VMware modules detected."
else
    echo "No VMware modules detected."
fi

echo "-------------------------------------------------"

# Check for VirtualBox specific modules
echo "7. Checking for VBox"
if lsmod | grep -q "vboxdrv"; then
    echo "VirtualBox modules detected."
else
    echo "No VirtualBox modules detected."
fi

echo "-------------------------------------------------"

# Check for Hypervisor Specific Devices (example: Hyper-V)
echo "8. Checking for HyperV, etc"
if [ -d /sys/class/misc/vmbus/ ]; then
    echo "Hyper-V specific devices found."
else
    echo "No Hyper-V specific devices found."
fi

echo "-------------------------------------------------"
echo "Hypervisor check complete."
