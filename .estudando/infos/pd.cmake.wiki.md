# Home

Charles K. Neimog edited this page on Jun 22, 2024 · [12 revisions](https://github.com/pure-data/pd.cmake/wiki/Home/_history)

# Welcome to pd.cmake Wiki

[](https://github.com/pure-data/pd.cmake/wiki#welcome-to-pdcmake-wiki)

The repository offers a set of script to facilitate the creation of CMake projects to compile Pure Data externals. CMake is a free, open-source and cross-platform system that allows to generate makefiles and projects for many OS and build systems and/or IDEs (Unix makefile, XCode, Visual Studio, etc.). So the goal of the pd.cmake is to offer a system that allows to easily and quickly create projects for developing and compiling Pd externals on the environment of your choice.

# Variables

[](https://github.com/pure-data/pd.cmake/wiki#variables)

- `PDCMAKE_DIR`: Define the `PATH` where is located _pd.cmake_.
- `PD_SOURCES_PATH`: Define the `PATH` where is located `m_pd.h`.
- `PDLIBDIR`: Define the `PATH` where the externals should be installed.
- `PDBINDIR`: Define the `PATH` where is located `pd.dll` or `pd64.dll` (Just for Windows).
- `PD_FLOATSIZE`: Define the float size (32 or 64).
- `PD_BUILD_STATIC_OBJECTS`: Build objects as static libraries (`.a`).
- `PD_INSTALL_LIBS`: Define if we must install the externals in `PDLIBDIR` or not (True|On or False|Off).
- `PD_ENABLE_TILDE_TARGET_WARNING`: Enable/Disable a warning when using target name with `~`. `pd.cmake` automatically replaces `~` with `_tilde` but it keeps the default warning because, if you do something like this:

```cmake
pd_add_external(myfft~ fft~/fft~.cpp)
target_link_libraries(myfft~ PRIVATE fftw3f)
```

This will not work, the correct is something like this:

```cmake
pd_add_external(myfft~ fft~/fft~.cpp TARGET myfft_tilde)
target_link_libraries(myfft_tilde PRIVATE fftw3f)
```

### Defining Variables

[](https://github.com/pure-data/pd.cmake/wiki#defining-variables)

You have mainly two ways to define these variables.

- Using the `-D` flag in the configuration process, something like:

```shell
cmake . -B build -DPD_INSTALL_LIBS=ON 
```

to set PD_INSTALL_LIBS as True.

- Using the `set` command:

```cmake
set(PD_INSTALL_LIBS ON)
```

# Adding Extra Files

[](https://github.com/pure-data/pd.cmake/wiki#adding-extra-files)

To add files to the external you must use the function `pd_add_datafile`. For example:

```cmake
pd_add_external(simple simple/simple.cpp) 
pd_add_datafile(simple simple/simple-help.pd)
```

Copies the `simple-help.pd` to the `PDLIBDIR` if `PD_INSTALL_LIBS` is `True`.

# Static Libraries for Externals Objects

[](https://github.com/pure-data/pd.cmake/wiki#static-libraries-for-externals-objects)

With `pd.cmake` you can build externals libraries as STATIC libraries. This mean that it is possible to easily build standalone applications without any dynamic library requirement (`.so`, `.dylib`, `.dll`). To build the dynamic object (`.a`) set the variable `PD_BUILD_STATIC_OBJECTS=ON`. You can use the flag `-DPD_BUILD_STATIC_OBJECTS=ON` from command line or inside the `CMakeLists.txt`:

```cmake
set(PD_BUILD_STATIC_OBJECTS ON)
```

When compiling a library, `pd.cmake` adds all objects of the library (defined by `project(mylibrary)`) to a variable called `${PROJECT_NAME}_STATIC_LIBRARIES`. To statically link all objects in your app you can use this:

```cmake
# 1) First, get all external object targets and save them in the variable all_static_targets
get_property(all_static_targets GLOBAL PROPERTY "${PROJECT_NAME}_STATIC_LIBRARIES") 
# 2) Then, link them.
target_link_libraries(MyApp PRIVATE all_static_targets) # Link all objects

```

## Emscripten

[](https://github.com/pure-data/pd.cmake/wiki#emscripten)

When using Emscripten, `pd.cmake` will build static libraries. These libraries can then be used with Emscripten to enable the use of external components in web browsers. You just need to link the objects

# Github Actions

[](https://github.com/pure-data/pd.cmake/wiki#github-actions)

**1. Create Necessary Folders:**

- Navigate to your Library Folder.
- Create a new folder named `.github`.
- Within `.github`, create another folder named `workflows`.

**2. Download Example File:**

- Download the provided example file from this link [here](https://raw.githubusercontent.com/pure-data/pd.cmake/main/.github/workflows/c-cpp.yml).
- Paste the downloaded file into the workflows folder you just created.

**3. Modify Variables:**

- Open the downloaded file.
- Find the variable `LIBNAME` on line 09.
- Replace `simple` with the name of your library.

**4. Commit and Upload:**

- Commit the changes to your repository on GitHub.

**5. Run Workflow:**

- Go to the Actions tab on your GitHub repository page.
- Look for an action called `C/C++ CI` (if you don't change the name).
- Click on it, then click Run workflow.
- Wait for the workflow to complete.

**6. Download Result:**

- After the workflow has finished running, refresh the page.
- Look for a new item, usually titled with the last commit message.
- If you see a blue checkbox, click on it.
- Scroll down and locate a file named `yourlibname-ALL-binaries`.
- Download this file.

If the workflow fails (you see a red `x` instead of a checkbox), you'll need to debug. You can seek help in the issues section of the `pd.cmake` repository.

If you use `fftw3` in your object or anything else, you must install it. There are indications in the `c-cpp.yml` where you add your required libraries. For Windows, it is preferable to use `mingw64`.