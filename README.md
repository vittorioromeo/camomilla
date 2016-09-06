# camomilla

## What is it?

`camomilla` is a very simple Python 3 script that simplifies errors produced by C++ compilers. It is very useful while dealing with heavily-templated code *(e.g. when using [boost::hana](http://www.boost.org/doc/libs/1_61_0/libs/hana/doc/html/index.html) or [boost::fusion](http://www.boost.org/doc/libs/1_61_0/libs/fusion/doc/html/))*.

`camomilla` perform the following text transformations:

1. **Template typename collapsing.**

    Nested template typenames are collapsed to a specific user-defined depth. This is the most useful transformation executed by `camomilla`. Example:

    ```bash
    echo "metavector<metatype<metawhatever<int>>>::method()" | ./camomilla -d1 
    # outputs
    metavector<metatype<?>>::method()

    echo "metavector<metatype<metawhatever<int>>>::method()" | ./camomilla -d2
    # outputs
    metavector<metatype<metawhatever<?>>>::method()

    echo "metavector<metatype<metawhatever<int>>>::method()" | ./camomilla -d3
    # outputs
    metavector<metatype<metawhatever<int>>>::method()
    ```

    This is incredibly useful when using template metaprogramming libraries, that usually internally nest a huge amount of wrappers.

2. **Namespace replacement regexes.**

    A simple transformation from a long namespace symbol to a shorter *(or absent)* one. 

    ```bash
    echo "std::vector<std::pair<std::int16_t, std::int32_t>>" | ./camomilla --depth=100
    # outputs
    vector<pair<int16_t, int32_t>>
    
    echo "boost::hana::tuple<boost::hana::tuple<boost::hana::int_c<10>, boost::hana::int_c<15>>>" | ./camomilla --depth=100
    # outputs
    bh::tuple<bh::tuple<bh::int_c<10>, bh::int_c<15>>>
    ```

3. **Tuple/pair replacements.**

    TODO

4. **Generic replacement regexes.**

    ```bash
    echo "std::forward<decltype(std::tuple<unsigned long long, std::size_t, int>)>(x)" | ./camomilla --depth=100
    # outputs
    fwd<decltype(tuple<ulong long, sz_t, int>)>(x)
    ```

## TODO

* Look for TODOs in script.

* gcc, g++, clang, clang++ aliases that pass error to camomilla.

* Makefile/install script.

* --depth=-1 or --alldepth or whatever.

* Flags to control transformations.

* Reading from config file.

* Refactor code.