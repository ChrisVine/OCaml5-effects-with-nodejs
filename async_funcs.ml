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

let await_http_get await resume host path port =
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
                      (Js.wrap_callback (fun _ -> resume (`Get (Result.Ok !accum))))))
  and http = require "http" in
  let req = http##request opts cb in
  ignore (req##on (Js.string "error")
                  (Js.wrap_callback
                     (fun e -> resume (`Get (Result.Error (Js.to_string e##.message)))))) ;
  ignore (req##end_) ;
  match await () with
    `Get res -> res
  | _ -> assert false
