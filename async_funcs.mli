val await_yield : (unit -> [> `Unit ]) -> ([> `Unit ] -> unit) -> unit

val await_sleep : (unit -> [> `Unit ]) -> ([> `Unit ] -> unit) -> float -> unit

val await_http_get : (unit -> [> `HttpGet of (string, string) Result.t ]) ->
                     ([> `HttpGet of (string, string) Result.t ] -> unit) ->
                     string -> string -> int -> (string, string) Result.t
