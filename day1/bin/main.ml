open Claudius

type coord = { latitude : float; longitude : float }
type point = { x : float; y : float; z : float }

let radius = 60.

let rotate_x (a : float) (p : point) : point =
  {
    p with
    y = (p.y *. cos a) -. (p.z *. sin a);
    z = (p.y *. sin a) +. (p.z *. cos a);
  }

let rotate_y (a : float) (p : point) : point =
  {
    p with
    x = (p.x *. cos a) -. (p.z *. sin a);
    z = (p.x *. sin a) +. (p.z *. cos a);
  }

let _rotate_z (a : float) (p : point) : point =
  {
    p with
    x = (p.x *. cos a) -. (p.y *. sin a);
    y = (p.x *. sin a) +. (p.y *. cos a);
  }

let _point_z_cmp (a : point) (b : point) : int =
  if a.z == b.z then 0 else if a.z < b.z then 1 else -1

let geojson_to_points filename =
  let data = Yojson.Basic.from_file filename in
  let open Yojson.Basic.Util in
  let title = data |> member "name" |> to_string in
  Printf.printf "%s\n" title;

  let features = data |> member "features" |> to_list in
  Printf.printf "%d features\n" (List.length features);

  List.filter_map
    (fun feat ->
      let geometry = feat |> member "geometry" in
      let geom_type = geometry |> member "type" |> to_string in
      match geom_type with
      | "Point" -> (
          let coordinates = geometry |> member "coordinates" |> to_list in
          match List.length coordinates with
          | 2 ->
              let typed_coords = List.map to_float coordinates in
              Some
                {
                  longitude = List.nth typed_coords 0;
                  latitude = List.nth typed_coords 1;
                }
          | _ -> None)
      | _ -> None)
    features

let render_to_primitives (_ft : float) (s : Screen.t) (points : point list) :
    Primitives.t list =
  let width, height = Screen.dimensions s and palette = Screen.palette s in
  let m = 2000. +. (cos (0. /. 30.) *. 600.) in
  List.map
    (fun e ->
      Primitives.Pixel
        ( {
            x = (width / 2) + int_of_float (m *. e.x /. (e.z +. 400.));
            y = (height / 2) + int_of_float (m *. e.y /. (e.z +. 400.));
          },
          (Palette.size palette - 1) / if e.z < 0. then 1 else 3 ))
    points

let tick points t s prev _i =
  let buffer =
    Framebuffer.map
      (fun _pixel -> 0 (* if pixel > 4 then (pixel - 4) else 0*))
      prev
  in

  let ft = Float.of_int t in

  List.map (fun p -> rotate_y (0.01 *. ft) p |> rotate_x 0.1) points
  (* |> List.sort point_z_cmp*)
  (* |> List.filter_map (fun p ->
       if p.z < 0. then Some p else None
     )*)
  |> render_to_primitives ft s
  |> Framebuffer.render buffer;

  buffer

let pi = acos (-1.)
let deg_to_radians x = x /. 180. *. pi

let () =
  let filename =
    try Sys.argv.(1)
    with Invalid_argument _ -> failwith "Filename argument missing"
  in

  let points =
    geojson_to_points filename
    |> List.map (fun coord ->
           let lat = deg_to_radians coord.latitude
           and lng = deg_to_radians coord.longitude in
           {
             x = radius *. cos lat *. cos lng;
             y = radius *. sin lng *. cos lat;
             z = radius *. sin lat;
           }
           |> rotate_x (pi *. 0.5))
  in

  Palette.generate_mono_palette 16
  |> Screen.create 1024 1024 1
  |> Base.run "Day 1" None (tick points)
