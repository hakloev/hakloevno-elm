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
        model ! [ getAllArticles, getDetailedForecasts, getTextualForecasts ]



-- MODEL


type alias Model =
    { articles : List Article
    , detailedForecasts : List DetailedForecast
    , textualForecasts : List TextualForecast
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


type alias DetailedForecast =
    { from : String
    , to : String
    , icon : String
    , temperature : String
    , pressure : String
    , precipitation : String
    , windSpeed : WindSpeed
    , windDirection : WindDirection
    }


type alias WindDirection =
    { direction : String
    , degrees : String
    }


type alias WindSpeed =
    { beaufort : String
    , mps : String
    }


type alias TextualForecast =
    { from : String
    , to : String
    , kind : String
    , forecast : String
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
    , detailedForecasts = []
    , textualForecasts = []
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
    | GetArticles (Result Http.Error (List Article))
    | GetDetailedForecasts (Result Http.Error (List DetailedForecast))
    | GetTextualForecasts (Result Http.Error (List TextualForecast))



-- | LoadDepartures (Result Http.Error (List Departure))
-- | SetSelectedStop String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GetArticles (Result.Ok articles) ->
            ( { model | articles = articles }, Cmd.none )

        GetArticles (Result.Err err) ->
            ( { model | loadError = toString err, articles = [] }, Cmd.none )

        GetDetailedForecasts (Result.Ok forecasts) ->
            -- Should probably also add a check for empty list here?
            let
                newForecasts =
                    -- Take the first forecast after sorting by to-timestamp
                    List.sortBy (\f -> f.to) forecasts |> List.take 1
            in
                ( { model | detailedForecasts = newForecasts }, Cmd.none )

        GetDetailedForecasts (Result.Err err) ->
            ( { model | loadError = toString err, detailedForecasts = [] }, Cmd.none )

        GetTextualForecasts (Result.Ok forecasts) ->
            ( { model | textualForecasts = forecasts }, Cmd.none )

        GetTextualForecasts (Result.Err err) ->
            ( { model | loadError = toString err, textualForecasts = [] }, Cmd.none )



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


forecastLocation : String
forecastLocation =
    "?lat=59.94&lon=10.77"


getTextualForecasts : Cmd Msg
getTextualForecasts =
    let
        request =
            Http.get ("/api/weather/location/text/" ++ forecastLocation) decodeTextualForecasts
    in
        Http.send GetTextualForecasts request


decodeTextualForecasts : Decode.Decoder (List TextualForecast)
decodeTextualForecasts =
    let
        forecastDecoder =
            Decode.list decodeTextualForecast
    in
        Decode.at [ "forecasts" ] forecastDecoder


decodeTextualForecast : Decode.Decoder TextualForecast
decodeTextualForecast =
    Decode.map4 TextualForecast
        (Decode.field "from" Decode.string)
        (Decode.field "to" Decode.string)
        (Decode.field "type" Decode.string)
        (Decode.field "forecast" Decode.string)


getDetailedForecasts : Cmd Msg
getDetailedForecasts =
    let
        request =
            Http.get ("/api/weather/location/" ++ forecastLocation) decodeDetailedForecasts
    in
        Http.send GetDetailedForecasts request


decodeDetailedForecasts : Decode.Decoder (List DetailedForecast)
decodeDetailedForecasts =
    let
        forecastDecoder =
            Decode.list decodeDetailedForecast
    in
        Decode.at [ "forecasts" ] forecastDecoder


decodeDetailedForecast : Decode.Decoder DetailedForecast
decodeDetailedForecast =
    Decode.map8 DetailedForecast
        (Decode.field "from" Decode.string)
        (Decode.field "to" Decode.string)
        (Decode.field "icon" decodeIcon)
        (Decode.field "temperature" decodeTemperature)
        (Decode.field "pressure" decodePressure)
        (Decode.field "precipitation" decodePrecipitation)
        (Decode.field "windSpeed" decodeWindSpeed)
        (Decode.field "windDirection" decodeWindDirection)


decodeIcon : Decode.Decoder String
decodeIcon =
    Decode.field "number" Decode.string


decodeTemperature : Decode.Decoder String
decodeTemperature =
    Decode.field "value" Decode.string


decodePressure : Decode.Decoder String
decodePressure =
    Decode.field "value" Decode.string


decodePrecipitation : Decode.Decoder String
decodePrecipitation =
    Decode.field "value" Decode.string


decodeWindSpeed : Decode.Decoder WindSpeed
decodeWindSpeed =
    Decode.map2 WindSpeed
        (Decode.field "name" Decode.string)
        (Decode.field "mps" Decode.string)


decodeWindDirection : Decode.Decoder WindDirection
decodeWindDirection =
    Decode.map2 WindDirection
        (Decode.field "name" Decode.string)
        (Decode.field "deg" Decode.string)


getAllArticles : Cmd Msg
getAllArticles =
    let
        request =
            Http.get "/api/articles/" decodeArticleList
    in
        Http.send GetArticles request


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
        , div [ id "spacer" ] []
        , div [ id "forecast-container" ] [ renderForecastWidget model ]
        , div [ id "main-content", class "container" ] [ renderArticles model ]
        ]


renderForecastWidget : Model -> Html Msg
renderForecastWidget model =
    div [ class "container" ]
        [ case model.detailedForecasts of
            [] ->
                div [ id "forecast-loading" ] [ h2 [] [ text "Loading weather..." ] ]

            forecasts ->
                renderForecast model
        ]


renderForecast : Model -> Html Msg
renderForecast model =
    let
        detailedForecast =
            let
                data =
                    -- List.sortBy (\f -> f.from) model.textualForecasts |> List.head
                    List.head model.detailedForecasts
            in
                div [] [ renderDetailedForecast data ]

        textualForecast =
            let
                data =
                    List.sortBy (\f -> f.from) model.textualForecasts |> List.head
            in
                div [ id "forecast-textual" ] [ renderTextualForecast data ]
    in
        div []
            [ detailedForecast
            , textualForecast
            ]


renderDetailedForecast : Maybe DetailedForecast -> Html Msg
renderDetailedForecast data =
    case data of
        Just h ->
            div []
                [ div [ id "forecast-city" ] [ h3 [] [ text "Trondheim" ] ]
                , div []
                    [ div [ id "forecast-main-data" ]
                        [ div [ id "forecast-icon" ] [ img [ src ("static/weather/" ++ h.icon ++ ".svg") ] [] ]
                        , div [ id "forecast-degrees" ] [ span [] [ text (h.temperature ++ "°C") ] ]
                        ]
                    , div [ id "forecast-details" ]
                        [ ul []
                            [ li [] [ span [] [ text (h.windSpeed.mps ++ " m/s " ++ h.windDirection.direction) ] ]
                            , li [] [ span [] [ text (h.precipitation ++ "mm") ] ]
                            , li [] [ span [] [ text (h.pressure ++ " hPa") ] ]
                            ]
                        ]
                    ]
                ]

        Nothing ->
            div [] [ text "No forecast found..." ]


renderTextualForecast : Maybe TextualForecast -> Html Msg
renderTextualForecast data =
    case data of
        Just d ->
            p [] [ text d.forecast ]

        Nothing ->
            p [] [ text "No textual forecast found..." ]


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
