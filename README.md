# camomilla

[![license][badge.license]][license]
[![gratipay][badge.gratipay]][gratipay]
![badge.python3](https://img.shields.io/badge/python-3-ff69b4.svg?style=flat-square)

[badge.license]: http://img.shields.io/badge/license-mit-blue.svg?style=flat-square
[badge.gratipay]: https://img.shields.io/gratipay/user/SuperV1234.svg?style=flat-square

[license]: https://github.com/SuperV1234/camomilla/blob/master/LICENSE
[gratipay]: https://gratipay.com/~SuperV1234/

## What is it?

`camomilla` is a simple [Python 3](http://python.org) script that simplifies errors produced by C++ compilers. It is very useful while dealing with heavily-templated code *(e.g. when using [boost::hana](http://www.boost.org/doc/libs/1_61_0/libs/hana/doc/html/index.html) or [boost::fusion](http://www.boost.org/doc/libs/1_61_0/libs/fusion/doc/html/))*.

`camomilla` transforms the error text to make it easier to read. It supports *JSON configuration files* that can include each other recursively and *caches the last error* so that the user can quickly *reprocess* the original error with different transformation options.


## Example errors

The table below shows the size reduction of the errors in the `example_errors` folder. The original error was generated from a real project, [ecst](http://github.com/SuperV1234/ecst), by simply mispelling a member field name in a template-heavy context.

|               | Bytes (original) | Bytes (after camomilla) | Relative size change |
|---------------|------------------|-------------------------|----------------------|
| g++ 6.1.1     | 38487            | 3680                    | -90.43%              |
| clang++ 3.8.1 | 16856            | 2990                    | -82.26%              |

A size reduction often means that the error is easier to pinpoint. Using `-r` *(`--reprocess`)* to incrementally "add detail" to the error is then a good approach to gather more information on its cause/origin.


Here's a *(partial)* screenshot of the original `g++` error - it couldn't fit in my terminal window.

![Terminal screenshot: original error](/example_errors/gcc_before.png?raw=true)

Here's the *full* screenshot of the the same error, processed by `camomilla`.

![Terminal screenshot: processed error](/example_errors/gcc_after.png?raw=true)


## Solution or workaround?

`camomilla` is merely a workaround for the fact that compilers do not filter *(either automatically or through flags)* the depth of template typenames. Errors in projects making use of libraries such as `boost::hana` or `boost::fusion` therefore include a lot of "typename boilerplate" that can make the error harder to read.

Library developers are sometimes forced to make use of techniques to erase the long typenames in order to simplify the errors and *decrease compilation time*: [`boost::experimental::di`](https://github.com/boost-experimental/di) is an example.

I think this is something that should be addressed directly in the compilers - I've created a *feature request/bug report* both in the [GCC Bug Tracker](https://gcc.gnu.org/bugzilla/show_bug.cgi?id=71167) and in the [Clang Bug Tracker](https://llvm.org/bugs/show_bug.cgi?id=27793).



## Transformations

`camomilla` performs the following text transformations:

1. **Template typename collapsing.**

    Nested template typenames are collapsed to a specific user-defined depth. This is the most useful transformation executed by `camomilla`. Example:

    ```bash
    echo "metavector<metatype<metawhatever<int>>>::method()" | camomilla -d0
    # outputs
    metavector<?>::method()

    echo "metavector<metatype<metawhatever<int>>>::method()" | camomilla -d1
    # outputs
    metavector<metatype<?>>::method()

    echo "metavector<metatype<metawhatever<int>>>::method()" | camomilla -d2
    # outputs
    metavector<metatype<metawhatever<?>>>::method()

    echo "metavector<metatype<metawhatever<int>>>::method()" | camomilla -d3
    # outputs
    metavector<metatype<metawhatever<int>>>::method()
    ```

    This is incredibly useful when using template metaprogramming libraries, that usually internally nest a huge amount of wrappers.

2. **Namespace replacement regexes.**

    A simple transformation from a long namespace symbol to a shorter *(or absent)* one.

    ```bash
    echo "std::vector<std::pair<std::int16_t, std::int32_t>>" | camomilla --depth=100
    # outputs
    vector<pair<int16_t, int32_t>>

    echo "boost::hana::tuple<boost::hana::tuple<boost::hana::int_c<10>, boost::hana::int_c<15>>>" | camomilla -d100
    # outputs
    bh::tuple<bh::tuple<bh::int_c<10>, bh::int_c<15>>>
    ```

3. **Generic replacement regexes.**

    ```bash
    echo "std::forward<decltype(std::tuple<unsigned long long, std::size_t, int>)>(x)" | camomilla -d100
    # outputs
    fwd<decltype(tuple<ulong long, sz_t, int>)>(x)
    ```



## Usage

### Error redirection

Errors produced by compilers can be easily piped into `camomilla`:

```bash
# Pipe both `stdout` and `stderr` into `camomilla`
g++ ./x.cpp |& camomilla -d5
```

If `|&` is not supported by your shell or if you want to compare the original error to the processed one, using a temporary file is a good solution:

```bash
# Redirect both `stdout` and `stderr` into `error.out`
g++ ./x.cpp &> error.out

# Process the error
cat error | camomilla -d2
```

### Reprocessing

The last processed original error is cached *(unless `--no-temp-cache` is specified)*. It is possible to reuse the source of the last error to perform different transformations, ignoring `stdin`. This is particularly useful when playing with the `--depth` parameter to get the required typename information while avoiding clutter.

```bash
# Process error
g++ ./x.cpp |& camomilla -d0

# Whoops! Need more typename information.
camomilla -r -d1

# Still a little bit more...
camomilla -r -d2
```


## Configuration

### Argparse-generated help

```bash
usage: camomilla [-h] [--template-collapsing | --no-template-collapsing]
                 [--namespace-replacements | --no-namespace-replacements]
                 [--generic-replacements | --no-generic-replacements]
                 [--process-by-line | --no-process-by-line]
                 [--temp-cache | --no-temp-cache] [-r | --no-reprocess]
                 [--reprocess-prev-config | --no-reprocess-prev-config] [-d X]
                 [-c P]

optional arguments:
  -h, --help                   show this help message and exit
  --template-collapsing        | Control template collapsing
  --no-template-collapsing     '
  --namespace-replacements     | Control namespace replacements
  --no-namespace-replacements  '
  --generic-replacements       | Control generic replacements
  --no-generic-replacements    '
  --process-by-line            | Control process by line
  --no-process-by-line         '
  --temp-cache                 | Control temp cache
  --no-temp-cache              '
  -r, --reprocess              | Control reprocess previous source
  --no-reprocess               '
  --reprocess-prev-config      | Control reprocess with previous configuration
  --no-reprocess-prev-config   '
  -d X, --depth X              Template collapsing depth
  -c P, --config P             Configuration file path(s)
```

### Basic command-line options

#### Enable/disable transformations

Error text transformations can be turned on and off individually by using the following flags. All transformations are **on** by default.

```bash
# Template typename collapsing (default: ON)
--template-collapsing
--no-template-collapsing

# Namespace replacement regexes (default: ON)
--namespace-replacements
--no-namespace-replacements

# Generic replacement regexes (default: ON)
--generic-replacements
--no-generic-replacements
```

#### Enable/disable temporary cache

`camomilla` stores the last processed original error *(and last used configuration)* in your OS-dependant *temp folder*. This option can be controlled with:

```bash
# Temporary "last error cache" (default: ON)
--temp-cache
--no-temp-cache
```

#### Reprocessing

If an error has been cached, `camomilla` can be invoked with reprocessing options to read directly from the cache *(ignoring standard input)*:

```bash
# Reprocess cached error (default: OFF)
-r
--reprocess
--no-reprocess

# Reprocess with cached configuration (default: ON)
--reprocess-prev-config
--no-reprocess-prev-config
```

#### Template typename collapsing options

The depth of the *template typename collapsing* transformation can be specified with the `-d` *(or `--depth`)* flag.

```bash
# Collapse all templates with depth `>= 5`
camomilla -d5

# Collapse all templates with depth `>= 100`
camomilla --depth=100
```

#### Process by line

By default, `camomilla` processes the error line by line. This behavior can be disabled *(in order to process the error all at once)* with the `--no-process-by-line` flag.



### Configuration files

Configurations files are JSON documents that allow users to define their *namespace replacement regexes* and *generic replacement regexes*. They also allow users to override command-line arguments *(or set unspecified options)*. Configuration files can refer to each other recursively.

#### Using configuration files

Any number of configuration file paths can be passed to `camomilla` through the `-c` *(or `--config`)* flag. Configuration files are read sequentially *(the order matters for option overriding)*.

```bash
# Executes `camomilla` reading `conf0.json`
camomilla -c"conf0.json"

# Executes `camomilla` reading `conf0.json` first, then `conf1.json`
camomilla -c"conf0.json" -c"conf1.json"
```

Here's a more complex example:

```bash
# Executes `camomilla` with:
# * Template typename collapsing depth: 4
# * Namespace replacement regexes: off
# * Reading the `~/camomilla_configs/test.json` file
camomilla -d4 --no-namespace-replacements -c"~/camomilla_configs/test.json"

# `test.json` may:
# * Override the specified depth
# * Override the specified `--no-namespace-replacements` option
# * Set unspecified options (e.g. `--no-generic-replacements`)
```

#### Writing configuration files

Configuration files are written in JSON. Here's an example file with complete syntax:

```javascript
{
    // Set/override options
    "enableTemplateCollapsing": false,
    "enableNamespaceReplacements": false,
    "enableTuplePairReplacements": false,
    "enableGenericReplacements": false,
    "templateCollapsingDepth": 10,

    // Add namespace replacements
    "namespaceReplacements": [
        "std": "",
        "boost::hana": "bh",
        "boost::fusion": "bf",
        "boost::spirit": "bs",
    ],

    // Add generic replacements
    "genericReplacements" : [
        "tuple": "tpl",
        "forward": "fwd"
    ],

    // Include other config files
    "configPaths": [
        "~/camomilla_configs/boost_spirit.json",
        "~/camomilla_configs/limit_template_depth.json"
    ]
}
```

#### Multiple configuration files

When multiple configuration files are passed as command-line arguments, or if any configuration file "includes" another file, the behavior is as follows:

* Options, such as `enableTemplateCollapsing` or `templateCollapsingDepth`, are **overridden** or set.

    * Previously set options will be potentially overwritten by the next configuration file(s).

* Namespace replacements and generic replacements will be **accumulated** or **overridden**.

    * If a configuration file has a replacement with the same key as a previous one, its value will be overridden.

    * If a configuration file defines a replacement that wasn't previously seen, it will be added without replacing any existing replacement.



