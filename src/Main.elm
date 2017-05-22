module Main exposing (..)

import Markdown
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as Decode


-- APP


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- INIT


init : ( Model, Cmd Msg )
init =
    let
        model =
            initialModel
    in
        -- model ! [ getStopDepartures model.selectedStop, getAllArticles ]
        model ! [ getAllArticles ]



-- MODEL


type alias Model =
    { articles : List Article
    , loadError : String
    }



-- { departures : List Departure
-- , stops : List StopID
-- , selectedStop : StopID
-- , articles : List Article
-- , loadError : String
-- }


type alias Article =
    { url : String
    , title : String
    , ingress : String
    , body : String
    , slug : String
    , publish : Bool
    , created : String
    , modified : String
    }



-- type alias StopID =
--     Int
-- type alias Departure =
--     { recordedAt : String
--     , meta : DepartureDetail
--     }
-- type alias DepartureDetail =
--     { destination : String
--     , line : String
--     , time : DepartureTime
--     }
-- type alias DepartureTime =
--     { aimedArrival : String
--     , expectedArrival : String
--     , aimedDeparture : String
--     , expectedDeparture : String
--     }


initialModel : Model
initialModel =
    { articles = []
    , loadError = ""
    }



-- { departures = []
-- , stops = [ 3012120, 3012122, 3012121, 3010465, 3012123 ]
-- , selectedStop = 3012120
-- , articles = []
-- , loadError = ""
-- }
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- UPDATE


type Msg
    = NoOp
    | GetAllArticles (Result Http.Error (List Article))



-- | LoadDepartures (Result Http.Error (List Departure))
-- | SetSelectedStop String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GetAllArticles (Result.Ok articles) ->
            ( { model | articles = articles }, Cmd.none )

        GetAllArticles (Result.Err err) ->
            ( { model | loadError = toString err, articles = [] }, Cmd.none )



-- LoadDepartures (Result.Ok deps) ->
--     ( { model | departures = deps }, Cmd.none )
-- LoadDepartures (Result.Err err) ->
--     ( { model | departures = [], loadError = toString err }, Cmd.none )
-- SetSelectedStop stopId ->
--     let
--         stopIdIntValue =
--             Result.withDefault 3012120 (String.toInt stopId)
--     in
--         ( { model | selectedStop = stopIdIntValue, departures = [] }, getStopDepartures stopIdIntValue )


getAllArticles : Cmd Msg
getAllArticles =
    let
        request =
            Http.get "/api/articles/" decodeArticleList
    in
        Http.send GetAllArticles request


decodeArticleList : Decode.Decoder (List Article)
decodeArticleList =
    Decode.list decodeArticle


decodeArticle : Decode.Decoder Article
decodeArticle =
    Decode.map8 Article
        (Decode.field "url" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "ingress" Decode.string)
        (Decode.field "body" Decode.string)
        (Decode.field "slug" Decode.string)
        (Decode.field "publish" Decode.bool)
        (Decode.field "created" Decode.string)
        (Decode.field "modified" Decode.string)



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ renderHeader
        , div [ id "main-content", class "container" ] [ renderArticles model ]
        ]


renderArticles : Model -> Html Msg
renderArticles model =
    section [ id "article-container" ]
        [ case model.articles of
            [] ->
                div [] [ h2 [] [ text "Loading..." ] ]

            _ ->
                div []
                    (model.articles
                        |> List.filter (\a -> a.publish == True)
                        |> List.map (\a -> renderArticle a)
                    )
        ]


renderArticle : Article -> Html Msg
renderArticle rawArticle =
    article [ class "article" ]
        [ section [ class "article-title" ] [ h1 [] [ text rawArticle.title ] ]
        , section [ class "article-ingress" ] [ p [] [ text rawArticle.ingress ] ]
        , section [ class "article-body" ] [ Markdown.toHtml [] rawArticle.body ]
        ]


renderHeader : Html Msg
renderHeader =
    header [ id "main-header" ]
        [ div [ class "container" ]
            [ div [ id "logo" ] [ span [] [ text "h" ] ]
            , a [ href "/" ] [ h3 [] [ text "hakloev.no" ] ]
            , nav []
                [ ul []
                    [ li [] [ a [ href "https://cv.hakloev.no" ] [ text "CV" ] ]
                    , li [] [ a [ href "https://github.com/hakloev/" ] [ text "GitHub" ] ]
                    , li [] [ a [ href "https://twitter.com/hakloevdal/" ] [ text "Twitter" ] ]
                    ]
                ]
            ]
        ]



-- getStopDepartures : StopID -> Cmd Msg
-- getStopDepartures stopId =
--     let
--         request =
--             Http.get ("http://reisapi.ruter.no/StopVisit/GetDepartures/" ++ toString stopId) decodeDepartureList
--     in
--         Http.send LoadDepartures request
-- decodeDepartureList : Decode.Decoder (List Departure)
-- decodeDepartureList =
--     Decode.list decodeDeparture
-- decodeDeparture : Decode.Decoder Departure
-- decodeDeparture =
--     Decode.map2 Departure
--         (Decode.field "RecordedAtTime" Decode.string)
--         (Decode.field "MonitoredVehicleJourney" decodeDepartureDetail)
-- decodeDepartureDetail : Decode.Decoder DepartureDetail
-- decodeDepartureDetail =
--     Decode.map3 DepartureDetail
--         (Decode.field "DestinationName" Decode.string)
--         (Decode.field "PublishedLineName" Decode.string)
--         (Decode.field "MonitoredCall" decodeDepartureTime)
-- decodeDepartureTime : Decode.Decoder DepartureTime
-- decodeDepartureTime =
--     Decode.map4 DepartureTime
--         (Decode.field "AimedArrivalTime" Decode.string)
--         (Decode.field "ExpectedArrivalTime" Decode.string)
--         (Decode.field "AimedDepartureTime" Decode.string)
--         (Decode.field "ExpectedDepartureTime" Decode.string)
-- departureDetail : Departure -> Html Msg
-- departureDetail departure =
--     div []
--         [ h2 [] [ text <| departure.meta.line ++ " - " ++ departure.meta.destination ]
--         -- , p [] [ text <| formatedDateString departure.meta.time.expectedArrival ]
--         , p [] [ text <| formatedDateString departure.meta.time.expectedDeparture ]
--         ]
-- stopSelect : List StopID -> Html Msg
-- stopSelect stops =
--     div []
--         [ select [ onInput SetSelectedStop ]
--             (List.map (\stopId -> option [ value (toString stopId) ] [ text (toString stopId) ]) stops)
--         ]
-- formatedDateString : String -> String
-- formatedDateString dateString =
--     case Date.fromString dateString of
--         Ok date ->
--             toString (Date.hour date) ++ ":" ++ padMinuteString (Date.minute date)
--         Err err ->
--             "Error parsing date"
-- padMinuteString : Int -> String
-- padMinuteString min =
--     if min < 10 then
--         "0" ++ toString min
--     else
--         toString min
