##
########################################################################################################################
#
#  Copyright (C) 2021 Advanced Micro Devices, Inc. All rights reserved.
#
########################################################################################################################
set(supported_package_types
  DEB
  RPM
)

if(NOT PACKAGE_NAME)
  message(WARNING "PACKAGE_NAME is not specifiled, default is amdvlk")
  set(PACKAGE_NAME "amdvlk")
endif()

if(NOT PACKAGE_VERSION)
  message(WARNING "PACKAGE_VERSION is not specified, default is 1.0")
  set(PACKAGE_VERSION "1.0")
endif()

function(identifyPackageType)
  if(NOT PACKAGE_TYPE)
      identifyPackageTypeFromPlatform()
  endif()

  if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
#if VKI_CLOSED_SOURCE
    if(PACKAGE_NAME STREQUAL "vulkan-amdgpu-pro")
      set(CMAKE_INSTALL_PREFIX "/opt/amdgpu-pro" CACHE PATH "cmake install prefix" FORCE)
    elseif(PACKAGE_NAME STREQUAL "vulkan-amdgpu")
      set(CMAKE_INSTALL_PREFIX "/opt/amdgpu" CACHE PATH "cmake install prefix" FORCE)
    else()
#endif
    set(CMAKE_INSTALL_PREFIX "/usr" CACHE PATH "cmake install prefix" FORCE)
#if VKI_CLOSED_SOURCE
    endif()
#endif
    if(TARGET_ARCHITECTURE_BITS EQUAL 64)
      if(PACKAGE_TYPE STREQUAL "DEB")
	set(CMAKE_INSTALL_LIBDIR "lib/x86_64-linux-gnu" CACHE PATH "cmake install libdir" FORCE)
      elseif(PACKAGE_TYPE STREQUAL "RPM")
        set(CMAKE_INSTALL_LIBDIR "lib64" CACHE PATH "cmake install libdir" FORCE)
      endif()
    elseif(TARGET_ARCHITECTURE_BITS EQUAL 32)
      if(PACKAGE_TYPE STREQUAL "DEB")
        set(CMAKE_INSTALL_LIBDIR "lib/i386-linux-gnu" CACHE PATH "cmake install libdir" FORCE)
      elseif(PACKAGE_TYPE STREQUAL "RPM")
        set(CMAKE_INSTALL_LIBDIR "lib" CACHE PATH "cmake install libdir" FORCE)
      endif()
    endif()
  endif()
  if(NOT ${PACKAGE_TYPE} IN_LIST supported_package_types)
    message(WARNING "Selected an unsupported package type, please choose from this list: ${supported_package_types}")
  endif()

  findPackagingTool()
endfunction()

function(identifyPackageTypeFromPlatform)
  find_program(lsb_release_exec lsb_release)

  if(NOT "${lsb_release_exec}" STREQUAL "lsb_release_exec_NOTFOUND")
    execute_process(COMMAND ${lsb_release_exec} -is
                    OUTPUT_VARIABLE lsb_release_id_short
                    OUTPUT_STRIP_TRAILING_WHITESPACE
    )
  endif()

  set(deb_distros
    Ubuntu
    Debian
  )

  set(rpm_distros
    SUSE
    CentOS
    RedHat
    RedHatEnterprise
    RedHatEnterpriseWorkstation
  )

  if("${lsb_release_id_short}" IN_LIST deb_distros)
    set(platform_package_type "DEB")
  elseif("${lsb_release_id_short}" IN_LIST rpm_distros)
    set(platform_package_type "RPM")
  else()
    set(platform_package_type "TGZ")
    message(WARNING
      "Failed to identify Linux flavor, either lsb_release is missing or we couldn't identify your distro.\n"
      "The package target will now generate TGZ, if you want to generate native packages please install lsb_release, "
      "or choose a different package type through the CMake variable PACKAGE_TYPE; available values are DEB, RPM"
    )
  endif()
  set(PACKAGE_TYPE "${platform_package_type}" CACHE STRING "platform packing type" FORCE)
endfunction()

function(findPackagingTool)
  if(PACKAGE_TYPE STREQUAL "DEB")
    unset(PACKAGING_TOOL_PATH_INTERNAL CACHE)
    unset(deb_packaging_tool CACHE)
    find_program(deb_packaging_tool dpkg)

    if("${deb_packaging_tool}" STREQUAL "deb_packaging_tool-NOTFOUND")
      message(WARNING "Packaging tool dpkg needed to create DEB packages has not been found, please install it if you want to create packages")
    endif()
  elseif(PACKAGE_TYPE STREQUAL "RPM")
    unset(PACKAGING_TOOL_PATH_INTERNAL CACHE)
    unset(rpm_packaging_tool CACHE)
    find_program(rpm_packaging_tool rpmbuild)

    if("${rpm_packaging_tool}" STREQUAL "rpm_packaging_tool-NOTFOUND")
      message(WARNING "Packaging tool rpmbuild needed to create RPM packages has not been found, please install it if you want to create packages")
    endif()
  endif()
