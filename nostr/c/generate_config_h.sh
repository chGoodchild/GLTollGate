#!/bin/bash

# Set the PATH environment variable
export PATH="$PATH:/home/username/openwrt/staging_dir/toolchain-mips_24kc_gcc-12.3.0_musl/bin"

# Set the STAGING_DIR environment variable
export STAGING_DIR="/home/username/openwrt/staging_dir"

# Function to determine endianness and generate config.h
generate_config_h() {
    # Check the compiler's endianness configuration
    endianess=$(mips-openwrt-linux-musl-gcc -Q --help=target | grep '^\s*-m\(e[bl]\)' | grep enabled)

    # Create or overwrite config.h
    echo "/* Generated config.h for endianess */" > config.h

    if [[ "$endianess" == *"-meb"* ]]; then
        echo "#define HAVE_BIG_ENDIAN 1" >> config.h
        echo "Configured for Big Endian"
    elif [[ "$endianess" == *"-mel"* ]]; then
        echo "#define HAVE_LITTLE_ENDIAN 1" >> config.h
        echo "Configured for Little Endian"
    else
        echo "#error Unknown Endian" >> config.h
        echo "Endianess could not be determined, check compiler flags!"
    fi
}

# Call the function to generate config.h
generate_config_h
