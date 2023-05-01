(** This file uses ocaml-5 effects to provide asymmetrical "generator"
   coroutines.

   These generators are in the style of python (and ECMAScript)
   generators: the generator function can both yield a value to the
   iterator and on resuming receive a value from it.  The value given
   to the first invocation of the iterator is ignored, because the
   generator function has yet to start.  Any value given to subsequent
   invocations of the iterator is returned by the relevant yield
   expression in the generator function when the generator function
   resumes.  In addition, as in the case of python generators, the
   value returned by the generator function is ignored: if the
   generator is not infinite, when reaching the end of the generator
   function the iterator raises a Stop_iteration exception.  When the
   iterator returns a value, it returns the value explicitly yielded
   by the generator function. *)

exception Stop_iteration

(** make_iterator is a function which takes a generator function as an
   argument and returns a function ('b -> 'a).  The returned function
   ('b -> 'a) is an iterator coroutine which will invoke the generator
   function and then return any value yielded by that function.  The
   generator function takes a yield function as its only argument of
   type ('a -> 'b) and returns any type, which is ignored.

   One point to note is that where a generator function does not use
   the value returned by yield (such as where that value is unit) and
   the iterator is never actually applied, the compiler may be unable
   to deduce the type of that value and may mark it as a weakly
   polymorphic type which cannot be generalised and escapes its scope.
   So below, the expression:

     let iter = make_iterator (fun yield -> yield 2 ; yield 4)

   will fail to compile if there is no use of iter.  Where this
   problem arises, it can be averted by explicitly typing the
   definition of iter as follows:

     let iter : unit -> int = make_iterator (fun yield -> yield 2 ;
                                                          yield 4) *)
val make_iterator : (('a -> 'b) -> _) -> 'b -> 'a

(** Typical use is like this:

{[   async (fun await resume ->

        [... set up node asynchronous operation which applies
             'resume' to a polymorphic variant in its completion
             callback ...]

        match await () with 
           [... match on the polymorphic variant ...]

        [... do more of the same as required...])]}

   async takes a waitable function (namely a function which takes
   'await' as its first parameter, which is a yield function obtained
   by a call to make-iterator, and 'resume' as its second parameter,
   which is an iterator constructed by make_iterator).  The 'resume'
   argument must only be called by an asynchronous callback, and the
   'await' argument must only be called by the waitable function in
   order to block until the callback is ready to let it resume.  When
   it unblocks, the 'await' argument returns the value (if any) passed
   to ’resume’ by the callback, which must be a polymorphic variant
   carrying its payload.  The return value of the waitable function is
   ignored.

   The 'await' argument is a thunk (that is, it always takes a unit
   argument).  async returns unit.

   A more general explanation is that the block of code executed by
   the application of async to the waitable function is a separate
   unit of computation, which appears within itself to proceed
   sequentially even though in fact it executes asynchronously on the
   node event loop.  Each such block also appears to execute
   concurrently with other 'async' blocks running on the same event
   loop.  Each 'async' block is therefore in some sense analogous to a
   thread of execution.

   Examples of usage are in examples.ml and async_funcs.ml *)
val async : ((unit -> ([> `Unit ] as 'a)) -> ('a -> unit) -> _) -> unit