endfunction()

function(generateInstallTargets)
  install(FILES ${CMAKE_BINARY_DIR}/icd/amd_icd${TARGET_ARCHITECTURE_BITS}.json COMPONENT icd DESTINATION /etc/vulkan/icd.d)
  install(FILES ${CMAKE_BINARY_DIR}/icd/amd_icd${TARGET_ARCHITECTURE_BITS}.json COMPONENT icd DESTINATION /etc/vulkan/implicit_layer.d)
#if VKI_CLOSED_SOURCE
  if(PACKAGE_NAME STREQUAL "vulkan-amdgpu-pro" OR PACKAGE_NAME STREQUAL "vulkan-amdgpu")
    if(EXISTS ${CMAKE_SOURCE_DIR}/copyright)
      install(FILES ${CMAKE_SOURCE_DIR}/copyright COMPONENT icd DESTINATION share/doc/${PACKAGE_NAME})
    else()
      message(WARNING "copyright is not found under ${CMAKE_SOURCE_DIR}, please put it there")
    endif()
  elseif(PACKAGE_NAME STREQUAL "amdvlk")
#endif
  install(FILES ${CMAKE_SOURCE_DIR}/LICENSE.txt COMPONENT icd DESTINATION share/doc/${PACKAGE_NAME})
#if VKI_CLOSED_SOURCE
  endif()
#endif
  if(PACKAGE_TYPE STREQUAL "DEB")
    if(EXISTS ${CMAKE_SOURCE_DIR}/changelog.Debian.gz)
      install(FILES ${CMAKE_SOURCE_DIR}/changelog.Debian.gz COMPONENT icd DESTINATION share/doc/${PACKAGE_NAME})
    else()
      message(WARNING "changelog.Debian.gz is not found under ${CMAKE_SOURCE_DIR}, please put it there")
    endif()
  endif()
  install(FILES ${CMAKE_BINARY_DIR}/icd/amdvlk${TARGET_ARCHITECTURE_BITS}.so COMPONENT icd DESTINATION ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR})
endfunction()

function(generatePackageTarget)
#if VKI_CLOSED_SOURCE
  if(PACKAGE_NAME STREQUAL "vulkan-amdgpu-pro")
    set(PACKAGE_DESCRIPTION "AMDGPU Pro Vulkan driver")
  elseif(PACKAGE_NAME STREQUAL "vulkan-amdgpu")
    set(PACKAGE_DESCRIPTION "AMDGPU Vulkan driver")
  elseif(PACKAGE_NAME STREQUAL "amdvlk")
#endif
  set(PACKAGE_DESCRIPTION "AMD Open Source Driver for Vulkan")
#if VKI_CLOSED_SOURCE
  endif()
#endif
  set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PACKAGE_DESCRIPTION}")
  set(CPACK_PACKAGE_NAME "${PACKAGE_NAME}")
  set(CPACK_PACKAGE_VENDOR "Advanced Micro Devices (AMD)")
  set(CPACK_PACKAGE_CONTACT "gpudriverdevsupport@amd.com")
#if VKI_CLOSED_SOURCE
  if(PACKAGE_NAME STREQUAL "vulkan-amdgpu-pro" OR PACKAGE_NAME STREQUAL "vulkan-amdgpu")
    set(CPACK_PACKAGE_HOMEPAGE_URL "http://www.amd.com")
  else()
#endif
  set(CPACK_PACKAGE_HOMEPAGE_URL "https://github.com/GPUOpen-Drivers/AMDVLK")
#if VKI_CLOSED_SOURCE
  endif()
