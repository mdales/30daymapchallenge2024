open Claudius
open Graphics

let radius = 60.

let project s (v : vec) : Primitives.point =
  let width, height = Screen.dimensions s in
  let m = 2000. +. (cos (0. /. 30.) *. 600.) in
  {
    x = (width / 2) + int_of_float (m *. v.x /. (v.z +. 400.));
    y = (height / 2) + int_of_float (m *. v.y /. (v.z +. 400.));
  }

let render_to_primitives (_ft : float) (s : Screen.t) (elements : elem list) :
    Primitives.t list =
  let palette = Screen.palette s in
  List.map
    (fun e ->
      match e with
      | Point e ->
          Primitives.Pixel
            (project s e, (Palette.size palette - 1) / if e.z < 0. then 1 else 3)
      | Line (a, b) ->
          Primitives.Line
            ( project s a,
              project s b,
              (Palette.size palette - 1) / if a.z < 0. then 1 else 3 )
      | Triangle (a, b, c) ->
          Primitives.FilledTriangle
            (project s a, project s b, project s c, Palette.size palette - 1)
      | Polygon vl ->
          Primitives.FilledPolygon
            (List.map (project s) vl, Palette.size palette - 1))
    elements

let rotate_element angle e =
  let rfunc x = rotate_x 0.1 (rotate_y angle x) in
  match e with
  | Point v -> Point (rfunc v)
  | Line (a, b) -> Line (rfunc a, rfunc b)
  | Triangle (a, b, c) -> Triangle (rfunc a, rfunc b, rfunc c)
  | Polygon vl -> Polygon (List.map rfunc vl)

let tick elements t s prev _i =
  let buffer =
    Framebuffer.map
      (fun _pixel -> 0 (* if pixel > 4 then (pixel - 4) else 0*))
      prev
  in

  let ft = Float.of_int t in

  List.map (rotate_element (0.01 *. ft)) elements
  (* |> List.sort point_z_cmp*)
  (* |> List.filter_map (fun p ->
       if p.z < 0. then Some p else None
     )*)
  |> render_to_primitives ft s
  |> Framebuffer.render buffer;

  buffer

let pi = acos (-1.)
let deg_to_radians x = x /. 180. *. pi

let coord_to_vec (coord : Feature.coord) =
  let lat = deg_to_radians coord.latitude
  and lng = deg_to_radians coord.longitude in
  {
    x = radius *. cos lat *. cos lng;
    y = radius *. sin lng *. cos lat;
    z = radius *. sin lat;
  }
  |> rotate_x (pi *. 0.5)

let () =
  let args_list = List.tl (Array.to_list Sys.argv) in

  let features =
    List.concat_map
      (fun filename -> Geojson.of_file filename |> Geojson.features)
      args_list
  in

  let elements =
    List.concat_map
      (fun feat ->
        match Feature.geometry feat with
        | Point coord -> [ Point (coord_to_vec coord) ]
        | MultiLineString lines ->
            List.concat_map
              (fun coordinate_list ->
                match coordinate_list with
                | [] | _ :: [] -> []
                | hd1 :: hd2 :: tl ->
                    let rec loop last next rest acc =
                      let n =
                        Line (coord_to_vec last, coord_to_vec next) :: acc
                      in
                      match rest with [] -> n | hd :: tl -> loop next hd tl n
                    in
                    loop hd1 hd2 tl [])
              lines
        | Polygon coordinate_list_list -> (
            (* GeoJSON polygons are lists of polygons, with the first being the outer and the rest being holes.
               Claudius doesn't model those, so we just process the first one and ignore the others for now.
            *)
            match coordinate_list_list with
            | coordinate_list :: _ ->
                [ Polygon (List.map coord_to_vec coordinate_list) ]
            | _ -> [])
        | _ -> [])
      features
  in

  Printf.printf "%d features\n" (List.length features);
  Printf.printf "%d elements\n" (List.length elements);

  Palette.generate_mono_palette 16
  |> Screen.create 1024 1024 1
  |> Base.run "Day 1" None (tick elements)
