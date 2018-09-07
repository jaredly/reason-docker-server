open Lwt
open Cohttp
open Cohttp_lwt_unix

let count = ref 0

let server =
  let callback _conn req body =
    let uri = req |> Request.uri |> Uri.to_string in
    let meth = req |> Request.meth |> Code.string_of_method in
    let headers = req |> Request.headers |> Header.to_string in
    count := count.contents + 1;
    body |> Cohttp_lwt.Body.to_string >|= (fun body ->
      (Printf.sprintf "Hello folks! This site has been visited %d times\n\nUri: %s\nMethod: %s\nHeaders\nHeaders: %s\nBody: %s"
         count.contents uri meth headers body))
    >>= (fun body -> Server.respond_string ~status:`OK ~body ())
  in
  Server.create ~mode:(`TCP (`Port 8000)) (Server.make ~callback ())

let () = ignore (Lwt_main.run server)