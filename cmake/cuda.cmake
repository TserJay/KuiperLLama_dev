#if (MSVC)
#    # Setting this to true brakes Visual Studio builds.
#    set(CUDA_ATTACH_VS_BUILD_RULE_TO_CUDA_FILE OFF CACHE BOOL "CUDA_ATTACH_VS_BUILD_RULE_TO_CUDA_FILE")
#endif ()
#
#if (CMAKE_VERSION VERSION_GREATER_EQUAL 3.16)
#    include(CheckLanguage)
#    check_language(CUDA)
#    if (CMAKE_CUDA_COMPILER)
#        enable_language(CUDA)
#
#        if (CMAKE_VERSION VERSION_GREATER_EQUAL 3.17)
#            find_package(CUDAToolkit QUIET)
#            set(CUDA_TOOLKIT_INCLUDE ${CUDAToolkit_INCLUDE_DIRS})
#        else ()
#            set(CUDA_FIND_QUIETLY TRUE)
#            find_package(CUDA 9.0)
#        endif ()
#
#        set(CUDA_FOUND TRUE)
#        set(CUDA_VERSION_STRING ${CMAKE_CUDA_COMPILER_VERSION})
#    else ()
#        message(STATUS "No CUDA compiler found")
#    endif ()
#else ()
#    set(CUDA_FIND_QUIETLY TRUE)
#    find_package(CUDA 9.0)
#endif ()
#
#if (CUDA_FOUND)
#    message(STATUS "Found CUDA Toolkit v${CUDA_VERSION_STRING}")
#
#    include(FindCUDA/select_compute_arch)
#    CUDA_DETECT_INSTALLED_GPUS(INSTALLED_GPU_CCS_1)
#    string(STRIP "${INSTALLED_GPU_CCS_1}" INSTALLED_GPU_CCS_2)
#    string(REPLACE " " ";" INSTALLED_GPU_CCS_3 "${INSTALLED_GPU_CCS_2}")
#    string(REPLACE "." "" CUDA_ARCH_LIST "${INSTALLED_GPU_CCS_3}")
#    SET(CMAKE_CUDA_ARCHITECTURES ${CUDA_ARCH_LIST})
#    MESSAGE(STATUS "CMAKE_CUDA_ARCHITECTURES: ${CMAKE_CUDA_ARCHITECTURES}")
#
#    if (DEFINED CMAKE_CUDA_COMPILER_LIBRARY_ROOT_FROM_NVVMIR_LIBRARY_DIR)
#        set(CMAKE_CUDA_COMPILER_LIBRARY_ROOT "${CMAKE_CUDA_COMPILER_LIBRARY_ROOT_FROM_NVVMIR_LIBRARY_DIR}")
#    elseif (EXISTS "${CMAKE_CUDA_COMPILER_TOOLKIT_ROOT}/nvvm/libdevice")
#        set(CMAKE_CUDA_COMPILER_LIBRARY_ROOT "${CMAKE_CUDA_COMPILER_TOOLKIT_ROOT}")
#    elseif (CMAKE_SYSROOT_LINK AND EXISTS "${CMAKE_SYSROOT_LINK}/usr/lib/cuda/nvvm/libdevice")
#        set(CMAKE_CUDA_COMPILER_LIBRARY_ROOT "${CMAKE_SYSROOT_LINK}/usr/lib/cuda")
#    elseif (EXISTS "${CMAKE_SYSROOT}/usr/lib/cuda/nvvm/libdevice")
#        set(CMAKE_CUDA_COMPILER_LIBRARY_ROOT "${CMAKE_SYSROOT}/usr/lib/cuda")
#    else ()
#        message(FATAL_ERROR "Couldn't find CUDA library root.")
#    endif ()
#    unset(CMAKE_CUDA_COMPILER_LIBRARY_ROOT_FROM_NVVMIR_LIBRARY_DIR)
#else ()
#    message(STATUS "CUDA was not found.")
#endif ()


# ============================================================
# Modern CUDA setup (NO FindCUDA, NO auto-detect GPU CC)
# Compatible with CUDA 11.x – 13.x, Ampere + Blackwell
# ============================================================



