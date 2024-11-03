type vec = { x : float; y : float; z : float }

type elem =
  | Point of vec
  | Line of vec * vec
  | Triangle of vec * vec * vec
  | Polygon of vec list

let rotate_x (a : float) (p : vec) : vec =
  {
    p with
    y = (p.y *. cos a) -. (p.z *. sin a);
    z = (p.y *. sin a) +. (p.z *. cos a);
  }

let rotate_y (a : float) (p : vec) : vec =
  {
    p with
    x = (p.x *. cos a) -. (p.z *. sin a);
    z = (p.x *. sin a) +. (p.z *. cos a);
  }

let rotate_z (a : float) (p : vec) : vec =
  {
    p with
    x = (p.x *. cos a) -. (p.y *. sin a);
    y = (p.x *. sin a) +. (p.y *. cos a);
  }

let point_z_cmp (a : vec) (b : vec) : int =
  if a.z == b.z then 0 else if a.z < b.z then 1 else -1
