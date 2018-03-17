(* build with:
   ocamlfind ocamlc -package delimcc -linkpkg -o delimcc_nondet.byte delimcc_nondet.ml
*)

module type MONAD = sig
    type 'a m
    val return : 'a -> 'a m
    val bind : 'a m -> ('a -> ('b m)) -> 'b m
end

module type RMONAD = sig
  module M : MONAD
  open M
  type ans

  val reflect : 'a m -> 'a
  val reify : (unit -> ans) -> ans m
end

module Represent (A : sig module M : MONAD;; type ans end) : (RMONAD with module M = A.M and type ans = A.ans) = struct
  type ans = A.ans
  module M = A.M

  let prompt =
    Delimcc.new_prompt ()
  let reify t =
    Delimcc.push_prompt prompt (fun () -> M.return (t ()))
  let reflect m =
    Delimcc.shift prompt (fun k -> M.bind m k)
end

module ListMonad : (MONAD with type 'a m = 'a list) = struct
  type 'a m = 'a list

  let return x = [x]

  let rec bind l f = List.flatten (List.map f l)
end

module N = Represent(struct
  module M = ListMonad
  type ans = int list
end)

let choose xs = N.reflect xs
let withNondeterminism f = N.reify f

let n = int_of_string Sys.argv.(1)

let range =
  let rec range i =
    if i = n then []
    else i :: range (i + 1)
  in range 0

let rec okay i c = function
  | [] -> true
  | x::xs -> c <> x && (c-x) <> i && (c-x) <> -i && okay (i+1) c xs

let rec enum_nqueens i l =
  if i = n then
    l
  else begin
    let c = choose (List.filter (fun c -> okay 1 c l) range) in
    enum_nqueens (i + 1) (c :: l)
  end

let solutions = withNondeterminism (fun () -> enum_nqueens 0 [])

let () =
  print_int (List.length solutions);
  print_newline ()
