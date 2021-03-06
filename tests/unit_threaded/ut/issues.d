module unit_threaded.ut.issues;

import unit_threaded;
import unit_threaded.asserts;


interface ICalcView {
   @property string total() @safe pure;
   @property void total(string t) @safe pure;
}

class CalcController {
    private ICalcView view;

    this(ICalcView view) @safe pure {
        this.view = view;
    }

    void onClick(int number) @safe pure {
        import std.conv: to;
        view.total = number.to!string;
    }
}


@("54")
@safe pure unittest {
   auto m = mock!ICalcView;
   m.expect!"total"("42");

   auto ctrl = new CalcController(m);
   ctrl.onClick(42);

   m.verify;
}


@("82")
@safe unittest {

    import std.exception: assertThrown;

    static class A {
        string x;

        override string toString() const {
            return x;
        }
    }

    class B : A {}

    auto actual = new B;
    auto expected = new B;

    actual.x = "foo";
    expected.x = "bar";

    assertThrown(actual.shouldEqual(expected));
}


@("124")
@safe pure unittest {
    static struct Array {

        alias opSlice this;

        private int[] ints;

        bool opCast(T)() const if(is(T == bool)) {
            return ints.length != 0;
        }

        inout(int)[] opSlice() inout {
            return ints;
        }
    }

    {
        auto arr = Array([1, 2, 3]);
        arr.shouldEqual([1, 2, 3]);
    }

    {
        const arr = Array([1, 2, 3]);
        arr.shouldEqual([1, 2, 3]);
    }

}


@("138")
@safe unittest {
    import std.exception: assertThrown;

    static class Class {
        private string foo;
        override bool opEquals(scope Object b) @safe @nogc pure nothrow scope const {
            return foo == (cast(Class)b).foo;
        }
    }

    auto a = new Class;
    auto b = new Class;

    a.foo = "1";
    b.foo = "2";

    // Object.opEquals isn't scope and therefore not @safe
    assertThrown(() @trusted { a.should == b; }());
}


@("146")
@safe unittest {
    version(unitThreadedLight) {}
    else {
        assertExceptionMsg(shouldApproxEqual(42000.301, 42000.302, 1e-9),
                           `    tests/unit_threaded/ut/issues.d:123 - Expected approx: 42000.302000` ~ "\n" ~
                           `    tests/unit_threaded/ut/issues.d:123 -      Got       : 42000.301000`);
    }
}


version(unitThreadedLight) {}
else {

    // should not compile for @safe
    @("176.0")
        @safe pure unittest {

        int* ptr;
        bool func(int a) {
            *(ptr + 256) = 42;
            return a % 2 == 0;
        }

        static assert(!__traits(compiles, check!func(100)));
    }

    @("176.1")
        @safe unittest {
        import std.traits: isSafe;

        int* ptr;
        bool func(int a) {
            *(ptr + 256) = 42;
            return a % 2 == 0;
        }

        static assert(!isSafe!({ check!func(100); }));
    }
}


@("182")
// not @safe or pure because the InputRange interface member functions aren't
@system unittest {
    import std.range: inputRangeObject;
    auto a = [1, 2, 3];
    auto b = [1, 2, 3];
    a.inputRangeObject.should == b;
}
