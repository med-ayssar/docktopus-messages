include(CMakeFindDependencyMacro)
find_dependency(flatbuffers)

set(_docktopus_messages_root "${CMAKE_CURRENT_LIST_DIR}/../../..")

if(NOT TARGET docktopus::messages)
  add_library(docktopus::messages INTERFACE IMPORTED)
  set_target_properties(docktopus::messages PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${_docktopus_messages_root}/include"
    INTERFACE_LINK_LIBRARIES "flatbuffers::flatbuffers"
  )
endif()
