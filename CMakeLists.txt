cmake_minimum_required(VERSION 3.1)

project(qmlarkdown LANGUAGES CXX)
set(PROJECT_VERSION "0.0.1")

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

include(FeatureSummary)

find_package(Qt5 "5.12.0" COMPONENTS Core Widgets Quick QuickControls2 WebEngine CONFIG REQUIRED COMPONENTS)

# https://github.com/schnitzeltony/markdown-qt
find_package(MarkdownQt REQUIRED)

find_package(KF5SyntaxHighlighting REQUIRED)
# https://github.com/schnitzeltony/ksyntax-highlighting-wrapper
find_package(TextAreaEnhanced REQUIRED)

# https://github.com/schnitzeltony/fontawesome-qml
find_package(FontAweSomeQml REQUIRED)

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

add_executable(qmlarkdown
    ${SOURCES} ${HEADERS} ${RESOURCES}
)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# add QT_QML_DEBUG for debug-config
target_compile_definitions(qmlarkdown PRIVATE $<$<CONFIG:Debug>:QT_QML_DEBUG>)

target_link_libraries(qmlarkdown
    PRIVATE
        Qt5::Core
        Qt5::Widgets
        Qt5::Quick
        Qt5::QuickControls2
        Qt5::WebEngine
        MarkdownQt::MarkdownQt
        TextAreaEnhanced::TextAreaEnhanced
        FontAweSomeQml::FontAweSomeQml
)

install(TARGETS qmlarkdown
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