# ======================   new  ===============================
# MSVC workaround（保留，虽然你在 WSL 下基本用不到）
if (MSVC)
    set(CUDA_ATTACH_VS_BUILD_RULE_TO_CUDA_FILE OFF
            CACHE BOOL "CUDA_ATTACH_VS_BUILD_RULE_TO_CUDA_FILE")
endif ()

# ------------------------------------------------------------
# Enable CUDA language
# ------------------------------------------------------------
include(CheckLanguage)
check_language(CUDA)

if (NOT CMAKE_CUDA_COMPILER)
    message(STATUS "No CUDA compiler found")
    return()
endif ()

enable_language(CUDA)

# ------------------------------------------------------------
# Find CUDA Toolkit (modern way)
# ------------------------------------------------------------
if (CMAKE_VERSION VERSION_GREATER_EQUAL 3.17)
    find_package(CUDAToolkit REQUIRED)
    set(CUDA_FOUND TRUE)
    set(CUDA_VERSION_STRING ${CUDAToolkit_VERSION})
    set(CUDA_TOOLKIT_INCLUDE ${CUDAToolkit_INCLUDE_DIRS})
else ()
    message(FATAL_ERROR "CMake >= 3.17 is required for modern CUDA support")
endif ()

message(STATUS "Found CUDA Toolkit v${CUDA_VERSION_STRING}")
message(STATUS "CUDA compiler: ${CMAKE_CUDA_COMPILER}")
message(STATUS "CUDA compiler version: ${CMAKE_CUDA_COMPILER_VERSION}")

# ------------------------------------------------------------
# CUDA Architectures (CRITICAL PART)
# ------------------------------------------------------------
# ❗ Do NOT use:
#   - FindCUDA
#   - CUDA_DETECT_INSTALLED_GPUS
#   - native / +PTX
#
# Always set numeric architectures explicitly.
# ------------------------------------------------------------

if (NOT DEFINED CMAKE_CUDA_ARCHITECTURES)
    # Turing (20xx), Ampere (30xx/A100), Blackwell(50xx)
    set(CMAKE_CUDA_ARCHITECTURES 75 86 120
            CACHE STRING "CUDA architectures" FORCE)
endif ()

message(STATUS "CMAKE_CUDA_ARCHITECTURES: ${CMAKE_CUDA_ARCHITECTURES}")

# ------------------------------------------------------------
# CUDA library root detection (keep your original logic, cleaned)
# ------------------------------------------------------------
if (DEFINED CMAKE_CUDA_COMPILER_LIBRARY_ROOT_FROM_NVVMIR_LIBRARY_DIR)
    set(CMAKE_CUDA_COMPILER_LIBRARY_ROOT
            "${CMAKE_CUDA_COMPILER_LIBRARY_ROOT_FROM_NVVMIR_LIBRARY_DIR}")
elseif (EXISTS "${CMAKE_CUDA_COMPILER_TOOLKIT_ROOT}/nvvm/libdevice")
    set(CMAKE_CUDA_COMPILER_LIBRARY_ROOT
            "${CMAKE_CUDA_COMPILER_TOOLKIT_ROOT}")
elseif (CMAKE_SYSROOT_LINK AND
        EXISTS "${CMAKE_SYSROOT_LINK}/usr/lib/cuda/nvvm/libdevice")
    set(CMAKE_CUDA_COMPILER_LIBRARY_ROOT
            "${CMAKE_SYSROOT_LINK}/usr/lib/cuda")
elseif (EXISTS "${CMAKE_SYSROOT}/usr/lib/cuda/nvvm/libdevice")
    set(CMAKE_CUDA_COMPILER_LIBRARY_ROOT
            "${CMAKE_SYSROOT}/usr/lib/cuda")
else ()
    message(FATAL_ERROR "Couldn't find CUDA library root.")
endif ()

unset(CMAKE_CUDA_COMPILER_LIBRARY_ROOT_FROM_NVVMIR_LIBRARY_DIR)

# ------------------------------------------------------------
# Optional: safer default CUDA flags
# ------------------------------------------------------------
set(CMAKE_CUDA_STANDARD 14)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_EXTENSIONS OFF)

# Enable separable compilation by default if needed
# (targets can override this)
set(CMAKE_CUDA_SEPARABLE_COMPILATION ON)
