open Effect
open Effect.Shallow

exception Stop_iteration

type ('a, 'b) running =
  Running of ('a,'b) continuation
| Done

(* type a below is the type yielded.
   type b below is the type returned on resumption after yield

   f is a function taking 'yield' as its only argument and returning
   any type (its return value is ignored) *)

let make_iterator (type a b) (f: (a -> b) -> _) =
  let module M = struct type _ Effect.t += Yield : a -> b Effect.t end in
  let yield v = perform (M.Yield v) in

  let curr = ref (Running (fiber (fun _ -> f yield))) in

  let iter (arg:b) : a =
    match !curr with
    | Done -> raise Stop_iteration
    | Running k ->
       continue_with k arg
         { effc =
             (fun (type c) (eff : c Effect.t) ->
               match eff with
               | M.Yield v -> Some (fun (k: (c,_) continuation) ->
                                  curr := Running k ;
                                  v)
               | _ -> None) ;
           exnc = (fun e -> raise e) ;
           retc = (fun _ -> curr := Done ;
                            raise Stop_iteration ) } in
  iter

let async waitable =
  (* I am surprised these work, where we dereference 'resume' when
     passing it as an argument of the generator function given to
     make_iterator; but it appears dereferencing is delayed until the
     return value of make_iterator is applied, which is what we
     want. *)
  (*
  let resume = ref (fun _ -> assert false) in
  resume :=  make_iterator (fun await -> waitable await !resume) ;
  !resume `Unit
   *)

  let resume = ref (fun _ -> assert false) in
  let iter = make_iterator (fun await -> waitable await !resume) in
  resume := (fun x -> try iter x with
                        Stop_iteration -> print_endline "Stop" ; ()
                      | exn -> raise exn) ;
  !resume `Unit

   (* await is a yield function of type ('a -> 'b) specialised to the
      types described in the signature

      resume is an iterator of type ('b -> 'a) specialised to the
      types described in the signature

      waitable is a function taking a yield function (await) as its
      first argument and an iterator (resume) as its second argument,
      and whose return value is ignored

      await is always executed as a thunk with unit as its argument
      and so async always returns unit *)
