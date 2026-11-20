# The rsync application with windows: bookmarks, editor, console, server.
add_application(rsyncope
    app.c bookmarks.c console.c editor.c glue.c ../rsync/engine.c gui.r
    CREATOR "rSnc")
add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/gui.r.rsrc.bin
    APPEND DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../version.r
        ${CMAKE_CURRENT_SOURCE_DIR}/../version.h)
target_include_directories(rsyncope PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/../rsync)
target_link_libraries(rsyncope openrsync macposix)
set_target_properties(rsyncope PROPERTIES LINKER_LANGUAGE CXX)
target_link_options(rsyncope PRIVATE "-Wl,--wrap=abort" "-Wl,--wrap=_exit")
