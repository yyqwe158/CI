#!bin/bash
# Copyright 2019, Ahmad Thoriq Najahi "Najahiii" <najahiii@outlook.co.id>
# Copyright 2019, alanndz <alanmahmud0@gmail.com>
# Copyright 2020, Dicky Herlambang "Nicklas373" <herlambangdicky5@gmail.com>
# Copyright 2016-2020, HANA-CI Build Project
# SPDX-License-Identifier: GPL-3.0-or-later

# Kernel host environment
export KBUILD_BUILD_USER=unknownbaka
export KBUILD_BUILD_HOST=Baka-CI
export ARCH=arm64
export TZ=CST-8

# Kernel directory environment
BUILD_GCC=0
BUILD_CLANG=2
BUILD_KERNEL=2
CODENAME="polaris"
IMAGE="$(pwd)/kernel/out/arch/arm64/boot/Image.gz-dtb"
KERNEL="$(pwd)/kernel"
KERNEL_TEMP="$(pwd)/TEMP"
KERNEL_DEVICE="Xiaomi Mix 2s"
KERNEL_BOT=Baka-CI
KERNEL_DATE="$(date +%Y%m%d-%H%M)"
KERNEL_ANDROID_VER="Q"
# KSU version v0.9.5
# KSU_Next version v1.0.4
KERNELSU_VERSION="next-susfs"

# Telegram Bot
TELEGRAM_BOT_ID=${TELEGRAM_BOT}
TELEGRAM_GROUP_ID=${TELEGRAM_GROUP}
TELEGRAM_FILENAME="${KERNEL_NAME}-${CODENAME}-${KERNEL_DATE}.zip"

# Telegram Bot Service || Compiling Notification
function bot_template() {
curl -s -X POST https://api.telegram.org/bot${TELEGRAM_BOT_ID}/sendMessage -d chat_id=${TELEGRAM_GROUP_ID} -d "parse_mode=HTML" -d text="$(
            for POST in "${@}"; do
                echo "${POST}"
            done
          )"
}

# Create Temporary Folder
mkdir TEMP

# Build environment
apt-get update -qq && apt-get install --no-install-recommends -y bc binutils binutils-aarch64-linux-gnu binutils-arm-linux-gnueabi bison flex g++ gcc libssl-dev make patch subversion gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi ca-certificates curl git tar unzip wget zip zstd

# Clang environment
if [ "$BUILD_CLANG" = "1" ]; then
    git clone --depth=1 https://github.com/kdrag0n/proton-clang.git proton-clang
    export CLANG_PATH=$(pwd)/proton-clang/bin
    export PATH=${CLANG_PATH}:${PATH}
    export LD_LIBRARY_PATH="$(pwd)/proton-clang/bin/../lib:$PATH"
    #rm $CLANG_PATH/ld $CLANG_PATH/as
elif [ "$BUILD_CLANG" = "2" ]; then
    # Set the URL to the Android Clang/LLVM Prebuilts README
    URL="https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+/master/README.md"
    # Download the README file
    README=$(curl -s $URL)
    # Extract the version number
    VERSION=$(echo "$README" | grep 'clang-r' | head -1 | grep -oE 'clang-r[0-9]+' | head -1)
    wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/$VERSION.tar.gz -O google-clang.tar.gz
    mkdir google-clang && tar -xzvf google-clang.tar.gz -C google-clang > /dev/null
    export CLANG_PATH=$(pwd)/google-clang/bin
    export PATH=${CLANG_PATH}:${PATH}
    export LD_LIBRARY_PATH="$(pwd)/google-clang/bin/../lib:$PATH"
