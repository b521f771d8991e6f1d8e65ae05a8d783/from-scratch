cmake_minimum_required(VERSION 3.28)
project(FromScratch)

# Packaging

# add you binaries here
install(FILES "target/$ENV{TARGET}/$ENV{VARIANT}/backend" DESTINATION bin RENAME from-scratch)
install(FILES ".cmake/Sources/Test/TestApp" DESTINATION bin RENAME test-app)

get_filename_component(CPACK_PACKAGE_NAME ${CMAKE_CURRENT_SOURCE_DIR} NAME)
set(CPACK_PACKAGE_VERSION "0.0.1")
set(CPACK_PACKAGE_DESCRIPTION "bla")
set(CPACK_PACKAGE_VENDOR "bla")
set(CPACK_PACKAGE_CONTACT "bla")
set(CPACK_PACKAGE_LICENSE "bla")
set(CPACK_PACKAGE_EXECUTABLES "from-scratch" "FromScratch")
set(CPACK_GENERATOR "TGZ;STGZ")

include(CPack)