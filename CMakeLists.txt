# ╭─────────────────────────────────────────────────────────────────────────────╮
# │ py4pd - Build cross-plataforma para Pure Data + Python                     │
# │                                                                            │
# │ Variáveis essenciais (defina via linha de comando cmake):                  │
# │   -DPYVERSION=3.11           # Versão do Python (obrigatório)              │
# │   -DPYTHON_EXECUTABLE=...    # Caminho para o executável Python (opcional) │
# │   -DPD_SDK_INCLUDEDIR=...    # Diretório de includes do SDK do Pd          │
# │   -DPD_SDK_LIBDIR=...        # Diretório de libs do SDK do Pd              │
# │   -DPD_INSTALL_DIR=...       # Diretório de instalação do Pure Data        │
# │ Exemplos de uso:                                                           │
# │   cmake -B build -DPYVERSION=3.11 -DPYTHON_EXECUTABLE=/usr/bin/python3.11  │
# │   cmake -B build -DPD_SDK_INCLUDEDIR=/caminho/pd/include ...               │
# ╰─────────────────────────────────────────────────────────────────────────────╯

cmake_minimum_required(VERSION 3.20)
project(py4pd C)
set(CMAKE_C_STANDARD 23)
set(CMAKE_C_EXTENSIONS OFF) # Use pure C23 without compiler extensions

# ╭──────────────────────────────────────╮
# │               pd.cmake               │
# ╰──────────────────────────────────────╯
cmake_policy(SET CMP0135 NEW)
set(PDCMAKE_FILE ${CMAKE_BINARY_DIR}/pd.cmake)
if(NOT EXISTS ${PDCMAKE_FILE})
    message(STATUS "Downloading pd.cmake")
    file(
        DOWNLOAD https://raw.githubusercontent.com/pure-data/pd.cmake/refs/tags/v0.1.0/pd.cmake ${PDCMAKE_FILE}
        SHOW_PROGRESS
        STATUS DOWNLOAD_STATUS)
endif()
include(${PDCMAKE_FILE})

# ╭──────────────────────────────────────╮
# │      Checagem de variáveis           │
# ╰──────────────────────────────────────╯
if(NOT DEFINED PYVERSION)
    message(FATAL_ERROR "\n[py4pd] PYVERSION não definida. Use -DPYVERSION=3.11, por exemplo.")
else()
    message(STATUS "[py4pd] Usando Python version: ${PYVERSION}")
endif()

if(NOT DEFINED PD_SDK_INCLUDEDIR)
    message(FATAL_ERROR "\n[py4pd] PD_SDK_INCLUDEDIR não definida. Use -DPD_SDK_INCLUDEDIR=/caminho/para/pd/include")
endif()
if(NOT DEFINED PD_SDK_LIBDIR)
    message(FATAL_ERROR "\n[py4pd] PD_SDK_LIBDIR não definida. Use -DPD_SDK_LIBDIR=/caminho/para/pd/lib")
endif()

# ╭──────────────────────────────────────╮
# │            Python Include            │
# ╰──────────────────────────────────────╯
# PYTHON_EXECUTABLE deve ser apenas o executável (ex: python, python3.11, C:/Python311/python.exe)
if(NOT DEFINED PYTHON_EXECUTABLE OR PYTHON_EXECUTABLE STREQUAL "")
    if(WIN32)
        # Seleciona automaticamente o executável Python correto via variável de ambiente, conforme PYVERSION
        if(PYVERSION STREQUAL "3.11")
            set(PYTHON_EXECUTABLE $ENV{PYTHON311_EXE})
        elseif(PYVERSION STREQUAL "3.12")
            set(PYTHON_EXECUTABLE $ENV{PYTHON312_EXE})
        endif()
        # Fallback se a variável de ambiente não estiver definida
        if(NOT DEFINED PYTHON_EXECUTABLE OR PYTHON_EXECUTABLE STREQUAL "")
            set(PYTHON_EXECUTABLE "C:/Users/Esteban Viveros/AppData/Local/Programs/Python/Python311/python.exe")
            if(NOT EXISTS "${PYTHON_EXECUTABLE}")
                set(PYTHON_EXECUTABLE "python")
            endif()
        endif()
    else()
        set(PYTHON_EXECUTABLE "python${PYVERSION}")
    endif()
endif()