elif [ "$BUILD_CLANG" = "3" ]; then
    git clone --depth=1 https://github.com/crdroidmod/android_vendor_qcom_proprietary_llvm-arm-toolchain-ship_8.0.6.git snapdragon-llvm
    git clone --depth=1 https://github.com/arter97/arm32-gcc.git toolchain32
    export GCC_32_PATH=$(pwd)/toolchain32/bin
    export CLANG_PATH=$(pwd)/snapdragon-llvm/bin
    export PATH=${CLANG_PATH}:${GCC_32_PATH}:${PATH}
    export LD_LIBRARY_PATH="$(pwd)/snapdragon-llvm/bin/../lib:$PATH"
    apt-get install libtinfo5
    patch -p1 < build/snapdragon-llvm.patch
elif [ "$BUILD_CLANG" = "4" ]; then
    git clone --depth=1 https://gitlab.com/jjpprrrr/prelude-clang prelude-clang
    export CLANG_PATH=$(pwd)/prelude-clang/bin
    export PATH=${CLANG_PATH}:${PATH}
    export LD_LIBRARY_PATH="$(pwd)/prelude-clang/bin/../lib:$PATH"
fi

# GCC environment
if [ "$BUILD_GCC" = "1" ]; then
    git clone --depth=1 https://github.com/milouk/gcc-prebuilt-elf-toolchains.git toolchain
    git clone --depth=1 https://github.com/arter97/arm32-gcc.git toolchain32
    export GCC_PATH=$(pwd)/toolchain/aarch64-linux-elf/bin
    export GCC_32_PATH=$(pwd)/toolchain32/bin
    export PATH=${GCC_PATH}:${GCC_32_PATH}:${PATH}
    export CROSS_COMPILE=aarch64-linux-elf-
elif [ "$BUILD_GCC" = "2" ]; then
    git clone --depth=1 https://github.com/arter97/arm64-gcc.git toolchain
    git clone --depth=1 https://github.com/arter97/arm32-gcc.git toolchain32
    export GCC_PATH=$(pwd)/toolchain/bin
    export GCC_32_PATH=$(pwd)/toolchain32/bin
    export PATH=${GCC_PATH}:${GCC_32_PATH}:${PATH}
    export CROSS_COMPILE=aarch64-elf-
fi

# Kernel environment
if [ "$BUILD_KERNEL" = "1" ]; then
    KERNEL_NAME="Etude"
    KERNEL_SCHED="EAS"
    git clone --depth=1 https://github.com/PixelExperience-Devices/kernel_xiaomi_polaris ${KERNEL}
    sed -i "/CONFIG_CC_WERROR/d" ${KERNEL}/arch/arm64/configs/polaris_defconfig
    sed -i "/Werror/d" ${KERNEL}/drivers/staging/qcacld-3.0/Kbuild
elif [ "$BUILD_KERNEL" = "2" ]; then
    KERNEL_NAME="Utopia"
    KERNEL_BRANCH="staging"
    KERNEL_SCHED="EAS"
    git clone --depth=1 -b ${KERNEL_BRANCH} https://github.com/unknownbaka/utopia_kernel_polaris ${KERNEL}
    sed -i "/CONFIG_CC_WERROR/d" ${KERNEL}/arch/arm64/configs/polaris_defconfig
    #cd ${KERNEL} && git submodule update --init --remote && cd ..
    #patch -p1 < build/ksu_test.patch
    #cd ${KERNEL} && git submodule update --remote && cd KernelSU && git checkout v0.7.6 && cd ../..
    cd ${KERNEL} && git submodule update --init --remote

    # GitHub repository URL
    #REPO_URL="https://github.com/tiann/KernelSU.git"
    # Fetch the latest tag from the repository
    #LATEST_TAG=$(git ls-remote --tags $REPO_URL | cut -d'/' -f3 | sort -V | tail -n1)
    cd ${KERNEL}/KernelSU && git checkout $KERNELSU_VERSION
    cd ../..
fi

# AnyKernel 3
git clone --depth=1 https://github.com/unknownbaka/AnyKernel3