#endif
  set(CPACK_PACKAGE_RELOCATABLE OFF)
  set(CPACK_GENERATOR "${PACKAGE_TYPE}")
  set(CPACK_COMPONENTS_ALL "icd")
  set(CPACK_INSTALL_CMAKE_PROJECTS "${CMAKE_BINARY_DIR};${CMAKE_PROJECT_NAME};icd;/")
  if(CPACK_GENERATOR STREQUAL "DEB")
    if(TARGET_ARCHITECTURE_BITS EQUAL 64)
      set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
    elseif(TARGET_ARCHITECTURE_BITS EQUAL 32)
      set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "i386")
    endif()
    set(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")
    set(CPACK_DEBIAN_PACKAGE_SECTION "libs")
#if VKI_CLOSED_SOURCE
    if(PACKAGE_NAME STREQUAL "vulkan-amdgpu-pro")
      set(CPACK_DEBIAN_PACKAGE_DEPENDS "libc6 (>=2.17), libgcc1 (>= 1:3.4), libstdc++6 (>= 5.2), libwayland-amdgpu-client0, amdgpu-pro-core")
    elseif(PACKAGE_NAME STREQUAL "vulkan-amdgpu")
      set(CPACK_DEBIAN_PACKAGE_DEPENDS "libc6 (>=2.17), libgcc1 (>= 1:3.4), libstdc++6 (>= 5.2), libwayland-amdgpu-client0, amdgpu-core")
    else()
#endif
    set(CPACK_DEBIAN_PACKAGE_DEPENDS "libc6 (>=2.17), libgcc1 (>= 1:3.4), libstdc++6 (>= 5.2)")
#if VKI_CLOSED_SOURCE
    endif()
#endif
    if(PACKAGE_RELEASE)
      set(CPACK_PACKAGE_VERSION "${PACKAGE_VERSION}-${PACKAGE_RELEASE}")
    else()
      set(CPACK_PACKAGE_VERSION "${PACKAGE_VERSION}")
    endif()
    set(CPACK_DEBIAN_PACKAGE_HOMEPAGE "${CPACK_PACKAGE_HOMEPAGE_URL}")
    set(CPACK_DEBIAN_FILE_NAME "${CPACK_PACKAGE_NAME}_${CPACK_PACKAGE_VERSION}_${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}.deb")
  elseif(CPACK_GENERATOR STREQUAL "RPM")
    if(TARGET_ARCHITECTURE_BITS EQUAL 64)
      set(CPACK_RPM_PACKAGE_ARCHITECTURE "x86_64")
    elseif(TARGET_ARCHITECTURE_BITS EQUAL 32)
      set(CPACK_RPM_PACKAGE_ARCHITECTURE "i386")
    endif()
    set(CPACK_PACKAGE_VERSION "${PACKAGE_VERSION}")
    set(CPACK_RPM_PACKAGE_RELEASE "${PACKAGE_RELEASE}")
    if(CPACK_RPM_PACKAGE_RELEASE)
      set(CPACK_RPM_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CPACK_RPM_PACKAGE_RELEASE}.${CPACK_RPM_PACKAGE_ARCHITECTURE}.rpm")
    else()
      set(CPACK_RPM_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}.${CPACK_RPM_PACKAGE_ARCHITECTURE}.rpm")
    endif()
    set(CPACK_RPM_PACKAGE_DESCRIPTION "${PACKAGE_DESCRIPTION}")
    set(CPACK_RPM_PACKAGE_GROUP "System Environment/Libraries")
#if VKI_CLOSED_SOURCE
    if(PACKAGE_NAME STREQUAL "vulkan-amdgpu-pro")
      set(CPACK_RPM_PACKAGE_LICENSE "AMD GPU PRO EULA")
    else()
#endif
    set(CPACK_RPM_PACKAGE_LICENSE "MIT")
#if VKI_CLOSED_SOURCE
    endif()
#endif
  endif()

  include(CPack)

  if(PACKAGE_TYPE STREQUAL "RPM")
    set(PACKAGE_FILE_NAME ${CPACK_RPM_FILE_NAME})
    add_custom_command(OUTPUT ${PACKAGE_FILE_NAME} COMMAND ${CMAKE_COMMAND} --build . --target package)
  elseif(PACKAGE_TYPE STREQUAL "DEB")
    set(PACKAGE_FILE_NAME ${CPACK_DEBIAN_FILE_NAME})
    # Add "Multi-Arch: same" to deb control file
    file(WRITE ${CMAKE_BINARY_DIR}/fixDebPackage.sh
      "rm -rf debPackageRepack && mkdir debPackageRepack
cd debPackageRepack
cp ../${PACKAGE_FILE_NAME} .
ar x ${PACKAGE_FILE_NAME}
SUFFIX=\"gz\"
if [ -f \"control.tar.xz\" ]; then
    SUFFIX=\"xz\"
fi
mkdir DEBIAN && tar xf control.tar.$SUFFIX -C DEBIAN
echo Multi-Arch: same | tee -a DEBIAN/control
sed -i '/^$/d' DEBIAN/control
if [ \"$SUFFIX\" = \"xz\" ]; then
    tar -C DEBIAN -cJf control.tar.xz .
else
    tar -C DEBIAN -cf control.tar . && gzip -f control.tar
fi
ar rcs ${PACKAGE_FILE_NAME} debian-binary control.tar.$SUFFIX data.tar.$SUFFIX
cp ${PACKAGE_FILE_NAME} ../"
    )
    add_custom_command(OUTPUT ${PACKAGE_FILE_NAME}
                       COMMAND ${CMAKE_COMMAND} --build . --target package
                       COMMAND sh ${CMAKE_BINARY_DIR}/fixDebPackage.sh
    )
 endif()

 add_custom_target(makePackage DEPENDS ${PACKAGE_FILE_NAME})
endfunction()