message(STATUS "[py4pd][DEBUG] PYTHON_EXECUTABLE='${PYTHON_EXECUTABLE}'")
execute_process(
    COMMAND ${PYTHON_EXECUTABLE} --version
    OUTPUT_VARIABLE PYTHON_VERSION_OUTPUT
    ERROR_VARIABLE PYTHON_VERSION_ERROR
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE PYTHON_VERSION_RESULT
)
message(STATUS "[py4pd][DEBUG] python --version STDOUT: ${PYTHON_VERSION_OUTPUT}")
message(STATUS "[py4pd][DEBUG] python --version STDERR: ${PYTHON_VERSION_ERROR}")
message(STATUS "[py4pd][DEBUG] python --version RESULT: ${PYTHON_VERSION_RESULT}")

execute_process(
    COMMAND ${PYTHON_EXECUTABLE} -c "import sysconfig; print(sysconfig.get_paths()['include'])"
    OUTPUT_VARIABLE PYTHON_INCLUDE_DIR
    ERROR_VARIABLE PYTHON_INCLUDE_ERROR
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE EXEC_RESULT
)
message(STATUS "[py4pd][DEBUG] python -c sysconfig.get_paths()['include'] STDOUT: ${PYTHON_INCLUDE_DIR}")
message(STATUS "[py4pd][DEBUG] python -c sysconfig.get_paths()['include'] STDERR: ${PYTHON_INCLUDE_ERROR}")
message(STATUS "[py4pd][DEBUG] python -c sysconfig.get_paths()['include'] RESULT: ${EXEC_RESULT}")

if(EXEC_RESULT)
    message(FATAL_ERROR "[py4pd] Falha ao obter diretório de includes do Python. Verifique PYTHON_EXECUTABLE e PYVERSION.")
endif()

# ╭──────────────────────────────────────╮
# │           Python LD Flags            │
# ╰──────────────────────────────────────╯
if(WIN32)
    execute_process(
        COMMAND ${PYTHON_EXECUTABLE} -c "import sysconfig; print(sysconfig.get_path('stdlib'))"
        OUTPUT_VARIABLE PYTHON_STDLIB_DIR
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE EXEC_RESULT)
    # No Windows, as bibliotecas estão no diretório 'libs' da instalação Python
    get_filename_component(PYTHON_BASE_DIR "${PYTHON_STDLIB_DIR}" DIRECTORY)
    set(PYTHON_LIB_DIR "${PYTHON_BASE_DIR}/libs")
    string(REPLACE "." "" PYVERSION_NO_DOT ${PYVERSION})
    # Escapar o path para evitar problemas com espaços
    file(TO_NATIVE_PATH "${PYTHON_LIB_DIR}" PYTHON_LIB_DIR_NATIVE)
    set(PYTHON_LD_FLAGS "-L\"${PYTHON_LIB_DIR_NATIVE}\" -lpython${PYVERSION_NO_DOT}")
else()
    execute_process(
        COMMAND ${PYTHON_EXECUTABLE}-config --ldflags
        OUTPUT_VARIABLE PYTHON_LD_FLAGS
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE EXEC_RESULT)
    if(EXEC_RESULT)
        message(FATAL_ERROR "[py4pd] Falha ao obter ldflags do Python. Verifique PYTHON_EXECUTABLE e PYVERSION.")
    endif()
    string(REPLACE " " ";" PYTHON_LD_FLAGS ${PYTHON_LD_FLAGS})
    if(APPLE)
        list(GET PYTHON_LD_FLAGS 0 PYTHON_LD_FLAGS)
    endif()
    string(REPLACE " " ";" PYTHON_LD_FLAGS "${PYTHON_LD_FLAGS}")
    list(APPEND PYTHON_LD_FLAGS "-lpython${PYVERSION}")
endif()

# ╭──────────────────────────────────────╮
# │           PureData Object            │
# ╰──────────────────────────────────────╯
include_directories(${PD_SDK_INCLUDEDIR})
link_directories(${PD_SDK_LIBDIR})

file(GLOB PY4PD_SOURCES ${CMAKE_SOURCE_DIR}/Sources/*.c)
pd_add_external(py4pd "${PY4PD_SOURCES}")
target_include_directories(py4pd PUBLIC ${PYTHON_INCLUDE_DIR})
target_link_libraries(py4pd PUBLIC "${PYTHON_LD_FLAGS}")

