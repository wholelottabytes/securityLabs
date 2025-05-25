cmake_minimum_required(VERSION 3.16)
project(HashLibrary VERSION 1.0.0 LANGUAGES C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Опции сборки
option(BUILD_SHARED_LIBS "Build shared libraries" ON)
option(BUILD_STATIC_LIBS "Build static libraries" ON)

# Исходные файлы
set(SOURCES
    src/hash_lib.c
)

set(HEADERS
    src/hash_lib.h
)

# Создание shared library
if(BUILD_SHARED_LIBS)
    add_library(${PROJECT_NAME}_shared SHARED ${SOURCES})
    set_target_properties(${PROJECT_NAME}_shared PROPERTIES
        OUTPUT_NAME hash_lib
        VERSION ${PROJECT_VERSION}
        SOVERSION 1
        PUBLIC_HEADER "${HEADERS}"
    )
    
    # Линкуем системные библиотеки если нужно
    if(WIN32)
        target_link_libraries(${PROJECT_NAME}_shared advapi32)
    endif()
    
    # Установка include директорий
    target_include_directories(${PROJECT_NAME}_shared
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
            $<INSTALL_INTERFACE:include>
    )
endif()

# Создание static library
if(BUILD_STATIC_LIBS)
    add_library(${PROJECT_NAME}_static STATIC ${SOURCES})
    set_target_properties(${PROJECT_NAME}_static PROPERTIES
        OUTPUT_NAME hash_lib_static
        PUBLIC_HEADER "${HEADERS}"
    )
    
    if(WIN32)
        target_link_libraries(${PROJECT_NAME}_static advapi32)
    endif()
    
    target_include_directories(${PROJECT_NAME}_static
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
            $<INSTALL_INTERFACE:include>
    )
endif()

# Компиляционные флаги
if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(${PROJECT_NAME}_shared PRIVATE -Wall -Wextra -O2)
    if(BUILD_STATIC_LIBS)
        target_compile_options(${PROJECT_NAME}_static PRIVATE -Wall -Wextra -O2)
    endif()
endif()

# Установка
include(GNUInstallDirs)

if(BUILD_SHARED_LIBS)
    install(TARGETS ${PROJECT_NAME}_shared
        EXPORT HashLibraryTargets
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    )
endif()

if(BUILD_STATIC_LIBS)
    install(TARGETS ${PROJECT_NAME}_static
        EXPORT HashLibraryTargets
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    )
endif()