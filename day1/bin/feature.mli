type t
type coord = { latitude : float; longitude : float }

type geometry =
  | Point of coord
  | MultiPoint of coord list
  | List of coord list
  | MultiLineString of coord list list
  | None

val v : Yojson.Basic.t -> t
val geometry : t -> geometry
