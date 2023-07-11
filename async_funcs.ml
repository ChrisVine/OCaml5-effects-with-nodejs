open Js_of_ocaml

let require module_name =
  let open Js.Unsafe in
  fun_call
    (js_expr "require")
    [|inject (Js.string module_name)|]

let await_yield await resume =
  ignore @@ Js.Unsafe.global##setImmediate
              (Js.wrap_callback (fun _ -> resume `Unit )) ;
  match await () with
    `Unit -> ()
  | _ -> assert false

let await_sleep await resume secs =
  ignore @@ Js.Unsafe.global##setTimeout
              (Js.wrap_callback (fun _ -> resume `Unit ))
              (secs *. 1000.) ;
  match await () with
    `Unit -> ()
  | _ -> assert false

(* The above implementations of the await_yield and await_sleep
   functions are fine because the node setImmediate and setTimeout
   functions will always return before their callbacks execute.  In
   other words, there will be a yield to the node main loop before the
   callback executes which resumes the computation.

   For node callbacks where that may not be the case, the use of a
   ready guard as below is one way to deal with the issue.  (The use
   of a ready guard is in fact overkill here because in practice the
   end method of http.ClientRequest will return before its "end"
   callback executes.) *)
let await_http_get await resume host path port =
  let ready = ref false in

  let opts = Js.Unsafe.(obj [| "host" , inject (Js.string host) ;
                               "path" , inject (Js.string path) ;
                               "port" , inject port ;
                               "method" , inject (Js.string "GET") |])
  and cb = Js.wrap_callback
    (fun res ->
      let accum = ref "" in
      ignore (res##setEncoding (Js.string "utf8")) ;
      ignore (res##on (Js.string "data")
                      (Js.wrap_callback (fun chunk ->
                           accum := !accum ^ (Js.to_string chunk)))) ;
      ignore (res##on (Js.string "end")
                      (Js.wrap_callback (fun _ ->
                           if !ready then resume (`Get (Result.Ok !accum))
                           else Generators.async (fun await' resume' ->
                                    await_yield await' resume' ;
                                    resume (`Get (Result.Ok !accum)))))))
  and http = require "http" in
  let req = http##request opts cb in
  ignore (req##on (Js.string "error")
                  (Js.wrap_callback
                     (fun e -> resume (`Get (Result.Error (Js.to_string e##.message)))))) ;
  ignore (req##end_) ;

  ready := true ;
  match await () with
    `Get res -> res
  | _ -> assert false
