port module App exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as JD


-- PORTS


port initMapView : (List Node) -> Cmd msg
port doSearch : (List Node -> msg) -> Sub msg


-- MAIN


main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }


-- MODEL


type MyState
  = Init
  | Loading
  | Failure
  | Success (List Route)


type alias Model =
  { state: MyState
  }


type alias Node =
  { id: String
  , location: List Float
  , name: String
  }


type alias Route =
  { node_ids: List String
  , total_time: Int
  }


init : () -> (Model, Cmd Msg)
init _ =
  (Model Init, getNodes)


-- UPDATE


type Msg
  = Search (List Node)
  | GotRoutes (Result Http.Error (List Route))
  | GotNodes (Result Http.Error (List Node))


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Search nodes ->
      (model, (getRoutes nodes))

    GotRoutes result ->
      case result of
        Ok routes ->
          ({ model | state = Success routes }, Cmd.none)

        Err _ ->
          ({ model | state = Failure }, Cmd.none)

    GotNodes result ->
      case result of
        Ok nodes ->
          (model, initMapView nodes)

        Err _ ->
          ({ model | state = Failure }, Cmd.none)


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  doSearch Search


-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ h3 [] [ text "Route search example with Phoenix, Neo4j" ]
    , viewSearchResult model
    ]


viewSearchResult : Model -> Html Msg
viewSearchResult model =
  case model.state of
    Init ->
      text "Please select from/to nodes, then route search will executed."

    Loading ->
      text "Loading..."

    Failure ->
      text "Failed to load."

    Success routes ->
      let
        element (r) =
          let
            routing = r.node_ids |> String.join "-"
            total_time = r.total_time |> String.fromInt

          in
            li []
              [ text "total_time: "
              , text total_time
              , text "min, routing: "
              , text routing
              ]

      in
        div []
          [ ul [] (List.map element routes)
          ]


-- HTTP


getNodes : Cmd Msg
getNodes =
  let
    url = "http://localhost:4000/nodes"
  in
    Http.get
      { url = url
      , expect = Http.expectJson GotNodes nodesDecoder
      }


getRoutes : List Node -> Cmd Msg
getRoutes nodes =
  let
    from = getFromNodeId nodes
    to = getToNodeId nodes
    query = "from=" ++ from ++ "&to=" ++ to ++ "&limit=3"
    url = "http://localhost:4000/routes/search?" ++ query
  in
    Http.get
      { url = url
      , expect = Http.expectJson GotRoutes routesDecoder
      }


nodesDecoder : JD.Decoder (List Node)
nodesDecoder =
  JD.field "data" (JD.list nodeDecoder)


routesDecoder : JD.Decoder (List Route)
routesDecoder =
  JD.field "data" (JD.list routeDecoder)


nodeDecoder : JD.Decoder Node
nodeDecoder =
  JD.map3
    Node
    (JD.field "id" JD.string)
    (JD.field "location" (JD.list JD.float))
    (JD.field "name" JD.string)


routeDecoder : JD.Decoder Route
routeDecoder =
  JD.map2
    Route
    (JD.field "node_ids" (JD.list JD.string))
    (JD.field "total_time" JD.int)


getFromNodeId : List Node -> String
getFromNodeId nodes =
  case nodes |> List.head of
    Just node ->
      node.id

    Nothing ->
      ""


getToNodeId : List Node -> String
getToNodeId nodes =
  case nodes |> List.reverse |> List.head of
    Just node ->
      node.id

    Nothing ->
      ""
