cmake_minimum_required(VERSION 3.1)

project(qmlarkdown LANGUAGES CXX)
set(PROJECT_VERSION "0.0.1")

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# cmake macros
include(FeatureSummary)

# Qt5 libs
find_package(Qt5 COMPONENTS Core Qml Quick QuickControls2 WebEngine CONFIG REQUIRED COMPONENTS)

# cmark lib
find_package(PkgConfig REQUIRED)
pkg_check_modules (CMARK REQUIRED libcmark>=0.28.3)

# all sources by type
set(HEADERS
    src/cmarkwrapper.h
)

set(SOURCES
    src/cmarkwrapper.cpp
    src/main.cpp
)

set(RESOURCES
    appdata.qrc
)

# our application
add_executable(qmlarkdown
    ${SOURCES} ${HEADERS} ${RESOURCES}
)

# some target magic added by qtcreator
target_compile_definitions(qmlarkdown
    PRIVATE
        $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>
)

# dependencies
target_link_libraries(qmlarkdown
    PRIVATE
        Qt5::Core
        Qt5::Quick
        Qt5::QuickControls2
        Qt5::WebEngine
        ${CMARK_LIBRARIES}
)

# install application
install(TARGETS qmlarkdown
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# Display feature summary
feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
