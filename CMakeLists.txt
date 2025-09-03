cmake_minimum_required(VERSION 3.28)
project($ENV{PROJECT_NAME})

# Packaging

# add you binaries here
if(WIN32)
    set(EXE_SUFFIX ".exe")
else()
    set(EXE_SUFFIX "")
endif()

install(FILES "target/${TARGET}/${VARIANT}/backend${EXE_SUFFIX}" DESTINATION bin)

get_filename_component(CPACK_PACKAGE_NAME ${CMAKE_CURRENT_SOURCE_DIR} NAME)
set(CPACK_PACKAGE_VERSION "0.0.1")
set(CPACK_PACKAGE_DESCRIPTION "bla")
set(CPACK_PACKAGE_VENDOR "bla")
set(CPACK_PACKAGE_CONTACT "bla")
set(CPACK_PACKAGE_LICENSE "bla")
set(CPACK_PACKAGE_EXECUTABLES "backend")
set(CPACK_GENERATOR "TGZ;STGZ")

if(UNIX AND NOT APPLE)
    find_program(RPMBUILD_EXECUTABLE rpmbuild)
    find_program(DPKG_EXECUTABLE dpkg)
    if(RPMBUILD_EXECUTABLE)
        list(APPEND CPACK_GENERATOR "RPM")
    endif()
    if(DPKG_EXECUTABLE)
        list(APPEND CPACK_GENERATOR "DEB")
    endif()
    set(CPACK_GENERATOR "TGZ;STGZ;${CPACK_GENERATOR}")
endif()

include(CPack)