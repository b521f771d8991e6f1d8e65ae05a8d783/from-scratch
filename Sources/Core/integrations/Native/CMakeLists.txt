cmake_minimum_required(VERSION 3.28)
project(FromScratch LANGUAGES C CXX OBJC OBJCXX)

add_library(NativeIntegration STATIC test.h test.mm)