#!/bin/bash

function echoTest {
    echo "Testing:   '$1'"
    OUT0=$(echo -e "$1" | ./camomilla -d0)
    OUT1=$(./camomilla -r -d1)
    OUT2=$(./camomilla -r -d2)

    echo -e "    d2:    '$OUT2'"
    echo -e "    d1:    '$OUT1'"
    echo -e "    d0:    '$OUT0'"

    echo "____________________________________"
}

echoTest "class<Type>"
echoTest "rel<decltype(a < b)>"
echoTest "rel<decltype(a > b)>"
echoTest "stream<decltype(a << b)>"
echoTest "stream<decltype(a >> b)>"
echoTest "nested_rel<decltype(a<A> < b<B>)>"
echoTest "nested_rel<decltype(a<A> > b<B>)>"
echoTest "nested_stream<decltype(a<A> << b<B>)>"
echoTest "nested_stream<decltype(a<A> >> b<B>)>"
echoTest "nested_types<A<B>>"
echoTest "nested_types_rel<A<B(a < b)>>"
echoTest "nested_types_rel<A<B(a > b)>>"
echoTest "nested_types_stream<A<B(a << b)>>"
echoTest "nested_types_stream<A<B(a >> b)>>" "b"
