open ClaudiusII
open Graphics

let radius = 60.

let project s (v : vec) : Primitives.point =
  let width, height = Screen.dimensions s in
  let m = 2000. +. (cos (0. /. 30.) *. 600.) in
  {
    x = (width / 2) + int_of_float (m *. v.x /. (v.z +. 400.));
    y = (height / 2) + int_of_float (m *. v.y /. (v.z +. 400.));
  }

let render_to_primitives (_ft : float) (s : Screen.t)
    (elements : (elem * float) list) : Primitives.t list =
  let palette_size = Palette.size (Screen.palette s) - 1 in
  List.map
    (fun (e, c) ->
      let col = Int.of_float (Float.of_int palette_size *. c) in
      match e with
      | Point e ->
          Primitives.Point (project s e, col / if e.z < 0. then 1 else 3)
      | Line (a, b) ->
          Primitives.Line
            (project s a, project s b, col / if a.z < 0. then 1 else 3)
      | Triangle (a, b, c) ->
          Primitives.FilledTriangle (project s a, project s b, project s c, col)
      | Polygon vl ->
          let rep = Graphics.get_represent_vec e in
          Primitives.Polygon
            (Array.map (project s) vl, col / if rep.z < 0. then 1 else 3))
    elements

let rotate_element angle e =
  let rfunc x = rotate_x 0.1 (rotate_y angle x) in
  match e with
  | Point v -> Point (rfunc v)
  | Line (a, b) -> Line (rfunc a, rfunc b)
  | Triangle (a, b, c) -> Triangle (rfunc a, rfunc b, rfunc c)
  | Polygon vl -> Polygon (Array.map rfunc vl)

(* let tick elements t s prev _i =
   let buffer =
     Framebuffer.map
       (fun _pixel -> 128 (* if pixel > 4 then (pixel - 4) else 0*))
       prev
   in

   let ft = Float.of_int t in

   List.map
     (fun (coord, col) -> (rotate_element (0.01 *. ft) coord, col))
     elements
   |> List.sort (fun (a, _) (b, _) -> Graphics.element_z_cmp a b)
   (* |> List.filter_map (fun p ->
        if p.z < 0. then Some p else None
      )*)
   |> render_to_primitives ft s
   |> Framebuffer.render buffer;

   buffer*)

let tick elements t s _ _i =
  let ft = Float.of_int t in

  List.map
    (fun (coord, col) -> (rotate_element (0.01 *. ft) coord, col))
    elements
  |> List.sort (fun (a, _) (b, _) -> Graphics.element_z_cmp a b)
  (* |> List.filter_map (fun p ->
       if p.z < 0. then Some p else None
     )*)
  |> render_to_primitives ft s

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

let h3_lat_lng_to_vec (coord : H3.lat_lng) =
  let lat = coord.lat and lng = coord.lon in
  {
    x = radius *. cos lat *. cos lng;
    y = radius *. sin lng *. cos lat;
    z = radius *. sin lat;
  }
  |> rotate_x (pi *. 0.5)

let load_data_from_geojson filename =
  let features = Geojson.of_file filename |> Geojson.features in
  List.concat_map
    (fun feat ->
      match Feature.geometry feat with
      | Point coord -> [ (Point (coord_to_vec coord), 1.0) ]
      | MultiLineString lines ->
          List.concat_map
            (fun coordinate_list ->
              match coordinate_list with
              | [] | _ :: [] -> []
              | hd1 :: hd2 :: tl ->
                  let rec loop last next rest acc =
                    let n =
                      (Line (coord_to_vec last, coord_to_vec next), 1.0) :: acc
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
              [
                ( Polygon
                    (Array.map coord_to_vec (Array.of_list coordinate_list)),
                  1.0 );
              ]
          | _ -> [])
      | _ -> [])
    features

let load_data_from_csv filename =
  In_channel.with_open_text filename (fun inc ->
      let csv_inc = Csv.of_channel inc in
      let max_val =
        Csv.fold_left
          ~f:(fun acc row ->
            match row with
            | [ _cellid; value ] ->
                let fvalue = Float.of_string value in
                if fvalue > acc then fvalue else acc
            | _ -> acc)
          ~init:0.0 csv_inc
      in
      Printf.printf "%f\n" max_val;
      In_channel.seek inc 0L;
      let csv_inc = Csv.of_channel inc in
      Csv.fold_left
        ~f:(fun acc row ->
          match row with
          | [ cellid; value ] -> (
              let cell = H3.string_to_h3 cellid in
              let boundary = H3.cell_to_boundary cell in
              match boundary with
              | [||] -> acc
              | _ ->
                  ( Polygon (Array.map h3_lat_lng_to_vec boundary),
                    Float.of_string value /. max_val )
                  :: acc)
          | _ -> failwith "unable to parse CSV row")
        ~init:[] csv_inc)

let load_data_from_file filename =
  match Filename.extension filename with
  | ".geojson" | ".json" -> load_data_from_geojson filename
  | ".csv" -> load_data_from_csv filename
  | _ -> failwith (Printf.sprintf "Unrecognised file extension on %s" filename)

let () =
  let args_list = List.tl (Array.to_list Sys.argv) in

  let elements = List.concat_map load_data_from_file args_list in

  Printf.printf "%d elements\n" (List.length elements);

  Palette.generate_mono_palette 256
  |> Screen.create 1024 1024 1
  |> Base.run "Day 1" None (tick elements)
