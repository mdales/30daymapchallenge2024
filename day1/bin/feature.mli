type t
type coord = { latitude : float; longitude : float }

type geometry =
  | Point of coord
  | LineString of coord list
  | Polygon of coord list list
  | None

(* Not complete... *)
type property = String of string | Int of int | Float of float | Null

val v : Yojson.Basic.t -> t
val geometries : t -> geometry list
val property_keys : t -> string list
val property : t -> string -> property option
