cmake_minimum_required(VERSION 3.1)

project(qmlarkdown LANGUAGES CXX)
set(PROJECT_VERSION "0.0.1")

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# cmake macros
include(FeatureSummary)

# Qt5 libs
find_package(Qt5 "5.12.0" COMPONENTS Core Widgets Quick QuickControls2 WebEngine CONFIG REQUIRED COMPONENTS)

# libmarkdown-qt
find_package(MarkdownQt REQUIRED)

# QML wrapper for KF5SyntaxHighlighting
find_package(KSyntaxHighlightingWrapper REQUIRED)

# QML wrapper for Font-Awesome
find_package(FontAweSomeQml REQUIRED)

# all sources by type
set(HEADERS
    src/qthelper.h
)

set(SOURCES
    src/main.cpp
    src/qthelper.cpp
)

set(RESOURCES
    qmlarkdown.qrc
)

# our application
add_executable(qmlarkdown
    ${SOURCES} ${HEADERS} ${RESOURCES}
)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# add QT_QML_DEBUG for debug-config
target_compile_definitions(qmlarkdown PRIVATE $<$<CONFIG:Debug>:QT_QML_DEBUG>)

# dependencies
target_link_libraries(qmlarkdown
    PRIVATE
        Qt5::Core
        Qt5::Widgets
        Qt5::Quick
        Qt5::QuickControls2
        Qt5::WebEngine
        MarkdownQt::MarkdownQt
        KSyntaxHighlightingWrapper::KSyntaxHighlightingWrapper
        FontAweSomeQml::FontAweSomeQml
)

# install application
install(TARGETS qmlarkdown
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# Display feature summary
feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
