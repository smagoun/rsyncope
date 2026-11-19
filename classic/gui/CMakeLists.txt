# The rsync application with windows: bookmarks, editor, console, server.
add_application(rsyncope
    app.c bookmarks.c console.c editor.c glue.c ../rsync/engine.c gui.r
    CREATOR "rSnc")
target_include_directories(rsyncope PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/../rsync)
target_link_libraries(rsyncope openrsync macposix)
set_target_properties(rsyncope PROPERTIES LINKER_LANGUAGE CXX)
target_link_options(rsyncope PRIVATE "-Wl,--wrap=abort" "-Wl,--wrap=_exit")
