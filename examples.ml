open Generators

(* generator function yielding values *)
let iter = make_iterator (fun yield -> yield 2 ; yield 4)

let () =
  try print_int (iter ()) ; print_newline ()
  with Stop_iteration -> print_endline "Stop iteration"

let () =
  try print_int (iter ()) ; print_newline ()
  with Stop_iteration -> print_endline "Stop iteration"

let () =
  try print_int (iter ()) ; print_newline ()
  with Stop_iteration -> print_endline "Stop iteration"

let () =
  try print_int (iter ()) ; print_newline ()
  with Stop_iteration -> print_endline "Stop iteration"

(* sending values back to the generator function *)
let gen yield =
  let rec loop () =
    (match (yield ()) with
       `None -> ()
     | `Int i -> Printf.printf "%d\n" i
     | `Float f -> Printf.printf "%f\n" f) ;
    loop ()
  in
  loop ()

let () =
  let iter = make_iterator gen in
  iter `None ;
  iter (`Int 100) ;
  iter (`Float 200.2)

let () = async (fun await resume ->
             let open Async_funcs in
             print_endline "About to sleep" ;
             await_sleep await resume 1. ;
             print_endline "Finished first sleep" ;
             await_sleep await resume 1. ;
             print_endline "Finished second sleep")

let check_ip = "checkip.dyndns.com"

let () = async (fun await resume ->
             match
               Async_funcs.await_http_get await resume check_ip "/" 80
             with
               Ok body ->
               (try
                  let rx = Str.regexp "[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+" in
                  ignore (Str.search_forward rx body 0) ;
                  Printf.printf "IP address is: %s\n" (Str.matched_string body)
                with Not_found ->
                  prerr_endline "IP address not found")
             | Error err -> print_endline err)
