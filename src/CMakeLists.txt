add_subdirectory(calibration)
add_subdirectory(database)
add_subdirectory(eod)
add_subdirectory(realtime)
add_subdirectory(util)
add_subdirectory(validate)

configure_file(kcor_find_code_version.pro.in kcor_find_code_version.pro)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/kcor_find_code_version.pro DESTINATION src)

file(GLOB PRO_FILES "*.pro")
install(FILES ${PRO_FILES} DESTINATION src)

install(FILES epochs.cfg epochs.spec.cfg DESTINATION src)
