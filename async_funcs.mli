val await_sleep : (unit -> [> `Unit ]) -> ([> `Unit ] -> 'a) -> float -> unit

val await_http_get : (unit -> [> `Get of (string, string) Result.t ]) ->
                     ([> `Get of (string, string) Result.t ] -> unit) ->
                     string -> string -> int -> (string, string) Result.t