# Import telegram bot environment
function bot_env() {
if [ -a ${KERNEL}/localversion ]; then
    TELEGRAM_KERNEL_LOCALVER=$(cat ${KERNEL}/localversion | cut -c2-)
else
    TELEGRAM_KERNEL_LOCALVER=$(cat ${KERNEL}/out/.config | grep "CONFIG_LOCALVERSION=" | cut -d '"' -f 2 | cut -c2-)
fi
TELEGRAM_KERNEL_VER=$(cat ${KERNEL}/out/.config | grep Linux/arm64 | cut -d " " -f3)
TELEGRAM_CST_VER=$(cat ${KERNEL}/out/include/generated/compile.h | grep UTS_VERSION | cut -d '"' -f2)
TELEGRAM_COMPILER_NAME=$(cat ${KERNEL}/out/include/generated/compile.h | grep LINUX_COMPILE_BY | cut -d '"' -f2)
TELEGRAM_COMPILER_HOST=$(cat ${KERNEL}/out/include/generated/compile.h | grep LINUX_COMPILE_HOST | cut -d '"' -f2)
TELEGRAM_TOOLCHAIN_VER=$(cat ${KERNEL}/out/include/generated/compile.h | grep LINUX_COMPILER | cut -d '"' -f2)
TELEGRAM_TOOLCHAIN_VER=$(cat ${KERNEL}/out/include/generated/compile.h | grep LINUX_COMPILER | cut -d '"' -f2)
TELEGRAM_LINUX_VER=$(grep -a 'Linux version' out/arch/arm64/boot/Image)
}

# Telegram bot message || first notification
function bot_first_compile() {
bot_template   "<b>||------------------${KERNEL_BOT} Build Bot------------------||</b>" \
                "" \
                "<b>${KERNEL_NAME} Kernel build Start!</b>" \
                "" \
                "<b>Device :</b><code> ${KERNEL_DEVICE} </code>" \
                "<b>Android Version :</b><code> ${KERNEL_ANDROID_VER} </code>" \
                "<b>Kernel Branch :</b><code> ${KERNEL_BRANCH} </code>" \
                "<b>Latest commit :</b><code> $(git -C ${KERNEL} --no-pager log --pretty=format:'"%h - %s (%an)"' -1) </code>"
}

function bot_first_compile_() {
bot_template   "<b>||------------------${KERNEL_BOT} Build Bot------------------||</b>" \
                "" \
                "<b>${KERNEL_NAME} Kernel build Start!</b>" \
                "" \
                "<b>Device :</b><code> ${KERNEL_DEVICE} </code>" \
                "<b>Android Version :</b><code> ${KERNEL_ANDROID_VER} </code>" \
                "<b>Kernel Branch :</b><code> ${KERNEL_BRANCH} </code>"
}

# Telegram bot message || bot notification
function bot_complete_compile() {
bot_env
bot_template   "<b>||------------------${KERNEL_BOT} Build Bot------------------||</b>" \
                "" \
                "<b>Linux Version :</b><code> ${TELEGRAM_LINUX_VER} </code>" \
                "<b>Kernel Scheduler :</b><code> ${KERNEL_SCHED} </code>" \
                "<b>Kernel Version :</b><code> Linux ${TELEGRAM_KERNEL_VER} </code>" \
                "<b>Kernel Local Version :</b><code> ${TELEGRAM_KERNEL_LOCALVER} </code>" \
                "<b>Kernel Host :</b><code> ${TELEGRAM_COMPILER_NAME}@${TELEGRAM_COMPILER_HOST} </code>" \
                "<b>Kernel Toolchain :</b><code> ${TELEGRAM_TOOLCHAIN_VER} </code>" \
                "<b>CST Version :</b><code> ${TELEGRAM_CST_VER} </code>"
}

# Telegram bot message || success notification
function bot_build_success() {
bot_template   "<b>${KERNEL_NAME} Kernel build Success!</b>" \
                "" \
                "<b>Compile Time :</b><code> $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) </code>"
}

# Telegram bot message || failed notification
function bot_build_failed() {
bot_template   "<b>${KERNEL_NAME} Kernel build Failed!</b>" \
                "" \
                "<b>Compile Time :</b><code> $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) </code>"
}

