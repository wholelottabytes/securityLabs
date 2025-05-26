cmake_minimum_required(VERSION 3.4.1)

find_library(log-lib log)
find_library(android-lib android)

add_library(accelerometerjni SHARED
        accelerometer_jni.cpp)

target_link_libraries(accelerometerjni
        ${log-lib}
        ${android-lib})
