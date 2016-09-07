# camomilla





## What is it?

`camomilla` is a very simple [Python 3](http://python.org) script that simplifies errors produced by C++ compilers. It is very useful while dealing with heavily-templated code *(e.g. when using [boost::hana](http://www.boost.org/doc/libs/1_61_0/libs/hana/doc/html/index.html) or [boost::fusion](http://www.boost.org/doc/libs/1_61_0/libs/fusion/doc/html/))*.

`camomilla` perform the following text transformations:

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

3. **Tuple/pair replacements.**

    TODO

4. **Generic replacement regexes.**

    ```bash
    echo "std::forward<decltype(std::tuple<unsigned long long, std::size_t, int>)>(x)" | camomilla -d100
    # outputs
    fwd<decltype(tuple<ulong long, sz_t, int>)>(x)
    ```





## Configuration

### Basic command-line options

#### Enable/disable transformations

Error text transformations can be turned on and off individually by using the following flags. All transformations are **on** by default.

```bash
# Template typename collapsing
--template-collapsing
--no-template-collapsing

# Namespace replacement regexes
--namespace-replacements
--no-namespace-replacements

# Tuple/pair replacements
--tuple-pair-replacements
--no-tuple-pair-replacements

# Generic replacement regexes
--generic-replacements
--no-generic-replacements
```

#### Options - template typename collapsing

The depth of the *template typename collapsing* transformation can be specified with the `-d` *(or `--depth`)* flag.

```bash
# Collapse all templates with depth `>= 5`
camomilla -d5

# Collapse all templates with depth `>= 100`
camomilla --depth=100
```




### Configuration files

Configurations files are JSON documents that allow users to define their *namespace replacement regexes* and *generic replacement regexes*. They also allow users to override command-line arguments *(or set unspecified options)*. Configuration files can refer to each other recursively.

#### Using configuration files

Any number of configuration file paths can be passed to `camomilla` through the `-c` *(or `--config`)* flag. Configuration files are read sequentially *(the order matters for option overriding)*.

```bash
# Executes `camomilla` reading `conf0.json`
camomilla -c conf0.json

# Executes `camomilla` reading `conf0.json` first, then `conf1.json`
camomilla -c conf0.json conf1.json
```

Here's a more complex example:

```bash
# Executes `camomilla` with:
# * Template typename collapsing depth: 4
# * Namespace replacement regexes: off
# * Reading the `~/camomilla_configs/test.json` file
camomilla -d4 --no-namespace-replacements -c ~/camomilla_configs/test.json

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
        ["std", ""],
        ["boost::hana", "bh"],
        ["boost::fusion", "bf"],
        ["boost::spirit", "bs"]
    ]

    // Add generic replacements
    "genericReplacements" : [
        ["tuple", "tpl"],
        ["forward", "fwd"]
    ]

    // Include other config files
    "configPaths": [
        "~/camomilla_configs/boost_spirit.json",
        "~/camomilla_configs/limit_template_depth.json"
    ],
}
```

#### Multiple configuration files

When multiple configuration files are passed as command-line arguments, or if any configuration file "includes" another file, the behavior is as follows:

* Options, such as `enableTemplateCollapsing` or `templateCollapsingDepth`, are **overridden** or set.

    * Previously set options will be potentially overwritten by the next configuration file(s).

* Namespace replacements and generic replacements will be **accumulated** or **overridden**.

    * If a configuration file has a replacement with the same key as a previous one, its value will be overridden.

    * If a configuration file defines a replacement that wasn't previously seen, it will be added without replacing any existing replacement.


## TODO

* Look for TODOs in script.

* gcc, g++, clang, clang++ aliases that pass error to camomilla.

* Makefile/install script.

* --depth=-1 or --alldepth or whatever.

* Flags to control transformations.

* Reading from config file.

* Refactor code.

* --help -h

* Blog article.

* Table in README with kbs/wordcount before/after.
