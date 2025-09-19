cmake_minimum_required(VERSION 3.28)
project($ENV{PROJECT_NAME})

# Packaging

# add you binaries here
if(WIN32)
    set(EXE_SUFFIX ".exe")
else()
    set(EXE_SUFFIX "")
endif()

install(FILES "target/${TARGET}/${VARIANT}/backend${EXE_SUFFIX}"
        PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE WORLD_EXECUTE
        DESTINATION bin)

get_filename_component(CPACK_PACKAGE_NAME $ENV{PROJECT_NAME} NAME)
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
        set(CPACK_DEBIAN_PACKAGE_DEPENDS "libswiftlang (>= 6.0.3), gnustep-gui-runtime (>= 0.32.0-3)")
    endif()
    set(CPACK_GENERATOR "TGZ;STGZ;${CPACK_GENERATOR}")
endif()

include(CPack)