# Compile polaris Begin
function run() {
START=$(date +"%s")
bot_first_compile
if [ "$?" != "0" ]; then
	bot_first_compile_
fi
make -s -C ${KERNEL} ${CODENAME}_defconfig O=out
if [ "$BUILD_GCC" = "0" ]; then
    if [ "$BUILD_CLANG" = "3" ]; then
        make -C ${KERNEL} -j$(nproc --all) O=out \
                        CC=clang \
                        CROSS_COMPILE=aarch64-linux-android- \
                        CROSS_COMPILE_ARM32=armv7-linux-androideabi- \
                        2>&1| tee ${KERNEL_TEMP}/compile_success.log \
                        2> tee ${KERNEL_TEMP}/compile_fail.log
    else
        make -C ${KERNEL} -j$(nproc --all) O=out \
                        CC=clang \
                        LD=ld.lld \
                        AR=llvm-ar \
                        NM=llvm-nm \
                        STRIP=llvm-strip \
                        OBJCOPY=llvm-objcopy \
                        OBJDUMP=llvm-objdump \
                        OBJSIZE=llvm-size \
                        READELF=llvm-readelf \
                        HOSTCC=clang \
                        HOSTCXX=clang++ \
                        HOSTAR=llvm-ar \
                        CLANG_TRIPLE=aarch64-linux-gnu- \
                        CROSS_COMPILE=aarch64-linux-gnu- \
                        CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                        2>&1| tee ${KERNEL_TEMP}/compile_success.log \
                        2> tee ${KERNEL_TEMP}/compile_fail.log
    fi
elif [ "$BUILD_GCC" = "2" ]; then
    make -C ${KERNEL} -j$(nproc --all) O=out \
                    2>&1| tee ${KERNEL_TEMP}/compile_success.log \
                    2> tee ${KERNEL_TEMP}/compile_fail.log
else
    make -C ${KERNEL} -j$(nproc --all) O=out \
                    CROSS_COMPILE=aarch64-linux-gnu- \
                    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                    2>&1| tee ${KERNEL_TEMP}/compile_success.log \
                    2> tee ${KERNEL_TEMP}/compile_fail.log
fi
if ! [ -a $IMAGE ]; then
	END=$(date +"%s")
	DIFF=$(($END - $START))
	bot_build_failed
	curl -F chat_id=${TELEGRAM_GROUP_ID} -F document="@${KERNEL_TEMP}/compile_fail.log"  https://api.telegram.org/bot${TELEGRAM_BOT_ID}/sendDocument
	exit 1
fi
END=$(date +"%s")
DIFF=$(($END - $START))
bot_complete_compile
bot_build_success
cp ${IMAGE} AnyKernel3
anykernel
kernel_upload
}

# AnyKernel
function anykernel() {
cd AnyKernel3
sed -i "s/ExampleKernel/${KERNEL_NAME}Kernel/g" anykernel.sh
sed -i "s/DeviceName/${KERNEL_DEVICE}/g" anykernel.sh
sed -i "s/codename/${CODENAME}/g" anykernel.sh
#sed -i "s/do.refresh_rate=/do.refresh_rate=67/g" anykernel.sh
sed -i "s/do.battery_capacity=/do.battery_capacity=4000/g" anykernel.sh
make -j$(nproc --all)
mv Kernel.zip ${KERNEL_TEMP}/${KERNEL_NAME}-${CODENAME}-${KERNEL_DATE}.zip
}

# Upload Kernel
function kernel_upload() {
curl -F chat_id=${TELEGRAM_GROUP_ID} -F document="@${KERNEL_TEMP}/${KERNEL_NAME}-${CODENAME}-${KERNEL_DATE}.zip" https://api.telegram.org/bot${TELEGRAM_BOT_ID}/sendDocument
curl -F chat_id=${TELEGRAM_GROUP_ID} -F document="@${KERNEL_TEMP}/compile_success.log" https://api.telegram.org/bot${TELEGRAM_BOT_ID}/sendDocument
}

# Running
run
