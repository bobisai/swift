add_swift_host_tool(swift-frontend
  driver.cpp
  autolink_extract_main.cpp
  modulewrap_main.cpp
  swift_api_digester_main.cpp
  swift_indent_main.cpp
  swift_symbolgraph_extract_main.cpp
  swift_api_extract_main.cpp
  SWIFT_COMPONENT compiler
)
target_link_libraries(swift-frontend
                      PRIVATE
                        swiftAPIDigester
                        swiftDriver
                        swiftFrontendTool
                        swiftSymbolGraphGen
                        LLVMBitstreamReader)

swift_create_post_build_symlink(swift-frontend
  SOURCE "swift-frontend${CMAKE_EXECUTABLE_SUFFIX}"
  DESTINATION "swift${CMAKE_EXECUTABLE_SUFFIX}"
  WORKING_DIRECTORY "${SWIFT_RUNTIME_OUTPUT_INTDIR}")

swift_create_post_build_symlink(swift-frontend
  SOURCE "swift-frontend${CMAKE_EXECUTABLE_SUFFIX}"
  DESTINATION "swiftc${CMAKE_EXECUTABLE_SUFFIX}"
  WORKING_DIRECTORY "${SWIFT_RUNTIME_OUTPUT_INTDIR}")

swift_create_post_build_symlink(swift-frontend
  SOURCE "swift-frontend${CMAKE_EXECUTABLE_SUFFIX}"
  DESTINATION "swift-indent${CMAKE_EXECUTABLE_SUFFIX}"
  WORKING_DIRECTORY "${SWIFT_RUNTIME_OUTPUT_INTDIR}")

swift_create_post_build_symlink(swift-frontend
  SOURCE "swift-frontend${CMAKE_EXECUTABLE_SUFFIX}"
  DESTINATION "swift-symbolgraph-extract${CMAKE_EXECUTABLE_SUFFIX}"
  WORKING_DIRECTORY "${SWIFT_RUNTIME_OUTPUT_INTDIR}")

swift_create_post_build_symlink(swift-frontend
  SOURCE "swift-frontend${CMAKE_EXECUTABLE_SUFFIX}"
  DESTINATION "swift-api-extract${CMAKE_EXECUTABLE_SUFFIX}"
  WORKING_DIRECTORY "${SWIFT_RUNTIME_OUTPUT_INTDIR}")

swift_create_post_build_symlink(swift-frontend
  SOURCE "swift-frontend${CMAKE_EXECUTABLE_SUFFIX}"
  DESTINATION "swift-autolink-extract${CMAKE_EXECUTABLE_SUFFIX}"
  WORKING_DIRECTORY "${SWIFT_RUNTIME_OUTPUT_INTDIR}")

swift_create_post_build_symlink(swift-frontend
  SOURCE "swift-frontend${CMAKE_EXECUTABLE_SUFFIX}"
  DESTINATION "swift-api-digester${CMAKE_EXECUTABLE_SUFFIX}"
  WORKING_DIRECTORY "${SWIFT_RUNTIME_OUTPUT_INTDIR}")

add_swift_tool_symlink(swift swift-frontend compiler)
add_swift_tool_symlink(swiftc swift-frontend compiler)
add_swift_tool_symlink(swift-symbolgraph-extract swift-frontend compiler)
add_swift_tool_symlink(swift-api-extract swift-frontend compiler)
add_swift_tool_symlink(swift-autolink-extract swift-frontend autolink-driver)
add_swift_tool_symlink(swift-indent swift-frontend editor-integration)
add_swift_tool_symlink(swift-api-digester swift-frontend compiler)

# If building as part of clang, make sure the headers are installed.
if(NOT SWIFT_BUILT_STANDALONE)
  add_dependencies(swift-frontend clang-resource-headers)
endif()

add_dependencies(compiler swift-frontend)
swift_install_in_component(FILES "${SWIFT_RUNTIME_OUTPUT_INTDIR}/swift${CMAKE_EXECUTABLE_SUFFIX}"
                           DESTINATION "bin"
                           COMPONENT compiler)
swift_install_in_component(FILES "${SWIFT_RUNTIME_OUTPUT_INTDIR}/swiftc${CMAKE_EXECUTABLE_SUFFIX}"
                           DESTINATION "bin"
                           COMPONENT compiler)
swift_install_in_component(FILES "${SWIFT_RUNTIME_OUTPUT_INTDIR}/swift-symbolgraph-extract${CMAKE_EXECUTABLE_SUFFIX}"
                           DESTINATION "bin"
                           COMPONENT compiler)
swift_install_in_component(FILES "${SWIFT_RUNTIME_OUTPUT_INTDIR}/swift-api-extract${CMAKE_EXECUTABLE_SUFFIX}"
                           DESTINATION "bin"
                           COMPONENT compiler)
swift_install_in_component(FILES "${SWIFT_RUNTIME_OUTPUT_INTDIR}/swift-api-digester${CMAKE_EXECUTABLE_SUFFIX}"
                           DESTINATION "bin"
                           COMPONENT compiler)
add_dependencies(autolink-driver swift-frontend)
swift_install_in_component(FILES "${SWIFT_RUNTIME_OUTPUT_INTDIR}/swift-autolink-extract${CMAKE_EXECUTABLE_SUFFIX}"
                           DESTINATION "bin"
                           COMPONENT autolink-driver)
add_dependencies(editor-integration swift-frontend)
swift_install_in_component(FILES "${SWIFT_RUNTIME_OUTPUT_INTDIR}/swift-indent${CMAKE_EXECUTABLE_SUFFIX}"
                           DESTINATION "bin"
                           COMPONENT editor-integration)

