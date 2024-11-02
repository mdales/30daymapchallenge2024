type t = { root : Yojson.Basic.t }
type coord = { latitude : float; longitude : float }

type geometry =
  | Point of coord
  | MultiPoint of coord list
  | List of coord list
  | MultiLineString of coord list list
  | None

let v root = { root }

let geometry v =
  let open Yojson.Basic.Util in
  let geometry = v.root |> member "geometry" in
  let geom_type = geometry |> member "type" |> to_string in
  match geom_type with
  | "Point" -> (
      let coordinates = geometry |> member "coordinates" |> to_list in
      match List.length coordinates with
      | 2 ->
          let typed_coords = List.map to_float coordinates in
          Point
            {
              longitude = List.nth typed_coords 0;
              latitude = List.nth typed_coords 1;
            }
      | _ -> None)
  | "MultiLineString" ->
      (* coordinates is a list of lists of points *)
      let list_of_list_of_coords =
        geometry |> member "coordinates" |> to_list
      in
      MultiLineString
        (List.map
           (fun line_node ->
             let list_of_coords = to_list line_node in
             List.filter_map
               (fun point_list ->
                 let coordinates = to_list point_list in
                 match List.length coordinates with
                 | 2 ->
                     let typed_coords = List.map to_float coordinates in
                     Some
                       {
                         longitude = List.nth typed_coords 0;
                         latitude = List.nth typed_coords 1;
                       }
                 | _ -> None)
               list_of_coords)
           list_of_list_of_coords)
  | _ -> None
