TEMPLATE = app
CONFIG += console c++11
CONFIG -= app_bundle
CONFIG -= qt

SOURCES += \
    ../../AsmMaker.cpp \
    ../../AsmParser.cpp \
    ../../AsmProcessor18.cpp

HEADERS += \
    ../../AsmMaker.h \
    ../../AsmParser.h \
    ../../stdafx.h
